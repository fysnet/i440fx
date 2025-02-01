comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: pci.asm                                                            *
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
*   pci include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.16                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 21 Jan 2025                                                *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; pci protected mode entry point and tables

PCI_FIXED_HOST_BRIDGE    equ  0x12378086  ; i440FX PCI bridge
PCI_FIXED_HOST_BRIDGE2   equ  0x01228086  ; i430FX PCI bridge
PCI_FIXED_HOST_BRIDGE3   equ  0x71908086  ; i440BX PCI bridge

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; this code is pmode code
;  (https://wiki.osdev.org/BIOS32)
.pmode
.para
bios32_entry_point:
           pushf
           cmp  eax,0x49435024     ; "$PCI"
           jne  short pci_unknown_service
           mov  eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           cmp  eax,PCI_FIXED_HOST_BRIDGE
           je   short @f
           cmp  eax,PCI_FIXED_HOST_BRIDGE2
           je   short @f
           cmp  eax,PCI_FIXED_HOST_BRIDGE3
           je   short @f
           cmp  eax,0xFFFFFFFF
           je   short pci_unknown_service
@@:        mov  ebx,0x000E0000
           mov  edx,offset pcibios_protected
           mov  ecx,0x10000
           xor  al,al
           jmp  short @f
pci_unknown_service:
           mov  al,0x80
@@:        
.ifdef BX_QEMU
           and  dword [esp+8],0xFFFFFFFC ; reset cs.RPL for kqemu ?????
.endif
           popf
           retf

.para
pcibios_protected:
           pushf
           cli
           push esi
           push edi
           
           ; installation check
           cmp  al,0x01
           jne  short @f

           mov  bx,0x0210
           call pci_pro_get_max_bus
           mov  edx,0x20494350   ; 'PCI '
           mov  al,0x01
           jmp  pci_pro_ok

@@:        ; find pci device
           cmp  al,0x02
           jne  short @f
           
           shl  ecx,16
           mov  cx,dx
           xor  bx,bx
           mov  di,0x00
pci_pro_devloop:
           call pci_pro_select_reg
           mov  dx,0x0CFC
           in   eax,dx
           cmp  eax,ecx
           jne  short pci_pro_nextdev
           or   si,si
           je   pci_pro_ok
           dec  si
pci_pro_nextdev:
           inc  bx
           cmp  bx,0x0200
           jne  short pci_pro_devloop
           mov  ah,0x86
           jmp  pci_pro_fail

@@:        ; find class code
           cmp  al,0x03
           jne  short @f

           xor  bx,bx
           mov  di,0x08
pci_pro_devloop2:
           call pci_pro_select_reg
           mov  dx,0x0CFC
           in   eax,dx
           shr  eax,8
           cmp  eax,ecx
           jne  short pci_pro_nextdev2
           or   si,si
           je   pci_pro_ok
           dec  si
pci_pro_nextdev2:
           inc  bx
           cmp  bx,0x0200
           jne  short pci_pro_devloop2
           mov  ah,0x86
           jmp  pci_pro_fail

@@:        ; read configuration byte
           cmp  al,0x08
           jne  short @f

           call pci_pro_select_reg
           push edx
           mov  dx,di
           and  dx,0x03
           add  dx,0x0CFC
           in   al,dx
           pop  edx
           mov  cl,al
           jmp  pci_pro_ok

@@:        ; read configuration word
           cmp al,0x09
           jne  short @f

           call pci_pro_select_reg
           push edx
           mov  dx,di
           and  dx,0x02
           add  dx,0x0CFC
           in   ax,dx
           pop  edx
           mov  cx,ax
           jmp  short pci_pro_ok

@@:        ; read configuration dword
           cmp  al,0x0A
           jne  short @f

           call pci_pro_select_reg
           push edx
           mov  dx,0x0CFC
           in   eax,dx
           pop  edx
           mov  ecx,eax
           jmp  short pci_pro_ok

@@:        ; write configuration byte
           cmp  al,0x0B
           jne  short @f
           
           call pci_pro_select_reg
           push edx
           mov  dx,di
           and  dx,0x03
           add  dx,0x0CFC
           mov  al,cl
           out  dx,al
           pop  edx
           jmp  short pci_pro_ok

@@:        ; write configuration word
           cmp  al,0x0C
           jne  short @f

           call pci_pro_select_reg
           push edx
           mov  dx,di
           and  dx,0x02
           add  dx,0x0CFC
           mov  ax,cx
           out  dx,ax
           pop  edx
           jmp  short pci_pro_ok

@@:        ; write configuration dword
           cmp  al,0x0D
           jne  short @f

           call pci_pro_select_reg
           push edx
           mov  dx,0x0CFC
           mov  eax,ecx
           out  dx,eax
           pop  edx
           jmp  short pci_pro_ok

@@:        mov  ah,0x81
pci_pro_fail:
           pop  edi
           pop  esi
.ifdef BX_QEMU
           and  dword [esp+8],0xFFFFFFFC ; reset cs.RPL for kqemu ?????
.endif
           popfd
           stc
           retf

pci_pro_ok:
           xor  ah,ah
           pop  edi
           pop  esi
.ifdef BX_QEMU
           and  dword [esp+8],0xFFFFFFFC ; reset cs.RPL for kqemu ?????
.endif
           popfd
           clc
           retf

pci_pro_get_max_bus:
           push eax
           mov  eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           mov  cx,0
           cmp  eax,PCI_FIXED_HOST_BRIDGE3
           jne  short @f
           mov  cx,0x0001
@@:        pop  eax
           ret

pci_pro_select_reg:
           push edx
           mov  eax,0x800000
           mov  ax,bx
           shl  eax,8
           and  di,0xFF
           or   ax,di
           and  al,0xFC
           mov  dx,0x0CF8
           out  dx,eax
           pop  edx
           ret

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; back to real mode stuff
.rmode

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; PCI Services
; on entry:
;  ds = 0x0040
;  stack currently has (after we set bp):
;   flags    cs      ip      es      ds
;  [bp+44] [bp+42] [bp+40] [bp+38] [bp+36]
;    edi     esi     ebp     esp     ebx     edx     ecx     eax
;  [bp+04] [bp+08] [bp+12] [bp+16] [bp+20] [bp+24] [bp+28] [bp+32]
; on return
;  nothing
; destroys nothing
pcibios_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ; sub  sp,4

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; first make sure we have a PCI present
           mov  eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           cmp  eax,PCI_FIXED_HOST_BRIDGE
           je   short @f
           cmp  eax,PCI_FIXED_HOST_BRIDGE2
           je   short @f
           cmp  eax,PCI_FIXED_HOST_BRIDGE3
           je   short @f
           cmp  eax,0xFFFFFFFF
           jne  short @f
           mov  ah,0xFF
           jmp  pci_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure our registers are up to date
@@:        mov  eax,REG_EAX
           mov  ecx,REG_ECX
           mov  edx,REG_EDX
           mov  esi,REG_ESI
           mov  edi,REG_EDI
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; installation check
           cmp  al,0x01
           jne  short @f
           mov  word REG_AX,0x0001
           mov  word REG_BX,0x0210
           call pci_real_get_max_bus
           mov  dword REG_EDX,0x20494350   ; 'PCI '
           mov  dword REG_EDI,(0xE0000 + pcibios_protected)
           jmp  pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; find pci device
@@:        cmp  al,0x02
           jne  short @f

           shl  ecx,16
           mov  cx,dx
           xor  bx,bx
           xor  di,di
pci_real_devloop:
           call pci_real_select_reg
           mov  dx,0x0CFC
           in   eax,dx
           cmp  eax,ecx
           jne  short pci_real_nextdev
           or   si,si
           mov  REG_BX,bx
           je   pci_int1A_success
           dec  si
pci_real_nextdev:
           inc  bx
           cmp  bx,0x0200          ;;; bus 2, devfunc 0 ???????????? (what if we have more than 2 buses?)
           jne  short pci_real_devloop
           ;mov  dx,cx
           ;shr  ecx,16
           mov  ax,0x8602
           jmp  pci_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; find class code
@@:        cmp  al,0x03
           jne  short @f

           xor  bx,bx
           mov  di,0x08
pci_real_devloop2:
           call pci_real_select_reg
           mov  dx,0x0CFC
           in   eax,dx
           shr  eax,8
           cmp  eax,ecx
           jne  short pci_real_nextdev2
           or   si,si
           mov  REG_BX,bx
           je   pci_int1A_success
           dec  si
pci_real_nextdev2:
           inc  bx
           cmp  bx,0x0200          ;;; bus 2, devfunc 0 ???????????? (what if we have more than 2 buses?)
           jne  short pci_real_devloop2
           ;mov  dx,cx
           ;shr  ecx,16
           mov  ax,0x8603
           jmp  pci_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; bus specific operations
@@:        cmp  al,0x06
           jne  short @f

           mov  ax,0x8106
           jmp  pci_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read configuration byte
@@:        cmp  al,0x08
           jne  short @f

           call pci_real_select_reg
           mov  dx,di
           and  dx,0x03
           add  dx,0x0CFC
           in   al,dx
           mov  REG_CL,al
           jmp  pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read configuration word
@@:        cmp  al,0x09
           jne  short @f

           call pci_real_select_reg
           mov  dx,di
           and  dx,0x02
           add  dx,0x0CFC
           in   ax,dx
           mov  REG_CX,ax
           jmp  pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read configuration dword
@@:        cmp  al,0x0A
           jne  short @f

           call pci_real_select_reg
           mov  dx,0x0CFC
           in   eax,dx
           mov  REG_ECX,eax
           jmp  short pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write configuration byte
@@:        cmp  al,0x0B
           jne  short @f

           call pci_real_select_reg
           mov  dx,di
           and  dx,0x03
           add  dx,0x0CFC
           mov  al,cl
           out  dx,al
           jmp  short pci_int1A_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write configuration word
@@:        cmp  al,0x0C
           jne  short @f

           call pci_real_select_reg
           mov  dx,di
           and  dx,0x02
           add  dx,0x0CFC
           mov  ax,cx
           out  dx,ax
           jmp  short pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; write configuration dword
@@:        cmp  al,0x0D
           jne  short @f

           call pci_real_select_reg
           mov  dx,0x0CFC
           mov  eax,ecx
           out  dx,eax
           jmp  short pci_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get irq routing options
           ; (this call assumes the Guest sets DS to 0xF000)
@@:        cmp  al,0x0E
           jne  short @f

           mov  ax,(pci_routing_table_structure_end - pci_routing_table_structure_start)
           cmp  es:[di],ax
           jb   short pci_real_too_small
           stosw                 ; size of our return data
           mov  si,offset pci_routing_table_structure_start
           les  di,es:[di+2]
           mov  cx,ax
           cld
           rep
             movsb
           mov  word REG_BX,((1 << 9) | (1 << 11)) ; irq 9 and 11 are used
           jmp  short pci_int1A_success
pci_real_too_small:
           stosw                 ; size of our return data
           mov  ah,0x89
           jmp  short pci_int1A_fail

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown/unsupported function call
@@:        
           mov  bx,$
           mov  ax,REG_AX
           call unsupported

           mov ah,0x81

pci_int1A_fail:
           mov  REG_AX,ax
           or   word REG_FLAGS,0x0001
           mov  sp,bp
           pop  bp
           ret

pci_int1A_success:
           mov  byte REG_AH,0x00 ; success
           and  word REG_FLAGS,(~0x0001)

           mov  sp,bp
           pop  bp
           ret
pcibios_function endp


; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the last bus number
; on entry:
;  nothing
; on return
;  cx = last bus number
; destroys none
pci_real_get_max_bus proc near uses eax
           mov  eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           xor  cx,cx
           cmp  eax,PCI_FIXED_HOST_BRIDGE3
           jne  short @f
           inc  cx
@@:        ret
pci_real_get_max_bus endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; 
; on entry:
;  bx = ??
;  di = ??
; on return
;  nothing
; destroys eax ??
pci_real_select_reg proc near uses dx
           mov  eax,0x800000
           mov  ax,bx
           shl  eax,8
           and  di,0xFF
           or   ax,di
           and  al,0xFC
           mov  dx,0x0CF8
           out  dx,eax
           ret
pci_real_select_reg endp

.if (DO_INIT_BIOS32 == 0)

pci_irq_list:
  db 11, 10, 9, 5

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; set the bus/dev/func/address
; on entry:
;  bx = 
;  dx = 
; on return
;  nothing
pcibios_init_sel_reg proc near uses eax
           mov  eax,0x00800000
           mov  ax,bx
           shl  eax,8
           and  dl,0xFC
           or   al,dl
           mov  dx,0x0CF8
           out  dx,eax
           ret
pcibios_init_sel_reg endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the PCI
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
init_pci_bases proc near uses ds
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
           push bp
           mov  bp,sp            ; so we can use the stack for some locals
           mov  eax,0xC0000000   ; base for memory init
           push eax
           mov  ax,0xC000        ; base for i/o init
           push ax
           mov  ax,0x0010        ; start at BAR 0
           push ax
           mov  bx,0x0008
pci_init_io_loop1:
           mov  dl,0x00
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   ax,dx
           cmp  ax,0xFFFF
           jz   next_pci_dev
           mov  dl,0x04          ; disable i/o and memory space access
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   al,dx
           and  al,0xFC
           out  dx,al
pci_init_io_loop2:
           mov  dl,[bp-8]
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   eax,dx
           test al,0x01
           jnz  init_io_base
           mov  ecx,eax
           mov  eax,0xFFFFFFFF
           out  dx,eax
           in   eax,dx
           cmp  eax,ecx
           je   short next_pci_base
           not  eax
           mov  ecx,eax
           mov  eax,[bp-4]
           out  dx,eax
           add  eax,ecx          ; calculate next free mem base
           add  eax,0x01000000
           and  eax,0xFF000000
           mov  [bp-4],eax
           jmp  short next_pci_base
init_io_base:
           mov  cx,ax
           mov  ax,0xFFFF
           out  dx,ax
           in   ax,dx
           cmp  ax,cx
           je   short next_pci_base
           xor  ax,0xFFFE
           mov  cx,ax
           mov  ax,[bp-6]
           out  dx,ax
           add  ax,cx            ; calculate next free i/o base
           add  ax,0x0100
           and  ax,0xFF00
           mov  [bp-6],ax
next_pci_base:
           mov  al,[bp-8]
           add  al,0x04
           cmp  al,0x28
           je   short enable_iomem_space
           mov  [bp-8],al
           jmp  short pci_init_io_loop2
enable_iomem_space:
           mov  dl,0x04          ; enable i/o and memory space access if available
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   al,dx
           or   al,0x03
           out  dx,al
next_pci_dev:
           mov  byte [bp-8],0x10
           inc  bx
           cmp  bx,0x0100
           jne  pci_init_io_loop1
           leave
           ret
init_pci_bases endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the (basic) PCI
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
init_pci_irqs proc near uses ds
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; 
           push bp
           mov  dx,0x04D0        ; reset ELCR1 + ELCR2
           mov  al,0x00
           out  dx,al
           inc  dx
           out  dx,al
           
           mov  ax,BIOS_BASE2
           mov  ds,ax
           
           mov  si,offset pci_routing_table_structure
           mov  bh,[si+8]
           mov  bl,[si+9]
           mov  dl,0x00
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   ax,dx
           cmp  ax,[si+12]       ; check irq router
           jne  pci_init_end
           mov  dl,[si+34]
           call pcibios_init_sel_reg
           push bx               ; save irq router bus + devfunc
           mov  dx,0x0CFC
           mov  ax,0x8080
           out  dx,ax            ; reset PIRQ route control
           add  dx,2
           out  dx,ax
           mov  ax,[si+6]
           sub  ax,0x20
           shr  ax,4
           mov  cx,ax
           add  si,0x20          ; set pointer to 1st entry
           mov  bp,sp
           push offset pci_irq_list
           push 0x0000
pci_init_irq_loop1:
           mov  bh,[si]
           mov  bl,[si+1]
pci_init_irq_loop2:
           mov  dl,0x00
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           in   ax,dx
           cmp  ax,0xFFFF
           jnz  short pci_test_int_pin
           test bl,0x07
           jz   short next_pir_entry
           jmp  short next_pci_func
pci_test_int_pin:
           mov  dl,0x3C
           call pcibios_init_sel_reg
           mov  dx,0x0CFD
           in   al,dx
           and  al,0x07
           jz   short next_pci_func
           dec  al               ; determine pirq reg
           mov  dl,0x03
           mul  dl
           add  al,0x02
           xor  ah,ah
           mov  bx,ax
           mov  al,[si+bx]
           mov  dl,al
           mov  bx,[bp]
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           and  al,0x03
           add  dl,al
           in   al,dx
           cmp  al,0x80
           jb   short pirq_found
           mov  bx,[bp-2]        ; pci irq list pointer
           mov  al,[bx]
           out  dx,al
           inc  bx
           mov  [bp-2],bx
           call pcibios_init_set_elcr
pirq_found:
           mov  bh,[si]
           mov  bl,[si+1]
           add  bl,[bp-3]        ; pci function number
           mov  dl,0x3C
           call pcibios_init_sel_reg
           mov  dx,0x0CFC
           out  dx,al
next_pci_func:
           inc  byte [bp-3]
           inc  bl
           test bl,0x07
           jnz  short pci_init_irq_loop2
next_pir_entry:
           add  si,0x10
           mov  byte [bp-3],0x00
           loop pci_init_irq_loop1
           mov  sp,bp
           pop  bx
pci_init_end:
           pop  bp
           ret
init_pci_irqs endp

pcibios_init_set_elcr proc near uses ax cx
           mov  dx,0x04D0
           test al,0x08
           jz   short is_master_pic
           inc  dx
           and  al,0x07
is_master_pic:
           mov  cl,al
           mov  bl,0x01
           shl  bl,cl
           in   al,dx
           or   al,bl
           out  dx,al
           ret
pcibios_init_set_elcr endp

.else   ; DO_INIT_BIOS32

;PCI_ADDRESS_SPACE_MEM   0x00
PCI_ADDRESS_SPACE_IO    equ  0x01
;PCI_ADDRESS_SPACE_MEM_PREFETCH  0x08

PCI_ROM_SLOT            equ  6
PCI_NUM_REGIONS         equ  7

;PCI_DEVICES_MAX 64

PCI_CLASS_STORAGE_IDE  equ  0x0101
PCI_CLASS_DISPLAY_VGA  equ  0x0300
PCI_CLASS_SYSTEM_PIC   equ  0x0800

PCI_VENDOR_ID          equ  0x00
PCI_DEVICE_ID          equ  0x02
PCI_COMMAND            equ  0x04
PCI_COMMAND_IO         equ  0x01  ; Enable response in I/O space
PCI_COMMAND_MEMORY     equ  0x02  ; Enable response in Memory space
PCI_COMMAND_BUSMASTER  equ  0x04  ; Enable response as Bus Master
PCI_CLASS_DEVICE       equ  0x0A
PCI_HEADER_TYPE        equ  0x0E
PCI_INTERRUPT_LINE     equ  0x3C
PCI_INTERRUPT_PIN      equ  0x3D
;PCI_MIN_GNT   0x3e  /* 8 bits */
;PCI_MAX_LAT   0x3f  /* 8 bits */

PCI_BASE_ADDRESS_0      equ  0x10
PCI_ROM_ADDRESS         equ  0x30
PCI_ROM_ADDRESS_ENABLE  equ  0x01

PCI_VENDOR_ID_INTEL               equ  0x8086
PCI_DEVICE_ID_INTEL_82437         equ  0x0122
PCI_DEVICE_ID_INTEL_82441         equ  0x1237
PCI_DEVICE_ID_INTEL_82443         equ  0x7190
PCI_DEVICE_ID_INTEL_82443_1       equ  0x7191
PCI_DEVICE_ID_INTEL_82443_NOAGP   equ  0x7192
PCI_DEVICE_ID_INTEL_82371FB_0     equ  0x122E
PCI_DEVICE_ID_INTEL_82371FB_1     equ  0x1230
PCI_DEVICE_ID_INTEL_82371SB_0     equ  0x7000
PCI_DEVICE_ID_INTEL_82371SB_1     equ  0x7010
PCI_DEVICE_ID_INTEL_82371AB_0     equ  0x7110
PCI_DEVICE_ID_INTEL_82371AB       equ  0x7111
PCI_DEVICE_ID_INTEL_82371AB_3     equ  0x7113

PCI_VENDOR_ID_IBM                 equ  0x1014
PCI_VENDOR_ID_APPLE               equ  0x106B

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a byte from the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset
; on return
;  al = byte read
; destroys nothing
pci_config_read_byte proc near uses cx dx
           ; shift count
           mov  cl,bl
           and  cl,0x03
           shl  cl,3

           push eax              ; save the high word/high byte of eax
           xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           shr  eax,cl
           mov  cl,al
           pop  eax              ; restore the high word/high byte of eax
           mov  al,cl

           ret
pci_config_read_byte endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a word from the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset (can cross a dword boundary)
; on return
;  ax = word read
; destroys nothing
pci_config_read_word proc near uses cx dx
           ; do we cross a dword boundary?
           mov  cl,bl
           and  cl,0x03
           cmp  cl,0x02
           jbe  short @f

           ; we cross a boundary, so read two bytes instead
           inc  bx
           call pci_config_read_byte
           mov  ah,al
           dec  bx
           call pci_config_read_byte
           ret

           ; we don't cross a boundary, so read the word
@@:        shl  cl,3             ; shift count
           
           push eax              ; save the high word of eax
           xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           shr  eax,cl
           mov  cx,ax
           pop  eax              ; restore the high word of eax
           mov  ax,cx

           ret
pci_config_read_word endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a dword from the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset (can cross a dword boundary)
; on return
;  eax = dword read
; destroys nothing
pci_config_read_dword proc near uses cx edx
           ; do we cross a dword boundary?
           mov  cl,bl
           and  cl,0x03
           jz   short @f

           ; we cross a boundary, so read two words instead
           add  bx,2
           call pci_config_read_word
           shl  eax,16
           sub  bx,2
           call pci_config_read_word
           ret

           ; we don't cross a boundary, so read the word
@@:        xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           ;and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx

           ret
pci_config_read_dword endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a byte to the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset
;  al = byte to write
; on return
;  nothing
; destroys nothing
pci_config_write_byte proc near uses eax bx cx dx
           ; shift count
           mov  cl,bl
           and  cl,0x03
           shl  cl,3

           push ax               ; save byte to write
           xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           mov  ebx,0xFFFFFF00
           rol  ebx,cl
           and  eax,ebx
           pop  bx               ; restore byte to write
           and  ebx,0xFF
           shl  ebx,cl
           or   eax,ebx
           out  dx,eax

           ret
pci_config_write_byte endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a word to the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset
;  ax = word to write
; on return
;  nothing
; destroys nothing
pci_config_write_word proc near uses eax bx cx dx
           ; do we cross a dword boundary?
           mov  cl,bl
           and  cl,0x03
           cmp  cl,0x02
           jbe  short @f

           ; we cross a boundary, so write two bytes instead
           call pci_config_write_byte
           mov  al,ah
           inc  bx
           call pci_config_write_byte
           ret

           ; we don't cross a boundary, so write the word
@@:        shl  cl,3             ; shift count

           push ax               ; save word to write
           xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           in   eax,dx
           mov  ebx,0xFFFF0000
           rol  ebx,cl
           and  eax,ebx
           pop  bx               ; restore word to write
           and  ebx,0xFFFF
           shl  ebx,cl
           or   eax,ebx
           out  dx,eax

           ret
pci_config_write_word endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a dword to the PCI configuration space
; on entry:
;  dh = bus
;  dl = devfunc
;  bx = byte offset
;  eax = dword to write
; on return
;  nothing
; destroys nothing
pci_config_write_dword proc near uses eax bx cx dx
           ; do we cross a dword boundary?
           mov  cl,bl
           and  cl,0x03
           jz   short @f

           ; we cross a boundary, so write two bytes instead
           call pci_config_write_word
           shr  eax,16
           add  bx,2
           call pci_config_write_word
           ret

           ; we don't cross a boundary, so write the dword
@@:        push eax              ; save dword to write
           xor  eax,eax
           mov  al,dh
           shl  eax,16
           mov  ah,dl
           mov  al,bl
           ;and  al,0xFC
           or   eax,0x80000000
           mov  dx,0x0CF8
           out  dx,eax
           mov  dx,0x0CFC
           pop  eax              ; restore dword to write
           out  dx,eax

           ret
pci_config_write_dword endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; is it the i440FX PCI Device entry?
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
pci_find_440fx proc near uses ax bx dx
           ; dx = bus/devfunc
           
           mov  bx,PCI_VENDOR_ID
           call pci_config_read_word
           cmp  ax,PCI_VENDOR_ID_INTEL
           jne  short pci_find_440fx_done

           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           cmp  ax,PCI_DEVICE_ID_INTEL_82441
           je   short @f
           cmp  ax,PCI_DEVICE_ID_INTEL_82437
           je   short @f
           cmp  ax,PCI_DEVICE_ID_INTEL_82443
           jne  short pci_find_440fx_done

@@:        mov  [EBDA_DATA->i440_pcidev],dx
           
pci_find_440fx_done:
           ret
pci_find_440fx endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Search through the PCI Configuration Space
; on entry:
;  ds = EBDA
;  bx = sub function to call
; on return
;  nothing
; destroys nothing
pci_for_each_device proc near uses cx dx si
           ; save function to call
           mov  si,bx
           
           xor  cx,cx            ; cx = bus
pci_for_each_device_01:
           cmp  cx,2
           jnb  short pci_for_each_device_done

           xor  dx,dx            ; dx = devfunc
pci_for_each_device_02:
           cmp  dx,256
           jnb  short pci_for_each_device_03

           push dx
           mov  dh,cl            ; bus
           mov  bx,PCI_VENDOR_ID
           call pci_config_read_word
           cmp  ax,0xFFFF
           jne  short @f
           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           cmp  ax,0xFFFF
           je   short pci_for_each_device_02a
@@:        call si
pci_for_each_device_02a:
           pop  dx
           inc  dx
           jmp  short pci_for_each_device_02

pci_for_each_device_03:
           inc  cx
           jmp  short pci_for_each_device_01

pci_for_each_device_done:
           ret
pci_for_each_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Lock the Shadow RAM
; (* is a far procedure *)
;  Change the memory PAM(s) to Read Only so that
;   the reads are from physical RAM, but writes are ignored
; on entry:
;  nothing
; on return
;  nothing
; destroys nothing
bios_lock_shadow_ram proc far uses ax bx dx ds
           mov  ax,EBDA_SEG
           mov  ds,ax

           mov  dx,[EBDA_DATA->i440_pcidev]
           
           wbinvd

           ; 0x59 = PAM0 = 0xF0000->0xFFFFF
           mov  bx,0x59
           call pci_config_read_byte
           and  al,0x0F
           or   al,0x10
           call pci_config_write_byte

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the following two actions break Jemm386 v5.79
           ; and/or HimemX v3.36. One or the other will re-map
           ; address range 0xE0000 -> 0xE3FFF to 0x149000
           ; which will then break this BIOS. Using standard
           ; MS-DOS memory handlers work as expected.
           ; Work-around: build with /DHIMEMHACK
           ; See: https://github.com/fysnet/i440fx/issues/4
.ifndef HIMEMHACK
           ; 0x5E = PAM5.0 = 0xE0000->0xE3FFF
           ;        PAM5.1 = 0xE4000->0xE7FFF
           mov  bx,0x5E
           mov  al,0x11
           call pci_config_write_byte

           ; 0x5F = PAM6.0 = 0xE8000->0xEBFFF
           ;        PAM6.1 = 0xEC000->0xEFFFF
           mov  bx,0x5F
           mov  al,0x11
           call pci_config_write_byte
.endif

           retf
bios_lock_shadow_ram endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Unlock the Shadow RAM
; (* is a far procedure *)
;  Change the memory PAM(s) to Read/Write
; on entry:
;  ds = EBDA
; on return
;  nothing
; destroys nothing
bios_unlock_shadow_ram proc far uses ax bx dx

           mov  dx,[EBDA_DATA->i440_pcidev]
           
           wbinvd

           ; 0x59 = PAM0 = 0xF0000->0xFFFFF
           mov  bx,0x59
           call pci_config_read_byte
           and  al,0x0F
           or   al,0x30
           call pci_config_write_byte

           ; 0x5E = PAM5.0 = 0xE0000->0xE3FFF
           ;        PAM5.1 = 0xE4000->0xE7FFF
           mov  bx,0x5E
           mov  al,0x33
           call pci_config_write_byte

           ; 0x5F = PAM6.0 = 0xE8000->0xEBFFF
           ;        PAM6.1 = 0xEC000->0xEFFFF
           mov  bx,0x5F
           mov  al,0x33
           call pci_config_write_byte

           retf
bios_unlock_shadow_ram endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize the PCI
; on entry:
;  ds = EBDA
; on return
;  nothing
; destroys nothing
pci_bios_init proc near uses bx
           
           mov  dword [EBDA_DATA->pci_bios_io_addr],0x0000C000
           mov  dword [EBDA_DATA->pci_bios_agp_io_addr],0x0000E000
           mov  dword [EBDA_DATA->pci_bios_mem_addr],0xC0000000
           mov  dword [EBDA_DATA->pci_bios_agp_mem_addr],0xD0000000
           mov  dword [EBDA_DATA->pci_bios_rom_start],0x000C0000

           mov  bx,offset pci_bios_init_bridges
           call pci_for_each_device
           mov  bx,offset pci_bios_init_device
           call pci_for_each_device
           mov  bx,offset pci_bios_init_optrom
           call pci_for_each_device
           
           ; we can now write to 0x000E0000->0x000FFFFF
           ret
pci_bios_init endp

pci_irqs   db  11, 9, 11, 9

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize a PCI bridge
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
pci_bios_init_bridges proc near uses all
           push bp
           mov  bp,sp
           sub  sp,2

pci_elcr   equ  [bp-2]

           ; dx = bus/devfunc
           mov  bx,PCI_VENDOR_ID
           call pci_config_read_word
           cmp  ax,PCI_VENDOR_ID_INTEL
           jne  pci_bios_init_bridges_done

           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           cmp  ax,PCI_DEVICE_ID_INTEL_82371FB_0
           je   short pci_bios_init_bridges_00
           cmp  ax,PCI_DEVICE_ID_INTEL_82371SB_0
           je   short pci_bios_init_bridges_00
           cmp  ax,PCI_DEVICE_ID_INTEL_82371AB_0
           jne  short pci_bios_init_bridges_01

           ; is a PIIX/PIIX3/PIIX4 PCI to ISA Bridge
pci_bios_init_bridges_00:
           ; save the bus/devfunc for later use
           mov  [EBDA_DATA->i440_pciisa],dx
           
           ; initialize the elcr's
           xor  bx,bx
           mov  pci_elcr,bx
@@:        push bx               ; save counter (0 -> 3)
           push dx               ; save bus/devfunc
           push bx               ; save counter (0 -> 3)
           movzx dx,byte cs:[bx+pci_irqs] ; dx = irq
           
           ; elcr[irq >> 3] |= (1 << (irq & 7));
           push dx               ; save irq
           lea  bx,pci_elcr
           shr  dx,3
           add  bx,dx
           pop  dx               ; restore irq
           mov  cl,dl
           and  cl,7
           mov  al,1
           shl  al,cl
           or   ss:[bx],al
           
           pop  bx               ; restore counter (0 -> 3)
           mov  al,dl            ; dl = irq
           pop  dx               ; restore bus/devfunc
           add  bx,0x60          ; register 0x60 + counter
           call pci_config_write_byte
           pop  bx               ; restore counter (0 -> 3)
           inc  bx
           cmp  bx,4
           jb   short @b

           ; write them
           mov  ax,pci_elcr
           mov  dx,0x04D0
           out  dx,al
           mov  al,ah
           inc  dx
           out  dx,al
           jmp  pci_bios_init_bridges_done

pci_bios_init_bridges_01:
           cmp  ax,PCI_DEVICE_ID_INTEL_82441
           je   short pci_bios_init_bridges_02
           cmp  ax,PCI_DEVICE_ID_INTEL_82437
           jne  short pci_bios_init_bridges_03

           ; is a i440FX / i430FX PCI Bridge
pci_bios_init_bridges_02:
           ; dx = bus/devfunc
           call bios_shadow_init
           jmp  pci_bios_init_bridges_done

pci_bios_init_bridges_03:
           cmp  ax,PCI_DEVICE_ID_INTEL_82443
           je   short pci_bios_init_bridges_04
           cmp  ax,PCI_DEVICE_ID_INTEL_82443_NOAGP
           jne  short pci_bios_init_bridges_05

           ; is a i440BX PCI Bridge
pci_bios_init_bridges_04:
           ; dx = bus/devfunc
           call bios_shadow_init
           
           push ds
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  bx,offset pci_routing_table_structure
           mov  byte [bx+0x09],0x38     ; IRQ router DevFunc
           mov  byte [bx+0x21],0x38     ; 1st entry: PCI2ISA
           mov  byte [bx+0x31],0x40     ; 2nd entry: 1st slot
           mov  byte [bx+0x41],0x48     ; 3rd entry: 2nd slot
           mov  byte [bx+0x51],0x50     ; 4th entry: 3rd slot
           mov  byte [bx+0x61],0x58     ; 5th entry: 4th slot
           mov  cl,0x60                 ; 6th entry: 5th slot
           cmp  ax,PCI_DEVICE_ID_INTEL_82443
           jne  short @f
           mov  byte [bx+0x70],0x01     ; 6th entry: AGP
           mov  cl,0x00                 ; 6th entry: AGP slot
           push bx
           mov  bx,0xB4                 ; AGP aperture size 64 MB
           mov  al,0x30                 ;
           call pci_config_write_byte   ; dx = bus/devfunc
           pop  bx
@@:        mov  [bx+0x71],cl            ;
           
           ; calculate the checksum
           mov  byte [bx+0x1F],0        ; clear the crc before the check
           mov  cx,[bx+0x06]            ; retrieve the size
           xor  al,al                   ;
@@:        add  al,[bx]                 ;
           inc  bx                      ;
           loop @b                      ;
           neg  al                      ;
           mov  [bx+0x1F],al            ; store the new crc
           pop  ds

           jmp  short pci_bios_init_bridges_done

pci_bios_init_bridges_05:
           cmp  ax,PCI_DEVICE_ID_INTEL_82443_1
           jne  short pci_bios_init_bridges_done

           ; is a i440BX PCI/AGP Bridge
           ; dx = bus/devfunc
           mov  bx,0x04
           mov  ax,0x0107
           call pci_config_write_word
           mov  bx,0x0D
           mov  al,0x40
           call pci_config_write_byte
           mov  bx,0x19
           mov  al,0x01
           call pci_config_write_byte
           mov  bx,0x1A
           mov  al,0x01
           call pci_config_write_byte
           mov  bx,0x1B
           mov  al,0x40
           call pci_config_write_byte
           mov  bx,0x1C
           mov  al,0xE0
           call pci_config_write_byte
           mov  bx,0x1D
           mov  al,0xF0
           call pci_config_write_byte
           mov  bx,0x20
           mov  ax,0xD000
           call pci_config_write_word
           mov  bx,0x22
           mov  ax,0xD1F0
           call pci_config_write_word
           mov  bx,0x24
           mov  ax,0xD200
           call pci_config_write_word
           mov  bx,0x26
           mov  ax,0xD3F0
           call pci_config_write_word
           mov  bx,0xEE
           mov  al,0x88
           call pci_config_write_byte

pci_bios_init_bridges_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
pci_bios_init_bridges endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize a PCI device
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
pci_bios_init_device proc near uses alld
           push bp
           mov  bp,sp
           sub  sp,8

pci_is_i440bx    equ [bp-1]
pci_headt        equ [bp-2]
pci_b_vendor_id  equ [bp-4]
pci_b_device_id  equ [bp-6]
pci_b_class      equ [bp-8]

           mov  byte pci_is_i440bx,0

           ; get the chipset
           push dx
           xor  dx,dx            ; bus = 0, devfunc = 0
           mov  bx,PCI_VENDOR_ID
           call pci_config_read_word
           cmp  ax,PCI_VENDOR_ID_INTEL
           jne  short @f
           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           cmp  ax,PCI_DEVICE_ID_INTEL_82443
           jne  short @f
           mov  byte pci_is_i440bx,1
@@:        pop  dx
           
           ; dx = bus/devfunc
           mov  bx,PCI_VENDOR_ID
           call pci_config_read_word
           mov  pci_b_vendor_id,ax
           
           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           mov  pci_b_device_id,ax
           
           mov  bx,PCI_CLASS_DEVICE
           call pci_config_read_word
           mov  pci_b_class,ax
           
           mov  bx,PCI_HEADER_TYPE
           call pci_config_read_byte
           mov  pci_headt,al

           ; depending on the class...
           mov  ax,pci_b_class
           cmp  ax,PCI_CLASS_STORAGE_IDE
           jne  short pci_not_ide
           
           mov  ax,pci_b_vendor_id
           cmp  ax,PCI_VENDOR_ID_INTEL
           jne  short pci_ide_not_intel
           mov  ax,pci_b_device_id
           cmp  ax,PCI_DEVICE_ID_INTEL_82371FB_1
           je   short @f
           cmp  ax,PCI_DEVICE_ID_INTEL_82371SB_1
           je   short @f
           cmp  ax,PCI_DEVICE_ID_INTEL_82371AB
           jne  short pci_ide_not_intel
@@:        ; PIIX3/PIIX4 IDE
           mov  bx,0x40
           mov  ax,0x8000        ; enable IDE0
           call pci_config_write_word
           mov  bx,0x42
          ;mov  ax,0x8000        ; enable IDE1
           call pci_config_write_word
           jmp  pci_map_interrupt

pci_ide_not_intel:
           ; IDE: we map it as in ISA mode
           mov  ax,0x01F0
           mov  bx,0
           call pci_set_io_region_addr
           mov  ax,0x03F4
           mov  bx,1
           call pci_set_io_region_addr
           mov  ax,0x0170
           mov  bx,2
           call pci_set_io_region_addr
           mov  ax,0x0374
           mov  bx,3
           call pci_set_io_region_addr
           jmp  pci_map_interrupt
    
pci_not_ide:
           cmp  ax,PCI_CLASS_SYSTEM_PIC
           jne  short pci_not_pic

           cmp  word pci_b_vendor_id,PCI_VENDOR_ID_IBM
           jne  pci_map_interrupt
           cmp  word pci_b_device_id,0x0046
           je   short @f
           cmp  word pci_b_device_id,0xFFFF
           jne  pci_map_interrupt
@@:        mov  eax,(0x80800000 + 0x00040000)
           mov  bx,0
           call pci_set_io_region_addr
           jmp  pci_map_interrupt

pci_not_pic:
           cmp  ax,0xFF00
           jne  short pci_default_map

           cmp  word pci_b_vendor_id,PCI_VENDOR_ID_APPLE
           jne  pci_map_interrupt
           cmp  word pci_b_device_id,0x0017
           je   short @f
           cmp  word pci_b_device_id,0x0022
           jne  pci_map_interrupt
@@:        mov  eax,0x80800000
           mov  bx,0
           call pci_set_io_region_addr
           jmp  pci_map_interrupt

pci_default_map:
           test byte pci_headt,0x03
           jnz  pci_map_interrupt
           
           ; disable i/o and memory access
           mov  bx,PCI_COMMAND
           call pci_config_read_word
           and  ax,0xFFFC
           call pci_config_write_word
           
           ; default memory mappings
           xor  cx,cx
pci_memory_mappings:
           ; get the size of the addressable space
           ; (calculate the BAR. cx = 0 = 0x10, cx = 1 = 0x14, etc)
           mov  bx,cx
           shl  bx,2
           add  bx,PCI_BASE_ADDRESS_0
           mov  eax,0xFFFFFFFF
           cmp  cx,PCI_ROM_SLOT
           jb   short @f
           ; cx = 6 = ROM address at 0x30
           mov  bx,PCI_ROM_ADDRESS
           mov  al,0xFE          ; don't write bit 0
@@:        call pci_config_write_dword
           call pci_config_read_dword
           or   eax,eax          ; if size = 0, nothing here
           jz   short pci_memory_mappings_next

           ; size = ~(return & ~0xF) + 1
           mov  edi,eax
           and  edi,0xFFFFFFF0
           not  edi
           inc  edi              ; edi = size
           
           test al,PCI_ADDRESS_SPACE_IO
           jz   short pci_memory_mappings1
           lea  bx,[EBDA_DATA->pci_bios_agp_io_addr]
           cmp  dh,1
           je   short @f
           lea  bx,[EBDA_DATA->pci_bios_io_addr]
@@:        mov  esi,16          ; minimum alignment
           jmp  short pci_memory_mappings2
pci_memory_mappings1:
           lea  bx,[EBDA_DATA->pci_bios_agp_mem_addr]
           cmp  dh,1
           je   short @f
           lea  bx,[EBDA_DATA->pci_bios_mem_addr]
@@:        mov  esi,0x00010000  ; minimum alignment
pci_memory_mappings2:           ; edi = size
           
           ; *paddr = (*paddr + size - 1) & ~(size - 1);
           mov  eax,[bx]        ; read the current value
           add  eax,edi         ; add the size
           dec  eax             ; - 1
           push edi             ; save the size
           dec  edi             ; and by ~(size-1)
           not  edi             ;
           and  eax,edi         ;
           pop  edi             ; restore the size
           mov  [bx],eax        ; write it back
           push bx
           mov  bx,cx
           call pci_set_io_region_addr
           pop  bx

           ; if it is a ROM_SLOT and class = VGA, write the pcirom address too
           cmp  cx,PCI_ROM_SLOT
           jne  short @f
           cmp  word pci_b_class,PCI_CLASS_DISPLAY_VGA
           jne  short @f
           call pci_bios_init_pcirom

@@:        ; is size < alignment ?
           mov  eax,esi         ; assume minimum alignment
           cmp  edi,esi         ; edi = size, esi = alignment
           jb   short @f
           mov  eax,edi         ; is size
@@:        add  [bx],eax
           
pci_memory_mappings_next:
           inc  cx
           cmp  cx,PCI_NUM_REGIONS
           jb   pci_memory_mappings
            
           ; enable i/o and memory access
           mov  bx,PCI_COMMAND
           call pci_config_read_word
           or   ax,(PCI_COMMAND_MEMORY | PCI_COMMAND_IO)
           call pci_config_write_word

pci_map_interrupt:
           mov  bx,PCI_INTERRUPT_PIN
           call pci_config_read_byte
           or   al,al
           jz   short @f
           
           xor  ah,ah
           mov  bx,ax
           dec  bx
           mov  al,pci_is_i440bx
           call pci_slot_get_pirq
           xor  ah,ah
           mov  bx,ax
           mov  al,cs:[bx+pci_irqs]
           mov  bx,PCI_INTERRUPT_LINE
           call pci_config_write_byte

@@:        cmp  word pci_b_vendor_id,PCI_VENDOR_ID_INTEL
           jne  short pci_bios_init_device_done
           cmp  word pci_b_device_id,PCI_DEVICE_ID_INTEL_82371AB_3
           jne  short pci_bios_init_device_done
           
           ; PIIX4 Power Management device (for ACPI)
           mov  dword [EBDA_DATA->pm_io_base],PM_IO_BASE
           mov  dword [EBDA_DATA->smb_io_base],SMB_IO_BASE
           
           ; don't hardwire acpi to 9
           ;mov  al,9
           ;mov  bx,PCI_INTERRUPT_LINE
           ;call pci_config_write_byte

           call pci_config_read_byte
           mov  [EBDA_DATA->pm_sci_int],al

           call piix4_pm_enable
           mov  byte [EBDA_DATA->acpi_enabled],1
            
pci_bios_init_device_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
pci_bios_init_device endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Initialize a PCI optional rom
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
pci_bios_init_optrom proc near uses alld
           
           mov  ebx,[EBDA_DATA->pci_bios_rom_start]
           cmp  ebx,0xC0000
           jne  short optrom_skip_isa

           ; skip the VGA BIOS area in case it's ISA
           movzx eax,byte fs:[ebx+2]
           test al,0x1F
           jz   short @f
           and  al,0xE0
           add  eax,0x20
@@:        shl  eax,9
           add  [EBDA_DATA->pci_bios_rom_start],eax
           
optrom_skip_isa:
           mov  bx,PCI_CLASS_DEVICE
           call pci_config_read_word
           cmp  ax,PCI_CLASS_DISPLAY_VGA
           je   short @f

           mov  bx,PCI_ROM_ADDRESS
           call pci_config_read_dword
           and  eax,0xFFFFFC00
           call pci_bios_init_pcirom

@@:        ret
pci_bios_init_optrom endp

BIOS_TMP_STORAGE  equ  0x00030000  ; 128 KB used to copy the BIOS to shadow RAM

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; activate the shaddow ram for addresses 0xE0000 - > 0xFFFFF
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
bios_shadow_init proc near ; don't place anything here
           push ax
           push bx

           ; make sure that we are reading from the ROM
           ; 0x59 = PAM0 = 0xF0000->0xFFFFF
           mov  bx,0x59
           call pci_config_read_byte
           and  al,0xCF
           call pci_config_write_byte

           ; 0x5E = PAM5.0 = 0xE0000->0xE3FFF
           ;        PAM5.1 = 0xE4000->0xE7FFF
           mov  bx,0x5E
           call pci_config_read_byte
           and  al,0xCC
           call pci_config_write_byte

           ; 0x5F = PAM6.0 = 0xE8000->0xEBFFF
           ;        PAM6.1 = 0xEC000->0xEFFFF
           mov  bx,0x5F
           call pci_config_read_byte
           and  al,0xCC
           call pci_config_write_byte
           
           ; copy the ROM to BIOS_TMP_STORAGE
           ; memcpy(BIOS_TMP_STORAGE, 0x000E0000, 0x20000);
           pushd 0x00020000
           pushd 0x000E0000
           pushd BIOS_TMP_STORAGE
           call memcpy32
           add  sp,12

           ; since as soon as we mark the memory as R/O,
           ;  Bochs (and QEMU) no longer read the code,
           ;  they read zeros. So we have to jump to our
           ;  copied code which is in physical RAM to
           ;  finish out the function
           push BIOS_BASE
           push offset bios_shadow_init_ret

           ; jump to the physical RAM area of the next code
           jmp  far ($+5),(BIOS_TMP_STORAGE >> 4)

           ; change the memory PAM(s) to Write Only so that
           ;  the write goes to physical RAM, not the ROM
           mov  bx,0x59
           call pci_config_read_byte
           or   al,0x30
           call pci_config_write_byte

           mov  bx,0x5E
           call pci_config_read_byte
           or   al,0x33
           call pci_config_write_byte

           mov  bx,0x5F
           call pci_config_read_byte
           or   al,0x33
           call pci_config_write_byte

           ; copy the temp ROM to physical memory
           ; memcpy(0x000E0000, BIOS_TMP_STORAGE, 0x20000);
           pushd 0x20000
           pushd BIOS_TMP_STORAGE
           pushd 0x000E0000
           call memcpy32
           add  sp,12

           ; now return back to our BIOS code which is now
           ;  in Shadow RAM
.diag 0
           retf               ; return far back to 'bios_shadow_init_ret' below
.diag 1

bios_shadow_init_ret:
           ; save the PCI dev/func for later use
           mov  [EBDA_DATA->i440_pcidev],dx

           pop  bx
           pop  ax
           ret                ; is a near ret
bios_shadow_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a value to a BAR
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
;  eax = address
;  bx = BAR
; on return
;  nothing
; destroys nothing
pci_set_io_region_addr proc near uses eax bx cx si ds

           mov  cx,bx

           ; assume it is not a rom slot
           shl  bx,2
           add  bx,PCI_BASE_ADDRESS_0
           cmp  cx,PCI_ROM_SLOT
           jb   short @f
           ; is a rom slot
           mov  bx,PCI_ROM_ADDRESS
           or   al,PCI_ROM_ADDRESS_ENABLE
@@:        call pci_config_write_dword
           
           mov  bx,BIOS_BASE2
           mov  ds,bx
           and  al,0xFE
           push eax
           push cx
           mov  si,offset pci_rom_region_str
           call bios_printf
           add  sp,6

           ret
pci_set_io_region_addr endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize a pci rom
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
;  eax = address
; on return
;  nothing
; destroys nothing
pci_bios_init_pcirom proc near uses alld
           push bp
           mov  bp,sp
           sub  sp,26

pcirom_reg        equ  [bp-2]
pcirom_reg_base   equ  [bp-4]
pcirom_value      equ  [bp-6]
pcirom_addr       equ  [bp-10]
pcirom_cur_addr   equ  [bp-14]
pcirom_size       equ  [bp-18]
pcirom_tmp_addr   equ  [bp-22]
pcirom_cur_sz     equ  [bp-26]

           ; if address == 0, just return
           or   eax,eax
           jz   pci_bios_init_pcirom_done

           ; determine the PAM base from the bus/devfunc value
           ; (If using QEMU and '-machine q35', it is an MCH style bridge (8086:29C0))
           ;  (MCH PAM registers start at 0x90)
           ; (Bochs and QEMU w/o '-machine q35' use a i440x style bridge (8086:1237))
           ;  (i440x PAM registers start at 0x59)
           mov  word pcirom_reg_base,0x5A ; assume the i440x
.ifdef BX_QEMU
           push dx
           push ax
           xor  dx,dx  ; PCI Root Bridge (Bus/Dev/Func = 0/0/0)
           mov  bx,PCI_DEVICE_ID
           call pci_config_read_word
           cmp  ax,0x1237
           je   short @f
           mov  word pcirom_reg_base,0x91 ; assume the 82G33 (MCH style chipset)
@@:        pop  ax
           pop  dx
.endif
           ; make sure i/o and memory access is endabled
           mov  bx,PCI_COMMAND
           push ax
           call pci_config_read_word
           or   ax,(PCI_COMMAND_MEMORY | PCI_COMMAND_IO)
           call pci_config_write_word
           pop  ax

           ; if signature not found, return
           cmp  word fs:[eax],0xAA55
           jne  pci_bios_init_pcirom_done
           
           mov  pcirom_addr,eax
           movzx eax,byte fs:[eax+2]
           test al,0x03
           jz   short @f
           and  al,0xFC
           add  eax,4
@@:        shl  eax,9
           mov  pcirom_size,eax  ; save the size
           
           mov  ecx,[EBDA_DATA->pci_bios_rom_start]
           add  eax,ecx
           cmp  eax,0x000E0000
           ja   pci_bios_init_pcirom_done
           
           push dx               ; save bus/devfunc
           mov  pcirom_cur_addr,ecx ; current address of this rom
           mov  dword pcirom_tmp_addr,0
pci_bios_init_pcirom_0:
           ; calculate cur size
           mov  eax,0x00004000
           mov  ecx,pcirom_cur_addr
           and  ecx,0x00003FFF
           sub  eax,ecx
           mov  pcirom_cur_sz,eax

           mov  ecx,pcirom_size
           sub  ecx,pcirom_tmp_addr
           cmp  ecx,eax
           jnb  short @f
           mov  pcirom_cur_sz,ecx

@@:        mov  eax,pcirom_cur_addr
           shr  eax,15
           and  ax,0x07
           add  ax,pcirom_reg_base
           mov  pcirom_reg,ax

           mov  cl,4
           mov  eax,pcirom_cur_addr
           test eax,0x00004000
           jnz  short @f
           xor  cl,cl

@@:        xor  dx,dx            ; bus/devfunc = 0/00
           mov  bx,pcirom_reg
           call pci_config_read_byte
           ; al = (al & (~(0x03 << cl))) | (0x02 << cl);
           mov  ah,0x03
           shl  ah,cl
           not  ah
           and  al,ah
           mov  ah,0x02
           shl  ah,cl
           or   al,ah
           mov  pcirom_value,al
           call pci_config_write_byte

           ; memcpy(pcirom_cur_addr, pcirom_addr + pcirom_tmp_addr, pcirom_cur_sz);
           push dword pcirom_cur_sz  ; count of bytes to copy
           mov  eax,pcirom_addr
           add  eax,pcirom_tmp_addr
           push eax                  ; source
           mov  eax,pcirom_cur_addr
           push eax                  ; target
           call memcpy32
           add  sp,12

           mov  al,pcirom_value
           ; al = (al & (~(0x03 << cl))) | (0x01 << cl);
           mov  ah,0x03
           shl  ah,cl
           not  ah
           and  al,ah
           mov  ah,0x01
           shl  ah,cl
           or   al,ah
           mov  bx,pcirom_reg
           call pci_config_write_byte

           mov  eax,pcirom_cur_sz
           add  pcirom_cur_addr,eax
           add  pcirom_tmp_addr,eax

           mov  eax,pcirom_tmp_addr
           cmp  eax,pcirom_size
           jb   pci_bios_init_pcirom_0

           mov  ecx,[EBDA_DATA->pci_bios_rom_start]
           push ds
           mov  ax,BIOS_BASE2
           mov  ds,ax
           push dword pcirom_size
           push ecx
           mov  si,offset pci_rom_copied_str
           call bios_printf
           add  sp,8
           pop  ds

           mov  eax,pcirom_size
           add  [EBDA_DATA->pci_bios_rom_start],eax

           pop  dx               ; restore bus/devfunc
           mov  bx,PCI_ROM_ADDRESS
           xor  al,al
           call pci_config_write_byte

pci_bios_init_pcirom_done:
           mov  sp,bp            ; restore the stack
           pop  bp
           ret
pci_bios_init_pcirom endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the global irq number
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
;  al = is_i440BX
;  bx = pin
; on return
;  al = irq number
; destroys nothing
pci_slot_get_pirq proc near uses cx
           
           mov  cl,dl
           shr  cl,3             ; cl = dev
           dec  cl               ; - 1
           or   al,al            ;
           jz   short @f         ;
           sub  cl,6             ; - 6 more
@@:        add  cl,bl            ; add the pin
           and  cl,3             ; only bottom 2 bits
           mov  al,cl            ; return in al
           
           ret
pci_slot_get_pirq endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the global irq number
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
piix4_pm_enable proc near uses eax bx

; todo: move this to acpi.asm????
           
           ; PIIX4 Power Management device (for ACPI)
           mov  bx,0x40
           mov  eax,(PM_IO_BASE | 1)
           call pci_config_write_dword
           
           mov  bx,0x80
           mov  al,0x01          ; enable PM IO space
           call pci_config_write_byte

           mov  bx,0x90
           mov  eax,(SMB_IO_BASE | 1)
           call pci_config_write_dword

           mov  bx,0xD2
           mov  al,0x09          ; enable SMBus IO space
           call pci_config_write_byte

           call smm_init

           ret
piix4_pm_enable endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the SMM
; on entry:
;  ds = EBDA
;  dh = bus
;  dl = devfunc
; on return
;  nothing
; destroys nothing
smm_init   proc near uses alld
           
           mov  bx,0x58
           call pci_config_read_dword
           test eax,(1 << 25)
           jnz  smm_init_done

           ; save the value for use later
           mov  ecx,eax
           
           ; enable the SMM memory window
           push dx
           mov  dx,[EBDA_DATA->i440_pcidev]
           mov  bx,0x72
           mov  al,(0x02 | 0x48)
           call pci_config_write_byte
           pop  dx

           ; save original memory content
           ; memcpy(0xA8000, 0x38000, 0x8000);
           pushd 0x8000          ; count
           pushd 0x38000         ; source
           pushd 0xA8000         ; target
           call memcpy32
           add  sp,12
           
           ; copy the SMM relocation code
           ; memcpy(0x38000, &smm_relocation_start, &smm_relocation_end - &smm_relocation_start);
           push word cs:[smm_relocation_start_sz]
           push BIOS_BASE        ; source seg
           push offset smm_relocation_start
           push 0x3800           ; targ seg
           push 0x0000           ; targ off
           call memcpy16
           add  sp,10
           
           ; enable SMI generation when writing to the APMC register
           mov  bx,0x58
           mov  eax,ecx
           or   eax,(1 << 25)
           call pci_config_write_dword
           
           ; init APM status port
           mov  al,0x01
           out  0xB3,al
           
           ; raise an SMI interrupt
           mov  al,0x00
           out  0xB2,al
           
           ; wait until SMM code executed
@@:        in   al,0xB3
           or   al,al
           jnz  short @b
           
           ; restore original memory content
           ; memcpy(0x38000, 0xa8000, 0x8000);
           pushd 0x8000          ; count
           pushd 0xA8000         ; source
           pushd 0x38000         ; target
           call memcpy32
           add  sp,12
           
           ; copy the SMM code
           ; memcpy(0xA8000, &smm_code_start, &smm_code_end - &smm_code_start);
           push word cs:[smm_code_start_sz]
           push BIOS_BASE        ; source seg
           push offset smm_code_start
           push 0xA800           ; targ seg
           push 0x0000           ; targ off
           call memcpy16
           add  sp,10
           
           wbinvd
           
           ; close the SMM memory window and enable normal SMM
           push dx
           mov  dx,[EBDA_DATA->i440_pcidev]
           mov  bx,0x72
           mov  al,(0x02 | 0x08)
           call pci_config_write_byte
           pop  dx
           
smm_init_done:
           ret
smm_init   endp

.endif  ; DO_INIT_BIOS32

.end
