comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: pnp.asm                                                            *
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
*   pnp include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 12 Jan 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

PNP_IS_REALMODE        equ  0     ; guaranteed realmode (use for testing purposes only, otherwise must be 0)

PNP_SUCCESS            equ  0x00  ; Function completed successfully
PNP_UNKNOWN_FUNCTION   equ  0x81  ; Unknown, or invalid, function number passed
PNP_NOT_SUPPORTED      equ  0x82  ; The function is not supported on this system
PNP_INVALID_HANDLE     equ  0x83  ; Device node number/handle passed is invalid or out of range
PNP_BAD_PARAMETER      equ  0x84  ; Function detected invalid resource descriptors or resource descriptors were specified out of order
PNP_SET_FAILED         equ  0x85  ; Set Device Node function failed
PNP_EVENTS_NOT_PENDING equ  0x86  ; There are no events pending
PNP_SYSTEM_NOT_DOCKED  equ  0x87  ; The system is currently not docked
PNP_NO_ISA_PNP_CARDS   equ  0x88  ; Indicates that no ISA Plug and Play cards are installed in the system
PNP_UNABLE_DOCK_CAPS   equ  0x89  ; Indicates that the system was not able to determine the capabilities of the docking station
PNP_NO_BATTERY         equ  0x8A  ; The system failed the undocking sequence because it detected that the system unit did not have a battery
PNP_RESOURCE_CONFLICT  equ  0x8B  ; The system failed to successfully dock because it detected a resource conflict with one of the primary boot devices; such as Input, Output, or the IPL device
PNP_BUFFER_TOO_SMALL   equ  0x8C  ; The memory buffer passed in by the caller was not large enough to hold the data to be returned by the system BIOS
PNP_USE_ESCD_SUPPORT   equ  0x8D  ; ...system BIOS must be handled through the interfaces defined by the ESCD Specification
PNP_MSG_NOT_SUPPORTED  equ  0x8E  ; The message passed to the system BIOS through function 04h, Send Message, is not supported on the system
PNP_HARDWARE_ERROR     equ  0x8F  ; The system BIOS detected a hardware failure

PNP_MSD_NODE_LEN  equ 29   ; length of an MSD node (floppy, ide)
PNP_VGA_NODE_LEN  equ 105  ; length of the VGA node (VGA, Banshee, Cirrus)

; ECP Parallel port
pnp_node_01:
   dw  248                 ; length 248
   db  1                   ; handle
   db  41h, 0D0h, 04h, 00h ; 0_10000_01110_10000__0000_0100_0000_0000b = PNP0400 = Standard LPT printer port
   db  7,1,2               ; ECP 1.? compliant port
   dw  0x0080              ; bits 8:7 = 01b = can be configured at run time
   
   ; allocated resource configuration descriptor
   db  0_0101_010b         ; DMA format, 2 more bytes
     db  0x00                ; DMA bitmask (bit 0 = channel 0)
     db  0x08                ; compatibility mode, word mode
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<7)              ; IRQ 7
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0378              ; minimum IO base address
     dw  0x0378              ; maximum IO base address
     db  8                   ; minimum alignment
     db  8                   ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0778              ; minimum IO base address
     dw  0x0778              ; maximum IO base address
     db  8                   ; minimum alignment
     db  8                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
     
   ; possible resource configuration descriptor block:
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0378              ; minimum IO base address
       dw  0x0378              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0778              ; minimum IO base address
       dw  0x0778              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0278              ; minimum IO base address
       dw  0x0278              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0678              ; minimum IO base address
       dw  0x0678              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x03BC              ; minimum IO base address
       dw  0x03BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x07BC              ; minimum IO base address
       dw  0x07BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0378              ; minimum IO base address
       dw  0x0378              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0778              ; minimum IO base address
       dw  0x0778              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x0E                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0278              ; minimum IO base address
       dw  0x0278              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0678              ; minimum IO base address
       dw  0x0678              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x0E                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x03BC              ; minimum IO base address
       dw  0x03BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x07BC              ; minimum IO base address
       dw  0x07BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  0x0000
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0378              ; minimum IO base address
       dw  0x0378              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0778              ; minimum IO base address
       dw  0x0778              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  0x0000
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0278              ; minimum IO base address
       dw  0x0278              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0678              ; minimum IO base address
       dw  0x0678              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0101_010b         ; DMA format, 2 more bytes
       db  0x00                ; DMA bitmask (bit 0 = channel 0)
       db  0x08                ; compatibility mode, word mode
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  0x0000
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x03BC              ; minimum IO base address
       dw  0x03BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x07BC              ; minimum IO base address
       dw  0x07BC              ; maximum IO base address
       db  4                   ; minimum alignment
       db  4                   ; size of register space
   db  0_0111_000b         ; end dependent function
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; 16550A-compatible COM port
pnp_node_02:
   dw  66                  ; length 66
   db  2                   ; handle
   db  41h, 0D0h, 05h, 01h ; 0_10000_01110_10000__0000_0101_0000_0001b = PNP0501 = 16550A-compatible COM port
   db  7,0,2               ; 16550-compatible
   dw  0x0080              ; bits 8:7 = 01b = can be configured at run time

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<4)              ; IRQ 4
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x03F8              ; minimum IO base address
     dw  0x03F8              ; maximum IO base address
     db  8                   ; minimum alignment
     db  8                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  (1<<4)              ; IRQ 4
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x03F8              ; minimum IO base address
       dw  0x03F8              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  (1<<3)              ; IRQ 3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x03E8              ; minimum IO base address
       dw  0x03E8              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0100_010b         ; IRQ format, 2 more bytes
       dw  ((1<<12) | (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)) ; IRQ 12,7,6,5,4,3
     db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
       db  1                   ; info: decodes all 16-bit ISA bus
       dw  0x0110              ; minimum IO base address
       dw  0x07F8              ; maximum IO base address
       db  8                   ; minimum alignment
       db  8                   ; size of register space
   db  0_0111_000b         ; end dependent function
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; APIC
pnp_node_03:
   dw  42                  ; length 42
   db  3                   ; handle
   db  41h, 0D0h, 00h, 03h ; 0_10000_01110_10000__0000_0000_0000_0011b = PNP0003 = APIC
   db  8,0x80,0            ; Other System Peripheral
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00011101b         ; info: 32-bit supported, high-address, non-cacheable, writable
     dd  IOAPIC_BASE_ADDR  ; base address (I/O APIC)
     dd  0x00010000        ; length (64k)
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00011101b         ; info: 32-bit supported, high-address, non-cacheable, writable
     dd  APIC_BASE_ADDR    ; base address (APIC)
     dd  0x00010000        ; length (64k)
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; HPET
pnp_node_04:
   dw  30                  ; length 30
   db  4                   ; handle
   db  41h, 0D0h, 01h, 03h ; 0_10000_01110_10000__0000_0001_0000_0011b = PNP0103 = High precision event timer
   db  8,0x80,0            ; Other System Peripheral
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00011101b         ; info: 32-bit supported, high-address, non-cacheable, writable
     dd  0xFED00000        ; base address (HPET)
     dd  0x00001000        ; length
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; Mouse Controller
pnp_node_05:
   dw  26                  ; length 26
   db  5                   ; handle
   db  41h, 0D0h, 0Fh, 13h ; 0_10000_01110_10000__0000_1111_0001_0011b = PNP0F13 = PS/2 Port for PS/2-style Mice
   db  9,2,0               ; Mouse Controller
   dw  0x0180              ; bits 8:7 = 11b = can only be configured at run time

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<12)             ; IRQ 12
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_0110_000b         ; start dependent function (default: acceptable)
     db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<12)             ; IRQ 12
   db  0_0111_000b         ; end dependent function
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; System Board
pnp_node_06:
   dw  94                  ; length 94
   db  6                   ; handle
   db  41h, 0D0h, 0Ch, 01h ; 0_10000_01110_10000__0000_1100_0000_0001b = PNP0C01 = System Board
   db  5,0,0               ; General RAM
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00010011b         ; info: 8- and 16-bit supported, read cache-write through, writable
     dd  0x00000000        ; base address
     dd  0x000A0000        ; length
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00110010b         ; info: shadowable, 8- and 16-bit supported, read cache-write through, non-writable
     dd  0x000E0000        ; base address
     dd  0x00020000        ; length
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00010011b         ; info: 8- and 16-bit supported, read cache-write through, writable
     dd  0x00100000        ; base address
     dd  ?                 ; length (this length gets patched before we block shadowram) (** watch modifying this location **)
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0800              ; minimum IO base address
     dw  0x0800              ; maximum IO base address
     db  0                   ; minimum alignment
     db  224                 ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0C00              ; minimum IO base address
     dw  0x0C00              ; maximum IO base address
     db  0                   ; minimum alignment
     db  128                 ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0062              ; minimum IO base address
     dw  0x0062              ; maximum IO base address
     db  0                   ; minimum alignment
     db  2                   ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0065              ; minimum IO base address
     dw  0x0065              ; maximum IO base address
     db  0                   ; minimum alignment
     db  11                  ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x00E0              ; minimum IO base address
     dw  0x00E0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  16                  ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; ISA PIC (8259 Compatible)
