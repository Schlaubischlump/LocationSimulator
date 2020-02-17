//
//  Config.h
//  LocationSimulator
//
//  Created by David Klopp on 17.02.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

#ifndef Config_h
#define Config_h

#include <errno.h>
#include <libimobiledevice/libimobiledevice.h>

// MARK: - C-Backend configuration

// detect network devices
#define ALLOW_NETWORK_DEVICES 1
// prefer network devices, even if they are connected via USB
#define PREFER_NETWORK_DEVICES 0


// MARK: - Configuration helper variables

#if PREFER_NETWORK_DEVICES
    #define LOOKUP_OPS IDEVICE_LOOKUP_USBMUX | IDEVICE_LOOKUP_NETWORK | IDEVICE_LOOKUP_PREFER_NETWORK
#else
    #if ALLOW_NETWORK_DEVICES
        #define LOOKUP_OPS IDEVICE_LOOKUP_USBMUX | IDEVICE_LOOKUP_NETWORK
    #else
        #define LOOKUP_OPS IDEVICE_LOOKUP_USBMUX
    #endif
#endif



// MARK: - Logging

#define LOG(desc, format, arg...) do { fprintf(stderr, "[" desc  "]: " format "\n", ##arg); } while(0)

#define LOG_ERR(fmt, arg...) LOG("ERROR", fmt, ##arg)
#define LOG_INFO(fmt, arg...) LOG("INFO", fmt, ##arg)
#define LOG_WARN(fmt, arg...) LOG("WARNING", fmt, ##arg)

#endif /* Config_h */
