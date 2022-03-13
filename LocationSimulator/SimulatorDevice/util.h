//
//  util.h
//  LocationSimulator
//
//  Created by David Klopp on 13.03.21.
//  Copyright © 2021 David Klopp. All rights reserved.
//

#ifndef util_h
#define util_h

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <sys/proc_info.h>
#import <libproc.h>
#import <dlfcn.h>

#import "Header/CoreSimulator.h"
#import "Header/SimulatorBridge.h"
#include "logger.h"

// The iOS Simulator bundle identifier
NSString * _Nonnull const kSimBundleID = @"com.apple.iphonesimulator";

/**
 Load a dynamic library given an absolute path.
 */
static inline void* _Nullable load_bundle(NSString * _Nonnull path) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        LOG_ERROR("Bundle at path %s: Not found!", path.UTF8String);
        return nil;
    }
    void* fw = dlopen(path.UTF8String, RTLD_NOW | RTLD_GLOBAL);
    if (!fw) {
        LOG_ERROR("Bundle at path %s: Could not be opened. Reason: %s", path.UTF8String, dlerror());
        return nil;
    }
    return fw;
}

/**
 - Return: All possible simulator bridge port names for each Simulator.app instance.
 */
static inline NSArray<NSNumber *>* _Nonnull getSimulatorPIDs() {
    NSMutableArray<NSNumber *> *ports = [[NSMutableArray alloc] init];
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications) {
        if ([app.bundleIdentifier isEqualToString: kSimBundleID]) {
            [ports addObject:[NSNumber numberWithInt:app.processIdentifier]];
        }
    }
    return ports;
}

/**
 Get the bridge port name for a given port.
 - Parameter pid: the iphonesimulator instance pid
 - Return: portname for the simulator bridge
 */
static inline NSString * _Nonnull getBridgePortName(pid_t pid) {
    return [NSString stringWithFormat:@"%@.bridge.%d", kSimBundleID, pid];
}


/**
 Get the SimulatorBridge instance for a SimDevice.
 - Parameter device: the SimDevice instance
 - Parameter portName: the port name of the bridge
 - Return: SimulatorBridge instance
 */
static inline SimulatorBridge * _Nullable bridgeForSimDevice(SimDevice * _Nonnull device, NSString* _Nonnull portName) {
    NSError *error = nil;
    mach_port_t bridgePort = [device lookup:portName error:&error];
    if (error == nil && bridgePort != 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSPort *bridgeMachPort = [NSMachPort portWithMachPort:bridgePort];
        NSConnection *bridgeConnection = [NSConnection connectionWithReceivePort:nil sendPort: bridgeMachPort];
        NSDistantObject *bridgeDistantObject = [bridgeConnection rootProxy];
        if ([bridgeDistantObject respondsToSelector:@selector(setLocationScenarioWithPath:)]) {
#pragma clang diagnostic pop
            return (SimulatorBridge *) bridgeDistantObject;
        }
        LOG_ERROR("SimDevice %s: Distant Object for port: '%s' is not a SimulatorBridge.", device.name.UTF8String,
                  portName.UTF8String);
    } else {
        LOG_ERROR("SimDevice %s: Could not get port for name: '%s'", device.name.UTF8String, portName.UTF8String);
    }
    return nil;
}

/**
 - Return: path to the currently active developer dir
 */
static inline NSString * _Nullable getActiveDeveloperDir() {
    NSString *xcodeSelectPath = @"/usr/bin/xcode-select";

    // If xcode-select is not installed, just skip the simulator support.
    if (![NSFileManager.defaultManager fileExistsAtPath:xcodeSelectPath]) {
        LOG_ERROR("xcode-select '%s': Not found!", xcodeSelectPath.UTF8String);
        return nil;
    }

    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = xcodeSelectPath;
    task.arguments = @[@"-p"];
    task.standardOutput = pipe;
    [task launch];
    [task waitUntilExit];


    NSString *grepOutput = nil;

    // Make sure no error occurred.
    if (task.terminationStatus == 0) {
        grepOutput = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    } else {
        LOG_ERROR("xcode-select '%s': Failed with error code %d", xcodeSelectPath.UTF8String, task.terminationStatus);
    }
    [file closeFile];

    return grepOutput;
}

#endif /* util_h */