pnp_node_07:
   dw  45                  ; length 45
   db  7                   ; handle
   db  41h, 0D0h, 00h, 00h ; 0_10000_01110_10000__0000_0000_0000_0000b = PNP0000 = AT Interrupt Controller
   db  8,0,1               ; ISA PIC (8259 Compatible)
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<2)              ; IRQ 2
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0020              ; minimum IO base address
     dw  0x0020              ; maximum IO base address
     db  0                   ; minimum alignment
     db  0x20                ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x00A0              ; minimum IO base address
     dw  0x00A0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  0x20                ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x04D0              ; minimum IO base address
     dw  0x04D0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  2                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; ISA System Timer
pnp_node_08:
   dw  29                  ; length 29
   db  8                   ; handle
   db  41h, 0D0h, 01h, 00h ; 0_10000_01110_10000__0000_0001_0000_0000b = PNP0100 = AT Timer
   db  8,2,1               ; ISA System Timer
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<0)              ; IRQ 0
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0040              ; minimum IO base address
     dw  0x0040              ; maximum IO base address
     db  0                   ; minimum alignment
     db  32                  ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; ISA RTC Controller
pnp_node_09:
   dw  29                  ; length 29
   db  9                   ; handle
   db  41h, 0D0h, 0Bh, 00h ; 0_10000_01110_10000__0000_1011_0000_0000b = PNP0B00 = AT Real-Time Clock
   db  8,3,1               ; ISA RTC Controller
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<8)              ; IRQ 8
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0070              ; minimum IO base address
     dw  0x0070              ; maximum IO base address
     db  0                   ; minimum alignment
     db  16                  ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; Keyboard Controller
pnp_node_10:
   dw  37                  ; length 37
   db  10                  ; handle
   db  41h, 0D0h, 03h, 03h ; 0_10000_01110_10000__0000_0011_0000_0011b = PNP0303 = IBM Enhanced (101/102-key, PS/2 mouse support)
   db  9,0,0               ; Keyboard Controller
   dw  0x000B              ; primary input device, is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<1)              ; IRQ 1
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0060              ; minimum IO base address
     dw  0x0060              ; maximum IO base address
     db  0                   ; minimum alignment
     db  1                   ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0064              ; minimum IO base address
     dw  0x0064              ; maximum IO base address
     db  0                   ; minimum alignment
     db  1                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; Coprocessor
pnp_node_11:
   dw  29                  ; length 29
   db  11                  ; handle
   db  41h, 0D0h, 0Ch, 04h ; 0_10000_01110_10000__0000_0011_0000_0011b = PNP0C04 = Math Coprocessor
   db  8,0x80,0            ; Other System Peripheral
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0100_010b         ; IRQ format, 2 more bytes
     dw  (1<<13)              ; IRQ 13
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x00F0              ; minimum IO base address
     dw  0x00F0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  16                  ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; ISA DMA Controller
