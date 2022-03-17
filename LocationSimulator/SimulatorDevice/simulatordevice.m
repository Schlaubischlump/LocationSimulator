//
//  simulatordevice.c
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

#import "LocationSimulator-Swift.h"
#include "simulatordevice.h"
#include "util.h"

@interface SimDeviceWrapper() {
    SimDevice *_device;
    SimulatorBridge *_bridge;
    pid_t _pid;
    BOOL _isConnected;
}
- (instancetype)initWithDevice:(SimDevice * _Nonnull)device;
/**
 True if simulator bridge is required to spoof the location, False otherwise.
 Xcode <= 12.4 require the simulator bridge. Xcode >= 12.5 can use SimDevice directly.
 */
- (BOOL)requiresBridge;
@end

@implementation SimDeviceWrapper

static SimDeviceSet *defaultSet = nil;
/// Keep a list with all currently available devices.
static NSMutableSet<SimDeviceWrapper *> *knownDevices;

+ (void)initialize {
    // This is called before any other function... Make sure the logger exists
    [[NSFileManager defaultManager] initLogger];

    // Load the CoreSimulator library or fail if it can not be loaded.
    NSString *coreSimulatorPath = @"/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator";
    if (!load_bundle(coreSimulatorPath)) {
        LOG_ERROR("SimDeviceWrapper: CoreSimulator '%s': Load failed!", coreSimulatorPath.UTF8String);
        return;
    }
    // Get the active developer directory.
    NSString *path = getActiveDeveloperDir();
    if (!path) {
        LOG_ERROR("SimDeviceWrapper: Could not get active developer directory!", coreSimulatorPath.UTF8String);
        return;
    }
    // Try to create a SimServiceContext instance for the active developer directory.
    NSError *error = nil;

    Class _SimServiceContext = NSClassFromString(@"SimServiceContext");
    SimServiceContext* context = NULL;
    if ([_SimServiceContext respondsToSelector:@selector(serviceContextForDeveloperDir:error:)]) {
        context = [_SimServiceContext serviceContextForDeveloperDir:path error:&error];
    }

    if (!context || (error != nil)) {
        LOG_ERROR("SimDeviceWrapper: Could not create 'SimServiceContext' instance.");
        return;
    }
    // Create a default device set based on the SimServiceContext.
    SimDeviceSet *set = NULL;
    if ([context respondsToSelector:@selector(defaultDeviceSetWithError:)]) {
        set = [context defaultDeviceSetWithError:&error];
    }
    if (!set || (error != nil)) {
        LOG_ERROR("SimDeviceWrapper: Could not get default 'SimDeviceSet'.");
        return;
    }
    defaultSet = set;
    knownDevices = [[NSMutableSet<SimDeviceWrapper *> alloc] init];
}

+ (NSUInteger)subscribe:(void (^ _Nonnull)(SimDeviceWrapper * _Nonnull))handler {
    if (!defaultSet)
        return -1;

    // Send a notification for all already connected devices.
    for (SimDevice *device in defaultSet.availableDevices) {
        SimDeviceWrapper *deviceWrapper = [[SimDeviceWrapper alloc] initWithDevice:device];
        // The device might not be ready yet. Just skip it, the device detection notification will handle it.
        if (![deviceWrapper isConnected])
            continue;
        [knownDevices addObject:deviceWrapper];
        handler(deviceWrapper);
    }

    void (^deviceDetectedHandler)(NSDictionary * _Nullable) = ^(NSDictionary* info) {
        NSString *notification_name = info[@"notification"];
        if ([notification_name isEqualToString: @"SimDeviceNotificationType_BootStatus"]) {
            // This notificaton appears when the device did finish booting
            SimDeviceBootInfo* bootInfo = info[@"SimDeviceNotification_NewBootStatus"];

            if (bootInfo == nil) {
                LOG_FATAL("SimDeviceWrapper: 'SimDeviceNotification_NewBootStatus' not found in info dictionary.");
            }

            if (bootInfo.isTerminalStatus && bootInfo.status == SimBootStatusFinished)
            {
                SimDeviceWrapper *deviceWrapper = [[SimDeviceWrapper alloc] initWithDevice:info[@"device"]];
                [knownDevices addObject:deviceWrapper];
                handler(deviceWrapper);
            }
        }
        // Whenever any device status changes
        if ([notification_name isEqualToString: @"availableDevices_changed"]) {
            NSArray<NSString *> *udids = [defaultSet.availableDevices valueForKeyPath:@"UDID.UUIDString"];

            NSMutableArray<SimDeviceWrapper *> *devicesToRemove = [[NSMutableArray alloc] init];
            for (SimDeviceWrapper *deviceWrapper in knownDevices) {
                if (![udids containsObject:deviceWrapper.udid]) {
                    [deviceWrapper disconnect];
                    [devicesToRemove addObject:deviceWrapper];
                    handler(deviceWrapper);
                }
            }

            for (SimDeviceWrapper *deviceWrapper in devicesToRemove) {
                [knownDevices removeObject:deviceWrapper];
            }
        }
    };

    if ([defaultSet respondsToSelector:@selector(registerNotificationHandler:)]) {
        // Xcode 12.x
        return [defaultSet registerNotificationHandler: deviceDetectedHandler];
    } else if ([defaultSet respondsToSelector:@selector(registerNotificationHandlerOnQueue:handler:)]) {
        // Xcode 13.x
        return [defaultSet registerNotificationHandlerOnQueue: NULL handler: deviceDetectedHandler];
    } else {
        LOG_FATAL("SimDeviceWrapper: Could not register notification handler. No viable method found.");
    }
    return -1;
}

