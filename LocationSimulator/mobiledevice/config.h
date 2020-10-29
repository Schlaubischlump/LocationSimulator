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

// MARK: - Logging

#define LOG(desc, format, arg...) do { fprintf(stderr, "[" desc  "]: " format "\n", ##arg); } while(0)

#define LOG_ERR(fmt, arg...) LOG("ERROR", fmt, ##arg)
#define LOG_INFO(fmt, arg...) LOG("INFO", fmt, ##arg)
#define LOG_WARN(fmt, arg...) LOG("WARNING", fmt, ##arg)

#endif /* Config_h */
