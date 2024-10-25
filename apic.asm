comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: apic.asm                                                           *
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
*   apic include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.08                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 25 Oct 2024                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
*                                                                          *
***************************************************************************|


comment ^

todo: If we don't specify to QEMU to not use the APIC, it won't
      fire an interrupt via this 8259.

Since we support an APIC via this BIOS, we need to use it instead.

IA32_APIC_BASE  equ  0x1B
           ; eax,0
           ; cpuid
           ; if eax > 0
           ; cpuid
           ; edx: bit 9, = apic present
           ; edx: bit 5, = msr register is present

           ; clear bits 11:10 to disable the APIC
           mov  ecx,IA32_APIC_BASE
           rdmsr
           ;and  eax,0xFFFF0000
           ; io apic is at 0xFEC00000


           ; do we have an APIC installed?
           test dword [EBDA_DATA->cpuid_features],CPUID_APIC
           jz   short smp_probe_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; call the APIC code first. If found, we return
           ;  and disable the 8259.
           ; else, we enable and use the 8259.
           call init_apic
           jc   short @f

           ; the apic was found and initialized. Mask all 
           ;  interrupts on the 8259 and return
           mov  al,0xFF
           out  PORT_PIC_MASTER_DATA,al
           out  PORT_PIC_SLAVE_DATA,al
           ret

           ; todo: we already enabled it before
           ; make sure the apic is enabled
           ;mov  esi,APIC_BASE_ADDR
           ;or   dword fs:[esi+APIC_SVR],APIC_ENABLED

^

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the APIC
; on entry:
;  ds -> EBDA
; on return
;  carry set if no apic found
; destroys none
init_apic  proc near uses eax ecx esi
           
           mov  esi,APIC_BASE_ADDR
           mov  eax,fs:[esi+APIC_REG_VER]
           mov  ecx,eax
           and  al,0xFF
           cmp  al,0x14
           jne  init_apic_error
           mov  [EBDA_DATA->apic_version],al
           
           and  ecx,0x00FF0000
           shr  ecx,16
           mov  [EBDA_DATA->apic_lvt_entries],cl

           mov  eax,fs:[esi+APIC_REG_ID]
           shr  eax,24
           mov  [EBDA_DATA->apic_id],al

           push ds
           push si
           xor  ah,ah
           mov  al,[EBDA_DATA->apic_lvt_entries]
           push ax
           mov  al,[EBDA_DATA->apic_version]
           push ax
           mov  al,[EBDA_DATA->apic_id]
           push ax
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  si,offset apic_found_str
           call bios_printf
           add  sp,6
           pop  si
           pop  ds

           ; local destination register
           xor  eax,eax
           mov  fs:[esi+APIC_REG_LDR],eax
           
           ; destination format register
           mov  eax,0xFFFFFFFF
           mov  fs:[esi+APIC_REG_DFR],eax

           ; task priority register
           xor  eax,eax
           mov  fs:[esi+APIC_REG_TRP],eax
           
           ; timer interrupt vector
           mov  eax,(1 << 16)
           mov  fs:[esi+APIC_REG_TIMER],eax
           
           ; performance counter interrupt
          ;mov  eax,(1 << 16)
           mov  fs:[esi+APIC_REG_PERFORM],eax
           
           ; local interrupt 0, 1
          ;mov  eax,(1 << 16)
           mov  fs:[esi+APIC_REG_LINT0],eax
           mov  fs:[esi+APIC_REG_LINT1],eax
           
           ; error interrupt
          ;mov  eax,(1 << 16)
           mov  fs:[esi+APIC_REG_LERROR],eax

           ; thermal sensor (if present)
           cmp  byte [EBDA_DATA->apic_lvt_entries],6
           jb   short @f
           mov  eax,((0 << 16) | (0 << 8))
           mov  fs:[esi+APIC_REG_THERM],eax

           ; now enable the APIC, and give it a Spourios interrupt vector
