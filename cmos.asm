comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: cmos.asm                                                           *
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
* DESCRIPTION:                                                             *
*   cmos include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 25 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*   See the end of this file for the CMOS map                              *
***************************************************************************|

PORT_CMOS_INDEX        equ  0x0070
PORT_CMOS_DATA         equ  0x0071

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a byte from the cmos
; on entry:
;  ah = byte offset
; on return
;  al = byte read
; destroys ax
cmos_get_byte proc near
           mov  al,ah
           out  PORT_CMOS_INDEX,al
           in   al,PORT_CMOS_DATA
           ret
cmos_get_byte endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a byte to the cmos
; on entry:
;  ah = byte offset
;  al = byte to write
; on return
;  nothing
; destroys ax
cmos_put_byte proc near
           xchg al,ah
           out  PORT_CMOS_INDEX,al
           xchg al,ah
           out  PORT_CMOS_DATA,al
           ret
cmos_put_byte endp

.end

Legend:
S - set by the emulator (Bochs)
B - set by the bios
U - unused by the bios

LOC NOTES MEANING
0x00  S rtc seconds
0x01  B second alarm
0x02  S rtc minutes
0x03  B minute alarm
0x04  S rtc hours
0x05  B hour alarm

0x06  S,U day of week
0x07  S,B date of month
0x08  S,B month
0x09  S,B year

0x0a  S,B status register A
0x0b  S,B status register B
0x0c  S status register C
0x0d  S status register D

0x0f  S shutdown status
    values:
  0x00: normal startup
  0x09: normal
  0x0d+: normal
  0x05: eoi ?
  else: unimpl

0x10  S fd drive type (2 nibbles: high=fd0, low=fd1)
    values:
  1: 360K 5.25"
  2: 1.2MB 5.25"
  3: 720K 3.5"
  4: 1.44MB 3.5"
  5: 2.88MB 3.5"

!0x11 configuration bits!!

0x12  S how many disks first (hd type)

!0x13 advanced configuration bits!!

0x14  S,U equipment byte (?)
  bits  where   what
  7-6 floppy.cc
  5-4 vga.cc    0 = vga
  2 keyboard.cc 1 = enabled
  0 floppy.cc

0x15  S,U base memory - low
0x16  S,U base memory - high

0x17  S,U extended memory in k - low
0x18  S,U extended memory in k - high

0x19  S hd0: extended type
0x1a  S hd1: extended type

0x1b  S,U hd0:cylinders - low
0x1c  S,U hd0:cylinders - high
0x1d  S,U hd0:heads
0x1e  S,U hd0:write pre-comp - low
0x1f  S,U hd0:write pre-comp - high
0x20  S,U hd0:retries/bad_map/heads>8
0x21  S,U hd0:landing zone - low
0x22  S,U hd0:landing zone - high
0x23  S,U hd0:sectors per track

0x24  S,U hd1:cylinders - low
0x25  S,U hd1:cylinders - high
0x26  S,U hd1:heads
0x27  S,U hd1:write pre-comp - low
0x28  S,U hd1:write pre-comp - high
0x29  S,U hd1:retries/bad_map/heads>8
0x2a  S,U hd1:landing zone - low
0x2b  S,U hd1:landing zone - high
0x2c  S,U hd1:sectors per track

0x2d  S boot from (bit5: 0:hd, 1:fd)

0x2e  S,U standard cmos checksum (0x10->0x2d) - high
0x2f  S,U standard cmos checksum (0x10->0x2d) - low

0x30  S extended memory in k - low
0x31  S extended memory in k - high

0x32  S rtc century

0x34  S extended memory in 64k (above 16Meg) - low
0x35  S extended memory in 64k (above 16Meg) - high

0x37  S ps/2 rtc century (copy of 0x32, needed for winxp)

0x38  S eltorito boot sequence + boot signature check
  bits
  0 floppy boot signature check (1: disabled, 0: enabled)
  7-4 boot drive #3 (0: unused, 1: fd, 2: hd, 3:cd, else: fd)

0x39  S ata translation policy - ata0 + ata1
  bits
  1-0 ata0-master (0: none, 1: LBA, 2: LARGE, 3: R-ECHS)
  3-2 ata0-slave
  5-4 ata1-master
  7-6 ata1-slave

0x3a  S ata translation policy - ata2 + ata3 (see above)

0x3b  S ata biosdetect flags - ata0 + ata1 (unimplemented)
  bits
  1-0 ata0-master (0: auto, 1: cmos, 2: none)
  3-2 ata0-slave
  5-4 ata1-master
  7-6 ata1-slave

0x3c  S ata biosdetect flags - ata2 + ata3 (unimplemented)

0x3d  S eltorito boot sequence (see above)
  bits
  3-0 boot drive #1
  7-4 boot drive #2

0x3f  S BIOS options
  bits
  0 fastboot (skip boot menu delay)
  7-1 reserved

0x5b  S   extra memory above 4GB (in 64k) (low byte)
0x5c  S   extra memory above 4GB (in 64k) (mid byte)
0x5d  S   extra memory above 4GB (in 64k) (high byte)

0x5f  U 
