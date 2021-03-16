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

// The iOS Simulator bundle identifier
NSString * _Nonnull const kSimBundleID = @"com.apple.iphonesimulator";

/**
 Load a dynamic library given an absolute path.
 */
void* _Nullable load_bundle(NSString * _Nonnull path) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"WARNING: Bundle is not present at path: %@", path);
        return nil;
    }
    void* fw = dlopen(path.UTF8String, RTLD_NOW | RTLD_GLOBAL);
    if (!fw) {
        NSLog(@"ERROR: %s", dlerror());
        return nil;
    }
    return fw;
}

/**
 - Return: All possible simulator bridge port names for each Simulator.app instance.
 */
NSArray<NSNumber *>* _Nonnull getSimulatorPIDs() {
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
NSString * _Nonnull getBridgePortName(pid_t pid) {
    return [NSString stringWithFormat:@"%@.bridge.%d", kSimBundleID, pid];
}


/**
 Get the SimulatorBridge instance for a SimDevice.
 - Parameter device: the SimDevice isntance
 - Parameter portName: the port name of the bridge
 - Return: SimulatorBridge instance
 */
SimulatorBridge * _Nullable bridgeForSimDevice(SimDevice * _Nonnull device, NSString* _Nonnull portName) {
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
        NSLog(@"Distant Object for port: '%@' is not a SimulatorBridge", portName);
    } else {
        NSLog(@"Could not get port for name: '%@'", portName);
    }
    return nil;
}

/**
 - Return: path to the currently active developer dir
 */
NSString * _Nullable getActiveDeveloperDir() {
    NSString *xcodeSelectPath = @"/usr/bin/xcode-select";

    // If xcode-select is not installed, just skip the simulator support.
    if (![NSFileManager.defaultManager fileExistsAtPath:xcodeSelectPath]) {
        NSLog(@"[Error]: Could not find: %@", xcodeSelectPath);
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

    // Make sure no error occured.
    if (task.terminationStatus == 0) {
        grepOutput = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    }
    [file closeFile];

    return grepOutput;
}

#endif /* util_h */
