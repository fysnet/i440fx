comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: cpu.asm                                                            *
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
*   cpu include file                                                       *
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
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

cpu_not_supported_str  db "A 80x586 CPU w/MSR's and CPUID is required...",13,10,0

CPUID_MSR    equ  (1 << 5)
CPUID_APIC   equ  (1 << 9)
CPUID_MTRR   equ  (1 << 12)

CPUID_EXT_VMX      equ  (1 << 5)
MSR_FEATURE_CTRL   equ  0x03A
FEATURE_CTRL_LOCK  equ  0x1
FEATURE_CTRL_VMX   equ  0x4

SMP_MSR_ADDR      equ  0x0510

MSR_MTRRcap            equ   0x000000FE
MSR_MTRRfix64K_00000   equ   0x00000250
MSR_MTRRfix16K_80000   equ   0x00000258
MSR_MTRRfix16K_A0000   equ   0x00000259
MSR_MTRRfix4K_C0000    equ   0x00000268
MSR_MTRRfix4K_C8000    equ   0x00000269
MSR_MTRRfix4K_D0000    equ   0x0000026A
MSR_MTRRfix4K_D8000    equ   0x0000026B
MSR_MTRRfix4K_E0000    equ   0x0000026C
MSR_MTRRfix4K_E8000    equ   0x0000026D
MSR_MTRRfix4K_F0000    equ   0x0000026E
MSR_MTRRfix4K_F8000    equ   0x0000026F
MSR_MTRRdefType        equ   0x000002FF

; MTRRphysBase_MSR(reg) (0x200 + 2 * (reg))
; MTRRphysMask_MSR(reg) (0x200 + 2 * (reg) + 1)

