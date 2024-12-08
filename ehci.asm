comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: ehci.asm                                                           *
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
*   ehci include file                                                      *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

.if DO_INIT_BIOS32

EHCI_CAP_REGS struct
  EHcCaps              dword
  EHcHCSParams         dword
  EHcHCCParams         dword
  EHcHCSPPortRoute     qword
EHCI_CAP_REGS ends

EHCI_OP_REGS struct
  EHcOPS_USBCommand    dword
  EHcOPS_USBStatus     dword
  EHcOPS_USBInterrupt  dword
  EHcOPS_FrameIndex    dword
  EHcOPS_CtrlDSSegment dword
  EHcOPS_PeriodicList  dword
  EHcOPS_AsyncList     dword
  EHcOPS_reserved      dup 36
  EHcOPS_ConfigFlag    dword
  EHcOPS_PortStatus    dword  ; first port
EHCI_OP_REGS ends

EHC_OPS_STATUS_ASYN_ENABLE  equ (1 <<15)
EHC_OPS_STATUS_ASYN_ADDV    equ (1 << 5)
EHC_OPS_STATUS_SYS_ERROR    equ (1 << 4)
EHC_OPS_STATUS_ROLL_OVER    equ (1 << 3)
EHC_OPS_STATUS_PORT_CHANGE  equ (1 << 2)
EHC_OPS_STATUS_ERROR        equ (1 << 1)
EHC_OPS_STATUS_INTERRUPT    equ (1 << 0)
EHC_OPS_STATUS_IRQ_FLAGS    equ (EHC_OPS_STATUS_SYS_ERROR | EHC_OPS_STATUS_PORT_CHANGE | EHC_OPS_STATUS_ERROR | EHC_OPS_STATUS_INTERRUPT)
EHC_OPS_STATUS_WC_FLAGS     equ (EHC_OPS_STATUS_ASYN_ADDV | EHC_OPS_STATUS_SYS_ERROR | EHC_OPS_STATUS_ROLL_OVER | EHC_OPS_STATUS_PORT_CHANGE | EHC_OPS_STATUS_ERROR | EHC_OPS_STATUS_INTERRUPT)

EHCI_PORT_WRITE_MASK     equ  0x007FF1EE
EHCI_PORT_CCS            equ (1<<0)
EHCI_PORT_CSC            equ (1<<1)
EHCI_PORT_ENABLED        equ (1<<2)
EHCI_PORT_ENABLE_C       equ (1<<3)
EHCI_PORT_OVER_CUR       equ (1<<4)
EHCI_PORT_OVER_CUR_C     equ (1<<5)
EHCI_PORT_RESET_BIT      equ (1<<8)
EHCI_PORT_LINE_STATUS    equ (3<<10)
EHCI_PORT_PP             equ (1<<12)
EHCI_PORT_OWNER          equ (1<<13)

EHC_LEGACY_USBLEGSUP     equ 0x00
EHC_LEGACY_USBLEGCTLSTS  equ 0x04
EHC_LEGACY_USBLEGSPCL    equ 0x08

EHCI_MEMORY_SIZE   equ  (4288 * USB_DEVICE_MAX)
EHCI_MEMORY_ALIGN  equ  4096

EHCI_PTR_T0       equ  (0<<0)
EHCI_PTR_T1       equ  (1<<0)
EHCI_PTR_Q        equ  (01b<<1)
EHCI_QH_HS_HEAD   equ  (1<<15)   ; Head of Queue

EHCI_QTD_TOGGLE0  equ  (0<<31)
EHCI_QTD_TOGGLE1  equ  (1<<31)

EHCI_STATUS_ACTIVE  equ (1 << 7)

EHCI_TOKEN_OUT    equ  0
EHCI_TOKEN_IN     equ  1
EHCI_TOKEN_SETUP  equ  2

; HC uses the first 48 (68 if 64-bit) bytes
;  but: each queue must be 32 byte aligned
;  and: we would like it to be a multiple of 64 bytes
;   so: the remaining 60 bytes is scratch space
QUEUE_HEAD_HS struct  ; 128 bytes
	horz_ptr            dword  ;
  endpt_caps          dword  ;
  hub_info            dword  ;
  cur_qTD_ptr         dword  ;
  next_qTD_ptr        dword  ;
  alt_next_qTD_ptr    dword  ;
  status              dword  ;
  buff0_ptr           dword  ;
  buff1_ptr           dword  ;
  buff2_ptr           dword  ;
  buff3_ptr           dword  ;
  buff4_ptr           dword  ;
  buff0_hi            dword  ;
  buff1_hi            dword  ;
  buff2_hi            dword  ;
  buff3_hi            dword  ;
  buff4_hi            dword  ;
  ; HC Driver used space
  first_qTD_ptr       dword  ;  first TD of Queue
  resv0               dup 56 ;
QUEUE_HEAD_HS ends

QUEUE_TD_HS struct ; 64 bytes
  next_qTD_ptr        dword  ;
  alt_next_qTD_ptr    dword  ;
  status              dword  ;
  buff0_ptr           dword  ;
  buff1_ptr           dword  ;
  buff2_ptr           dword  ;
  buff3_ptr           dword  ;
  buff4_ptr           dword  ;
  buff0_hi            dword  ;
  buff1_hi            dword  ;
  buff2_hi            dword  ;
  buff3_hi            dword  ;
  buff4_hi            dword  ;
  our_size            dword  ;
  resv                dup 8  ;
QUEUE_TD_HS ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a ehci controller via the PCI services
; on entry:
;  es -> EBDA
; on return
;  nothing
; destroys none
init_ehci_boot  proc near uses alld
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to detect a EHCI by finding a EHCI PCI controller
           xor  esi,esi
