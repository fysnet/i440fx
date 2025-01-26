# i440fx
i440fx BIOS source code intended for Bochs

This is the assembly source code to an Intel i440fx compatible BIOS I wrote based on the .C source code included with the original [BOCHS BIOS](https://github.com/bochs-emu/Bochs/tree/master/bochs/bios). I have fixed many issues that came with that BIOS as well as added more function. It has been tested using most (MS)DOS Operating Systems up to and including recent Windows(tm) Operating Systems that still boot via BIOS. See below for a list of OSes I have tested.

It is intended to be used in the [BOCHS environment](https://github.com/bochs-emu/Bochs), but can be built and used in the [QEMU environment](https://www.qemu.org/). See below for more information.

My intent is twofold. The first and foremost was to add booting from a USB device within BOCHS. For example, you can boot a device image as a floppy, hdd, or cd-rom. The second was simply to see if I can do it, write a BIOS that will boot an OS.

It is built with my own Intel x86 assembler found at [https://www.fysnet.net/newbasic.htm](https://www.fysnet.net/newbasic.htm).

The documentation can be found at [https://github.com/fysnet/i440fx/tree/main/docs/index.html](https://github.com/fysnet/i440fx/tree/main/docs/index.html).

#### 05 Jan 2025
* The format of the internal ESCD has changed. If you use the ESCD option, please delete the current ESCD.BIN file and allow the BIOS to create a new clean one.

## Notes
* To build, be sure to have <a href="https://www.fysnet.net/newbasic.htm">NBASM</a> version 27.14 or higher.

  For use with Bochs: `nbasm64 i440fx /z`\
  For use with QEMU: `nbasm64 i440fx /z /DBX_QEMU`
  
  If no errors, you will have a ready to use `i440fx.bin` file.

  NBASM is for DOS and Windows only. No *nix port is available at this time. (though it has been known to run under WINE?)

* To use this BIOS in Bochs, include a similar line in your `bochsrc.txt` file as one of the following:
  
   `romimage: file=$BXSHARE/bios/i440fx.bin`\
   `romimage: file=$BXSHARE/bios/i440fx.bin, flash_data="escd.bin"`
    
   (substituting `$BXSHARE` for an actual path if you don't have the `BXSHARE` environment variable initialized)

* You can use this BIOS with QEMU as well using the following parameters:

  Required: `-bios C:\path\to\this\bios\i440fx_qemu.bin`\
  Recommended addition:\
  `-cpu pentium3-v1`\
    **or**\
  `-machine q35` (Known to work but not fully supported)

  Make sure and assemble with the `/DBX_QEMU` parameter as shown above.

* To boot a USB device, use the following line in your bochsrc.txt file:

  `boot: usb`

  This will boot the first USB device found.\
  All controller types are supported: UHCI, OHCI, EHCI, and xHCI.

  For example, if you want to boot a USB floppy disk, include the following line in your Bochs `bochsrc.txt` file.

  `usb_uhci: port1=floppy, options1="speed:full, path:some/path/floppy.img, model:teac"`

  To boot a floppy or other drive using another controller, use a very similar line:

  `usb_ohci: port2=cdrom, options2="speed:full, path:../common/bootcd.iso"`\
  `usb_ehci: port1=disk, options1="speed:high, path:../common/hdd.img, proto:bbb"`\
  `usb_xhci: port1=disk, options1="speed:super, path:../common/hdd.img, proto:bbb"`

  Remember that each controller other than the UHCI requires the `slotx=` addition in the `pci` declaration:

  `pci: enabled=1, chipset=i440fx, slot1=usb_ohci`

  The `uasp` protocol is currently not supported with this BIOS.

#### Type of device detected
* If a USB HDD device is detected, the following checks will be made on the first sector:
  
  1. `byte[0] == 0xEB and byte[2] == 0x90 ; jmp short xxxx`\
    or\
     `byte[0] == 0xE9 and word[1] < 0x1FE ; jmp near xxxx`
  2. `word at [11] == 512 ; bytes per sector`
  3. `word at [14] > 0 ; reserved sectors`
  4. `byte at [16] == 1 or 2 ; number of fats`
  5. `bytes at [54:61] == 'FAT12   ' ; system`
  6. `word at [19] == 2880 ; sectors`\
  or
  7. `word at [19] == 0 && dword at [32] == 2880 ; extended sectors`

  * If all of the above is true, no matter the size of the HDD image, this BIOS will mount it as a 1.44M floppy disk.
  
  * If the `Block Size == 2048`, a CD-ROM is assumed and will attempt to mount the bootable image within the CD-ROM using no emulation using 2048-byte sectors, or floppy or hdd emulation using 512-byte sectors.
  
  * Otherwise, it will attempt to mount as a hdd device with or w/o a MBR.

#### Other included items
* The graphic image in the top right corner can be changed simply by including another custom RLE bitmap. Any 24-bit RGB standard Windows BMP file can be used. A small app to convert this BMP file to the custom RLE bitmap used by this BIOS is written in ANSI C and is included with the source listing in the `icon` folder. It is recommended that you 'adjust' the BMP file to use 16 or less total pixel colors. The less pixel color difference, the smaller the custom RLE bitmap. i.e.: using your favorite bitmap image viewer/editor, adjust the count of colors used to 16 or less. A 24-bit "monochrome" bitmap only uses two colors and will create a very small custom RLE bitmap. A bitmap that uses many of the 24-bit colors will create a rather large custom RLE bitmap and may not fit in the space provided within the BIOS image.

* If you include the `flash_data=` parameter as in:\
  `romimage: file=$BXSHARE/bios/i440fx.bin, flash_data="escd.bin"`\
  This BIOS will use the data in the `escd.bin` file, preserving any changes. If the file does not exist, a default will be used and saved on exit. Currently, the `NUM LOCK on` flag is set, meaning that the num lock will be turned on at startup. A procedure is in the works to modify this data, either outside of the emulation, within the emulatation, or both.

* It includes a GUI style setup app that is involked pressing F10. It can be used with the mouse or using the TAB, Shift-TAB, and Space keys on the keyboard. It needs some work and a lot of things added, but the core is there. As soon as I get a static format in the extra space of the ESCD, I will add to this GUI. However, adding items are as simple as adding a `GUI_OBJECT` to the `gui_root_object` linked list in the `setup.asm` file. The GUI code will parse, display, and process events accordingly.

### A list of known issues
* This BIOS will print to the console, any panics or warnings indicating that something went wrong, or isn't supported. If currently in a text mode (like DOS), it will display this text at the current cursor location, possibly disturbing the guest's text output. Once more testing is done, these panics and warning will be removed.
* This BIOS uses the `xchg cx,cx` instruction to stop the Bochs debugger at certain places, mostly places that have yet to be supported. Most of the time, you can simply continue.
* **As of right now, after a major re-build**, you should delete the `escd.bin` file so that the BIOS will build a new default file. For example, the latest build retrieves the seconds to wait for a F12/F10 key press. If you have an old `escd.bin` file, it might return zero (or 0x90) and either not wait for you to press a key, or wait a long time.
* When using Jemm386 (v5.79 and possibly all versions) and/or HimemX (v3.36 and possibly all versions), one or the other will remap the address range 0x000E0000 -> 0x000E3FFF to 0x00149000. Of course this will break this BIOS, or any BIOS that uses the extended BIOS area starting at 0x000E0000. Using standard (MS-)DOS memory extenders work as expected.\
Build with `/DHIMEMHACK` to allow the use of Jemm386 and/or HimemX. This will ignore the part that breaks this BIOS. See <a href="https://github.com/fysnet/i440fx/issues/4">https://github.com/fysnet/i440fx/issues/4</a> for more information.

### A list of Guest OS I have tested with
* Note that even though I list a guest OS here, this doesn't mean my BIOS passes all tests. It simply means that I have successfully booted this guest with default or normal options and parameters. Thorough testing is still in order.\
If you have tested this BIOS with your homebrew OS or any other OS and would like it listed here, please let me know by sending me a URL to a bootable image. I can be reached at `fys [at] fysnet [dot] net`.\
(Listed in no particular order)
  * [FreeDOS](https://www.freedos.org/)
  * [Gentoo](https://www.gentoo.org/) (older version, I haven't tried a latest release yet)
  * [netbsd](https://www.netbsd.org/) (older version, I haven't tried a latest release yet)
  * MS-DOS v6.22 (Other versions have been tested sporadically)
  * OS2Warp v4.0
  * [pdos](http://pdos.org)
  * [ReactOS](https://reactos.org) v0.4.14
  * [SliTaz](https://slitaz.org/en/) (older version, I haven't tried a latest release yet)
  * [TinyCore](http://tinycorelinux.net/) (older version, I haven't tried a latest release yet)
  * Windows 3.11
  * Windows 95
  * Windows 95 OSR2
  * Windows 98
  * Windows 98 SE
  * Windows 2000
  * Windows ME
  * Windows XP
  * Windows 7
  * Windows 8.1
  * Windows 10
  * Windows 11