pnp_node_12:
   dw  45                  ; length 45
   db  12                  ; handle
   db  41h, 0D0h, 02h, 00h ; 0_10000_01110_10000__0000_0010_0000_0000b = PNP0200 = AT DMA Controller
   db  8,1,1               ; ISA DMA Controller
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_0101_010b         ; DMA format, 2 more bytes
     db  0x10                ; DMA bitmask (channel 4)
     db  0x12                ; 16-bit and word count
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0000              ; minimum IO base address
     dw  0x0000              ; maximum IO base address
     db  0                   ; minimum alignment
     db  32                  ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0080              ; minimum IO base address
     dw  0x0080              ; maximum IO base address
     db  0                   ; minimum alignment
     db  32                  ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x00C0              ; minimum IO base address
     dw  0x00C0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  32                  ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; AT-style speaker sound
pnp_node_13:
   dw  26                  ; length 26
   db  13                  ; handle
   db  41h, 0D0h, 08h, 00h ; 0_10000_01110_10000__0000_1000_0000_0000b = PNP0800 = AT-style speaker sound
   db  8,0x80,0            ; Other System Peripheral
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0061              ; minimum IO base address
     dw  0x0061              ; maximum IO base address
     db  0                   ; minimum alignment
     db  1                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; General PCI Bridge
pnp_node_14:
   dw  26                  ; length 26
   db  14                  ; handle
   db  41h, 0D0h, 0Ah, 03h ; 0_10000_01110_10000__0000_1010_0000_0011b = PNP0A03 = PCI Bus
   db  6,4,0               ; General PCI Bridge
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x0CF8              ; minimum IO base address
     dw  0x0CF8              ; maximum IO base address
     db  0                   ; minimum alignment
     db  8                   ; size of register space
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

; Standard VGA (only used if no PCI vga found) (if PCI vga found, the floppy or hdd will overwrite this area)
pnp_node_15:
   dw  70                  ; length 70
   db  15                  ; handle
   db  41h, 0D0h, 09h, 00h ; 0_10000_01110_10000__0000_1001_0000_0000b = PNP0900 = VGA compatible
   db  3,0,0               ; VGA Compatible Controller
   dw  0x0003              ; is not configurable, cannot be disabled

   ; allocated resource configuration descriptor
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x03B0              ; minimum IO base address
     dw  0x03B0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  12                  ; size of register space
   db  0_1000_111b         ; I/O Port descriptor, 7 more bytes
     db  1                   ; info: decodes all 16-bit ISA bus
     dw  0x03C0              ; minimum IO base address
     dw  0x03C0              ; maximum IO base address
     db  0                   ; minimum alignment
     db  32                  ; size of register space
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00010001b         ; info: 8/16-bit supported, non-cacheable, writable
     dd  0x000A0000        ; base address
     dd  0x0000FFFF        ; length
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00010001b         ; info: 8/16-bit supported, non-cacheable, writable
     dd  0x000B0000        ; base address
     dd  0x0000FFFF        ; length
   db  1_0000110b          ; 32-bit fixed location memory range descriptor
    dw  0x0009             ; 9 bytes in length
     db  00010001b         ; info: 8/16-bit supported, non-cacheable, writable
     dd  0x000C0000        ; base address
     dd  0x00007FFF        ; length
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; possible resource configuration descriptor block:
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
   
   ; compatible device identifiers
   db  0_1111_001b         ; end tag, 1 more byte
     db  0                 ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

pnp_node_16:
  ; we reserved enough room for one floppy drive and two ATA controllers, each PNP_MSD_NODE_LEN bytes
  dup (PNP_MSD_NODE_LEN * 3),0


PNP_NODE_LIST_S struct
  handle      byte
  next        byte
  size        word
  location    word
PNP_NODE_LIST_S ends

; a list of the nodes we have
pnp_node_list  db  1                  ; handle
               db  2                  ; next handle (or 0xFF for none)
               dw  248                ; size of node
               dw  offset pnp_node_01 ; offset of node

               db  2                  ; handle
               db  3                  ; next handle (or 0xFF for none)
               dw  66                 ; size of node
               dw  offset pnp_node_02 ; offset of node

               db  3                  ; handle
               db  4                  ; next handle (or 0xFF for none)
               dw  42                 ; size of node
               dw  offset pnp_node_03 ; offset of node

               db  4                  ; handle
               db  5                  ; next handle (or 0xFF for none)
               dw  30                 ; size of node
               dw  offset pnp_node_04 ; offset of node

               db  5                  ; handle
               db  6                  ; next handle (or 0xFF for none)
               dw  26                 ; size of node
               dw  offset pnp_node_05 ; offset of node

               db  6                  ; handle
               db  7                  ; next handle (or 0xFF for none)
               dw  94                 ; size of node
               dw  offset pnp_node_06 ; offset of node

               db  7                  ; handle
               db  8                  ; next handle (or 0xFF for none)
               dw  45                 ; size of node
               dw  offset pnp_node_07 ; offset of node

               db  8                  ; handle
               db  9                  ; next handle (or 0xFF for none)
               dw  29                 ; size of node
               dw  offset pnp_node_08 ; offset of node

               db  9                  ; handle
               db  10                 ; next handle (or 0xFF for none)
               dw  29                 ; size of node
               dw  offset pnp_node_09 ; offset of node

               db  10                 ; handle
               db  11                 ; next handle (or 0xFF for none)
               dw  37                 ; size of node
               dw  offset pnp_node_10 ; offset of node

               db  11                 ; handle
               db  12                 ; next handle (or 0xFF for none)
               dw  29                 ; size of node
               dw  offset pnp_node_11 ; offset of node

               db  12                 ; handle
               db  13                 ; next handle (or 0xFF for none)
               dw  45                 ; size of node
               dw  offset pnp_node_12 ; offset of node

               db  13                 ; handle
               db  14                 ; next handle (or 0xFF for none)
               dw  26                 ; size of node
               dw  offset pnp_node_13 ; offset of node

               db  14                 ; handle
               db  0xFF               ; next handle (or 0xFF for none)
               dw  26                 ; size of node
               dw  offset pnp_node_14 ; offset of node

               ; we save room to add up to four more entries
               ; (one VGA, one floppy drive, two ata controllers)
               ; these are added in 'pnp_initialize'
               dup (4 * sizeof(PNP_NODE_LIST_S)),0