ehci_cntrlr_detection:
           push esi
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00001100_00000011_00100000b
           mov  ax,0xB103
           int  1Ah
           pop  esi
           jc   init_ehci_boot_done

           ; found a EHCI controller, so initialize it
           call ehci_initialize
           jc   init_ehci_boot_next

           ; initialize the stack
           call ehci_stack_initialize

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if there are any devices present and enumerate them
           xor  edx,edx
           ; point to our controller's block memory (use es:esi+USB_CONTROLLER->)
           push esi
           mov  ebp,esi          ; save the controller index in ebp
           imul esi,sizeof(USB_CONTROLLER)
           add  esi,EBDA_DATA->usb_ehci_cntrls

           ; initialize our callback pointers
           mov  word es:[esi+USB_CONTROLLER->callback_bulk],offset ehci_do_bulk_packet
           mov  word es:[esi+USB_CONTROLLER->callback_control],offset ehci_control_packet
           mov  byte es:[esi+USB_CONTROLLER->device_cnt],0

           ; we should now have a running schedule and all ports are owned by us.
ehci_dev_detection:
           ; reset a port.
           call ehci_port_reset
           ;  If it is a high-speed device, we returned al = 1
           ;  If it is a full- or low-speed device, we returned al = 0
           ;  (but have already handed over the device to a companion)
           ;  If no device attached, we returned al = 0
           or   al,al
           jz   short @f

           ; allocate the devices memory block
           movzx ebx,byte es:[esi+USB_CONTROLLER->device_cnt]
           imul ebx,sizeof(dword)
           add  ebx,USB_CONTROLLER->device_data
           add  ebx,esi
           mov  eax,sizeof(USB_DEVICE)
           mov  ecx,1
           ;push dx
           ;mov  dx,offset mem_ehci_device_data
           call memory_allocate
           ;pop  dx
           mov  es:[ebx],eax
           mov  ebx,eax
           
           mov  al,es:[esi+USB_CONTROLLER->device_cnt]
           mov  fs:[ebx+USB_DEVICE->device_num],al
           
           ; we have something connected and enabled
           call ehci_enumerate
           or   ax,ax
           jnz  short @f

           ; mark the controller type (and index)
           mov  ax,bp            ; controller index
           shl  al,4             ; index is in bits 5:4
           or   al,USB_CONTROLLER_EHCI
           mov  fs:[ebx+USB_DEVICE->controller],al
           
           ; mount the drive
           call usb_mount_device
           or   al,al
           jz   short @f

           ; increment the count of devices found
           inc  byte es:[esi+USB_CONTROLLER->device_cnt]
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],USB_DEVICE_MAX
           je   short ehci_dev_detection0

           ; try the next port
@@:        inc  edx
           movzx eax,byte es:[esi+USB_CONTROLLER->numports]
           cmp  edx,eax
           jb   short ehci_dev_detection

           ; if no devices found, stop the controller
ehci_dev_detection0:
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],0
           jne  short @f
           mov  edi,es:[esi+USB_CONTROLLER->base]
           movzx edx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],0
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_ConfigFlag],0

           ; and free the allocated memory
           mov  eax,es:[esi+USB_CONTROLLER->base_memory]
           or   eax,eax
           jz   short @f
           call memory_free

           ; loop so that we can see if there are any more
@@:        pop  esi
init_ehci_boot_next:
           inc  esi
           cmp  esi,MAX_USB_CONTROLLERS
           jb   ehci_cntrlr_detection

init_ehci_boot_done:
           ret
init_ehci_boot  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the found ehci controller
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  si = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  carry clear if successful
; destroys none
ehci_initialize proc near uses alld ds
           
           ; the EHCI is memmapped, so find the address
           mov  ax,0xB10A
           mov  di,0x10
           int  1Ah
           ; is it Port IO?
           test cl,1
           jnz  ehci_initialize_error
           and  cl,(~0xF)
           mov  edi,ecx          ; save the base in edi
           
           ; make sure IO is allowed
           push edi
           mov  ax,0xB109
           mov  di,0x04
           int  1Ah
           or   cx,6             ; memory io and busmaster enable
           mov  ax,0xB10C
           mov  di,0x04
           int  1Ah
           pop  edi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure legacy is turned off
           call ehci_disable_legacy
           jc   ehci_initialize_error

           ; check that the version is something we know
           mov  edx,fs:[edi+EHCI_CAP_REGS->EHcCaps]
           shr  edx,16
           cmp  dx,0x0100
           jne  ehci_initialize_error
           
           ; check that the Ops offset is valid
           ; must be at least 0x10 and paragraph aligned
           mov  edx,fs:[edi+EHCI_CAP_REGS->EHcCaps]
           and  edx,0x000000FF
           cmp  dl,0x10
           jb   ehci_initialize_error
           test dl,0x03
           jnz  ehci_initialize_error

           ; edi -> caps register, edx is OPS offset
           ; make sure the run/stop bit is clear
           and  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],(~(1<<0))
           
           ; set the reset bit and wait for it to clear
           or   dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],(1<<1)
@@:        test dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],(1<<1)
           jnz  short @b

           ; check that bit 19 is set, remaining are zero, ignoring bits 11,9,and 8
           mov  eax,fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand]
           and  eax,(~0x00000B00)
           cmp  eax,0x00080000
           jne  ehci_initialize_error
           
           ; check that bit 12 is set in the status register
           test dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBStatus],(1<<12)
           jz   ehci_initialize_error
           
           ; remaining registers should all be zero
           cmp  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBInterrupt],0
           jne  ehci_initialize_error
           cmp  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_FrameIndex],0
           jne  ehci_initialize_error
           cmp  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_CtrlDSSegment],0
           jne  ehci_initialize_error
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; has the user (setup, cmos, etc) turned off EHCI?
           cmp  byte es:[EBDA_DATA->usb_ehci_legacy],1
           jne  short @f

           ; after the reset above, the Config register will be zero,
           ;  directing all devices to the companion controllers

           ; print that we found a EHCI, but turned over to the companions.
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  eax,fs:[edi+EHCI_CAP_REGS->EHcHCSParams]
           mov  bx,ax
           shr  ax,8             ; number of ports per companion controller
           and  ax,0x000F
           push ax
           shr  bx,12            ; number of companion controllers
           push bx
           push edi
           mov  si,offset ehci_found_str1
           call bios_printf
           add  sp,8
           
           ; we are done enumerating the ehci...
           jmp  short ehci_initialize_error

