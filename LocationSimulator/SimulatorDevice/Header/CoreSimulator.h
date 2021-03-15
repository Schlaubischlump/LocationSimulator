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
    SimBootStateOffline = 1,
    SimBootStateBooting = 2,
    SimBootStateBooted = 3,
    SimBootStateShutdown = 4
};

// This might not be accurate
typedef NS_ENUM(NSUInteger, SimBootStatus) {
    SimBootStatusWaitingOnSystemApp = 4,
    SimBootStatusFinished = 4294967295
};

@interface SimDeviceBootInfo : NSObject
@property(retain, nonatomic) NSDictionary * _Nonnull info;
@property(nonatomic) BOOL isTerminalStatus;
@property(nonatomic) NSUInteger status;
@end

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
