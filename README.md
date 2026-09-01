<img src="/assets/PicoBoot.png" alt="PicoBoot" align="left"/>


# PicoBoot BT 2W

PicoBoot is a long awaited IPL replacement modchip for the Nintendo GameCube. It's open source, cheap and easy to install.

**PicoBoot BT 2W** is a port of PicoBoot for the **Raspberry Pi Pico 2 W** that also adds built-in Bluetooth (Bluepad32), so a wireless controller can be used as a GameCube controller — no extra hardware or receiver dongle needed.

[![](https://dcbadge.limes.pink/api/server/fEhyWRPCmb)](https://click.webhdx.dev/discord)

## Features
* open source
* uses a $4 Raspberry Pi Pico 2 W board
* IPL injection modchip — boots geckoboot/Swiss and any homebrew of your choice
* built-in Bluetooth via Bluepad32 — pair a wireless gamepad and use it as a native GameCube controller
* upgradable via USB cable, without any drivers or programs
* very easy installation, only a few wires to solder

## Requirements
* A Raspberry Pi **Pico 2 W**
* A GameCube (DOL-001 or DOL-101)
* A few short jumper wires and basic soldering skills

## Installation

### 1. Flash the firmware
1. Put your Pico 2 W into bootloader mode (hold the **BOOTSEL** button while plugging it into USB).
2. A USB drive named `RPI-RP2` appears.
3. Copy the merged firmware `dist/picoboot_bt2w_full.uf2` onto it. The Pico reboots automatically.

> Building your own? See [Building from source](#building-from-source) below.

### 2. Wiring — booting (geckoboot/IPL injection)
The boot wiring uses the **up-to-date PicoBoot wiring**, soldering into the GameCube's memory-card/controller area:

![Up-to-date PicoBoot wiring](assets/Wiring%20diagram%20-%20up-to-date.jpg)

The IPL injection uses the standard PicoBoot points: **GP4, GP5, GP6**, plus **3V3** and **GND**. (The optional 5V `VSYS` power option shown on the diagram is for consoles that haven't been recapped.)

### 3. Wiring — Bluetooth
The **Bluetooth pin layout is the same as shown in the Bluetooth wiring diagram**:

![Bluetooth wiring](assets/Wiring%20diagram%20-%20Bluetooth.png)

The Bluetooth circuitry taps the **same data points as the controller ports** (the pads labelled **P1, P2, P3, P4**), connecting to the Pico's Bluetooth GPIOs. This lets a paired wireless gamepad work as a wired GameCube controller across all four player slots.

| Pad | GPIO |
|-----|------|
| P1 (Controller Port 1) | **22** |
| P2 (Controller Port 2) | **26** |
| P3 (Controller Port 3) | **27** |
| P4 (Controller Port 4) | **28** |

### 4. Power on and play
1. Pair your Bluetooth gamepad as you normally would for Bluepad32.
2. Power on the GameCube. PicoBoot injects geckoboot, and the wireless controller emulates the GameCube controller.

## Wiring summary
* **Booting (geckoboot/IPL injection):** uses the **up-to-date PicoBoot wiring** (from picoboot).
* **Bluetooth:** uses the **same Bluetooth pin layout** as the Bluetooth diagram (only the Bluetooth GPIOs come from the picoboot-bt layout).
* **Pins:**
  * IPL/injection: GPIO **4, 5, 6** (CS, CLK, DI) plus 3V3 and GND
  * Bluetooth/controller: GPIO **22, 26, 27, 28** (P1–P4)

## Building from source

### Windows
```
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```
Requires `cmake`, Ninja, an ARM toolchain, Python and the Raspberry Pi Pico SDK. Set `PICO_SDK_PATH` to your Pico SDK checkout (e.g. `C:\Users\you\pico-sdk`).

The script:
1. Downloads gekkoboot (`tools/get_gekkoboot.ps1`) if no `payload.dol` is present.
2. Processes the DOL into a payload UF2.
3. Builds the combined firmware.
4. Merges firmware + payload into `dist/picoboot_bt2w_full.uf2`.

### Linux / macOS
```
tools/build.sh
```

## Acknowledgements
* [webhdx/PicoBoot](https://github.com/webhdx/PicoBoot) — the original IPL injection PicoBoot.
* [ricardoquesada/bluepad32](https://github.com/ricardoquesada/bluepad32) — the Bluetooth/gamepad stack.
* [redolution](https://github.com/redolution) — gekkoboot/iplboot.

This project uses GPL-2.0 licensed code from the projects above.