@@:        ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; start to save information
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_ehci_cntrls
           
           mov  byte es:[si+USB_CONTROLLER->valid],0  ; not valid for now
           mov  es:[si+USB_CONTROLLER->busdevfunc],bx
           mov  es:[si+USB_CONTROLLER->base],edi
           mov  byte es:[si+USB_CONTROLLER->flags],0
           mov  es:[si+USB_CONTROLLER->op_reg_offset],dl

           ; get the irq
           push edi
           mov  ax,0xB108
           mov  di,0x3C
           int  1Ah
           mov  es:[si+USB_CONTROLLER->irq],cl
           pop  edi
           
           ; get the count of ports
           mov  eax,fs:[edi+EHCI_CAP_REGS->EHcHCSParams]
           and  al,0x0F
           mov  es:[si+USB_CONTROLLER->numports],al

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have found and initialized a EHCI
           ; (allocate some memory for it)
           mov  eax,EHCI_MEMORY_SIZE
           mov  ecx,EHCI_MEMORY_ALIGN
           ;push dx
           ;mov  dx,offset mem_ehci_stack
           call memory_allocate
           ;pop  dx
           mov  es:[si+USB_CONTROLLER->base_memory],eax

           ; mark this information valid
           mov  byte es:[si+USB_CONTROLLER->valid],1
           
           ; print that we found a EHCI
           mov  ax,BIOS_BASE2
           mov  ds,ax
           push dword es:[si+USB_CONTROLLER->base_memory]
           movzx ax,byte es:[si+USB_CONTROLLER->irq]
           push ax
           movzx ax,byte es:[si+USB_CONTROLLER->numports]
           push ax
           push dword es:[si+USB_CONTROLLER->base]
           mov  si,offset ehci_found_str0
           call bios_printf
           add  sp,12

           ; successful return
           clc
           ret

ehci_initialize_error:
           stc
           ret
ehci_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; turn off legacy support
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  esi = 0 for first controller, 1 for second, 2 for third, etc
;  fs:edi -> mem mapped register set
; on return
;  carry if not released
; destroys none
ehci_disable_legacy proc near uses eax edi
           mov  eax,fs:[edi+EHCI_CAP_REGS->EHcHCCParams]
           shr  ax,8

           ; must be at least at offset 0x0040
           cmp  ax,0x0040
           jb   short ehci_disable_legacy_done

           ; read the legacy support register
           push ax               ; save the eecp offset
           add  ax,EHC_LEGACY_USBLEGSUP
           mov  di,ax
           mov  ax,0xB10A
           int  1Ah
           pop  ax               ; restore the eecp offset

           ; is this the legacy cap register?
           cmp  cl,0x01          ; 1 = legacy cap register
           jne  short ehci_disable_legacy_done

           ; write 0 to the legacy control/status register to
           ;  disable all SMI interrupts for this device
           xor  ecx,ecx
           add  ax,EHC_LEGACY_USBLEGCTLSTS
           mov  di,ax
           mov  ax,0xB10D
           int  1Ah
           
           clc
           ret

ehci_disable_legacy_done:
           stc
           ret
