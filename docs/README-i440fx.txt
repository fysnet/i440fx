i440fx - A BIOS for Bochs and QEMU
Assembly source code included

    Contents

  * Overview: An overview of this BIOS
  * Objective: The objective of this BIOS
  * Resources: The required resources for this BIOS
  * Building: Building this BIOS from source
  * Usage: Using this BIOS with Bochs or QEMU
  * User interaction: Interaction with the BIOS
  * ESCD: Extended System Configuration Data usage
  * USB: USB emulation
  * Post: Last words


    Overview

  * This BIOS is designed to emulate the Intel 440fx (Pentium, 
    Pentium Pro, and Pentium II) and the later Intel 440bx
    (Pentium II, Pentium III, and Celeron) chipsets.
  * i440fx is an open source adaptation of the original Bochs BIOS
    with many fixes and enhancements. It is written entirely in x86
    Assembly assembled with the NBASM assembler.
  * It is designed to boot a guest following the BIOS Boot Specification
    with enhancements like PnP, USB emulation, ACPI, and other resources.
  * Unlike the previous source, this adaptation requires only one build
    application (the assembler) with a single command line. No
    manipulation or preprocessing of source code and no post-processing.
    A single assembler and a single command line creates the BIOS image
    all at once.
  * This BIOS is designed for and has been tested to boot guests as old
    as IBM PCDOS 2.0 (as long as you don't use the internal BASIC
    interpreter such as with BASICA, etc.) to most modern quests such as
    Windows 11 and various unix based quests.


    Objective

  * The objective for this BIOS was first to see if I can do it. I
    wanted to see if I could adapt and enhance the given BIOS to boot a
    wider range of guests, and second, to add booting from USB devices.
  * There are a few errors with the previous BIOS, a few in the CD-ROM
    emulation, as well as other misc errors. The objective of this BIOS
    is to eliminate errors and enhance its function.


    Resources

  * This BIOS is designed to be used with the BOCHS emulator.
      o Bochs Project page: https://sourceforge.net/projects/bochs/files/bochs/
      o Bochs github source: https://github.com/bochs-emu/Bochs
  * The source code for this BIOS.
      o i440fx: https://github.com/fysnet/i440fx
      o This source is licensed as:
              *                                                                          *
              *  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
              *                                                                          *
              *                         i440FX BIOS ROM v1.0                             *
              *                                                                          *
              * This code is freeware, not public domain.  Please use respectfully.      *
              *                                                                          *
              * You may:                                                                 *
              *  - use this code for learning purposes only.                             *
              *  - use this code in your own Operating System development.               *
              *  - distribute any code that you produce pertaining to this code          *
              *    as long as it is for learning purposes only, not for profit,          *
              *    and you give credit where credit is due.                              *
              *                                                                          *
              * You may NOT:                                                             *
              *  - distribute this code for any purpose other than listed above.         *
              *  - distribute this code for profit.                                      *
              *                                                                          *
              * You MUST:                                                                *
              *  - include this whole comment block at the top of this file.             *
              *  - include contact information to where the original source is located.  *
              *            https://github.com/fysnet/i440fx                              *
              *                                                                          *
                    

    Building

  * This BIOS is assembled with the NewBasic assembler.
      o NewBasic Assembler: https://www.fysnet.net/newbasic.htm -- version 00.27.16 or higher

  * This assembler is intended for DOS and 32-bit and 64-bit Windows.
    However, using additional resources, you can use this assembler on
    Linux.

      o Windows (Command Prompt):

        To build this BIOS for BOCHS, from the i440fx directory, use the
        following commandline:

               NBASM i440fx /x /z

        This will produce |i44fx.bin| ready to be inserted into the
        emulation. It will also create a |.lst| file showing all of the
        references throughout the source code, useful for debugging.

        To build this BIOS for Qemu, from the i440fx directory, use the
        following commandline:

               NBASM i440fx /x /z /DBX_QEMU

        You can exclude the |/x| parameter if you wish. If you exclude
        the |/z| parameter, NBASM will show a few diagnostic warnings.
        These can be ignored.

      o Linux:

        Using additional resources, you can use NBASM on Linux.

        I don't use Linux but a fellow user says you can use WINE to run
        NBASM. Just ignore the warning at the start and the end of the
        Wine output.

        To build this BIOS for BOCHS, from the i440fx directory, use the
        following:

               wine /path/to/program/nbasm64.exe /x /z i440fx

        This will produce |i44fx.bin| ready to be inserted into the
        emulation. It will also create a |.lst| file showing all of the
        references throughout the source code useful for debugging.

        To build this BIOS for Qemu, from the i440fx directory, use the
        following:

               wine /path/to/program/nbasm64.exe /x /z /DBX_QEMU i440fx

        You can exclude the |/x| parameter if you wish. If you exclude
        the |/z| parameter, NBASM will show a few diagnostic warnings.
        These can be ignored.


    Using

  * To use this BIOS with Bochs, place one of the following lines in
    your |bochsrc.txt| file:
      o  romimage: file=$BXSHARE/bios/i440fx/i440fx.bin
      o  romimage: file=$BXSHARE/bios/i440fx/i440fx.bin, flash_data="escd.bin"

    If you haven't set the |$BXSHARE| parameter to point to the Bochs
    directory, change the above to point directly to the binary file.

    The second example will use the ESCD (Extended System Configuration
    Data) data given in the |escd.bin| file. See the ESCD section for more 
    on this. If the file doesn't exist, this BIOS will create one using defaults.

    It is recommended that you use the following addition:
      o  cpu: model=pentium

  * To use this BIOS with QEMU, use the following parameter:
      o  -bios C:\path\to\this\bios\i440fx_qemu.bin

    It is recommended that you use the following addition:
      o  -cpu pentium3-v1

    The following has been known to work, but not completely supported:
      o  -machine q35


    User Interaction

  * During Boot, you will see a prompt.

  * Depending on the settings, you will have just a few seconds to press
    either F10 or F12.

    If you press F10, the setup will be shown. See the ESCD section for 
    more on this.

    If you press F12, you will be shown a list of found bootable
    devices. Press the letter next to the device you wish to boot.


    ESCD (Extended System Configuration Data)

  * This BIOS uses the Extended System Configuration Data (ESCD) area in
    the 0xFC000-0xFFFFF range.
  
    If you include an ESCD file to use (see a previous section), this
    BIOS will use the contents of that file for settings and other data
    during boot time. If you did not include a file, defaults will be used.

    This file and the data within it is used for various items
    throughout the boot.

      o Num Lock: Shall the Num Lock state be on or off at boot time?
      o Delay: The count of seconds to delay waiting for a key press at
        the shown prompt.
      o Other items will be added here.

  
    The Setup page:

  * The setup page appears when you press F10 at the boot prompt.
  * You can use the mouse or the arrow keys to move around the items. If
    you use the arrow keys, the space key will simulate a mouse click on
    the item selected.
  * Please note that a lot of work is still needed for this setup page
    and I will update this documentation when that work progresses.


    USB Emulation

  * This BIOS will emulate a given USB device.
  * Currently only the following items are supported:
      o  USB Floppy Disk
      o  USB Hard Drive
      o  CD-ROM Disc
  * Future plans are to emulate a USB mouse and Keyboard.
    To boot a USB device, use the following in your |bochsrc.txt| file:

           boot: usb

    Then depending on the USB controller used:

           usb_uhci: port1=floppy, options1="speed:full, path:some/path/floppy.img, model:teac"

    To boot a floppy or other drive using another controller, use a very
    similar line:

           usb_ohci: port2=cdrom, options2="speed:full, path:../common/bootcd.iso"
           usb_ehci: port1=disk, options1="speed:high, path:../common/hdd.img, proto:bbb"
           usb_xhci: port1=disk, options1="speed:super, path:../common/hdd.img, proto:bbb"

    Remember that each controller other than the UHCI requires the |slotx=| 
    addition in the pci declaration:

           pci: enabled=1, chipset=i440fx, slot1=usb_ohci

  * The emulation will be on the first found USB device, or press F12 to
    choose one from a list.
  * The uasp protocol is currently not supported with this BIOS.

    
    Type of device detected:

    This BIOS will do a few calculations on a given USB image file
    determining how to boot said file.

      o  If a USB HDD device is detected, the following checks will be
         made on the first sector:
         1. byte[0] == 0xEB and byte[2] == 0x90 ; jmp short xxxx
          or
            byte[0] == 0xE9 and word[1] < 0x1FE ; jmp near xxxx
         2. word at [11] == 512 ; bytes per sector
         3. word at [14] > 0 ; reserved sectors
         4. byte at [16] == 1 or 2 ; number of fats
         5. bytes at [54:61] == 'FAT12 ' ; system
         6. word at [19] == 2880 ; sectors
          or
            word at [19] == 0 && dword at [32] == 2880 ; extended sectors

         If all of the above is true, no matter the size of the HDD
         image, this BIOS will mount it as a 1.44M floppy disk.

      o  If the Block Size == 2048, a CD-ROM is assumed and will attempt
         to mount the bootable image within the CD-ROM using:

         Depending on the media (Eltorito Boot included?)
          + no emulation using 2048-byte sectors
          + floppy or hdd emulation using 512-byte sectors.
      o  Otherwise, it will attempt to mount as a hdd device with or w/o
         a MBR.


    Conclusion

  * All comments, patches, fixes, or other are always welcome,
    especially if the intent is to enhance this BIOS. Please create a
    Pull Request or create an Issue if you wish to contribute.


Latest Update: 29 Jan 2025, 16.37
