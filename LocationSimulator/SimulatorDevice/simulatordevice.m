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
}
- (instancetype)initWithDevice:(SimDevice * _Nonnull)device andBridge:(SimulatorBridge * _Nullable)bridge;
@end

@implementation SimDeviceWrapper

static SimDeviceSet *defaultSet = nil;

+ (void)initialize {
    // Load the CoreSimulator library
    load_bundle(@"/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator");

    NSString *path = getActiveDeveloperDir();
    if (!path) return;
    SimServiceContext* context = [NSClassFromString(@"SimServiceContext") serviceContextForDeveloperDir:path error:NULL];
    if (!context) return;
    defaultSet = [context defaultDeviceSetWithError:nil];
}

+ (NSUInteger)subscribe:(void (^ _Nonnull)(SimDeviceWrapper * _Nonnull))handler {
    // Send a notification for all currently connected devices.
    NSArray<NSString *>* simualtorPorts = getSimulatorBridgePortNames();
    for (SimDevice *device in defaultSet.availableDevices) {
        for (NSString *portName in simualtorPorts) {
            SimulatorBridge *bridge = bridgeForSimDevice(device, portName);
            if (!bridge) break;
            handler([[SimDeviceWrapper alloc] initWithDevice:device andBridge:bridge]);
        }
    }

    // Register a handler for all new devices.
    return [defaultSet registerNotificationHandler:^(NSDictionary* info) {
            NSString *notification_name = info[@"notification"];
            if ([notification_name isEqualToString: @"SimDeviceNotificationType_BootStatus"]) {
                // This notificaton appears when the device did finish booting
                SimDeviceBootInfo* bootInfo = info[@"SimDeviceNotification_NewBootStatus"];
                SimDeviceBootInfo* previousBootInfo = info[@"SimDeviceNotification_PreviousBootStatus"];
                if (bootInfo.isTerminalStatus && bootInfo.status == SimBootStatusFinished)
                {
                    // Iterate over all running simulator instances to find the correct one
                    for (NSString *portName in getSimulatorBridgePortNames()) {
                        SimDevice *device = info[@"device"];
                        SimulatorBridge *bridge = nil;
                        // New device connected
                        if (previousBootInfo.status != SimBootStatusFinished)
                            bridge = bridgeForSimDevice(device, portName);
                        // If the device is disconnected bridge will be nil
                        handler([[SimDeviceWrapper alloc] initWithDevice:device andBridge:bridge]);
                        break;
                    }
                }
            }
        }];
}

+ (BOOL)unsubscribe:(NSUInteger)handlerID {
    return [defaultSet unregisterNotificationHandler:handlerID error:NULL];
}

- (instancetype)initWithDevice:(SimDevice * _Nonnull)device andBridge:(SimulatorBridge * _Nullable)bridge {
    if (self = [super init]) {
        _device = device;
        _bridge = bridge;
    }
    return self;
}

- (NSString * _Nonnull)udid {
    return _device.UDID.UUIDString;
}

- (NSString * _Nonnull)name {
    return _device.name;
}

- (BOOL)hasBridge {
    return _bridge != NULL;
}

- (BOOL)setLocationWithLatitude:(double)latitude andLongitude:(double)longitude {
    if (!_bridge) return FALSE;
    [_bridge setLocationWithLatitude:latitude andLongitude:longitude];
    return TRUE;
}

- (BOOL)resetLocation {
    // FIXME: There is currently no reset function
    return _bridge != nil;
}

@end
