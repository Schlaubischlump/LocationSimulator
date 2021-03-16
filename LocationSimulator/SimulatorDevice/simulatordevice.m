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
}
- (instancetype)initWithDevice:(SimDevice * _Nonnull)device andBridge:(SimulatorBridge * _Nullable)bridge
                        forSimulatorPID:(pid_t)pid;
@end

@implementation SimDeviceWrapper

static SimDeviceSet *defaultSet = nil;

+ (void)initialize {
    // Load the CoreSimulator library or fail if it can not be loaded
    if (!load_bundle(@"/Library/Developer/PrivateFrameworks/CoreSimulator.framework/CoreSimulator")) {
        return;
    }

    NSString *path = getActiveDeveloperDir();
    if (!path) return;
    SimServiceContext* context = [NSClassFromString(@"SimServiceContext") serviceContextForDeveloperDir:path error:NULL];
    if (!context) return;
    defaultSet = [context defaultDeviceSetWithError:nil];
}

+ (NSUInteger)subscribe:(void (^ _Nonnull)(SimDeviceWrapper * _Nonnull))handler {
    if (!defaultSet)
        return -1;
    // Send a notification for all already connected devices.
    NSArray<NSNumber *>* simualtorPorts = getSimulatorPIDs();
    for (SimDevice *device in defaultSet.availableDevices) {
        for (NSNumber *simPID in simualtorPorts) {
            pid_t pid = (pid_t)simPID.intValue;
            SimulatorBridge *bridge = bridgeForSimDevice(device, getBridgePortName(pid));
            if (!bridge) break;

            __block SimDeviceWrapper *deviceWrapper = [[SimDeviceWrapper alloc] initWithDevice:device
                                                                                     andBridge:bridge
                                                                               forSimulatorPID:pid];
            // Listen for terminations of the Simulator app to disconnect the device
            NSNotificationCenter *workspaceNC = NSWorkspace.sharedWorkspace.notificationCenter;
            [workspaceNC addObserverForName:NSWorkspaceDidTerminateApplicationNotification
                                     object:nil
                                      queue:nil
                                 usingBlock:^(NSNotification * _Nonnull notification) {
                // If this device belongs to the currently terminated Simulator.app instance
                if ([notification.userInfo[@"NSApplicationProcessIdentifier"] intValue] == deviceWrapper->_pid) {
                    deviceWrapper->_bridge = nil;
                    handler(deviceWrapper);
                }
            }];

            // Add the device
            handler(deviceWrapper);
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
                    for (NSNumber *simPID in getSimulatorPIDs()) {
                        SimDevice *device = info[@"device"];
                        SimulatorBridge *bridge = nil;
                        pid_t pid = (pid_t)simPID.intValue;
                        // New device connected
                        if (previousBootInfo.status != SimBootStatusFinished)
                            bridge = bridgeForSimDevice(device, getBridgePortName(pid));
                        // If the device is disconnected bridge will be nil
                        __block SimDeviceWrapper *deviceWrapper = [[SimDeviceWrapper alloc] initWithDevice:device
                                                                                                 andBridge:bridge
                                                                                           forSimulatorPID:pid];
                        // If a device was connected
                        NSNotificationCenter *workspaceNC = NSWorkspace.sharedWorkspace.notificationCenter;

                        if (bridge != nil) {
                            // Listen for terminations of the Simulator app to disconnect the device
                            [workspaceNC addObserverForName:NSWorkspaceDidTerminateApplicationNotification
                                                     object:nil
                                                      queue:nil
                                                 usingBlock:^(NSNotification * _Nonnull notification) {
                                // If this device belongs to the currently terminated Simulator.app instance
                                if ([notification.userInfo[@"NSApplicationProcessIdentifier"] intValue] == deviceWrapper->_pid) {
                                    deviceWrapper->_bridge = nil;
                                    handler(deviceWrapper);
                                }
                            }];
                        } else {
                            // The device was disconnected. Stop listening for app termination.
                            [workspaceNC removeObserver:deviceWrapper];
                        }
                        // Add the device
                        handler(deviceWrapper);
                        break;
                    }
                }
            }
        }];
}

+ (BOOL)unsubscribe:(NSUInteger)handlerID {
    if (!defaultSet)
        return FALSE;
    return [defaultSet unregisterNotificationHandler:handlerID error:NULL];
}

- (instancetype)initWithDevice:(SimDevice * _Nonnull)device andBridge:(SimulatorBridge * _Nullable)bridge
               forSimulatorPID:(pid_t)pid {
    if (self = [super init]) {
        _device = device;
        _bridge = bridge;
        _pid = pid;
    }
    return self;
}

- (NSString * _Nonnull)udid {
    return _device.UDID.UUIDString;
}

- (pid_t)simulatorPID {
    return _pid;
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