ehci_disable_legacy endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the ehci's stack
; (we don't need periodical, only control/bulk, ie. the async list)
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  si = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  nothing
; destroys none
;
;  since we do not need a periodical stack, we simply have a round robin style
;   strings of Queue Heads. This string of Queue Heads has one Queue Head
;   for each device we will support (USB_DEVICE_MAX).
;  we then point each Queue Head to the next, with that last pointed to the first.
;  the TD pointer of these QHs will be temporarily marked TERM.
;  each of these QHs will have enough room allocated for a single
;   TD for the alt_pointer (Short Packet TD), and 512/8 = 64 TDs for the cur/next pointers.
;   (this allows any device with 512-byte sectors and an 8 byte packet, or
;    this allows any device with 2048-byte sectors and a 32 byte packet)
;  when a transaction is needed, the QH's pointers will be pointed to these TD's
;  each QH is aligned on a 128-byte boundary.
;  each TD is aligned on a 64-byte boundary.
;
; /-->[queue head]
; |     [alt pointer]-->[Transfer Desc_SPD]
; |     [cur pointer]----\
; |      |                |
; |   [queue head]->    [Transfer Desc_0]
; |      |                |
; |   [queue head]->    [Transfer Desc_1]
; |      |                |
; \<--[queue head]->    [Transfer Desc_2]
;                         |
;                       [Transfer Desc_3]
;                         |
;                       [Transfer Desc_4]
;                         ...
;                       [Transfer Desc_X]
;
; USB_DEVICE_MAX * 128 bytes for the QHs:             USB_DEVICE_MAX * 128
; USB_DEVICE_MAX * 64 bytes for the Short Packet TD:  USB_DEVICE_MAX * 64
; USB_DEVICE_MAX * 64 * (512 / 8) bytes for TDs:      USB_DEVICE_MAX * 64 * (512 / 8)
;                                                    --------------------------------
;                                                      (4 * 1024) + 
;                                                      ((128 + 64 + (64 * (512 / 8))) * USB_DEVICE_MAX
;                                                    --------------------------------
;                            total bytes allocated:    (4288 * USB_DEVICE_MAX) = EHCI_MEMORY_SIZE
;
ehci_stack_initialize proc near uses alld
           ; point to our controller's block memory
           imul si,sizeof(USB_CONTROLLER)
           add  si,EBDA_DATA->usb_ehci_cntrls

           ; aligned memory starts here
           mov  edi,es:[si+USB_CONTROLLER->base_memory]

           ; calculate the address to the first TD for the first QH
           lea  ebx,[edi+(sizeof(QUEUE_HEAD_HS) * USB_DEVICE_MAX)]

           ; create QH String (a count of USB_DEVICE_MAX QHs)
           mov  edx,edi          ; edx -> first QH
           lea  eax,[edi + sizeof(QUEUE_HEAD_HS)]   ; pointer to next QH
           or   eax,(EHCI_PTR_Q | EHCI_PTR_T0)
           mov  ebp,EHCI_QH_HS_HEAD ; first one is the HEAD
           mov  cx,USB_DEVICE_MAX
@@:        mov  fs:[edi+QUEUE_HEAD_HS->horz_ptr],eax
           mov  fs:[edi+QUEUE_HEAD_HS->endpt_caps],ebp
           mov  dword fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],EHCI_PTR_T1
           mov  dword fs:[edi+QUEUE_HEAD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           mov  fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr],ebx
           add  ebx,(sizeof(QUEUE_TD_HS) + (64 * sizeof(QUEUE_TD_HS)))
           add  edi,sizeof(QUEUE_HEAD_HS)
           add  eax,sizeof(QUEUE_HEAD_HS)
           xor  ebp,ebp
           loop @b
           ; point last QH to first QH
           sub  edi,sizeof(QUEUE_HEAD_HS)
           or   edx,(EHCI_PTR_Q | EHCI_PTR_T0)
           mov  fs:[edi+QUEUE_HEAD_HS->horz_ptr],edx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now there is enough room for each QH to have a single 
           ;  SPD TD (pointed to by the alt_next_TD pointer) and up 
           ;  to 64 regular TDs (pointed to by the next_TD pointer)
           ; writemem "C:\bochs\images\win95\dd.bin" 0x1FFB1000 512
           ;xchg cx,cx
           ;mov  eax,es:[si+USB_CONTROLLER->base_memory]

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now point the controller to this ascyn list and start the controller
           mov  edi,es:[si+USB_CONTROLLER->base]
           movzx edx,byte es:[si+USB_CONTROLLER->op_reg_offset]
           ;test dword fs:[edi+EHCI_CAP_REGS->EHcHCCParams],(1<<0)
           ;jz   short @f
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_CtrlDSSegment],0
@@:        mov  eax,es:[si+USB_CONTROLLER->base_memory]
           mov  fs:[edi+edx+EHCI_OP_REGS->EHcOPS_AsyncList],eax
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_FrameIndex],0
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBInterrupt],0
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBStatus],EHC_OPS_STATUS_WC_FLAGS
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],((8<<16) | (1<<5) | (1<<0))

           ; make sure and set bit 0 in Config register
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_ConfigFlag],1

           ret
ehci_stack_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a ehci port
; on entry:
;  es -> EBDA
;  edx = port number (0 or 1)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  al = 1 = port connected/enabled as a high-speed device
;     = 0 = no device attached, or is a full-, low-speed and was handed to the companion controller.
; destroys none
ehci_port_reset proc near uses edx edi

           ; calculate which port it is
           mov  edi,es:[esi+USB_CONTROLLER->base]
           imul edx,sizeof(dword)
           movzx ecx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           add  edx,ecx
           add  edx,EHCI_OP_REGS->EHcOPS_PortStatus

           ; clear the enable bit and status change bits (making sure the PP is set)
           or   dword fs:[edi+edx],(EHCI_PORT_PP | EHCI_PORT_OVER_CUR_C | EHCI_PORT_ENABLE_C | EHCI_PORT_CSC)

           ; read the port and see if a device is attached
           ; CCS = 1 and PORT_LINE_STATUS = 01b
           mov  eax,fs:[edi+edx]
           test eax,EHCI_PORT_CCS
           jz   short @f
           and  ax,EHCI_PORT_LINE_STATUS
           cmp  ax,(01b << 10)
           je   short @f
           
           ; set bit 8 clearing bit 2
           mov  eax,fs:[edi+edx]
           and  eax,(~EHCI_PORT_ENABLED)
           or   eax,EHCI_PORT_RESET_BIT
           mov  fs:[edi+edx],eax

           mov  eax,50
           call mdelay

           ; clear the reset, leaving the power bit set
           and  dword fs:[edi+edx],(~EHCI_PORT_RESET_BIT)

           mov  eax,3
           call mdelay

@@:        ; if the CCS bit is clear, nothing attached
           mov  eax,fs:[edi+edx]
           test eax,EHCI_PORT_CCS
           jz   short ehci_port_reset_empty

           ; if after the reset, if the enable bit is zero, we have a full- or low- speed attached
           test eax,EHCI_PORT_ENABLED
           jz   short @f

           ; else, we have a high-speed device attached
           ; clear the status bits and return good reset
           mov  eax,fs:[edi+edx]
           and  eax,EHCI_PORT_WRITE_MASK
           mov  fs:[edi+edx],eax
           jmp  short ehci_port_reset_good

           ; we must have a full- or low-speed device attached
@@:        mov  dword fs:[edi+edx],0

           mov  eax,10
           call mdelay

           ; set the owner bit
           mov  dword fs:[edi+edx],EHCI_PORT_OWNER

           ; now wait for the owner bit to be set, and the CCS bit to clear
@@:        mov  eax,fs:[edi+edx]
           and  eax,(EHCI_PORT_OWNER | EHCI_PORT_CCS)
           cmp  eax,EHCI_PORT_OWNER
           jne  short @b

           ; nothing connected and/or did not enable (or is a full- or low-speed device)
ehci_port_reset_empty:
           xor  al,al
           ret

           ; connected and enabled
ehci_port_reset_good:
           mov  al,1
           ret