@@:        mov  ax,0x7F                ; interrtupt 7Fh
           mov  bx,offset int7F_handler
           mov  cx,0xE000
           call set_int_vector
           
           mov  eax,fs:[esi+APIC_REG_SIV]
           or   eax,(1<<8)
           mov  al,0x7F          ; must have bits 3:0 = 00001111b
           mov  fs:[esi+APIC_REG_SIV],eax

           ; we found an apic
           clc
           ret
           
           ; either we didn't find an apic, or it
           ;  didn't initialize correctly
init_apic_error:           
           stc                   ; no apic found
           ret
init_apic  endp


IOAPIC_HANDLER_LEN  equ 10

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IO APIC's handlers.
; These simply jmp to the 'normal' IVT
; These should all be only IOAPIC_HANDLER_LEN bytes each
int50_handler:
           pushf
           call far offset int08_handler,BIOS_BASE
           call apic_eoi
           iret           
int51_handler:
           pushf
           call far offset int09_handler,BIOS_BASE
           call apic_eoi
           iret           
int52_handler:
           pushf
           call far offset int08_handler,BIOS_BASE  ; we overide IRQ 2 to IRQ 0
           call apic_eoi
           iret           
int53_handler:
           pushf
           call far offset int0B_handler,BIOS_BASE
           call apic_eoi
           iret           
int54_handler:
           pushf
           call far offset int0C_handler,BIOS_BASE
           call apic_eoi
           iret           
int55_handler:
           pushf
           call far offset int0D_handler,BIOS_BASE
           call apic_eoi
           iret           
int56_handler:
           pushf
           call far offset int0E_handler,BIOS_BASE
           call apic_eoi
           iret           
int57_handler:
           pushf
           call far offset int0F_handler_0,BIOS_BASE
           call apic_eoi
           iret           
int58_handler:
           pushf
           call far offset int70_handler,BIOS_BASE
           call apic_eoi
           iret           
int59_handler:
           pushf
           call far offset int71_handler,BIOS_BASE
           call apic_eoi
           iret           
int5A_handler:
           pushf
           call far offset int72_handler,BIOS_BASE
           call apic_eoi
           iret           
int5B_handler:
           pushf
           call far offset int73_handler,BIOS_BASE
           call apic_eoi
           iret           
int5C_handler:
           pushf
           call far offset int74_handler,BIOS_BASE
           call apic_eoi
           iret           
int5D_handler:
           pushf
           call far offset int75_handler,BIOS_BASE
           call apic_eoi
           iret           
int5E_handler:
           pushf
           call far offset int76_handler,BIOS_BASE
           call apic_eoi
           iret           
int5F_handler:
           pushf
           call far offset int77_handler_0,BIOS_BASE
           call apic_eoi
           iret           

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; APIC Spourious interrupt vector
; simply returns, no IOE needed
; on entry:
;  nothing
; on return
;  nothing
; destroys none
int7F_handler:
           iret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; APIC EOI
; on entry:
;  nothing
; on return
;  nothing
; destroys none
apic_eoi   proc near uses esi
           mov  esi,APIC_BASE_ADDR
           mov  dword fs:[esi+APIC_REG_EOI],0
           ret
apic_eoi   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the IOAPIC
; on entry:
;  ds -> EBDA
; on return
;  carry set if no ioapic found
; destroys none
init_ioapic proc near uses eax ebx ecx esi
           
           mov  esi,IOAPIC_BASE_ADDR
           mov  al,0           ; id
           shl  eax,24
           mov  ebx,IOAPIC_REG_ID
           call ioapic_write
           call ioapic_read
           shr  eax,24
           mov  [EBDA_DATA->ioapic_id],al

           mov  ebx,IOAPIC_REG_VER
           call ioapic_read
           mov  [EBDA_DATA->ioapic_ver],al
           shr  eax,16
           inc  ax
           mov  [EBDA_DATA->ioapic_entries],al

           ; count of entries must be at least 16
           cmp  al,16
           jb   short init_ioapic_error

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; update the BDA's interrupt vector table
           ;  vectors 0x50 -> 0x5F
           mov  ax,0x50
           mov  bx,offset int50_handler
           mov  cx,16
