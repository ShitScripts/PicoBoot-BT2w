cmake_minimum_required(VERSION 3.13)

# PICO_BOARD should be set to 'pico2_w' (the only supported target), or not
# set at all (which then defaults to 'pico2_w').
if(DEFINED PICO_BOARD AND NOT ${PICO_BOARD} STREQUAL "pico2_w")
    message(FATAL_ERROR "PICO_BOARD must be set to 'pico2_w' or not set at all")
else()
    set(PICO_BOARD "pico2_w")
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

include(cmake/extract_version.cmake)

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(picoboot LANGUAGES C CXX ASM VERSION ${PROJECT_VERSION_STRING})

set(BLUEPAD32_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/bluepad32)

# Use the BTstack bundled with the Pico SDK (RFC: pico_btstack_classic).
set(PICO_BTSTACK_PATH ${PICO_SDK_PATH}/lib/btstack)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/dist)

add_executable(picoboot
        src/picoboot.c
        src/hw.c
        src/pio.c
        src/status_led.c
        src/status_led/gpio.c
        src/status_led/cyw43.c
        src/gamecube.c
        src/intercore.c
        src/my_platform.c
)

pico_generate_pio_header(picoboot
        ${CMAKE_CURRENT_LIST_DIR}/src/picoboot.pio
)

pico_generate_pio_header(picoboot
        ${CMAKE_CURRENT_LIST_DIR}/src/joybus.pio
)

pico_set_program_name(picoboot "PicoBoot BT 2W")
pico_set_program_description(picoboot "RP2350 based modchip for Nintendo GameCube with Bluetooth gamepad support")
pico_set_program_version(picoboot ${FW_VER_STRING})
pico_set_program_url(picoboot "https://github.com/webhdx/PicoBoot")

target_link_options(pico_standard_link INTERFACE "LINKER:--script=${CMAKE_CURRENT_LIST_DIR}/memmap_picoboot.ld")

pico_enable_stdio_uart(picoboot 0)
pico_enable_stdio_usb(picoboot 1)

target_include_directories(picoboot PRIVATE
        src
        ${BLUEPAD32_ROOT}/src/components/bluepad32/include)

# Needed for btstack_config.h / sdkconfig.h so that libbluepad32 can include
# them.
include_directories(picoboot src)
include_directories(${PICO_BTSTACK_PATH}/src)

# Hack: The default search-path lookup for these headers must pick our project
# copies. It works in the upstream examples, so keep the ordering the same.

target_link_libraries(picoboot PRIVATE
        hardware_adc
        hardware_dma
        hardware_pio
        pico_cyw43_arch_none
        pico_btstack_classic
        pico_btstack_cyw43
        pico_multicore
        pico_stdlib
        bluepad32
)

add_subdirectory(${BLUEPAD32_ROOT}/src/components/bluepad32 libbluepad32)

# BTstack 1.8.x (bundled with Pico SDK 2.3.0) renamed hids_client_* to
# hids_host_*. Bluepad32 4.2.0 still uses the old names, so force-include a
# compat shim when compiling the C sources of the bluepad32 library. The
# language gate keeps the shim (which pulls in btstack.h) away from the ASM
# sources that the SDK attaches to this target.
target_compile_options(bluepad32 PRIVATE
    "$<$<COMPILE_LANGUAGE:C>:-Winvalid-offsetof;-include;${CMAKE_CURRENT_SOURCE_DIR}/src/btstack_hids_compat.h>"
)

# Our firmware target uses the same BTstack symbols without ambiguity, but the
# default btstack_config.h must be ours, so keep src ahead of the SDK headers.
include_directories(picoboot src)

pico_add_extra_outputs(picoboot)