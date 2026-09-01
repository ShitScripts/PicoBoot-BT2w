#!/usr/bin/env python3
"""
merge_uf2_bt.py - Merge a firmware UF2 with a payload UF2 into a single image.

This is a variant of PicoBoot's tools/merge_uf2.py adapted for the combined
"PicoBoot BT 2W" firmware:

  * The firmware UF2 (built by the Pico SDK for rp2350-arm-s) carries the
    family ID 0xE48BFF5A.
  * The payload UF2 (produced by process_ipl.py for 'rp2350') carries the
    family ID 0xE48BFF59.

Windows tool-releases of `uf2tool` are not assumed to be installed, so this
script performs the join directly. The CPU / board is rp2350-arm-s (family
0xE48BFF5A), and both UF2s are converted to that family for the combined file.

Pico W / Pico 2 W firmware runs from XIP flash (not executable RAM or "no
flash"), so we do NOT set the 0x2000 "file-container" (no-flash) flag on the
merged blocks: both inputs already describe normal flash content. The firmware
lives at 0x10000000 and the payload at 0x10080000.
"""

from dataclasses import dataclass
import itertools
import struct
import sys

block_format = "< 8I 476B I"
magic0 = 0x0A324655  # "UF2\n"
magic1 = 0x9E5D5157
magic2 = 0x0AB16F30

block_size = 256
sector_size = 4 * 1024

FAMILY_RP2350_ARM_S = 0xE48BFF5A
FAMILY_RP2350 = 0xE48BFF59


@dataclass
class Uf2Block:
    # Fields are ordered as they appear in the serialized binary
    # DO NOT CHANGE
    flags: int
    address: int
    size: int
    seq: int
    total_blocks: int
    family_id: int
    data: bytes = bytes()


def read_file(name):
    with open(name, "rb") as f:
        data = f.read()
    return data


def decode_uf2(data):
    while data:
        block, data = data[:512], data[512:]
        block = struct.unpack(block_format, block)

        header, body, footer = block[:8], block[8:-1], block[-1:]
        assert (header[:2], footer) == ((magic0, magic1), (magic2,))

        b = Uf2Block(*header[2:])
        b.data = bytes(body[:b.size])

        yield b


def write_uf2(blocks, name):
    with open(name, "wb") as f:
        for seq, b in enumerate(blocks):
            assert len(b.data) == b.size
            data = struct.pack(
                block_format,
                magic0,
                magic1,
                b.flags,
                b.address,
                b.size,
                seq,
                len(blocks),
                b.family_id,
                *b.data.ljust(476, b"\x00"),
                magic2,
            )
            f.write(data)


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <firmware.uf2> <payload.uf2> <output.uf2>")
        return 1

    firmware = sys.argv[1]
    payload = sys.argv[2]
    output = sys.argv[3]

    fw_blocks = [b for b in decode_uf2(read_file(firmware))]
    pl_blocks = [b for b in decode_uf2(read_file(payload))]

    if not fw_blocks or not pl_blocks:
        print("Error: empty input UF2")
        return 1

    # Sanity check the addresses before we touch anything.
    for b in fw_blocks:
        if not (0x10000000 <= b.address < 0x10080000):
            print(f"Error: firmware block outside firmware region: 0x{b.address:08X}")
            return 1
    for b in pl_blocks:
        if not (0x10080000 <= b.address < 0x10200000):
            print(f"Error: payload block outside payload region: 0x{b.address:08X}")
            return 1

    # Normalize every block onto the rp2350-arm-s family and clear the size
    # metadata/sector padding inconsistencies. Keep the "family id present"
    # flags bit 0x2000 clear (real flash, not no-flash).
    norm_flag = 0x00002000
    for b in fw_blocks + pl_blocks:
        b.family_id = FAMILY_RP2350_ARM_S
        b.flags = norm_flag
        if b.size != block_size:
            print(f"Error: unexpected block size {b.size}")
            return 1

    blocks = [b for b in fw_blocks + pl_blocks]

    # Fill each 4K sector so the flasher does not skip data. (Same behaviour as
    # the original merge tool.)
    block_map = set(b.address for b in blocks)
    sector_map = set(a // sector_size * sector_size for a in block_map)
    blocks_to_fill = set(
        itertools.chain.from_iterable(
            (range(a, a + sector_size, block_size) for a in sector_map),
        )
    ).difference(block_map)

    def padding_block(address):
        return Uf2Block(
            norm_flag,
            address,
            block_size,
            0,  # dummy
            0,  # dummy
            FAMILY_RP2350_ARM_S,
            bytes(block_size),
        )

    blocks += (padding_block(a) for a in blocks_to_fill)
    blocks.sort(key=lambda b: b.address)

    write_uf2(blocks, output)
    return 0


if __name__ == "__main__":
    sys.exit(main())