; during BIOS initialization, these will be read/write accessible.
; after initialization, they are read only
pnp_node_count  db  14                ; count of valid nodes (before pnp_initialize call)
pnp_node_size   dw  248               ; size of largest node
pnp_next_node   dw  offset pnp_node_15
pnp_next_idx    dw  (pnp_node_list + ((14 - 1) * sizeof(PNP_NODE_LIST_S))) ; *** points to the current last entry ***

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize the PNP
;  Shaddow Ram is implemented. We can write to 0x000E0000->0x000FFFFF
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
pnp_initialize proc near uses eax bx cx dx ds
           mov  ax,EBDA_SEG
           mov  ds,ax

           ; we need to patch the extended memory value in our physical memory node
           mov  eax,[EBDA_DATA->mem_base_ram_size]
           sub  eax,0x00100000
           mov  cs:[pnp_node_06 + ((4*12) - sizeof(dword))],eax  ; third 12-byte block, last dword of that block

           ret ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

           ; check if a pci vga card is found
           ; if not, add a standard VGA entry
           call pnp_add_vga

           ; we add one floppy disk controller if we found one
           cmp  byte [EBDA_DATA->fdd_count],0
           je   short @f
           mov  eax,0x0007D041 ; little_endian(0_10000_01110_10000__0000_0111_0000_0000b) = PNP0700 = PC standard floppy disk controller
           mov  cx,0x0206      ; Generic Floppy / irq 6
           mov  dx,0x3F0
           call pnp_add_msd

           ; go through the first two ata controllers
@@:        mov  cx,2
           xor  bx,bx
pnp_add_msd_0:
           cmp  byte [bx+EBDA_DATA->ata_0_iface],ATA_IFACE_NONE
           je   short @f

           push cx
           mov  eax,0x0006D041 ; little_endian(0_10000_01110_10000__0000_0110_0000_0000b) = PNP0600 = Generic ESDI/IDE/ATA compatible hard disk controller
           mov  ch,0x01        ; Generic IDE
           mov  cl,[bx+EBDA_DATA->ata_0_irq]
           mov  dx,[bx+EBDA_DATA->ata_0_iobase1]
           call pnp_add_msd
           pop  cx

@@:        add  bx,ATA_CHANNEL_SIZE
           loop short pnp_add_msd_0
           
           ret
pnp_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; add a floppy/hard disk/cdrom to the pnp node list
; on entry:
;  eax = id (PNP0700 for floppy, PNP0600 for IDE)
;  cl = irq (6 = irq 6)
;  ch = type (2 = floppy, 1 = ide)
;  dx = base0 IO address (0x3F0, 0x1F0, etc)
; on return
;  nothing
; destroys none
pnp_add_msd proc near uses eax bx cx dx ds
           mov  bx,BIOS_BASE
           mov  ds,bx
           
           mov  bx,pnp_next_node    ; offset to next available space for node data
           inc  byte pnp_node_count ; increment the count
           push ax                  ; preserved the id
           mov  al,pnp_node_count   ;

           ; build node
           mov  word [bx+0],PNP_MSD_NODE_LEN ; length
           mov       [bx+2],al   ; handle
           pop  ax               ; restore the id
           mov       [bx+3],eax  ; id
           mov  byte [bx+7],1    ; 
           mov       [bx+8],ch   ; type
           mov  byte [bx+9],0    ;
           mov  word [bx+10],0x0090 ; is configurable at runtime, primary IPL device

           ; build IRQ format
           mov  byte [bx+12],0_0100_010b         ; IRQ format, 2 more bytes
           mov  ax,1
           shl  ax,cl
           mov       [bx+13],ax                  ; IRQ cl

           ; allocated resource configuration descriptor
           mov  byte [bx+15],0_1000_111b         ; I/O Port descriptor, 7 more bytes
           mov  byte [bx+16],1                   ; info: decodes all 16-bit ISA bus
           mov       [bx+17],dx                  ; minimum IO base address
           mov       [bx+19],dx                  ; maximum IO base address
           mov  byte [bx+21],8                   ; minimum alignment
           mov  byte [bx+22],8                   ; size of register space

; floppy disk can have this added
;   db  0_0101_010b         ; DMA format, 2 more bytes
;     db  0x04                ; DMA bitmask (bit 2 = channel 2)
;     db  0x08                ; compatibility mode, word mode
           
           ; end tag
           mov  byte [bx+23],0_1111_001b         ; end tag, 1 more byte
           mov  byte [bx+24],0                   ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
           
           ; possible resource configuration descriptor block:
           ; end tag
           mov  byte [bx+25],0_1111_001b         ; end tag, 1 more byte
           mov  byte [bx+26],0                   ;  0 = no crc (!0 = zero byte crc from first byte in this block?)
           
           ; compatible device identifiers
           ; end tag
           mov  byte [bx+27],0_1111_001b         ; end tag, 1 more byte
           mov  byte [bx+28],0                   ;  0 = no crc (!0 = zero byte crc from first byte in this block?)

           ; update the location, size, and count
           add  word pnp_next_node,PNP_MSD_NODE_LEN
           
           ; update the list
           mov  al,pnp_node_count
           mov  dx,bx                          ; save location of this node
           mov  bx,pnp_next_idx                ; pointer to last used entry
           mov  [bx+PNP_NODE_LIST_S->next],al  ; mark the current last with next node
           add  bx,sizeof(PNP_NODE_LIST_S)
           mov  [bx+PNP_NODE_LIST_S->handle],al
           mov  byte [bx+PNP_NODE_LIST_S->next],0xFF
           mov  word [bx+PNP_NODE_LIST_S->size],PNP_MSD_NODE_LEN
           mov  [bx+PNP_NODE_LIST_S->location],dx

           ; update to this entry
           mov  pnp_next_idx,bx

           ret
