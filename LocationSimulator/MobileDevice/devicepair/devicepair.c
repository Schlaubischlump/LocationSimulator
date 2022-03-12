//
//  devicepair.c
//  LocationSimulator
//
//  Created by David Klopp on 07.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// Based on: https://github.com/libimobiledevice/libimobiledevice/blob/master/tools/idevice_id.c

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/libimobiledevice.h>

#include "../config.h"


/// Pair and validate the connection to the device with the given UDID.
/// - Parameter udid: iOS device UDID
/// - Return: True on success, False otherwise.
bool pairDevice(const char* udid, enum idevice_options lookup_ops) {
    idevice_t device = NULL;
    lockdownd_client_t client = NULL;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, lookup_ops)) {
        LOG_ERROR("Device \"%s\": Not found.", udid);
        return false;
    }

    // try to perform the handshake
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;
    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_client_new_with_handshake(device, &client, "devicepair"))) {
        LOG_ERROR("Device \"%s\": Could not connect to lockdownd, error code %d.", udid, ldret);
        idevice_free(device);
        return false;
    }

    // cleanup
    idevice_free(device);
    lockdownd_client_free(client);

    return true;
}