ehci_port_reset endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; enumerate a connected device
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
ehci_enumerate proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

ehci_tx_buffer_0    equ  [bp-4]
           
           ; get the address to our return buffer
           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  ehci_tx_buffer_0,eax ; save for later
           
           ; we wouldn't have gotten here if it wasn't a high-speed device
           mov  byte fs:[ebx+USB_DEVICE->speed],2 ; high-speed device
           mov  word fs:[ebx+USB_DEVICE->mps],64
           mov  cx,64            ; count of bytes to transfer (should only return 18)
           mov  byte fs:[ebx+USB_DEVICE->dev_addr],0
           
           ; get the devices descriptor
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call ehci_control_packet
           ; if we didn't return at least 8 bytes, there was an error
           cmp  eax,8
           jl   ehci_enumerate_done

           ; get the max packet size for this device
           mov  edi,ehci_tx_buffer_0
           call usb_get_mps
           mov  fs:[ebx+USB_DEVICE->mps],ax

           call ehci_port_reset

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the address of the device
           call usb_get_address_id
           mov  cl,0x05          ; request = 0x05 = set address
           call ehci_set_attribute
           cmp  eax,-1
           jle  short ehci_enumerate_done
           mov  fs:[ebx+USB_DEVICE->dev_addr],al

           ; get the devices descriptor
           mov  cx,18
           mov  edi,offset request_device_str
           mov  al,PID_IN
           call ehci_control_packet
           ; if we didn't return 18 bytes, there was an error
           cmp  eax,18
           jl   short ehci_enumerate_done

           ; if the class and subclass are not 0x00 & 0x00, then return
           mov  edi,ehci_tx_buffer_0
           cmp  word fs:[edi+4],0x0000   ; class and subclass == 0 ?
           jne  short ehci_enumerate_done

           ; we need to get the configuration descriptor
           mov  cx,512
           mov  edi,offset request_config_str
           mov  al,PID_IN
           call ehci_control_packet
           ; if returned -1, error
           cmp  eax,-1
           jle  short ehci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now find the interface descriptor 
           ; check the class (08), subclass (06), and protocol (0x50)  BBB
           ; check the class (08), subclass (06), and protocol (0x62)  UASP
           ; check the class (08), subclass (04), and protocol (0x50)  CB(i) with BBB
           ; check the class (08), subclass (04), and protocol (0x01)  CBI
           ; check the class (08), subclass (04), and protocol (0x00)  CB
           ; and if so, retreive the device data
           mov  edi,ehci_tx_buffer_0    ; start address of config desc
           mov  cx,ax              ; length of config descriptor
           call usb_configure_device
           cmp  ax,2               ; must have at least 2 bulk endpoints found
           jb   short ehci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now send the Set Configuration Request
           movzx ax,byte fs:[edi + 5] ; configuration value
           mov  cl,0x09          ; request = 0x09 = set configuration
           call ehci_set_attribute
           cmp  eax,-1
           jle  short ehci_enumerate_done

           ; return good enumeration
           xor  ax,ax
           mov  sp,bp
           pop  bp
           ret

ehci_enumerate_done:
           mov  ax,-1
           mov  sp,bp
           pop  bp
           ret
ehci_enumerate endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a control transfer to the controller
; on entry:
;  es -> EBDA
;  al = direction (PID_IN or PID_OUT)
;  cx = length of bytes to request
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  cs:edi -> request packet to send
;  fs:ebx -> USB_DEVICE
; on return
;  eax = size of buffer received
;      = negative value if error
; destroys none
ehci_control_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,20

ehci_ct_running_cnt    equ  [bp-2]
ehci_ct_tx_buffer      equ  [bp-6]
ehci_ct_requ_buffer    equ  [bp-10]
ehci_ct_requ_packet    equ  [bp-14]
ehci_ct_first_td       equ  [bp-18]
ehci_ct_direction      equ  [bp-19]

           ; save some items
           mov  ehci_ct_running_cnt,cx
           mov  ehci_ct_requ_packet,edi

           ; determine the direction
           mov  byte ehci_ct_direction,EHCI_TOKEN_IN
           cmp  al,PID_IN
           je   short @f
           mov  byte ehci_ct_direction,EHCI_TOKEN_OUT