pnp_add_msd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; if a PCI VGA is not found, add a Standard VGA to the list
; on entry:
;  nothing
; on return
;  nothing
; destroys none
pnp_add_vga proc near uses ax bx dx si ds
           ; search the PCI for a VGA device
           mov  ax,0xB103
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00000011_00000000_00000000b
           xor  si,si
           int  1Ah
           jnc  short @f

           mov  bx,BIOS_BASE
           mov  ds,bx

           ; no PCI VGA found, so 'increment' the entry count
           ;  which will 'add' our standard VGA entry to the list
           mov  dx,pnp_next_node
           add  word pnp_next_node,70
           inc  byte pnp_node_count ; increment the count
           mov  al,pnp_node_count

           mov  bx,pnp_next_idx
           mov  [bx+PNP_NODE_LIST_S->next],al  ; mark the current last with next node
           add  bx,sizeof(PNP_NODE_LIST_S)
           mov  [bx+PNP_NODE_LIST_S->handle],al
           mov  byte [bx+PNP_NODE_LIST_S->next],0xFF
           mov  word [bx+PNP_NODE_LIST_S->size],70
           mov  [bx+PNP_NODE_LIST_S->location],dx

           ; update to this entry
           mov  pnp_next_idx,bx

@@:        ret
pnp_add_vga endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; find a node and return its location
; on entry:
;  ds = BIOS_BASE
;  ax = node handle to find (0 = first)
; on return
;  if found:
;    ax = next handle (or 0xFF if no more)
;    cx = length of node
;    si -> node data
;  else:
;    cx = 0
; destroys none
pnp_find_node proc near uses bx
           
           ; point to our list
           mov  bx,offset pnp_node_list
           
           ; if node handle = 0, return the first one.
           or   ax,ax
           jnz  short pnp_find_node_loop

@@:        xor  ah,ah
           mov  al,[bx+PNP_NODE_LIST_S->next]
           mov  cx,[bx+PNP_NODE_LIST_S->size]
           mov  si,[bx+PNP_NODE_LIST_S->location]
           ret

           ; need to scroll through the list to find the handle
pnp_find_node_loop:
           cmp  al,[bx+PNP_NODE_LIST_S->handle]
           je   short @b
           mov  cl,[bx+PNP_NODE_LIST_S->next]
           add  bx,sizeof(PNP_NODE_LIST_S)
           cmp  cl,0xFF
           jb   short pnp_find_node_loop

           ; we didn't find it, so return zero
           xor  cx,cx
           ret
pnp_find_node endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; format of stack on call to this routine
;      arg6      ; 16-bit value, arg6
;      arg5      ; 16-bit value, arg5
;      arg4      ; 16-bit value, arg4
;      arg3      ; 16-bit value, arg3
;      arg2      ; 16-bit value, arg2
;      arg1      ; 16-bit value, arg1
;      func      ; 16-bit value, function
;       CS       ; 16-bit value, CS
;       IP       ; 16-bit value, IP
;      ebp       ; 32-bit our saved ebp
pnp_func  equ [ebp+08]
pnp_arg1  equ [ebp+10]
pnp_arg2  equ [ebp+12]
pnp_arg3  equ [ebp+14]
pnp_arg4  equ [ebp+16]
pnp_arg5  equ [ebp+18]
pnp_arg6  equ [ebp+20]

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; event polling flag area
pnp_event_flag  dd 0x00000000

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 16-bit real mode/protected mode entry point for PNP services
; we set the high order bit in AX to indicate if this was called
;  from real mode or 16-bit protected mode. This way we can use
;  the segment registers accordingly.
; on entry:
;  parameters shown above  
; on return
;  ax =  0 = success
;     = !0 = error
; destroys nothing
pnpbios_prot:
           push ebp
           mov  ebp,esp
           mov  ah,0x80
           jmp  short @f
pnpbios_real:
           push ebp
           movzx ebp,sp
           mov  ah,0x00
@@:        pushf
           push bx
           push cx
           push dx
           push si
           push di
           push ds
           push es

.if (PNP_IS_REALMODE)
           push ds
           mov  bx,BIOS_BASE
           mov  ds,bx
.endif
           ; we check AL only, since the function number will be < 0x0100
           ;  and we have set AH above to either 0x80 or 0x00
           mov  al,pnp_func
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x00: (required) Get number of system device nodes
           cmp  al,0x00
           jne  short @f
           
           ; arg5 = 16-bit selector / 16-bit segment pointing to BIOS_BASE
.if (!PNP_IS_REALMODE)
           mov  ds,pnp_arg5
.endif
           les  di,pnp_arg1      ; segment:offset NumNodes
           
           ; the specs say it is an "unsigned char *"...
           ; However: "Plug and Play BIOS CLARIFICATION Paper" for Plug and Play BIOS Specification, Version 1.0A, October 18, 1994
           ;  The 'Number of Nodes' variable was originally implemented as a WORD, then later it was changed to a CHAR.
           ;  All new BIOSs should be implemented a CHAR according to the specification.  All operating systems and 
           ;  utilities should expect a WORD then clear the upper byte because it is indeterminable.  This will allow
           ;  OS and utility vendors to be backwards compatible with earlier versions of plug and play BIOS.
           movzx ax,byte pnp_node_count
           mov  es:[di],ax

           les  di,pnp_arg3      ; segment:offset NodeSize
           mov  ax,pnp_node_size
           mov  es:[di],ax

           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x01: (required) Get system device node
