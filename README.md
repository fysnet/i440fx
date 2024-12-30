# i440fx
i440fx BIOS source code intended for Bochs

This is the assembly source code to an Intel i440fx compatible BIOS I wrote based on the .C source code included with the original [BOCHS BIOS](https://github.com/bochs-emu/Bochs/tree/master/bochs/bios). I have fixed many issues that came with that BIOS as well as added more function. It has been tested using most (MS)DOS Operating Systems up to and including recent Windows(tm) Operating Systems that still boot via BIOS.

It is intended to be used in the [BOCHS environment](https://github.com/bochs-emu/Bochs), but can be built and used in the [QEMU environment](https://www.qemu.org/). See the link below for more information.

My intent is twofold. The first and foremost was to add booting from a USB device within BOCHS. For example, you can boot a device image as a floppy, hdd, or cd-rom. The second was simply to see if I can do it, write a BIOS that will boot an OS.

It is built with my own Intel x86 assembler found at [https://www.fysnet.net/newbasic.htm](https://www.fysnet.net/newbasic.htm).

Documentation can be found at [https://www.fysnet.net/i440fx/index.htm](https://www.fysnet.net/i440fx/index.htm).
