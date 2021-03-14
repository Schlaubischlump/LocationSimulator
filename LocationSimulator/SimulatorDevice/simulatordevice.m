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
            if ([notification_name isEqualToString: @"device_state"]) {
                SimDevice *device = info[@"device"];
                SimBootState new_state = [info[@"new_state"] unsignedIntValue];
                if (new_state == SimBootStatusBooted) {
                    // New device added
                    for (NSString *portName in getSimulatorBridgePortNames()) {
                        // TODO: This is called to early. Use the other method I posted on github.
                        SimulatorBridge *bridge = bridgeForSimDevice(device, portName);
                        if (bridge != nil) {
                            handler([[SimDeviceWrapper alloc] initWithDevice:device andBridge:bridge]);
                            break;
                        }
                    }
                } else if (new_state == SimBootStatusShutdown) {
                    // Device removed
                    handler([[SimDeviceWrapper alloc] initWithDevice:device andBridge:nil]);
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
    // TODO: IDEA: Use NotificationCenter instead
    //[_bridge setLocationWithLatitude:latitude andLongitude:longitude];

    return TRUE;
}

- (BOOL)resetLocation {
    if (!_bridge) return FALSE;
    // TODO: IDEA: Use NotificationCenter instead
    return TRUE;
}

@end
