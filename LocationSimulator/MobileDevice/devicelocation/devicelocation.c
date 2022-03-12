//
//  devicelocation.c
//  LocationSimulator
//
//  Created by David Klopp on 07.08.19.
//  Copyright (c) 2019 David Klopp, All Rights Reserved.
//

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include <libimobiledevice/service.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/libimobiledevice.h>

#include "endianness.h"

#include "../config.h"


/// Stop spoofing the iOS device location and reset it to the original GPS coordinates.
/// - Parameter udid: iOS device UDID
/// - Return: True on success, False otherwise.
bool resetLocation(const char* udid, enum idevice_options lookup_ops) {
    bool res = false;
    idevice_t device = NULL;
    lockdownd_client_t client = NULL;
    service_client_t service_client = NULL;
    lockdownd_service_descriptor_t service = NULL;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, lookup_ops)) {
        LOG_ERROR("No iOS device with specified udid found.");
        goto leave_and_cleanup;
    }

    if (LOCKDOWN_E_SUCCESS != lockdownd_client_new_with_handshake(device, &client, "devicelocation")) {
        LOG_ERROR("Could not connect to lockdownd client.");
        goto leave_and_cleanup;
    }

    if ((lockdownd_start_service(client, "com.apple.dt.simulatelocation",  &service) != LOCKDOWN_E_SUCCESS) || !service) {
        LOG_ERROR("Could not start com.apple.dt.simulatelocation!");
        goto leave_and_cleanup;
    }

    if (service_client_new(device, service, &service_client)) {
        LOG_ERROR("Could not create service client.");
        goto leave_and_cleanup;
    }
    uint32_t send_bytes = 0;
    uint32_t stopMessage = htobe32(1);
    if (service_send(service_client, (void*)&stopMessage, sizeof(stopMessage), &send_bytes)
        || send_bytes != sizeof(stopMessage))
    {
        LOG_ERROR("Could not send stop data to service client.");
        goto leave_and_cleanup;
    }
    res = true;

leave_and_cleanup:
    if (service_client) service_client_free(service_client);
    if (service) lockdownd_service_descriptor_free(service);
    if (client) lockdownd_client_free(client);
    if (device) idevice_free(device);

    return res;
}


/// Set a new location on the specified iOS Device
/// - Parameter lat: new latitude data as string
/// - Parameter lng: new longitude data as string
/// - Parameter udid: iOS device UDID
/// - Return: True on success, False otherwise.
bool sendLocation(const char *lat, const char *lng, const char* udid, enum idevice_options lookup_ops) {
    bool res = false;
    idevice_t device = NULL;
    lockdownd_client_t client = NULL;
    service_client_t service_client = NULL;
    lockdownd_service_descriptor_t service = NULL;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, lookup_ops)) {
        LOG_ERROR("No iOS device with specified udid found.");
        goto leave_and_cleanup;
    }

    if (LOCKDOWN_E_SUCCESS != lockdownd_client_new_with_handshake(device, &client, "devicelocation")) {
        LOG_ERROR("Could not connect to lockdownd.");
        goto leave_and_cleanup;
    }

    if ((lockdownd_start_service(client, "com.apple.dt.simulatelocation",  &service) != LOCKDOWN_E_SUCCESS) || !service) {
        LOG_ERROR("Could not start com.apple.dt.simulatelocation!");
        goto leave_and_cleanup;
    }

    if (service_client_new(device, service, &service_client)) {
        LOG_ERROR("Could not create service client.");
        goto leave_and_cleanup;
    } else {
        uint32_t send_bytes = 0;
        uint32_t startMsg = htobe32(0);
        uint32_t lat_len = (uint32_t)htobe32(strlen(lat));
        uint32_t lng_len = (uint32_t)htobe32(strlen(lng));

        // send start
        if (service_send(service_client, (void*)&startMsg, sizeof(startMsg), &send_bytes)
            || send_bytes != sizeof(startMsg)) {
            LOG_ERROR("Could not send start data to service client.");
            goto leave_and_cleanup;
        }

        // send lat
        if (service_send(service_client, (void*)&lat_len, sizeof(lat_len), &send_bytes)
            || send_bytes != sizeof(lat_len)
            || service_send(service_client, lat, (uint32_t)strlen(lat), &send_bytes)
            || send_bytes != (uint32_t)strlen(lat))
        {
            LOG_ERROR("Could not send lat data to service client.");
            goto leave_and_cleanup;
        }

        // send lng
        if (service_send(service_client, (void*)&lng_len, sizeof(lng_len), &send_bytes)
            || send_bytes != sizeof(lng_len)
            || service_send(service_client, lng, (uint32_t)strlen(lng), &send_bytes)
            || send_bytes != (uint32_t)strlen(lng))
        {
            LOG_ERROR("Could not send lng data to service client.");
            goto leave_and_cleanup;
        }
        res = true;
    }

leave_and_cleanup:
    if (service_client) service_client_free(service_client);
    if (service) lockdownd_service_descriptor_free(service);
    if (client) lockdownd_client_free(client);
    if (device) idevice_free(device);

    return res;

}
