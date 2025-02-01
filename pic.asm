comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: pic.asm                                                            *
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
*   pic include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
* Master PIC    (08 hex)                                                   *
*   IRQ 0 – (int 08) system timer (cannot be changed)                      *
*   IRQ 1 – (int 09) keyboard on PS/2 port (cannot be changed)             *
*   IRQ 2 –          cascaded signals from IRQs 8–15                       *
*   IRQ 3 – (int 0B) serial port 2 (shared with serial port 4, if present) *
*   IRQ 4 – (int 0C) serial port 1 (shared with serial port 3, if present) *
*   IRQ 5 – (int 0D) parallel port 3 or sound card                         *
*   IRQ 6 – (int 0E) floppy disk controller                                *
*   IRQ 7 – (int 0F) parallel port 1 (shared with port 2, if present)      *
*                                                                          *
* Slave PIC     (70 hex)                                                   *
*   IRQ 8 – (int 70) real-time clock (RTC)                                 *
*   IRQ 9 – (int 71) ACPI or device configured to use IRQ 2 will use IRQ 9 *
*   IRQ 10 – (int 72)                                                      *
*   IRQ 11 – (int 73)                                                      *
*   IRQ 12 – (int 74) mouse on PS/2 port                                   *
*   IRQ 13 – (int 75) CPU co-processor                                     *
*   IRQ 14 – (int 76) primary ATA channel                                  *
*   IRQ 15 – (int 77) secondary ATA channel                                *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the PIC/APIC
; we assume no APIC at this time. Later (smp_probe)
;  detects the APIC and if found, initializes it and
;  disables this.
; on entry:
;  nothing
; on return
;  nothing
; destroys none
init_pic   proc near uses ax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; send initialization commands
           
           ; ICW1
           mov  al,0x11          ; initialize through ICW4
           out  PORT_PIC_MASTER_CMD,al
           out  PORT_PIC_SLAVE_CMD,al

           ; ICW2
           mov  al,0x08          ; irq 0 -> 7 to start at IDT 0x08
           out  PORT_PIC_MASTER_DATA,al
           mov  al,0x70          ; irq 8 -> 15 to start at IDT 0x70
           out  PORT_PIC_SLAVE_DATA,al

           ; ICW3
           mov  al,0x04          ; connect the master to the slave
           out  PORT_PIC_MASTER_DATA,al
           mov  al,0x02
           out  PORT_PIC_SLAVE_DATA,al

           ; ICW4
           mov  al,0x01          ; 80x86/88 mode
           out  PORT_PIC_MASTER_DATA,al
           out  PORT_PIC_SLAVE_DATA,al

           ; set the masks
           mov  al,0xB8
           out  PORT_PIC_MASTER_DATA,al ; master pic: unmask IRQ 0, 1, 2, 6
           mov  al,0x8F
           out  PORT_PIC_SLAVE_DATA,al ; slave  pic: unmask IRQ 12, 13, 14
           
           ; clear any that just fired
           call eoi_both_pic

           ret
init_pic   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; acknowledge master pic ioe
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
eoi_master_pic proc near uses ax
           mov  al,0x20
           out  PORT_PIC_MASTER_CMD,al
           ret
eoi_master_pic endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; acknowledge slave pic ioe
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
;  acknowledges the master too
eoi_slave_pic proc near uses ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           ret
eoi_slave_pic endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; acknowledge both the master and the slave pic ioe
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
;  acknowledges the master too
eoi_both_pic proc near uses ax
           mov  al,0x20
           out  PORT_PIC_SLAVE_CMD,al
           out  PORT_PIC_MASTER_CMD,al
           ret
eoi_both_pic endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get interrupt vector number
; on entry:
;  al = irq
; on return
;  al = intterupt vector number
; destroys nothing
; ax = irq 0->7 = int 08h -> 0Fh
; ax = irq 8->F = int 70h -> 77h
pic_get_int_vector proc near
           cmp  al,7
           ja   short @f
           
           ; al = 0 -> 7
           ; simply add 8
           add  al,8
           ret

@@:        ; al = 8 -> F
           ; add 0x70 - 8
           add  al,(0x70 - 8)
           ret
pic_get_int_vector endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; mask an irq
; on entry:
;  al = irq
; on return
;  nothing
; destroys nothing
pic_mask   proc near uses ax cx
           ; get mask bit
           mov  cl,al
           and  cl,7
           mov  ah,1
           shl  ah,cl

           cmp  al,7
           ja   short @f
           
           ; mask the irq
           in   al,PORT_PIC_MASTER_DATA
           or   al,ah
           out  PORT_PIC_MASTER_DATA,al
           ret

@@:        ; mask the irq
           in   al,PORT_PIC_SLAVE_DATA
           or   al,ah
           out  PORT_PIC_SLAVE_DATA,al

           ret
pic_mask   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; unmask an irq
; on entry:
;  al = irq
; on return
;  nothing
; destroys nothing
pic_unmask proc near uses ax cx
           ; get mask bit
           mov  cl,al
           and  cl,7
           mov  ah,1
           shl  ah,cl
           not  ah

           cmp  al,7
           ja   short @f
           
           ; unmask the irq
           in   al,PORT_PIC_MASTER_DATA
           and  al,ah
           out  PORT_PIC_MASTER_DATA,al
           ret

@@:        ; unmask the irq
           in   al,PORT_PIC_SLAVE_DATA
           and  al,ah
           out  PORT_PIC_SLAVE_DATA,al

           ; make sure bit 2 (chain bit) is unmasked as well
           in   al,PORT_PIC_MASTER_DATA
           and  al,(~(1<<2))
           out  PORT_PIC_MASTER_DATA,al

           ret
pic_unmask endp

.end
