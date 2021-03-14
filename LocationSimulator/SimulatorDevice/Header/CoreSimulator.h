//
//  CoreSimulator+SimulatorBridge.h
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

#ifndef CoreSimulator_h
#define CoreSimulator_h

#import <Foundation/Foundation.h>

// This might not be accurate
typedef NS_ENUM(NSUInteger, SimBootState) {
    SimBootStatusOffline = 1,
    SimBootStatusBooting = 2,
    SimBootStatusBooted = 3,
    SimBootStatusShutdown = 4
};

@interface SimDevice : NSObject
@property(copy, nonatomic) NSUUID * _Nonnull UDID;
@property(readonly, nonatomic) NSString * _Nonnull name;
- (mach_port_t)lookup:(NSString * _Nonnull)portName error:(NSError * _Nullable * _Nullable)error;
@end

@interface SimDeviceSet : NSObject
- (NSUInteger)registerNotificationHandler:(void (^_Nonnull)(NSDictionary * _Nullable))handler;
- (BOOL)unregisterNotificationHandler:(NSUInteger)handlerID error:(NSError * _Nullable * _Nullable)error;
@property(readonly, nonatomic) NSArray * _Nonnull availableDevices;
@end

@interface SimServiceContext : NSObject
+ (instancetype _Nonnull)serviceContextForDeveloperDir:(NSString * _Nonnull)path error:(NSError * _Nullable * _Nullable)error;
- (SimDeviceSet * _Nonnull)defaultDeviceSetWithError:(NSError * _Nullable * _Nullable)error;
@end


#endif /* CoreSimulator_h */