@@:        cmp  al,0x01
           jne  short @f

           ; arg5 = control flag
           ; we return the same info, whether it is next boot or current info...
           mov  ax,PNP_BAD_PARAMETER
           mov  cx,pnp_arg5
           cmp  cl,0
           jz   pnpbios_fail
           cmp  cl,2
           ja   pnpbios_fail

           ; arg6 = 16-bit selector / 16-bit segment pointing to BIOS_BASE
.if (!PNP_IS_REALMODE)
           mov  ds,pnp_arg6
.endif
           ; get node number
           les  di,pnp_arg1      ; segment:offset Node handle
           movzx ax,byte es:[di] ; get node handle to return

           ; find the node
           call pnp_find_node
           mov  bx,ax            ; save 'next' value in bx

           ; on return:
           ;  cx = 0, did not find it
           ;  cx = size = found it
           ;     = ds:si -> node
           mov  ax,PNP_BAD_PARAMETER
           or   cx,cx
           jz   pnpbios_fail

           ; update the node handle with 'next' value
           mov  es:[di],bl

           les  di,pnp_arg3      ; segment:offset NodeBuffer
           push di
           cld
           rep
             movsb
           pop  di
           
           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x02: (required) Set system device node
@@:        cmp  al,0x02
           jne  short @f

     ;xchg cx,cx
           mov  ax,pnp_arg1   ; node                  ; 0x0000
           mov  bx,pnp_arg2   ; node buffer offset    ; 0x000D
           mov  cx,pnp_arg3   ; node buffer seg       ; 0xF8
           mov  dx,pnp_arg4   ; control               ; 0x0001
           mov  si,pnp_arg5   ; bios selector         ; 0xF0


           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail
           ;jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x03: (required for Dynamic Event Management) Get event
@@:        cmp  al,0x03
           jne  short @f

     ;xchg cx,cx
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail
           ;jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x04: (required for Dynamic Event Management) Send message
