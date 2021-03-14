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
+ (NSUInteger)subscribe:(void (^ _Nonnull)(SimDeviceWrapper * _Nonnull))handler;
+ (BOOL)unsubscribe:(NSUInteger)handlerID;
- (NSString * _Nonnull)udid;
- (NSString * _Nonnull)name;
- (BOOL)hasBridge;
- (BOOL)setLocationWithLatitude:(double)latitude andLongitude:(double)longitude;
- (BOOL)resetLocation;
@end


#endif /* simulatordevice_h */
