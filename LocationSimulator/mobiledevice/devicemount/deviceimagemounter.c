//
//  deviceimagemounter.c
//  LocationSimulator
//
//  Created by David Klopp on 07.08.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// Based on: https://github.com/libimobiledevice/libimobiledevice/blob/master/tools/ideviceimagemounter.c

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <libimobiledevice/afc.h>
#include <libimobiledevice/lockdown.h>
#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/mobile_image_mounter.h>

#include "../config.h"

static const char PKG_PATH[] = "PublicStaging";
static const char PATH_PREFIX[] = "/private/var/mobile/Media";

typedef enum {
    DISK_IMAGE_UPLOAD_TYPE_AFC,
    DISK_IMAGE_UPLOAD_TYPE_UPLOAD_IMAGE
} disk_image_upload_type_t;


/**
 Check if the DeveloperDiskImage is mounted on the iOS Device.
 - Parameter udid: iOS device UDID
 - Return: True if the image is mounted, False otherwise.
 */
bool developerImageIsMountedForDevice(const char *udid) {
    bool res = false;

    plist_t result = NULL;
    idevice_t device = NULL;
    lockdownd_client_t lckd = NULL;
    mobile_image_mounter_client_t mim = NULL;
    lockdownd_service_descriptor_t service = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, LOOKUP_OPS)) {
        LOG_ERR("No device found.");
        return NULL;
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_client_new_with_handshake(device, &lckd, "deviceimagemounter"))) {
        LOG_ERR("Could not connect to lockdown, error code %d.", ldret);
        goto leave;
    }

    lockdownd_start_service(lckd, "com.apple.mobile.mobile_image_mounter", &service);

    if (!service || service->port == 0) {
        LOG_ERR("Could not start mobile_image_mounter service!");
        goto leave;
    }

    if (mobile_image_mounter_new(device, service, &mim) != MOBILE_IMAGE_MOUNTER_E_SUCCESS) {
        LOG_ERR("Could not connect to mobile_image_mounter!");
        goto leave;
    }

    if (service) {
        lockdownd_service_descriptor_free(service);
        service = NULL;
    }

    mobile_image_mounter_error_t err = mobile_image_mounter_lookup_image(mim, "Developer", &result);
    if (err == MOBILE_IMAGE_MOUNTER_E_SUCCESS) {
        char* key = NULL;
        plist_t subnode = NULL;
        plist_dict_iter it = NULL;
        plist_dict_new_iter(result, &it);
        plist_dict_next_item(result, it, &key, &subnode);
        while (subnode)
        {
            // if we find the ImageSignature key in the returned plist we can stop
            res = (strcmp(key, "ImageSignature") == 0);
            free(key);
            key = NULL;
            if (res) break;
            plist_dict_next_item(result, it, &key, &subnode);
        }
        free(it);
    } else {
        LOG_ERR("lookup_image returned %d", err);
    }

    // perform hangup command
    mobile_image_mounter_hangup(mim);
    // free client
    mobile_image_mounter_free(mim);

leave:
    if (lckd) {
        lockdownd_client_free(lckd);
    }
    idevice_free(device);

    return res;
}


static ssize_t mim_upload_cb(void* buf, size_t size, void* userdata)
{
    return fread(buf, 1, size, (FILE*)userdata);
}

/**
 Mount a specific DeveloperDiskImage on the iOS Device.
 - Parameter udid: iOS device UDID
 - Parameter devDMG: path to DeveloperDiskImage.dmg for this iOS Version
 - Parameter devSign: path to DeveloperDiskImage.dmg.signature for the devDMG file
 - Return: True if the image could be mounted, False otherwise.
 */