@@:        lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  ehci_ct_tx_buffer,eax
           lea  eax,[ebx+USB_DEVICE->request]
           mov  ehci_ct_requ_buffer,eax

           ; get the devices async list
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           imul eax,sizeof(QUEUE_HEAD_HS)
           add  edi,eax          ; edi now points to this device's QH
           push edi              ; save it

           ; get the address to the first TD for this QH
           mov  edi,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           mov  ehci_ct_first_td,edi
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create STATUS TD
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32
           mov  dword fs:[edi+QUEUE_TD_HS->next_qTD_ptr],EHCI_PTR_T1
           mov  dword fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           movzx eax,byte ehci_ct_direction
           xor  al,1             ; opposite
           shl  eax,8            ; direction at bit 8
           or   eax,(EHCI_QTD_TOGGLE1 | (0 << 16) | (0<<15) | (0<<12) | (3<<10) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  dword fs:[edi+QUEUE_TD_HS->our_size],0
           add  edi,sizeof(QUEUE_TD_HS)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP TD
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32
           mov  eax,edi
           add  eax,sizeof(QUEUE_TD_HS)
           mov  fs:[edi+QUEUE_TD_HS->next_qTD_ptr],eax
           mov  dword fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           mov  eax,(EHCI_QTD_TOGGLE0 | (8 << 16) | (0<<15) | (0<<12) | (3<<10) | (EHCI_TOKEN_SETUP << 8) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  eax,ehci_ct_requ_buffer
           mov  fs:[edi+QUEUE_TD_HS->buff0_ptr],eax
           add  eax,0x1000
           and  eax,0xFFFFF000
           mov  fs:[edi+QUEUE_TD_HS->buff1_ptr],eax
           mov  dword fs:[edi+QUEUE_TD_HS->our_size],8
           add  edi,sizeof(QUEUE_TD_HS)
           
           ; create request packet
           push esi
           mov  esi,ehci_ct_requ_packet
           mov  eax,ehci_ct_requ_buffer
           mov  ecx,cs:[esi+0]
           mov  fs:[eax+0],ecx
           mov  cx,cs:[esi+4]
           mov  fs:[eax+4],cx
           mov  cx,ehci_ct_running_cnt
           mov  fs:[eax+6],cx          ; length
           pop  esi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create IN/OUT TD(s)
           mov  edx,EHCI_QTD_TOGGLE1  ; toggle bit (1 for first IN/OUT after the SETUP)
ehci_td_loop0:
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32

           mov  cx,ehci_ct_running_cnt
           cmp  cx,fs:[ebx+USB_DEVICE->mps]
           jbe  short @f
           mov  cx,fs:[ebx+USB_DEVICE->mps]
@@:        sub  ehci_ct_running_cnt,cx
           mov  fs:[edi+QUEUE_TD_HS->our_size],cx
           mov  eax,edi
           add  eax,sizeof(QUEUE_TD_HS)
           mov  fs:[edi+QUEUE_TD_HS->next_qTD_ptr],eax
           mov  eax,ehci_ct_first_td
           mov  fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],eax
           movzx eax,byte ehci_ct_direction
           shl  eax,8            ; direction at bit 8
           or   eax,edx          ; include the toggle bit
           shl  ecx,16           ; count is at bit 16
           or   eax,ecx          ;
           or   eax,((0<<15) | (0<<12) | (3<<10) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  eax,ehci_ct_tx_buffer
           mov  fs:[edi+QUEUE_TD_HS->buff0_ptr],eax
           add  eax,0x1000
           and  eax,0xFFFFF000
           mov  fs:[edi+QUEUE_TD_HS->buff1_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff2_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff3_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff4_ptr],eax           
           movzx eax,word fs:[ebx+USB_DEVICE->mps]
           add  ehci_ct_tx_buffer,eax

           add  edi,sizeof(QUEUE_TD_HS) ; move to next TD
           xor  edx,EHCI_QTD_TOGGLE1    ; toggle bit

           cmp  word ehci_ct_running_cnt,0
           ja   ehci_td_loop0

           ; back up and mark the last IN/OUT TD to point to the STATUS TD
           sub  edi,sizeof(QUEUE_TD_HS)
           mov  eax,ehci_ct_first_td
           mov  fs:[edi+QUEUE_TD_HS->next_qTD_ptr],eax

           ; restore pointer to the QH
           pop  edi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Build the QH
           and  dword fs:[edi+QUEUE_HEAD_HS->endpt_caps],EHCI_QH_HS_HEAD
           movzx eax,word fs:[ebx+USB_DEVICE->mps]
           shl  eax,16
           mov  al,fs:[ebx+USB_DEVICE->dev_addr]
           or   eax,((8 << 28) | (1 << 14) | (2 << 12)) ; RL = 8, dtc = 1, EPS = high-speed
           or   fs:[edi+QUEUE_HEAD_HS->endpt_caps],eax
           mov  dword fs:[edi+QUEUE_HEAD_HS->hub_info],(1<<30)
           mov  eax,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           ;mov  fs:[edi+QUEUE_HEAD_HS->alt_next_qTD_ptr],eax
           add  eax,sizeof(QUEUE_TD_HS)
           mov  fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are ready to allow the controller to process our QH and TD's
           wbinvd

           ; wait for the last TD to be processed (the Status TD)
           mov  eax,ehci_ct_first_td
           call ehci_wait_for_complete
           or   eax,eax
           jne  short @f

           ; mark the QH->next_qTD_ptr as TERM again
           ;mov  dword fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],EHCI_PTR_T1
           ;mov  dword fs:[edi+QUEUE_HEAD_HS->alt_next_qTD_ptr],EHCI_PTR_T1

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           mov  al,ehci_ct_direction
           mov  edi,ehci_ct_first_td
           add  edi,sizeof(QUEUE_TD_HS)
           call ehci_check_qh

@@:        mov  sp,bp
           pop  bp
           ret
ehci_control_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a "set attribute" style control out request
; on entry:
;  es -> EBDA
;  ax = value to set the requests 'value' field to
;  cl = request value (5 = set address, 9 = set configuration)
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  eax = passed ax 'value'
;      = negative value if error
; destroys none
ehci_set_attribute proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,8

ehci_ad_value_word     equ  [bp-2]
ehci_ad_request_byte   equ  [bp-4]
ehci_ad_requ_buffer    equ  [bp-8]

           ; save some items
           mov  ehci_ad_value_word,ax
           mov  ehci_ad_request_byte,cl
           lea  eax,[ebx+USB_DEVICE->request]
           mov  ehci_ad_requ_buffer,eax

           ; get the devices async list
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           imul eax,sizeof(QUEUE_HEAD_HS)
           add  edi,eax          ; edi now points to this device's QH
           push edi              ; save it

           ; get the address to the first TD for this QH
           mov  edi,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP TD
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32
           mov  eax,edi
           add  eax,sizeof(QUEUE_TD_HS)
           mov  fs:[edi+QUEUE_TD_HS->next_qTD_ptr],eax
           mov  dword fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           mov  eax,(EHCI_QTD_TOGGLE0 | (8 << 16) | (0<<15) | (0<<12) | (3<<10) | (EHCI_TOKEN_SETUP << 8) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  eax,ehci_ad_requ_buffer
           mov  fs:[edi+QUEUE_TD_HS->buff0_ptr],eax
           add  eax,0x1000
           and  eax,0xFFFFF000
           mov  fs:[edi+QUEUE_TD_HS->buff1_ptr],eax
           mov  dword fs:[edi+QUEUE_TD_HS->our_size],8
           add  edi,sizeof(QUEUE_TD_HS)
           
           ; create request packet
           mov  eax,ehci_ad_requ_buffer
           mov  byte fs:[eax+0],0x00   ; host to device, standard, device
           mov  cl,ehci_ad_request_byte
           mov       fs:[eax+1],cl     ; request value
           mov  cx,ehci_ad_value_word
           mov       fs:[eax+2],cx
           mov  word fs:[eax+4],0      ; index
           mov  word fs:[eax+6],0      ; length

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create STATUS TD
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32
           mov  dword fs:[edi+QUEUE_TD_HS->next_qTD_ptr],EHCI_PTR_T1
           mov  dword fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           mov  eax,(EHCI_QTD_TOGGLE1 | (0 << 16) | (0<<15) | (0<<12) | (3<<10) | (01b<<8) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  dword fs:[edi+QUEUE_TD_HS->our_size],0
           mov  ecx,edi          ; save address of last TD

           ; restore pointer to the QH
           pop  edi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Build the QH
           and  dword fs:[edi+QUEUE_HEAD_HS->endpt_caps],EHCI_QH_HS_HEAD
           movzx eax,word fs:[ebx+USB_DEVICE->mps]
           shl  eax,16
           mov  al,fs:[ebx+USB_DEVICE->dev_addr]
           or   eax,((8 << 28) | (1 << 14) | (2 << 12)) ; RL = 8, dtc = 1, EPS = high-speed
           or   fs:[edi+QUEUE_HEAD_HS->endpt_caps],eax
           mov  dword fs:[edi+QUEUE_HEAD_HS->hub_info],(1<<30)
           mov  eax,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           mov  fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],eax
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are ready to allow the controller to process our QH and TD's
           wbinvd

           ; wait for the last TD to be processed
           mov  eax,ecx          ; ecx -> last TD in this transaction
           call ehci_wait_for_complete
           or   eax,eax
           jne  short @f

           ; mark the QH->next_qTD_ptr as TERM again
           ;mov  dword fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],EHCI_PTR_T1

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           mov  al,0xFF
           mov  edi,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           call ehci_check_qh
           or   eax,eax
           jnz  short @f
           movzx eax,word ehci_ad_value_word

@@:        mov  sp,bp
           pop  bp
           ret
ehci_set_attribute endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a bulk packet
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  cx = size of packet to send
;  dx = unused
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  edi -> physical address of buffer to read/write
; on return
;  eax = bytes sent/received
;      = negative value if error
; destroys none
ehci_do_bulk_packet proc near uses ebx ecx edx esi esi edi
           push bp
           mov  bp,sp
           sub  sp,20

ehci_bk_running_cnt    equ  [bp-2]
ehci_bk_tx_buffer      equ  [bp-6]
ehci_bk_org_vert_addr  equ  [bp-10]
ehci_bk_secondary_qh   equ  [bp-14]
ehci_bk_direction      equ  [bp-16]
ehci_bk_last_td        equ  [bp-20]

           ; save some items
           mov  ehci_bk_running_cnt,cx
           mov  ehci_bk_tx_buffer,edi

           ; determine the direction
           mov  byte ehci_bk_direction,EHCI_TOKEN_IN
           cmp  al,PID_IN
           je   short @f
           mov  byte ehci_bk_direction,EHCI_TOKEN_OUT

@@:        push esi              ; save the USB_CONTROLLER structure pointer
           
           ; get the devices async list
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
           movzx eax,byte fs:[ebx+USB_DEVICE->device_num]
           imul eax,sizeof(QUEUE_HEAD_HS)
           add  edi,eax          ; edi now points to this device's QH
           push edi              ; save it

           ; get the address to the first TD for this QH
           mov  edi,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           
           ; are we doing an in or an out
           lea  esi,[ebx+USB_DEVICE->endpoint_in]
           cmp  byte ehci_bk_direction,EHCI_TOKEN_IN
           je   short @f
           add  esi,sizeof(USB_DEVICE_EP)

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create IN/OUT TD(s)
           ; fs:esi -> endpoint info
@@:        mov  dl,fs:[esi+USB_DEVICE_EP->ep_toggle] ; toggle bit
           shl  edx,31
bk_ehci_td_loop0:
           mov  ax,sizeof(QUEUE_TD_HS)
           call memset32

           mov  cx,ehci_bk_running_cnt
           cmp  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
           jbe  short @f
           mov  cx,fs:[esi+USB_DEVICE_EP->ep_mps]
@@:        sub  ehci_bk_running_cnt,cx
           mov  fs:[edi+QUEUE_TD_HS->our_size],cx
           mov  eax,edi
           add  eax,sizeof(QUEUE_TD_HS)
           mov  fs:[edi+QUEUE_TD_HS->next_qTD_ptr],eax
           mov  dword fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr],EHCI_PTR_T1
           movzx eax,byte ehci_bk_direction
           shl  eax,8            ; direction at bit 8
           or   eax,edx          ; include the toggle bit
           shl  ecx,16           ; count is at bit 16
           or   eax,ecx          ;
           or   eax,((0<<15) | (0<<12) | (3<<10) | 0x80)
           mov  fs:[edi+QUEUE_TD_HS->status],eax
           mov  eax,ehci_bk_tx_buffer
           mov  fs:[edi+QUEUE_TD_HS->buff0_ptr],eax
           add  eax,0x1000
           and  eax,0xFFFFF000
           mov  fs:[edi+QUEUE_TD_HS->buff1_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff2_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff3_ptr],eax
           add  eax,0x1000
           mov  fs:[edi+QUEUE_TD_HS->buff4_ptr],eax           
           movzx eax,word fs:[esi+USB_DEVICE_EP->ep_mps]
           add  ehci_bk_tx_buffer,eax

           add  edi,sizeof(QUEUE_TD_HS) ; move to next TD
           xor  edx,EHCI_QTD_TOGGLE1    ; toggle bit

           cmp  word ehci_bk_running_cnt,0
           ja   bk_ehci_td_loop0

           ; back up and mark the last TD as the last
           sub  edi,sizeof(QUEUE_TD_HS)
           mov  dword fs:[edi+QUEUE_TD_HS->next_qTD_ptr],EHCI_PTR_T1
           mov  ecx,edi          ; save address of last TD
           
           ; save our toggle
           shr  edx,31
           mov  fs:[esi+USB_DEVICE_EP->ep_toggle],dl

           ; restore pointer to the QH
           pop  edi

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Build the QH
           and  dword fs:[edi+QUEUE_HEAD_HS->endpt_caps],EHCI_QH_HS_HEAD
           movzx eax,word fs:[esi+USB_DEVICE_EP->ep_mps]
           shl  eax,16
           mov  ah,fs:[esi+USB_DEVICE_EP->ep_val] ; endpoint value
           mov  al,fs:[ebx+USB_DEVICE->dev_addr]
           or   eax,((8 << 28) | (1 << 14) | (2 << 12)) ; RL = 8, dtc = 1, EPS = high-speed
           or   fs:[edi+QUEUE_HEAD_HS->endpt_caps],eax
           mov  dword fs:[edi+QUEUE_HEAD_HS->hub_info],(1<<30)
           mov  eax,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           mov  fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],eax

           ; restore the USB_CONTROLLER structure pointer
           pop  esi
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we are ready to allow the controller to process our QH and TD's
           wbinvd

           ; wait for the last TD to be processed
           mov  eax,ecx          ; ecx -> last TD in this transaction
           call ehci_wait_for_complete
           or   eax,eax
           jne  short @f

           ; mark the QH->next_qTD_ptr as TERM again
           mov  dword fs:[edi+QUEUE_HEAD_HS->next_qTD_ptr],EHCI_PTR_T1

           ; we now have a transaction that may or may not have completed successfully
           ; we need to check the TD(s)
           mov  al,ehci_bk_direction
           mov  edi,fs:[edi+QUEUE_HEAD_HS->first_qTD_ptr]
           call ehci_check_qh

