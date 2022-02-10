//
//  mobiledevice.h
//  LocationSimulator
//
//  Created by David Klopp on 20.12.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

#ifndef mobiledevice_h
#define mobiledevice_h

#include <stdbool.h>
#include <libimobiledevice/libimobiledevice.h>

// Reset the currently spoofed location of an iOS device to the original one.
bool resetLocation(const char* udid, enum idevice_options lookup_ops);

// Change the current location on an iOS device to new coordinates.
bool sendLocation(const char *lat, const char *lng, const char* udid, enum idevice_options lookup_ops);

// Pair and validate the connection to the device.
bool pairDevice(const char* udid, enum idevice_options lookup_ops);

// True if the developer image for this specific device is already mounted, false otherwise.
bool developerImageIsMountedForDevice(const char *udid, enum idevice_options lookup_ops);

// mount the developer image for a specific iOS Device
bool mountImageForDevice(const char *udid, const char *devDMG, const char *devSign, enum idevice_options lookup_ops);

// get the ProductVersion of the specific iOS Device
const char *deviceProductVersion(const char *udid, enum idevice_options lookup_ops);

// get the ProductName of the specific iOS Device
const char *deviceProductName(const char *udid, enum idevice_options lookup_ops);

// get the device name of the specific iOS Device
const char *deviceName(const char *udid, enum idevice_options lookup_ops);

#endif /* mobiledevice_h */
