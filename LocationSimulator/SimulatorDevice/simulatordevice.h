//
//  simulatordevice.h
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

#ifndef simulatordevice_h
#define simulatordevice_h

#import <Foundation/Foundation.h>
#include "Header/CoreSimulator.h"
#include "Header/SimulatorBridge.h"

@interface SimDeviceWrapper : NSObject
/**
 Call the handler for every currently connected simulator device and observe the simulator devices to call the handler
 again if a new device is connected or disconnected.
 - Paramater handler: the callback handler to perform
 - Return: the id of the notification subscriber
 */
+ (NSUInteger)subscribe:(void (^ _Nonnull)(SimDeviceWrapper * _Nonnull))handler;
/**
 Stop listening for device connect and disconnect events.
 - Paramater handlerID: the id of the notification handler
 - Return: True on success, false otherwise
 */
+ (BOOL)unsubscribe:(NSUInteger)handlerID;
/**
 The udid of this simulator device.
 */
- (NSString * _Nonnull)udid;
/**
 The name of this simulator device.
 */
- (NSString * _Nonnull)name;
/**
 True if a bridge connection to this device established. A bridge connection is required to remote control the device
 and change the current location.
 - Return: True if a bridge for this device exists. False otherwise.
 */
- (BOOL)hasBridge;
/**
 Change the current device location to a new location.
 - Parameter latitude: the new latitude
 - Parameter longitude: the new longitude
 - Return: True if the location could be changed, False otherwise.
 */
- (BOOL)setLocationWithLatitude:(double)latitude andLongitude:(double)longitude;
/**
 Currently a NOP. This should stop the simulation spoofing in the future, if an API becomes available.
 - Return: True if a bridge connection exists, False otherwise.
 */
- (BOOL)resetLocation;
@end


#endif /* simulatordevice_h */