@@:        mov  sp,bp
           pop  bp
           ret
ehci_do_bulk_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; check the TDs just executed
;  only check the ones that TD.PID = PID
;  TD.ourflags = 1 is the last to check
; on entry:
;  al = PID (EHCI_TOKEN_IN or EHCI_TOKEN_OUT or 0xFF)
;  fs:edi -> First TD
; on return
;  eax = size received/sent
;      = negative if error found
; destroys none
ehci_check_qh proc near uses ebx ecx edx esi
           mov  dl,al            ; dl = PID to check for
           xor  ebx,ebx          ; count of bytes read or written

ehci_check_loop_0:
           ; next TD to check
           mov  esi,fs:[edi+QUEUE_TD_HS->next_qTD_ptr]

           ; does the PID match our direction?
           mov  eax,fs:[edi+QUEUE_TD_HS->status]
           shr  eax,8
           and  al,0x03
           cmp  al,dl
           jne  short @f
           
           ; was it a successful transfer
           mov  eax,fs:[edi+QUEUE_TD_HS->status]
           test al,0x7E
           jnz  short @f

           ; successful transfer.
           ; the controller subtracts the amount transfered
           ;  from the amount we placed in the TD
           shr  eax,16
           and  eax,0x00007FFF
           mov  ecx,fs:[edi+QUEUE_TD_HS->our_size]
           sub  ecx,eax
           add  ebx,ecx 
           
           ; was it a short packet (any residue?)
           or   eax,eax
           jz   short @f
           mov  esi,fs:[edi+QUEUE_TD_HS->alt_next_qTD_ptr]