@@:        cmp  al,0x04
           jne  short @f
           ; we don't support event polling
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x05: (required for Dynamic Event Management) Get docking station information
@@:        cmp  al,0x05
           jne  short @f
           ; we are not a docking station (and we don't support event polling)
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x06: (required) Reserved
@@:        cmp  al,0x06
           jne  short @f
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x07: (required) Reserved
@@:        cmp  al,0x07
           jne  short @f
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x08: (required) Reserved
@@:        cmp  al,0x08
           jne  short @f
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x09: (optional) Set Statically allocated resource information
@@:        cmp  al,0x09
           jne  short @f
     xchg cx,cx
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail
           ;jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x0A: (optional) Get Statically allocated resource information
@@:        cmp  al,0x0A
           jne  short @f

           ; ***** use t.asm and try this function to see what is returned
     ;xchg cx,cx
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail
           ;jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x0B: (required for power management) Get APM ID table
@@:        cmp  al,0x0B
           jne  short @f

           ; ***** use t.asm and try this function to see what is returned
           ; (dell dimension 8110 returns 0x82)

     xchg cx,cx
           mov  ax,PNP_NOT_SUPPORTED
           jmp  pnpbios_fail
           ;jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x40: (required) Get Plug & Play ISA Configuration Structure
@@:        cmp  ax,0x0040
           jne  short @f

           ; this returns a 6-byte block: (these are the items we return)
           ;            revision:  0x01    (byte)
           ;       count of CSNs:  0x00    (byte)
           ;  isa read data port:  0x0000  (word) (undefined if CSNs = 0)
           ;            reserved:  0x0000  (word)
           les  di,pnp_arg1      ; segment:offset buffer
           mov  byte es:[di+0],0x01
           mov  byte es:[di+1],0x00
           mov  word es:[di+2],0x0000
           mov  word es:[di+4],0x0000
           jmp  pnpbios_success

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; the following is from the ESCD Specification
; it assumes it will be from real mode only, not called from 16-bit protected mode.
; if called from 16-bit protected mode (ah = 0x80), we simply return PNP_UNKNOWN_FUNCTION
;  | we adjust a segment register to get to the ESCD. 16-bit protected mode may have a
;  |  base set only to 0x000E0000 for that segment register.
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x41: (optional) Get extended system configuration data (ESCD) info
@@:        cmp  ax,0x0041
           jne  short @f

           ; the min buffer size in bytes? (far pointer)
           lds  di,pnp_arg1
           mov  word [di],ESCD_DATA_TOT_SIZE
           
           ; the max size of the escd the guest is allowed to write? (far pointer)
           lds  di,pnp_arg3
           mov  word [di],ESCD_DATA_SIZE
           
           ; we are not memmapped, so return NVStorageBase = 0
           lds  di,pnp_arg5
           mov  dword [di],0

           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x42: (optional) Read extended system configuration data (ESCD)
@@:        cmp  ax,0x0042
           jne  short @f

           ; the far pointer to the callers buffer to store the ESCD
           les  di,pnp_arg1
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset escd
           mov  cx,ESCD_DATA_TOT_SIZE
           cld
           rep
             movsb
           
           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x43: (optional) Write extended system configuration data (ESCD)
@@:        cmp  al,0x43
           jne  short @f

           ; the far pointer to the callers buffer to store the ESCD
           xchg cx,cx
           lds  si,pnp_arg1
           mov  ax,BIOS_BASE2
           mov  es,ax
           mov  di,offset escd
           mov  cx,ESCD_DATA_SIZE
           cld
           rep
             movsb
           
           ; mark the ESCD as dirty
           call bios_get_ebda
           mov  ds,ax
           mov  byte es:[EBDA_DATA->escd_dirty],1

           ; now commit the new ESCD
           call far offset bios_commit_escd,BIOS_BASE
           
           jmp  pnpbios_success

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; the following is from the BIOS Boot Specification v1.01, Jan 11, 1996
; it assumes it will be from real mode only, not called from 16-bit protected mode.
; if called from 16-bit protected mode (ah = 0x80), we simply return PNP_UNKNOWN_FUNCTION
;  | we adjust a segment register to get to the EBDA. 16-bit protected mode may have a
;  |  base set only to 0x000E0000 for that segment register.
;  | I thought of calling a function within the EBDA area that will return a value from
;  |  an offset within the EBDA area, but this assumes the CS selector doesn't have a
;  |  base set to 0x000E0000.
;  | I know of no way to get around this issue other than placing the IPL table within
;  |  the 0x000E0000 range. However, this will take up valuable space I am not willing to give up.

           ; we now check the function number in AX instead of just AL as above,
           ;  since AH will be 0x80 if called from 16-bit protected mode

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x60: (Optional: BIOS Boot Specification) get BIOS Boot Specification version supported
@@:        cmp  ax,0x0060
           jne  short @f
           les  di,pnp_arg1      ; segment:offset buffer
           mov  word es:[di],0x0101  ; version 1.01
           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x61: (Optional: BIOS Boot Specification: Required if 0x60 is supported) get IPL count
@@:        cmp  ax,0x0061
           jne  short @f

           ; assume 0 (we don't support BCV devices yet)
           xor  ax,ax
           cmp  word pnp_arg1,0  ; Switch 0 = IPL relative, 1 = BCV relative.
           jne  short pnpbios_func61_0
           ; get the count of entries in the IPL table
           call bios_get_ebda
           mov  es,ax
           mov  ax,es:[EBDA_DATA->ipl_table_count]
pnpbios_func61_0:
           les  di,pnp_arg2      ; segment:offset -- count of ipl entries (word)
           mov  es:[di],ax
           les  di,pnp_arg3      ; segment:offset -- max count (word)
           mov  word es:[di],IPL_TABLE_ENTRY_CNT
           les  di,pnp_arg4      ; segment:offset -- struct size (word)
           mov  word es:[di],16
           jmp  pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x62: (Optional: BIOS Boot Specification: Required if 0x60 is supported) get Priority Table
@@:        cmp  ax,0x0062
           jne  short @f
           
           ; we don't support BCV devices yet
           mov  ax,PNP_NOT_SUPPORTED
           cmp  word pnp_arg1,0  ; Switch 0 = IPL relative, 1 = BCV relative.
           jne  pnpbios_fail

           ; get the count of entries in the IPL table
           call bios_get_ebda
           mov  es,ax
           mov  cx,es:[EBDA_DATA->ipl_table_count]

           ; do priority table
           push cx
           les  di,pnp_arg2      ; segment:offset -- Priority
           xor  al,al
pnpbios_func62_0:
           mov  es:[di],al
           inc  di
           inc  al
           loop pnpbios_func62_0
           pop  cx

           ; do IPL table
           les  di,pnp_arg3      ; segment:offset -- Table
           xor  bx,bx
pnpbios_func62_1:
           call pnpbios_ipl_entry
           add  di,16
           inc  bx
           loop pnpbios_func62_1

           jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x63: (Optional: BIOS Boot Specification: Required if 0x60 is supported) set Priority
@@:        cmp  ax,0x0063
           jne  short @f
           
           ; we currently don't support the changing of the priority,
           ;  so we just return success
           ;mov  ax,pnp_arg1      ; Switch 0 = IPL relative, 1 = BCV relative.
           ;les  di,pnp_arg2      ; segment:offset -- Priority

           jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x64: (Optional: BIOS Boot Specification: Required if 0x60 is supported) get IPL device from last boot
@@:        cmp  ax,0x0064
           jne  short @f
           
           ; we have no way of storing the index to the last boot (when a complete shutdown/restart cycle is given)

           call bios_get_ebda
           mov  es,ax
           mov  ax,es:[EBDA_DATA->ipl_last_index]
           les  di,pnp_arg1      ; segment:offset -- IPL entry index (word)
           mov  es:[di],ax

           jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x65: (Optional: BIOS Boot Specification: Optional if 0x60 is supported) get Boot First IPL device
@@:        cmp  ax,0x0065
           jne  short @f
           
           call bios_get_ebda
           mov  es,ax
           mov  ax,es:[EBDA_DATA->ipl_bootfirst]
           les  di,pnp_arg1      ; segment:offset -- IPL entry index (word)
           mov  es:[di],ax

           jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; function 0x66: (Optional: BIOS Boot Specification: Optional if 0x60 is supported) set Boot First IPL device
@@:        cmp  ax,0x0066
           jne  short @f
           
           les  di,pnp_arg1      ; segment:offset -- IPL entry index (word)
           mov  bx,es:[di]
           
           call bios_get_ebda
           mov  es,ax
           mov  es:[EBDA_DATA->ipl_bootfirst],bx

           jmp  short pnpbios_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; else, unknown function
@@:        mov  ax,PNP_UNKNOWN_FUNCTION
           jmp  short pnpbios_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; was a successful function so return success
pnpbios_success:
           mov  ax,PNP_SUCCESS
pnpbios_fail:
.if (PNP_IS_REALMODE)
           pop  ds
.endif
           pop  es
           pop  ds
           pop  di
           pop  si
           pop  dx
           pop  cx
           pop  bx
           popf
           pop  ebp
           retf

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; build a BIOS Boot Specification IPL entry
; on entry:
;  bx = entry index
;  es:di -> where to build it
; on return
;  nothing
; destroys none
pnpbios_ipl_entry proc near uses ax bx cx dx ds
           call bios_get_ebda
           mov  ds,ax
           
           cmp  bx,[EBDA_DATA->ipl_table_count]
           jae  short @f
           
           mov  dx,bx            ; save the index in dx
           
           imul bx,sizeof(IPL_ENTRY)
           add  bx,EBDA_DATA->ipl_table_entries

           movzx ax,byte [bx+IPL_ENTRY->type]
           mov  es:[di+0],ax
           
           or   dx,((2<<10) | (1<<8))  ; media present and bootable (bits 3:0 from above)
           mov  es:[di+2],dx
           
           mov  word es:[di+4],offset int19_handler
           mov  word es:[di+6],BIOS_BASE
           
           lea  ax,[bx+IPL_ENTRY->description]
           mov  es:[di+8],ax
           mov  es:[di+10],ds
           
           mov  dword es:[di+12],0
           
@@:        ret
pnpbios_ipl_entry endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; scan an optional rom
; on entry:
;  ax = ending segment
;  cx = starting segment
;  ds = 0xE000
;  es = 0x0000
; on return
;  nothing
; destroys all general
pnp_scan_rom proc near uses di ds es

pnp_scan_rom_loop:
           push ax               ; save ending segment value
           mov  ax,4             ; default to 2k blocks

           ; is the word at cx:[0] = 0xAA55?
           mov  es,cx
           cmp  word es:[0x0000],0xAA55
           jne  pnp_scan_increment

           ; it is, so check the crc
           call pnp_scan_rom_crc
           jnz  pnp_scan_increment
           
           ; get the optional rom length
           mov  al,es:[0x0002]   ; al = 512-byte blocks
           test al,0x03          ; is it a mutiple of 2048
           jz   short @f         ;
           and  al,0xFC          ; if not, make it so for the next one
           add  al,0x04          ;

@@:        xor  bx,bx            ; ds = 0x0000
           mov  ds,bx            ;
           push ax               ; save the 'pointer' to the next one
           
           push cx               ; entry point is at cx:[0x0003]
           push 0x0003           ;
           
           ; Point ES:DI at "$PnP", which tells the ROM that we are a PnP BIOS
           ; That should stop it grabbing INT 19h; we will use its BEV instead
           mov  ax,BIOS_BASE2  ; es:id -> PnP structure
           mov  es,ax          ;
           mov  bx,0xFFFF      ; CSN (Card Select Number) or 0xFFFF if this device is not PnP
           mov  dx,0xFFFF      ; dx = PnP Data Port address (or 0xFFFF if there is no PnP available)
           mov  ax,0x08        ; for PCI, ah = bus, al = dev/func of the device we found the Optional ROM on (QEMU has the vga at pci = 0x08)
           mov  di,offset pnpbios_structure
           mov  bp,sp   ; Call ROM init routine using seg:off on stack
           call far [bp+0]
           cli           ; In case expansion ROM BIOS turns IF on
           add  sp,2     ; Pop offset value
           pop  cx       ; Pop seg value (restore CX)
           
           ; Look at the ROM's PnP Expansion header.  Properly, we're supposed
           ; to init all the ROMs and then go back and build an IPL table of
           ; all the bootable devices, but we can get away with one pass.
           mov  ds,cx              ; ROM base
           mov  bx,[0x001A]        ; 0x1A is the offset into ROM header that contains the offset of the
           cmp  dword [bx],"$PnP"  ;  PnP expansion header, where we look for signature "$PnP"
           jne  short short no_bev ;  (dbl quotes used to keep as '$PnP'. Single would little-endian it. i.e.: = 'PnP$')
           
           ; PnP Expansion header, offset 0x16, is the offset of Boot Connection Vector
           mov  ax,[bx+0x16]
           or   ax,ax              ; if 0x0000, there is no BCV present
           jz   short no_bcv
           
           ; Option ROM has BCV, run it now
           push cx       ; Push seg
           push ax       ; Push offset
           
           ; Point ES:DI at "$PnP", which tells the ROM that we are a PnP BIOS.
           mov  bx,BIOS_BASE2
           mov  es,bx
           mov  di,offset pnpbios_structure
           ; jump to BCV function entry pointer
           mov  bp,sp   ; Call ROM BCV routine using seg:off on stack
           call far [bp+0]
           cli           ; In case expansion ROM BIOS turns IF on
           add  sp,2     ; Pop offset value
           pop  cx       ; Pop seg value (restore CX)
           jmp  short no_bev

no_bcv:    mov  ax,[bx+0x1A]     ; 0x1A is also the offset into the expansion header of
           or   ax,ax            ;  the Bootstrap Entry Vector, or zero if there is none.
           jz   short no_bev
           
           ; Found a device that thinks it can boot the system.  Record its BEV and product name string.
           push es
           push ecx
           mov  es,cx                   ; ecx = seg:off of vector
           shl  ecx,16                  ;
           mov  cx,ax                   ;
           xor  eax,eax                 ; base lba
           mov  si,[bx+0x10]            ; Pointer to the product name string or zero if none
           mov  edx,((IPL_FLAGS_NSATA << 16) | (IPL_TYPE_BEV << 8) | (0 << 0))
           call add_boot_vector
           pop  ecx
           pop  es

no_bev:    pop  ax       ; Restore AX
pnp_scan_increment:
           shl  ax,5     ; convert 512-bytes blocks to 16-byte increments
                         ; because the segment selector is shifted left 4 bits.
           add  cx,ax
           pop  ax               ; restore ending segment value
           cmp  cx,ax
           jbe  pnp_scan_rom_loop
           
           ret
pnp_scan_rom endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; calulate the crc of a pnp rom
; on entry:
;  cx = segment of block to check
; on return
;  nothing
; destroys nothing
pnp_scan_rom_crc proc near uses all ds
           mov  ds,cx

           xor  ax,ax
           xor  bx,bx
           xor  cx,cx
           xor  dx,dx
           
           ; length is in byte ds:[0x0002] in 512 byte chunks
           mov  ch,[0x0002]
           shl  cx,1
           jnc  short @f
           jz   short @f
           xchg dx,cx
           dec  cx
@@:        add  al,[bx]
           inc  bx
           loop @b
           
           test dx,dx
           jz   short @f
           
           add  al,[bx]
           mov  cx,dx
           mov  dx,ds
           add  dh,0x10
           mov  ds,dx
           xor  dx,dx
           xor  bx,bx
           jmp  short @b

@@:        and  al,0xFF   ; or al,al
           ret
pnp_scan_rom_crc endp

.end