MTRR_MEMTYPE_UC    equ  0
MTRR_MEMTYPE_WC    equ  1
MTRR_MEMTYPE_WT    equ  4
MTRR_MEMTYPE_WP    equ  5
MTRR_MEMTYPE_WB    equ  6

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect the cpu
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
cpu_probe  proc near uses alld ds
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; up to this point, we have only used 80x386 instructions
           ; we need to make sure we have a 80x486+ with CPUID, RDMSR/WRMSR, and WBINVD
           ; check to see if the cpuid instruction is supported
           ; if bit 21 can be toggled, this cpu supports the cpuid instruction
           pushfd                ; save initial flag state
           pushfd
           pop  eax
           or   eax,(1<<21)
           push eax
           popfd
           pushfd
           pop  ebx
           mov  eax,ebx
           and  eax,(~(1<<21))
           push eax
           popfd
           pushfd
           pop  eax
           popfd                 ; restore initial flag state
           xor  eax,ebx
           test eax,(1<<21)
           jz   short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the CPUID instruction is supported
           xor  ebx,ebx
           xor  ecx,ecx
           mov  eax,1            ; get version information
           cpuid
           mov  [EBDA_DATA->cpuid_signature],eax
           mov  [EBDA_DATA->cpuid_features],edx
           mov  [EBDA_DATA->cpuid_ext_features],ecx

           ; so see if the MSR instructions (rdmsr/wrmsr) are supported
           ; (if bit 5 in the edx register is zero, they are not supported)
           test edx,(1<<5)
           jz   short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have a 486+ with at least RDMSR/WRMSR, RSM, WBINVD instructions
           ret

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the CPUID instruction is *not* supported
@@:        ; print a string (won't show on screen, but will in log files)
           push cs
           pop  ds
     xchg cx,cx ; ben ;;;;;;;;;;;;;;;;;;;;;;;;;;
           mov  si,offset cpu_not_supported_str
           call bios_printf
           ; shall we beep a few times????
           call freeze
           .noret
cpu_probe  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a MSR (and update the struct at SMP_MSR_ADDR?)
; on entry:
;  ecx = MSR index
;  edx:eax = value to write
; on return
;  nothing
; destroys none
wrmsr_smp  proc  near uses edi
           
           wrmsr

           ; I don't know what this is for....
           mov   edi,fs:[SMP_MSR_ADDR]
           mov   fs:[edi+0],ecx
           mov   fs:[edi+4],eax
           mov   fs:[edi+8],edx
           mov   dword fs:[edi+12],0

           ret
wrmsr_smp  endp

.ifdef BX_QEMU

QEMU_CFG_CTL_PORT     equ  0x0510
QEMU_CFG_DATA_PORT    equ  0x0511
QEMU_CFG_SIGNATURE    equ  0x00
QEMU_CFG_ID           equ  0x01
QEMU_CFG_UUID         equ  0x02

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; select QEMU config register
; on entry:
;  ds -> EBDA
;  ax = register
; on return
;  nothing
; destroys none
qemu_cfg_select proc near uses dx
           mov  dx,QEMU_CFG_CTL_PORT
           out  dx,ax
           ret
qemu_cfg_select endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 
; on entry:
;  ds -> EBDA
; on return
;  al = 1 = found configure port, 0 = not found
; destroys none
qemu_cfg_port_probe proc near uses dx
           mov  ax,QEMU_CFG_SIGNATURE
           call qemu_cfg_select

           mov  dx,QEMU_CFG_DATA_PORT
           in   al,dx
           shl  eax,8
           in   al,dx
           shl  eax,8
           in   al,dx
           shl  eax,8
           in   al,dx
           cmp  eax,'QEMU'
           mov  al,1
           je   short @f
           xor  al,al
@@:        ret
qemu_cfg_port_probe endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 
; on entry:
;  ds -> EBDA
;  ds:ax -> buffer to read config to
;  cx = size of buffer
; on return
;  nothing
; destroys none
qemu_cfg_read proc near uses bx dx
           jcxz short qemu_cfg_read_done

           mov  bx,ax
           mov  dx,QEMU_CFG_DATA_PORT
@@:        in   al,dx
           mov  [bx],al
           inc  bx
           loop @b

qemu_cfg_read_done:
           ret
qemu_cfg_read endp

.endif

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; setup the uuid
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
uuid_probe proc near
.ifdef BX_QEMU
           cmp  word [EBDA_DATA->qemu_cfg_port],0
           je   short @f
           push ax
           push cx
           mov  ax,QEMU_CFG_UUID
           call qemu_cfg_select
           mov  ax,EBDA_DATA->bios_uuid
           mov  cx,16
           call qemu_cfg_read
           pop  cx
           pop  ax
@@:        ret

.else
           mov  dword [EBDA_DATA->bios_uuid+ 0],0
           mov  dword [EBDA_DATA->bios_uuid+ 4],0
           mov  dword [EBDA_DATA->bios_uuid+ 8],0
           mov  dword [EBDA_DATA->bios_uuid+12],0
           ret
.endif
uuid_probe endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; setup the mtrr
; on entry:
;  ds -> EBDA
;  (assumes cpu_probe already called)
; on return
;  nothing
; destroys none
;  https://wiki.osdev.org/MTRR
setup_mtrr proc near
           
           mov  dword fs:[SMP_MSR_ADDR],0

           test dword [EBDA_DATA->cpuid_features],(CPUID_MTRR | CPUID_MSR)
           jz   setup_mtrr_done

           mov  ecx,MSR_MTRRcap
           rdmsr
           or   al,al            ; vcnt = count of variable size MTRR supported
           jz   setup_mtrr_done
           test ah,1             ; fix = all fixed-size MTRR are available
           jz   setup_mtrr_done

           ; memory from 0x00000 -> 0x7FFFF
           mov  edx,((MTRR_MEMTYPE_WB << 24) | (MTRR_MEMTYPE_WB << 16) | (MTRR_MEMTYPE_WB << 8) | MTRR_MEMTYPE_WB)
           mov  eax,edx
           mov  ecx,MSR_MTRRfix64K_00000
           call wrmsr_smp

           ; memory from 0x80000 -> 0x9FFFF
           mov  ecx,MSR_MTRRfix16K_80000
           call wrmsr_smp

           ; memory from 0xA0000 -> 0xBFFFF
           mov  edx,((MTRR_MEMTYPE_UC << 24) | (MTRR_MEMTYPE_UC << 16) | (MTRR_MEMTYPE_UC << 8) | MTRR_MEMTYPE_UC)
           mov  eax,edx
           mov  ecx,MSR_MTRRfix16K_A0000
           call wrmsr_smp

           ; memory from 0xC0000 -> 0xC7FFF
           mov  ecx,MSR_MTRRfix4K_C0000
           call wrmsr_smp

           ; memory from 0xC8000 -> 0xCFFFF
           mov  ecx,MSR_MTRRfix4K_C8000
           call wrmsr_smp

           ; memory from 0xD0000 -> 0xD7FFF
           mov  ecx,MSR_MTRRfix4K_D0000
           call wrmsr_smp

           ; memory from 0xD8000 -> 0xDFFFF
           mov  ecx,MSR_MTRRfix4K_D8000
           call wrmsr_smp

           ; memory from 0xE0000 -> 0xE7FFF
           mov  ecx,MSR_MTRRfix4K_E0000
           call wrmsr_smp

           ; memory from 0xE8000 -> 0xEFFFF
           mov  ecx,MSR_MTRRfix4K_E8000
           call wrmsr_smp

           ; memory from 0xF0000 -> 0xF7FFF
           mov  ecx,MSR_MTRRfix4K_F0000
           call wrmsr_smp

           ; memory from 0xF8000 -> 0xFFFFF
           mov  ecx,MSR_MTRRfix4K_F8000
           call wrmsr_smp
           
           ; Mark 3-4GB as UC, anything not specified defaults to WB
           mov  ecx,0x200
           xor  edx,edx
           mov  eax,(0xc0000000 | MTRR_MEMTYPE_UC)
           call wrmsr_smp
           
           ; get the number of physical address bits
           mov  eax,0x80000000
           cpuid
           mov  cl,32
           cmp  eax,0x80000008
           jb   short @f
           push ecx
           mov  eax,0x80000008
           cpuid
           pop  ecx
           mov  cl,al            ; lower 8 bits of eax = number of address bits
@@:        mov  eax,1
           xor  edx,edx
           ; we can't shift by 32, so we do two shifts of 16 each
           shr  cl,1
           push cx
           adc  cl,0             ; catch the odd bit (rare that it would be there though)
           shld edx,eax,cl
           shl  eax,cl
           pop  cx
           shld edx,eax,cl
           shl  eax,cl
           sub  edx,1
           sub  eax,1

           ; Make sure no reserved bit set to '1 in MTRRphysMask_MSR
           mov  ecx,edx
           mov  ebx,eax
           mov  edx,0xFFFFFFFF
           mov  eax,0xC0000000
           and  edx,ecx
           and  eax,ebx
           or   eax,0x800
           mov  ecx,0x201
           call wrmsr_smp
           
           mov  ecx,MSR_MTRRdefType
           xor  edx,edx
           mov  eax,(0x00000C00 | MTRR_MEMTYPE_WB)
           call wrmsr_smp

setup_mtrr_done:
           ret
setup_mtrr endp

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; this is the code to 'send' to each CPU via the APIC
smp_ap_boot_code_start:
           cli
           xor  ax,ax
           mov  ds,ax
           
           mov  ebx,SMP_MSR_ADDR
@@:        mov  ecx,[ebx]
           test ecx,ecx
           jz   short @f
           mov  eax,[ebx+4]
           mov  edx,[ebx+8]
           wrmsr
           add  ebx,12
           jmp  short @b
@@:        mov  eax,1
           cpuid
           and  ecx,CPUID_EXT_VMX
           jz   short @f
           mov  ecx,MSR_FEATURE_CTRL
           rdmsr
           or   eax,(FEATURE_CTRL_LOCK | FEATURE_CTRL_VMX)
           wrmsr
@@:        mov  ax,EBDA_SEG
           mov  ds,ax
           lock
             inc  word [EBDA_DATA->smp_cpus]
@@:        hlt
           jmp  short @b

; make sure we don't overrun the EBDA
.if (($ - smp_ap_boot_code_start) > AP_BOOT_ADDR_SZ)
%ERROR 1 'smp_ap_boot_code_start_sz is more than AP_BOOT_ADDR_SZ'
%PRINT ($ - smp_ap_boot_code_start)
.endif

smp_ap_boot_code_start_sz  dw  ($ - smp_ap_boot_code_start)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; code to relocate SMBASE to 0xa0000
smm_relocation_start:
           mov  ebx,(0x38000 + 0x7EFC)
           mov  al,[ebx]         ; revision ID to see if x86_64 or x86
           mov  ebx,(0x38000 + 0x7F00)
           cmp  al,0x64
           je   short @f
           mov  ebx,(0x38000 + 0x7EF8)
@@:        mov  eax,0xA0000
           mov  [ebx],eax
           ; indicate to the BIOS that the SMM code was executed
           xor  al,al
           out  0xB3,al
           rsm                   ; resume from system management mode
smm_relocation_start_sz  dw  ($ - smm_relocation_start)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; minimal SMM code to enable or disable ACPI
smm_code_start:
           in   al,0xB2
           cmp  al,0xF0
           jne  short @f
           
           ; ACPI disable
           mov  dx,(PM_IO_BASE + 0x04)  ; PMCNTRL
           in   ax,dx
           and  ax,0xFFFE
           out  dx,ax
           jmp  short smm_code_start_done

@@:        cmp  al,0xF1
           jne  short smm_code_start_done
           
           ; ACPI enable
           mov  dx,(PM_IO_BASE + 0x04)  ; PMCNTRL
           in   ax,dx
           or   ax,0x0001
           out  dx,ax

smm_code_start_done:
           rsm
smm_code_start_sz  dw  ($ - smm_code_start)

cpu_found_cpus_str  db  'Found %i cpu(s)',13,10,0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; find out how many CPUs we have
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
smp_probe  proc near uses alld ds es
           
           ; start with one
           mov  word [EBDA_DATA->smp_cpus],1
           
           ; do we have an APIC installed?
           test dword [EBDA_DATA->cpuid_features],CPUID_APIC
           jz   short smp_probe_done

           ; try to initalize the APIC
           call init_apic
           jc   short smp_probe_done
           
           ; try to initalize the IOAPIC
           call init_ioapic
           jc   short smp_probe_done
           
           ; copy the AP boot code to AP_BOOT_ADDR
           push word cs:[smp_ap_boot_code_start_sz]
           push BIOS_BASE
           push offset smp_ap_boot_code_start
           push (AP_BOOT_ADDR >> 4)
           push (AP_BOOT_ADDR & 0xF)
           call memcpy16
           add  sp,10
           
           ; broadcast SIPI
           mov  esi,APIC_BASE_ADDR
           mov  dword fs:[esi+APIC_REG_ICR], 000000000000_11_00_0_1_0_0_0_101_00000000b                         ; initialize
           mov  dword fs:[esi+APIC_REG_ICR],(000000000000_11_00_0_1_0_0_0_110_00000000b | (AP_BOOT_ADDR >> 12)) ; startup

.ifdef BX_QEMU
           ; wait for all CPUs to 'call in'
           mov  ah,0x5F
           call cmos_get_byte
           xor  ah,ah
           inc  ax
@@:        cmp  [EBDA_DATA->smp_cpus],ax
           jb   short @b

.else
           ; delay 10ms (10000 microseconds)
           xor  cx,cx
           mov  dx,10000
           mov  ah,0x86
           int  15h
.endif
           
           ; enable VMX for CPU #0 in IA32_FEATURE_CONTROL
           test dword [EBDA_DATA->cpuid_ext_features],CPUID_EXT_VMX
           jz   short smp_probe_done

           mov  ecx,MSR_FEATURE_CTRL
           rdmsr
           or   eax,FEATURE_CTRL_VMX   ;  or   eax,(FEATURE_CTRL_LOCK | FEATURE_CTRL_VMX) ; bochs Panics if we set the LOCK bit
           wrmsr

smp_probe_done:
           ;  print how many we found
           mov  ax,[EBDA_DATA->smp_cpus]
           push cs
           pop  ds
           push ax
           mov  si,offset cpu_found_cpus_str
           call bios_printf
           add  sp,2

           ret
smp_probe  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; create multi-processor table
; on entry:
;  ds -> EBDA
; on return
;  nothing
; destroys none
mptable_init proc near uses alld

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the current table location and make
           ;  sure we are 16-byte aligned
           mov  cx,[EBDA_DATA->smp_cpus]
           mov  edi,[EBDA_DATA->bios_table_cur_addr]
           add  edi,15
           and  edi,(~15)
           mov  [EBDA_DATA->mp_config_table],edi

           mov  dword fs:[edi],'PMCP'    ; 'PCMP' signature
           mov  word fs:[edi+4],0        ; length (patched later)
           mov  byte fs:[edi+6],4        ; specs version 1.4
           mov  byte fs:[edi+7],0        ; crc (patched later)
.ifdef BX_QEMU
           mov  dword fs:[edi+8],'UMEQ'  ; oem id 'QEMUCPU '
           mov  dword fs:[edi+12],' UPC' ;
.else
           mov  dword fs:[edi+8],'HCOB'  ; oem id 'BOCHSCPU'
           mov  dword fs:[edi+12],'UPCS' ;
.endif
           mov  dword fs:[edi+16],' 1.0' ; product id
           mov  dword fs:[edi+20],'    ' ;
           mov  dword fs:[edi+24],'    ' ;
           mov  dword fs:[edi+28],0      ; oem table start ptr
           mov  word fs:[edi+32],0       ; oem table start size
           mov  word fs:[edi+34],0       ; count of entries in table (patched later)
           mov  dword fs:[edi+36],APIC_BASE_ADDR ; address of APIC
           mov  word fs:[edi+40],0       ; extended table length
           mov  byte fs:[edi+42],0       ; extended table crc
           mov  byte fs:[edi+43],0       ; reserved

           ; at offset 0x2C (44d) in table
           ; first the CPU entry(s)
           add  edi,0x2C
           xor  bx,bx                    ; starting index
           mov  dl,0x03                  ; first one is the bootstrap cpu
@@:        mov  byte fs:[edi+0],0        ; type = processor
           mov  fs:[edi+1],bl            ; APIC id
           mov  byte fs:[edi+2],0x11     ; local APIC version (or 0x14)
           mov  fs:[edi+3],dl            ; cpu type (boot strap, etc)
           mov  eax,[EBDA_DATA->cpuid_signature]
           mov  fs:[edi+4],eax           ; cpu signature
           mov  eax,[EBDA_DATA->cpuid_features]
           mov  fs:[edi+8],eax           ; cpu features
           mov  dword fs:[edi+12],0      ; reserved
           mov  dword fs:[edi+16],0      ; reserved
           add  edi,20                   ; cpu entries are 20 bytes in length
           mov  dl,0x01                  ; any remaining cpu's are not bootstrap cpu
           inc  bx
           cmp  bx,cx
           jb   short @b
           
           ; at offset 0x2C + (cx * 20)
           ; cx = count of entries so far

           ; add ISA bus entry
           mov  byte fs:[edi+0],1        ; type = Bus (ISA)
           mov  byte fs:[edi+1],0        ; Bus ID
           mov  dword fs:[edi+2],' ASI'  ; 'ISA   '
           mov  word fs:[edi+6],'  '     ;
           add  edi,8
           inc  cx
           
           ; add PCI bus 0 entry
;           mov  byte fs:[edi+0],1        ; type = Bus (PCI)
;           mov  byte fs:[edi+1],1        ; Bus ID
;           mov  dword fs:[edi+2],' ICP'  ; 'PCI   '
;           mov  word fs:[edi+6],'  '     ;
;           add  edi,8
;           inc  cx

           ; add PCI bus 1 entry
;           mov  byte fs:[edi+0],1        ; type = Bus (PCI)
;           mov  byte fs:[edi+1],2        ; Bus ID
;           mov  dword fs:[edi+2],' ICP'  ; 'PCI   '
;           mov  word fs:[edi+6],'  '     ;
;           add  edi,8
;           inc  cx

           ; ioapic entry
           mov  dx,[EBDA_DATA->smp_cpus] ; used as io_apic id
           mov  byte fs:[edi+0],2        ; entry type = IO APIC
           mov  fs:[edi+1],dl            ; io apic id
           mov  byte fs:[edi+2],0x11     ; io apic version (or 0x20)
           mov  byte fs:[edi+3],1        ; enable
           mov  dword fs:[edi+4],IOAPIC_BASE_ADDR ; io apic address
           add  edi,8
           inc  cx

           ; irq entries
           xor  bx,bx                    ; index
mp_irq_entries:
           cmp  bx,2
           je   short mp_irq_entries2
           mov  byte fs:[edi+0],3        ; entry type = IO Interrupt Assignment
           mov  byte fs:[edi+1],0        ; int type (0 = vectored)
           mov  byte fs:[edi+2],0        ; flags
           mov  byte fs:[edi+3],0        ; 
           mov  byte fs:[edi+4],0        ; isa bus above
           mov       fs:[edi+5],bl       ; source irq = bx
           mov       fs:[edi+6],dl       ; apic id
           
           mov  byte fs:[edi+7],2        ; if irq = 2, source irq = 0
           or   bx,bx
           jz   short @f
           mov       fs:[edi+7],bl       ; 
@@:
           add  edi,8                    ; entries are 8 bytes in length
           inc  cx                       ; add to entry count
mp_irq_entries2:
           inc  bx                       ;
           cmp  bx,16                    ; up to 16 entries (minus entry 2)
           jb   short mp_irq_entries

           ; update pointer for next table entry
           mov  [EBDA_DATA->bios_table_cur_addr],edi
           sub  edi,[EBDA_DATA->mp_config_table]
           mov  eax,edi                  ; eax = length
           mov  [EBDA_DATA->mp_config_table_sz],ax
           
           ; patch length, crc, count of entries
           mov  edi,[EBDA_DATA->mp_config_table]
           mov  fs:[edi+4],ax            ; update the length
           mov  fs:[edi+34],cx           ; update the entry count
           call calc_checksum
           mov  fs:[edi+7],al            ; update the crc

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now do the floating pointer structure
           ;  make sure we are 16-byte aligned
           mov  edi,[EBDA_DATA->bios_table_cur_addr]
           add  edi,15
           and  edi,(~15)
           mov  [EBDA_DATA->fp_config_table],edi

           mov  dword fs:[edi],'_PM_'    ; '_MP_' signature
           mov  eax,[EBDA_DATA->mp_config_table]
           mov  fs:[edi+4],eax           ; pointer to mp table above
           mov  byte fs:[edi+8],1        ; length in 16-byte paras
           mov  byte fs:[edi+9],4        ; MP spec version
           mov  byte fs:[edi+10],0       ; crc (patched later)
           mov  byte fs:[edi+11],0       ; mp feature byte 1
           mov  byte fs:[edi+12],0       ; mp feature byte 2
           mov  byte fs:[edi+13],0       ; reserved
           mov  byte fs:[edi+14],0       ; reserved
           mov  byte fs:[edi+15],0       ; reserved
           add  edi,16

           ; update pointer for next table entry
           mov  [EBDA_DATA->bios_table_cur_addr],edi
           sub  edi,[EBDA_DATA->fp_config_table]
           mov  eax,edi                  ; eax = length
           mov  [EBDA_DATA->fp_config_table_sz],ax
           
           ; patch crc
           mov  edi,[EBDA_DATA->fp_config_table]
           call calc_checksum
           mov  fs:[edi+10],al           ; update the crc

  ; writemem "C:\bochs\images\winxp\dd.bin" 0x000FAE90 224  ; (216 + 8 filler)
  ;mov  eax,[EBDA_DATA->mp_config_table]
  ;mov  bx,[EBDA_DATA->mp_config_table_sz]  ; 200
  ;mov  cx,[EBDA_DATA->fp_config_table_sz]  ; 16
  ;mov  dx,cx
  ;add  dx,bx
  ;xchg cx,cx

           ret
mptable_init endp

.endif  ; DO_INIT_BIOS32

.end
