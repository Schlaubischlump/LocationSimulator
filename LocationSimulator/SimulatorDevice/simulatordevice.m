//
//  simulatordevice.c
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

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
- (BOOL)requiresBrdige;
@end

@implementation SimDeviceWrapper

static SimDeviceSet *defaultSet = nil;
/// Keep a list with all currently available devices.
static NSMutableSet<SimDeviceWrapper *> *knownDevices;

+ (void)initialize {
    // Load the CoreSimulator library or fail if it can not be loaded.
    NSString *coreSimulatorPath = @"/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator";
    if (!load_bundle(coreSimulatorPath)) {
        NSLog(@"[Error]: Could not load library: %@", coreSimulatorPath);
        return;
    }
    // Get the active developer directory.
    NSString *path = getActiveDeveloperDir();
    if (!path) {
        NSLog(@"[Error]: Could not get active developer directory.");
        return;
    }
    // Try to create a SimServiceContext instance for the active developer directory.
    NSError *error = nil;
    SimServiceContext* context = [NSClassFromString(@"SimServiceContext") serviceContextForDeveloperDir:path
                                                                                                  error:&error];
    if (!context || (error != nil)) {
        NSLog(@"[Error]: Could not create 'SimServiceContext' instance.");
        return;
    }
    // Create a default device set based on the SimServiceContext.
    SimDeviceSet *set = [context defaultDeviceSetWithError:&error];
    if (error != nil) {
        NSLog(@"[Error]: Could not get default 'SimDeviceSet'.");
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

    return [defaultSet registerNotificationHandler:^(NSDictionary* info) {
        NSString *notification_name = info[@"notification"];
        if ([notification_name isEqualToString: @"SimDeviceNotificationType_BootStatus"]) {
            // This notificaton appears when the device did finish booting
            SimDeviceBootInfo* bootInfo = info[@"SimDeviceNotification_NewBootStatus"];
            if (bootInfo.isTerminalStatus && bootInfo.status == SimBootStatusFinished)
            {
                SimDeviceWrapper *deviceWrapper = [[SimDeviceWrapper alloc] initWithDevice:info[@"device"]];
                [knownDevices addObject:deviceWrapper];
                handler(deviceWrapper);
            }
        }
        // When ever any device status changes.
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
    }];
}

+ (BOOL)unsubscribe:(NSUInteger)handlerID {
    if (!defaultSet)
        return FALSE;
    return [defaultSet unregisterNotificationHandler:handlerID error:NULL];
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

- (BOOL)requiresBrdige {
    if ([_device respondsToSelector:@selector(setLocationWithLatitude:andLongitude:error:)]) {
        return FALSE;
    }
    return TRUE;
}

- (void)connect {
    // Find the correct pid and get a bridge connection (XCode <= 12.4)
    if ([self requiresBrdige]) {
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
    if ([self requiresBrdige] && _bridge == NULL) {
        return FALSE;
    }
    return _isConnected;
}

- (BOOL)setLocationWithLatitude:(double)latitude andLongitude:(double)longitude {
    if ([self requiresBrdige]) {
        if (!_bridge) return FALSE;
        [_bridge setLocationWithLatitude:latitude andLongitude:longitude];
        return TRUE;
    }

    NSError *error;
    [_device setLocationWithLatitude:latitude andLongitude:longitude error:&error];
    return error == NULL;
}

- (BOOL)resetLocation {
    // There is no reset function for Xcode <= 12.4
    if ([self requiresBrdige])
        return _bridge != nil;

    NSError *error;
    [_device clearSimulatedLocationWithError:&error];
    return error == NULL;
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
