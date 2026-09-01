/**
 * SPDX-License-Identifier: Apache-2.0
 *
 * Compatibility shim: BTstack 1.8.x renamed the HIDS client API from
 * hids_client_* to hids_host_*. Bluepad32 4.2.0 still calls the old names.
 * This header is force-included (via CMake) into the bluepad32 library
 * sources so they link against the Pico SDK bundled BTstack.
 *
 * Only API functions are aliased. hids_client_packet_handler (a function
 * defined by bluepad32 itself) is intentionally left untouched.
 */
#ifndef PICOBOT_BT2W_HIDS_CLIENT_COMPAT_H
#define PICOBOT_BT2W_HIDS_CLIENT_COMPAT_H

#include <btstack.h>
#include <ble/gatt-service/hids_host.h>

#define hids_client_init hids_host_init
#define hids_client_connect hids_host_connect
#define hids_client_disconnect hids_host_disconnect
#define hids_client_enable_notifications hids_host_enable_notifications
#define hids_client_send_write_report hids_host_send_write_report
#define hids_client_descriptor_storage_get_descriptor_data hids_host_descriptor_storage_get_descriptor_data
#define hids_client_descriptor_storage_get_descriptor_len hids_host_descriptor_storage_get_descriptor_len

#endif /* PICOBOT_BT2W_HIDS_CLIENT_COMPAT_H */