//
//  deviceinfo.c
//  LocationSimulator
//
//  Created by David Klopp on 08.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// Based on: https://github.com/libimobiledevice/libimobiledevice/blob/master/tools/ideviceinfo.c

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/lockdown.h>

#include "../config.h"


/// Get the iOS product version string from the connected device
/// - Parameter udid: iOS device UDID
/// - Return: product version string in format: major.minor
const char *deviceProductVersion(const char *udid) {
    idevice_t device = NULL;
    idevice_error_t ret = idevice_new_with_options(&device, udid, LOOKUP_OPS);
    lockdownd_client_t client = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;

    if (ret != IDEVICE_E_SUCCESS) {
        LOG_ERR("No device found with udid %s, is it plugged in?", udid);
        return NULL;
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_client_new(device, &client, "deviceinfo"))) {
        LOG_ERR("Could not connect to lockdownd, error code %d", ldret);
        idevice_free(device);
        return NULL;
    }

    plist_t node = NULL;
    char *res = NULL;

    if(lockdownd_get_value(client, NULL, "ProductVersion", &node) == LOCKDOWN_E_SUCCESS && node != NULL && plist_get_node_type(node) == PLIST_STRING) {
        plist_get_string_val(node, &res);

        // only get the first two elements of the product version string
        if (res) {
            int product_version_major = 0;
            int product_version_minor = 0;
            if (sscanf(res, "%d.%d.%*d", &product_version_major, &product_version_minor))
                sprintf(res, "%d.%d", product_version_major, product_version_minor);
        }

        plist_free(node);
        node = NULL;
    }

    lockdownd_client_free(client);
    idevice_free(device);

    return res;
}

/// Get the name of the connected iOS device (not the name of the product).
/// - Parameter udid: iOS device UDID
/// - Return: name of the iOS device
const char *deviceName(const char *udid) {
    idevice_t device = NULL;
    lockdownd_client_t client = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, LOOKUP_OPS)) {
        LOG_ERR("No device found with udid %s, is it plugged in?", udid);
        return NULL;
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_client_new(device, &client, "devicename"))) {
        LOG_ERR("Could not connect to lockdownd, error code %d", ldret);
        idevice_free(device);
        return NULL;
    }

    char* name = NULL;
    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_get_device_name(client, &name))) {
        LOG_ERR("Could not get device name, error code %d", ldret);
    }

    lockdownd_client_free(client);
    idevice_free(device);

    return name;
}
