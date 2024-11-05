# i440fx
i440fx BIOS source code intended for Bochs

Dated: 19 Oct 2024

This is the assembly source code to an Intel i440fx compatible BIOS I wrote based on the .C source code included with the original [BOCHS BIOS](https://github.com/bochs-emu/Bochs/tree/master/bochs/bios). I have fixed many issues that came with that BIOS as well as added more function. It has been tested using most (MS)DOS Operating Systems up to and including recent Windows(tm) Operating Systems that still boot via BIOS.

It is intended to by used in the [BOCHS environment](https://github.com/bochs-emu/Bochs), but can be built and used in the [QEMU environment](https://www.qemu.org/). See the notes below for more information.

My intent is twofold. The first and foremost was to add booting from a USB device within BOCHS. For example, you can boot a device image as a floppy, hdd, or cd-rom. The second was simply to see if I can do it, write a BIOS that will boot an OS.

It is built with my own Intel x86 assembler found at [https://www.fysnet.net/newbasic.htm](https://www.fysnet.net/newbasic.htm).

```
Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  To build, be sure to have NBASM version 27.14 or higher
  For Bochs:
    nbasm64 i440fx /z
  For QEMU:
    nbasm64 i440fx /z /DBX_QEMU
  If no errors, you will have a ready to use i440fx.bin file

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 To use this BIOS in BOCHS, include a similar line in your bochsrc.txt file as:
   romimage: file=$BXSHARE/bios/i440fx.bin
   (substituting $BXSHARE for an actual path if you don't have the BXSHARE environment variable initialized)

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 You can use this BIOS with QEMU as well.
  Use the following parameters:
   required:
     -bios C:\bochs\bochs\bios\i440fx\i440fx_qemu.bin
   recommended:
     -cpu pentium3-v1
   known to work, but not fully supported:
     -machine q35
  Make sure and assemble with the /DBX_QEMU parameter as shown above.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 To boot a USB device, use the following line in your bochsrc.txt file:
  boot: usb
 This will boot the first USB device found.
 All controller types are supported: UHCI, OHCI, EHCI, and xHCI.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 If a USB HDD device is detected, the following checks will be made on the first sector:
  1) byte[0] == 0xEB and byte[2] == 0x90   ; jmp short xxxx
    or
     byte[0] == 0xE9 and word[1] < 0x1FE   ; jmp near xxxx
  2) word at [11] == 512                   ; bytes per sector
  3) word at [14] > 0                      ; reserved sectors
  4) byte at [16] == 1 or 2                ; number of fats
  5) bytes at [54-61] == 'FAT12   '        ; system
  6) word at [19] == 2880                  ; sectors
    or
     word at [19] == 0
      and
     dword at [32] == 2880                 ; extended sectors
  If all of the above is true, no matter the size of the HDD image, this BIOS will
   mount it as a 1.44M floppy disk.

   or

  If the Block Size == 2048, a CD-ROM is assumed and will attempt to mount the
   bootable image within the CD-ROM using 512-byte sectors

   or

  It will attempt to mount as a hdd device with or w/o a MBR.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 Graphic image in top right corner can be changed simply by including another
  custom RLE bitmap. Any 24-bit RGB standard Windows BMP file can be used.
  A small app to convert this BMP file to the custom RLE bitmap used by this
  BIOS is written in ASNI C.
 It is recommended to 'adjust' the BMP file to use 16 or less total pixel colors.
  The less pixel color difference, the smaller the custom RLE bitmap.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 If you include the 'flash_data=' as in:
    romimage: file=$BXSHARE/bios/i440fx.bin, flash_data="escd.bin"
 This BIOS will use the data in the escd.bin file, preserving any changes.
 If the file does not exist, a default will be used and saved on exit.
 Currently, the NUM LOCK on flag is set, meaning that the num lock will
  be turned on at startup.
 A procedure is in the works to modify this data, either outside of the
  emulation, within the emulate, or both.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 It includes a GUI style setup app that is involked pressing F10.
 It can be used with the mouse or using the TAB, Shift-TAB, and Space
  keys on the keyboard.
 It needs some work and a lot of things added, but the core is there.

Note: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 A list of known issues:
  - Booting from a USB CD-ROM is not yet supported. However, it doesn't need
    much to finish this function.
  - This BIOS will print to the console, panics or warnings indicating that
    something went wrong, or isn't supported. It will display this text
    at the current cursor location, possibly disturbing the guest's
    text output. Once more testing is done, these panics and warning
    will be removed.
  - This BIOS uses the 'xchg cx,cx' instruction to stop the BOCHS debugger
    at certain places, mostly places that have yet to be supported.
    Most of the time, you can simply continue.
  - as of right now, after a new build, you should delete the escd.bin
    file so that the BIOS will build a new default file.
    (for example, the latest build retrieves the seconds to wait for a 
     F12/F10 key press. If you have an old escd.bin file, it will return 
     zero (or 0x90) and either not wait for you to press a key, or wait
     a long time.)
  ```
