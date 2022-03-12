//
//  LocationSimulator2-Bridging-Header.h
//  LocationSimulator
//
//  Created by David Klopp on 18.08.19.
//  Copyright © 2020 David Klopp. All rights reserved.
//
#include "mobiledevice.h"
#include "simulatordevice.h"
#include "logger.h"

static void logInfo(const char *string) {
    LOG_INFO("%s", string);
}

static void logDebug(const char *string) {
    LOG_DEBUG("%s", string);
}

static void logFatal(const char *string) {
    LOG_FATAL("%s", string);
}

static void logTrace(const char *string) {
    LOG_TRACE("%s", string);
}

static void logError(const char *string) {
    LOG_ERROR("%s", string);
}

static void logWarning(const char *string) {
    LOG_WARN("%s", string);
}