@@:        push cx
           mov  cx,BIOS_BASE
           call set_int_vector
           pop  cx
           add  bx,IOAPIC_HANDLER_LEN
           inc  ax
           loop @b

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           mov  ecx,((~((1<<14) | (1<<13) | (1<<12) | (1<<6) | (1<<2) | (1<<1))) << 16) ; 1000111110111001_0000000000000000b  ; bit = 1 = masked, 0 = unmasked
           mov  ebx,IOAPIC_REG_REDIR ; start at 0x10
           mov  eax,0x50           ; start at 0x50
@@:        push ecx
           push eax
          ;or   eax,((0 << 8)  | \ ; delivery mode: fixed
          ;          (0 << 11) | \ ; destination mode: phys
          ;          (0 << 13) | \ ; active: high
          ;          (0 << 15));   ; trigger: edge
           and  ecx,(1 << 16)      ; get mask/unmask bit
           or   eax,ecx
           call ioapic_write
           inc  ebx
           movzx byte eax,[EBDA_DATA->ioapic_id]
           shl  eax,(56-32)      ; id in bits 31:24 of high dword
           call ioapic_write
           inc  ebx
           pop  eax
           pop  ecx
           shr  ecx,1
           
           ; increment to next
           inc  eax
           cmp  eax,0x60
           jb   short @b

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the apic was found and initialized. Mask all 
           ;  interrupts on the 8259
           mov  al,0xFF
           out  PORT_PIC_MASTER_DATA,al
           out  PORT_PIC_SLAVE_DATA,al

           clc
           ret

init_ioapic_error:
           stc
           ret
init_ioapic endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 'disable' the IO APIC and restore the 8259
; on entry:
;  es -> EBDA
; on return
;  nothing
; destroys none
ioapic_disable proc near uses eax ebx esi
           
           ; do we have an APIC installed?
           test dword es:[EBDA_DATA->cpuid_features],CPUID_APIC
           jz   short ioapic_disable_done

           ; we need to change all IO APIC interrupts to ExtINT (111b)
           ; so the 8259 will handle them.
           mov  esi,IOAPIC_BASE_ADDR
           mov  ebx,IOAPIC_REG_REDIR ; start at 0x10
           mov  eax,0x50           ; start at 0x50
@@:        push eax
           or   eax,((111b << 8)  | \ ; delivery mode: ExtINT (8259a)
                        (0 << 11) | \ ; destination mode: phys
                        (0 << 13) | \ ; active: high
                        (0 << 15) | \ ; trigger: edge
                        (0 << 16));   ; unmasked (let the 8259a handle it)
           call ioapic_write
           inc  ebx
           movzx byte eax,[EBDA_DATA->ioapic_id]
           shl  eax,(56-32)      ; id in bits 31:24 of high dword
           call ioapic_write
           inc  ebx
           pop  eax
           inc  eax
           cmp  eax,0x60
           jb   short @b

ioapic_disable_done:
           ; initialize the 8259 PIC
           call init_pic
           ret
ioapic_disable endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a register of the IOAPIC
; on entry:
;  ds -> EBDA
;  esi = IOAPIC base
;  ebx = address
; on return
;  eax = value read
; destroys none
ioapic_read proc near
           mov  fs:[esi+APIC_REG_SEL],ebx
           mov  eax,fs:[esi+APIC_REG_DATA]
           ret
ioapic_read endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a register of the IOAPIC
; on entry:
;  ds -> EBDA
;  esi = IOAPIC base
;  ebx = address
;  eax = value to write
; on return
;  nothing
; destroys none
ioapic_write proc near
           mov  fs:[esi+APIC_REG_SEL],ebx
           mov  fs:[esi+APIC_REG_DATA],eax
           ret
ioapic_write endp


.end