bool mountImageForDevice(const char *udid, const char *devDMG, const char *devSign) {
    bool res = false;

    idevice_t device = NULL;
    afc_client_t afc = NULL;
    lockdownd_client_t lckd = NULL;
    mobile_image_mounter_client_t mim = NULL;
    lockdownd_service_descriptor_t service = NULL;
    lockdownd_error_t ldret = LOCKDOWN_E_UNKNOWN_ERROR;

    if (IDEVICE_E_SUCCESS != idevice_new_with_options(&device, udid, LOOKUP_OPS)) {
        LOG_ERR("No device found.");
        return NULL;
    }

    if (LOCKDOWN_E_SUCCESS != (ldret = lockdownd_client_new_with_handshake(device, &lckd, "deviceimagemounter"))) {
        LOG_ERR("Could not connect to lockdown, error code %d.", ldret);
        goto leave;
    }

    // read the version string
    plist_t pver = NULL;
    char *product_version = NULL;
    lockdownd_get_value(lckd, NULL, "ProductVersion", &pver);
    if (pver && plist_get_node_type(pver) == PLIST_STRING) {
        plist_get_string_val(pver, &product_version);
    }

    // choose the right upload type
    disk_image_upload_type_t disk_image_upload_type = DISK_IMAGE_UPLOAD_TYPE_AFC;
    int product_version_major = 0;
    int product_version_minor = 0;
    if (product_version) {
        if (sscanf(product_version, "%d.%d.%*d", &product_version_major, &product_version_minor) == 2) {
            if (product_version_major >= 7)
                disk_image_upload_type = DISK_IMAGE_UPLOAD_TYPE_UPLOAD_IMAGE;
        }
    }

    lockdownd_start_service(lckd, "com.apple.mobile.mobile_image_mounter", &service);

    if (!service || service->port == 0) {
        LOG_ERR("Could not start mobile_image_mounter service!");
        goto leave;
    }

    if (mobile_image_mounter_new(device, service, &mim) != MOBILE_IMAGE_MOUNTER_E_SUCCESS) {
        LOG_ERR("Could not connect to mobile_image_mounter!");
        goto leave;
    }

    if (service) {
        lockdownd_service_descriptor_free(service);
        service = NULL;
    }

    struct stat fst;
    if (disk_image_upload_type == DISK_IMAGE_UPLOAD_TYPE_AFC) {
        if ((lockdownd_start_service(lckd, "com.apple.afc", &service) != LOCKDOWN_E_SUCCESS) || !service || !service->port) {
            LOG_ERR("Could not start com.apple.afc!");
            goto leave;
        }
        if (afc_client_new(device, service, &afc) != AFC_E_SUCCESS) {
            LOG_ERR("Could not connect to AFC!");
            goto leave;
        }
        if (service) {
            lockdownd_service_descriptor_free(service);
            service = NULL;
        }
    }

    if (stat(devDMG, &fst) != 0) {
        LOG_ERR("stat: %s: %s", devDMG, strerror(errno));
        goto leave;
    }

    size_t image_size = fst.st_size;
    if (stat(devSign, &fst) != 0) {
        LOG_ERR("stat: %s: %s", devSign, strerror(errno));
        goto leave;
    }


    char sig[8192];
    size_t sig_length = 0;
    FILE *f = fopen(devSign, "rb");
    if (!f) {
        LOG_ERR("opening signature file '%s': %s", devSign, strerror(errno));
        goto leave;
    }
    sig_length = fread(sig, 1, sizeof(sig), f);
    fclose(f);
    if (sig_length == 0) {
        LOG_ERR("Could not read signature from file '%s'", devSign);
        goto leave;
    }

    f = fopen(devDMG, "rb");
    if (!f) {
        LOG_ERR("opening image file '%s': %s", devDMG, strerror(errno));
        goto leave;
    }

    char *targetname = NULL;
    if (asprintf(&targetname, "%s/%s", PKG_PATH, "staging.dimage") < 0) {
        LOG_ERR("Out of memory!?");
        goto leave;
    }
    char *mountname = NULL;
    if (asprintf(&mountname, "%s/%s", PATH_PREFIX, targetname) < 0) {
        LOG_ERR("Out of memory!?");
        goto leave;
    }

    switch(disk_image_upload_type) {
        case DISK_IMAGE_UPLOAD_TYPE_UPLOAD_IMAGE:
            LOG_INFO("Uploading %s", devDMG);
            mobile_image_mounter_upload_image(mim, "Developer", image_size, sig, sig_length, mim_upload_cb, f);
            break;
        case DISK_IMAGE_UPLOAD_TYPE_AFC:
        default:
            LOG_INFO("Uploading %s --> afc:///%s", devDMG, targetname);
            char **strs = NULL;
            if (afc_get_file_info(afc, PKG_PATH, &strs) != AFC_E_SUCCESS) {
                if (afc_make_directory(afc, PKG_PATH) != AFC_E_SUCCESS) {
                    LOG_WARN("Could not create directory '%s' on device!", PKG_PATH);
                }
            }
            if (strs) {
                int i = 0;
                while (strs[i]) {
                    free(strs[i]);
                    i++;
                }
                free(strs);
            }

            uint64_t af = 0;
            if ((afc_file_open(afc, targetname, AFC_FOPEN_WRONLY, &af) !=
                 AFC_E_SUCCESS) || !af) {
                fclose(f);
                LOG_ERR("afc_file_open on '%s' failed!", targetname);
                goto leave;
            }

            char buf[8192];
            size_t amount = 0;
            do {
                amount = fread(buf, 1, sizeof(buf), f);
                if (amount > 0) {
                    uint32_t written, total = 0;
                    while (total < amount) {
                        written = 0;
                        if (afc_file_write(afc, af, buf, (uint32_t)amount, &written) != AFC_E_SUCCESS) {
                            LOG_ERR("AFC Write error!");
                            break;
                        }
                        total += written;
                    }
                    if (total != amount) {
                        LOG_ERR("wrote only %d of %d", total, (unsigned int)amount);
                        afc_file_close(afc, af);
                        fclose(f);
                        goto leave;
                    }
                }
            }
            while (amount > 0);

            afc_file_close(afc, af);
            break;
    }

    fclose(f);

    plist_t result = NULL;
    mobile_image_mounter_error_t err = mobile_image_mounter_mount_image(mim, mountname, sig, sig_length, "Developer", &result);
    res = (err == MOBILE_IMAGE_MOUNTER_E_SUCCESS);
    if (!res) {
        LOG_ERR("mount_image returned %d", err);
    }

    if (result) {
        plist_free(result);
    }

    // perform hangup command
    mobile_image_mounter_hangup(mim);
    // free client
    mobile_image_mounter_free(mim);

leave:
    if (afc) {
        afc_client_free(afc);
    }
    if (lckd) {
        lockdownd_client_free(lckd);
    }
    idevice_free(device);

    return res;
}