+ (BOOL)unsubscribe:(NSUInteger)handlerID {
    if (!defaultSet)
        return FALSE;

    if ([defaultSet respondsToSelector:@selector(unregisterNotificationHandler:error:)]) {
        NSError *error = nil;
        BOOL success = [defaultSet unregisterNotificationHandler:handlerID error:&error];
        return success && error == nil;
    } else {
        LOG_FATAL("SimDeviceWrapper: Could not unregister notification handler. No viable method found.");
    }

    return FALSE;
}

- (instancetype)initWithDevice:(SimDevice * _Nonnull)device {
    if (self = [super init]) {
        _device = device;
        _bridge = NULL;
        _pid = 0;

        [self connect];
    }
    return self;
}

- (NSString * _Nonnull)udid {
    return _device.UDID.UUIDString;
}

- (NSString * _Nonnull)name {
    return _device.name;
}

- (BOOL)requiresBridge {
    // FIXME: This is not the best check... If apple decides to change this method name in the future, we will fallback
    // FIXME: to using the bridge connection, which will fail. Keep an eye on this.
    if ([_device respondsToSelector:@selector(setLocationWithLatitude:andLongitude:error:)]) {
        return FALSE;
    }
    return TRUE;
}

- (void)connect {
    // Find the correct pid and get a bridge connection (XCode <= 12.4)
    if ([self requiresBridge]) {
        _isConnected = FALSE;
        NSArray<NSNumber *>* simualtorPorts = getSimulatorPIDs();

        for (NSNumber *simPID in simualtorPorts) {
            _pid = (pid_t)simPID.intValue;
            _bridge = bridgeForSimDevice(_device, getBridgePortName(_pid));
            if (_bridge != NULL) {
                _isConnected = TRUE;
                break;
            }
        }
    } else {
        _isConnected = TRUE;
    }
}

- (void)disconnect {
    _isConnected = FALSE;
    _bridge = NULL;
    _pid = 0;
}

- (BOOL)isConnected {
    if ([self requiresBridge] && _bridge == NULL) {
        return FALSE;
    }
    return _isConnected;
}

- (BOOL)setLocationWithLatitude:(double)latitude andLongitude:(double)longitude {
    if ([self requiresBridge]) {
        if (!_bridge) return FALSE;
        [_bridge setLocationWithLatitude:latitude andLongitude:longitude];
        return TRUE;
    }

    // Requires bridge checks that this function exists. It is save to call it here.
    NSError *error;
    [_device setLocationWithLatitude:latitude andLongitude:longitude error:&error];
    return error == NULL;
}

- (BOOL)resetLocation {
    // There is no reset function for Xcode <= 12.4
    if ([self requiresBridge])
        return _bridge != nil;

    NSError *error = NULL;
    if ([_device respondsToSelector:@selector(clearSimulatedLocationWithError:)]) {
        [_device clearSimulatedLocationWithError:&error];
        return error == NULL;
    }

    LOG_FATAL("SimDeviceWrapper: Could not clear location. No viable method found.");
    return FALSE;
}

@end


@implementation SimDeviceWrapper(Equatable)

- (BOOL)isEqual:(SimDeviceWrapper *)device
{
    return [self.udid isEqual:device.udid];
}

- (NSUInteger)hash
{
    return [self.udid hash];
}

@end