@@:        mov  edi,esi
           and  edi,(~0x3F)
           test esi,EHCI_PTR_T1
           jz   short ehci_check_loop_0
           
           mov  eax,ebx
           ret
ehci_check_qh endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; waits for the active bit in the specified TD to be cleared (by the controller)
; (uses a time out just so we don't freeze here)
; on entry:
;  fs:eax -> TD
;  es:esi -> this USB_CONTROLLER structure
; on return
;  eax = 0 if successful
;      = -1 if timed out
;      = status (bits 6:0)
; destroys none
ehci_wait_for_complete proc near uses ecx edx edi
           mov  edi,es:[esi+USB_CONTROLLER->base]
           movzx edx,byte es:[esi+USB_CONTROLLER->op_reg_offset]

           ; ring the doorbell
           or   dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBCommand],(1<<6)

           mov  ecx,0x00FFFFFF
ehci_wait_loop:
           test dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBStatus],EHC_OPS_STATUS_WC_FLAGS
           jz   short @f
           ; we need to clear the STATUS.IAA bit (as well as any others) to acknowledge the interrupt
           mov  dword fs:[edi+edx+EHCI_OP_REGS->EHcOPS_USBStatus],EHC_OPS_STATUS_WC_FLAGS
@@:        test dword fs:[eax+QUEUE_TD_HS->status],EHCI_STATUS_ACTIVE
           jz   short @f
           ; this will pause slightly, make sure the memory is 'intact' and serialize the instruction stream
           ; (however, is this ever the case in Bochs?. Probably does none of these things...)
           ;wbinvd
           dec  ecx
           jnz  short ehci_wait_loop
           
           ;;;; we timed out
           xchg cx,cx

           mov  eax,-1
           ret

           ; if the status == 0, we are good
@@:        mov  eax,fs:[eax+QUEUE_TD_HS->status]
           and  eax,0x000000FE
           ret
ehci_wait_for_complete endp

.endif  ; DO_INIT_BIOS32

.end
