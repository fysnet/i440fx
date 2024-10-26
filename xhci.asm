comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: xhci.asm                                                           *
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
*   xhci include file                                                      *
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

XHCI_CAP_REGS struct
  xHcCaps              dword
  xHcHCSParams1        dword
  xHcHCSParams2        dword
  xHcHCSParams3        dword
  xHcHCCParams1        dword
  xHcDBOffset          dword
  xHcRTSOffset         dword
  xHcHCCParams2        dword
  xHcVTIOSOffset       dword
XHCI_CAP_REGS ends

XHCI_OP_REGS struct
  xHcOPS_USBCommand    dword
  xHcOPS_USBStatus     dword
  xHcOPS_USBPageSize   dword
  xHcOPS_reserved0     dup 8
  xHcOPS_USBDnctrl     dword
  xHcOPS_USBCrcr       qword
  xHcOPS_reserved1     dup 16
  xHcOPS_USBDcbaap     qword
  xHcOPS_USBConfig     dword
XHCI_OP_REGS ends

xHC_OPS_USBPortSt   equ  0x400
xHC_PortUSB_POWER   equ  (1<<9)
xHC_PortUSB_CHANGE_BITS  equ ((1<<17) | (1<<18) | (1<<19) | (1<<20) | (1<<21) | (1<<22))

XHCI_PORT_REGS struct
  xHcPORT_PORTSC       dword
  xHcPORT_PORTPMSC     dword
  xHcPORT_PORTLI       dword
  xHcPORT_PORTresv     dword
XHCI_PORT_REGS ends

xHCI_TRB   struct
  param      qword
  status     dword
  command    dword
xHCI_TRB   ends

xHCI_RING  struct
  address    dword
  cur_trb    dword
  cycle_bit  byte
  resv       dup 3
xHCI_RING  ends

; we only support (need) one segment
xHCI_EVENT_RING struct
  address    dword    ; address of segment table
  first_trb  dword    ; address of first trb in segment
  cur_trb    dword    ; next free trb
  cycle_bit  byte     ;
  table_size byte     ; size of table
  cur_index  byte     ; current index
  resv       dup  5
xHCI_EVENT_RING ends

xHC_INTERRUPTER_IMAN         equ  0x00
xHC_INTERRUPTER_IMAN_IP      equ    (1<<0)
xHC_INTERRUPTER_IMAN_IE      equ    (1<<1)
xHC_INTERRUPTER_IMOD         equ  0x04
xHC_INTERRUPTER_TAB_SIZE     equ  0x08
xHC_INTERRUPTER_RESV         equ  0x0C
xHC_INTERRUPTER_ADDRESS      equ  0x10
xHC_INTERRUPTER_DEQUEUE      equ  0x18
xHC_INTERRUPTER_DEQUEUE_EHB  equ   (1<<3)

.enum  NORMAL=1, SETUP_STAGE, DATA_STAGE, STATUS_STAGE, ISOCH, LINK, EVENT_DATA, NO_OP,           \
       ENABLE_SLOT=9, DISABLE_SLOT, ADDRESS_DEVICE, CONFIG_EP, EVALUATE_CONTEXT, RESET_EP,        \
       STOP_EP=15, SET_TR_DEQUEUE, RESET_DEVICE, FORCE_EVENT, DEG_BANDWIDTH, SET_LAT_TOLERANCE,   \
       GET_PORT_BAND=21, FORCE_HEADER, NO_OP_CMD,                                                 \
       TRANS_EVENT=32, COMMAND_COMPLETION, PORT_STATUS_CHANGE, BANDWIDTH_REQUEST, DOORBELL_EVENT, \
       HOST_CONTROLLER_EVENT=37, DEVICE_NOTIFICATION, MFINDEX_WRAP

; event completion codes
.enum  TRB_SUCCESS=1, DATA_BUFFER_ERROR, BABBLE_DETECTION, TRANSACTION_ERROR, TRB_ERROR, STALL_ERROR,             \
       RESOURCE_ERROR=7, BANDWIDTH_ERROR, NO_SLOTS_ERROR, INVALID_STREAM_TYPE, SLOT_NOT_ENABLED, EP_NOT_ENABLED,  \
       SHORT_PACKET=13, RING_UNDERRUN, RUNG_OVERRUN, VF_EVENT_RING_FULL, PARAMETER_ERROR, BANDWITDH_OVERRUN,      \
       CONTEXT_STATE_ERROR=19, NO_PING_RESPONSE, EVENT_RING_FULL, INCOMPATIBLE_DEVICE, MISSED_SERVICE,            \
       COMMAND_RING_STOPPED=24, COMMAND_ABORTED, STOPPED, STOPPER_LENGTH_ERROR, xRESERVED, ISOCH_BUFFER_OVERRUN,  \
       EVERN_LOST=32, UNDEFINED, INVALID_STREAM_ID, SECONDARY_BANDWIDTH, SPLIT_TRANSACTION

NEC_TRB_TYPE_CMD_COMP  equ  48
NEC_TRB_TYPE_GET_FW    equ  49
NEC_TRB_TYPE_GET_UN    equ  50

TRB_CYCLE_ON          equ  (1<<0)
TRB_CYCLE_OFF         equ  (0<<0)
TRB_TOGGLE_CYCLE_ON   equ  (1<<1)
TRB_TOGGLE_CYCLE_OFF  equ  (0<<1)
TRB_CHAIN_ON          equ  (1<<4)
TRB_CHAIN_OFF         equ  (0<<4)
TRB_IOC_ON            equ  (1<<5)
TRB_IOC_OFF           equ  (0<<5)

XHCI_USB2     equ  0x02
XHCI_USB3     equ  0x03

XHCI_SPEED_FULL   equ  1
XHCI_SPEED_LOW    equ  2
XHCI_SPEED_HIGH   equ  3
XHCI_SPEED_SUPER  equ  4

.enum    xHCI_SLOT_CNTX,   \
         xHCI_CONTROL_EP,  \
         xHCI_EP1_OUT,     \
         xHCI_EP1_IN,      \
         xHCI_EP2_OUT,     \
         xHCI_EP2_IN,      \
         xHCI_EP3_OUT,     \
         xHCI_EP3_IN

; 24 bytes
xHCI_SLOT_CONTEXT struct
  entries           byte
  hub               byte
  mtt               byte
  speed             byte
  route_string      dword
  num_ports         byte
  rh_port_num       byte
  max_exit_latency  byte
  int_target        word
  ttt               byte
  tt_port_num       byte
  tt_hub_slot_id    byte
  slot_state        byte
  device_address    byte
  resvd             dup 6
xHCI_SLOT_CONTEXT ends

; EP State
.enum   EP_STATE_DISABLED, EP_STATE_RUNNING, EP_STATE_HALTED, EP_STATE_STOPPED, EP_STATE_ERROR

; 40 bytes
xHCI_EP_CONTEXT   struct
  interval          byte
  lsa               byte
  max_pstreams      byte
  mult              byte
  hid               byte
  ep_state          byte
  max_packet_size   word
  max_burst_size    word
  ep_type           byte
  cerr              byte
  max_esit_payload  dword
  average_trb_len   word
  ring              dup 12   ; sizeof(xHCI_RING)
  tr_dequeue_pointer dword
  dcs               byte
  resvd             dup 5
xHCI_EP_CONTEXT   ends

xHCI_EVENT_STATUS struct
  count             dword
  status            byte
  resv              dup 3
xHCI_EVENT_STATUS ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; detect a xhci controller via the PCI services
; on entry:
;  es -> EBDA
; on return
;  nothing
; destroys none
init_xhci_boot  proc near uses alld
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; try to detect a xHCI by finding a xHCI PCI controller
           xor  esi,esi
xhci_cntrlr_detection:
           push esi
           ;         unused   class   subclass prog int
           mov  ecx,00000000_00001100_00000011_00110000b
           mov  ax,0xB103
           int  1Ah
           pop  esi
           jc   init_xhci_boot_done
           
           ; found a xHCI controller, so initialize it
           call xhci_initialize
           jc   init_xhci_boot_next

           ; point to our controller's block memory (use es:esi+USB_CONTROLLER->)
           push esi
           mov  ebp,esi          ; save the controller index in ebp
           imul esi,sizeof(USB_CONTROLLER)
           add  esi,EBDA_DATA->usb_xhci_cntrls

           ; set and start the HC schedule
           mov  edi,es:[esi+USB_CONTROLLER->base]
           movzx edx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           mov  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCommand],((1<<3) | (1<<2) | (1<<0))

           ; make sure each port is powered
           test dword fs:[edi+XHCI_CAP_REGS->xHcHCCParams1],(1<<3)
           jz   short xhci_power_done
           movzx cx,byte es:[esi+USB_CONTROLLER->numports]
           add  edx,xHC_OPS_USBPortSt
xhci_power_on:
           test dword fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],xHC_PortUSB_POWER
           jnz  short @f
           mov  dword fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],xHC_PortUSB_POWER
@@:        add  edx,16
           loop xhci_power_on
xhci_power_done:
           
           xor  edx,edx          ; high dword of param
           xor  eax,eax          ; low dword of param
           xor  ebx,ebx          ; status
           mov  ecx,(NEC_TRB_TYPE_GET_FW << 10) ; command
           call xhci_insert_command

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; see if there are any devices present and enumerate them
           xor  edx,edx

           ; initialize our callback pointers
           mov  word es:[esi+USB_CONTROLLER->callback_bulk],offset xhci_do_bulk_packet
           mov  word es:[esi+USB_CONTROLLER->callback_control],offset xhci_control_packet
           mov  byte es:[esi+USB_CONTROLLER->device_cnt],0

           ; retrieve the extended caps
           call xhci_get_ext_caps
           mov  es:[esi+USB_CONTROLLER->base_memory],eax

           ; point to our device struct (use fs:ebx+USB_DEVICE->)
xhci_dev_detection:
           ; get the protocol of this port
           call xhci_get_port_protocol

           mov  bl,al
           call xhci_port_reset
           or   al,al
           jz   short @f

           ; allocate the devices memory block
           push bx               ; save the protocol of this port
           movzx ebx,byte es:[esi+USB_CONTROLLER->device_cnt]
           imul ebx,sizeof(dword)
           add  ebx,esi
           add  ebx,USB_CONTROLLER->device_data
           mov  eax,sizeof(USB_DEVICE)
           mov  ecx,1
           ;push dx
           ;mov  dx,offset mem_xhci_device_data
           call memory_allocate
           ;pop  dx
           mov  es:[ebx],eax
           mov  ebx,eax
           pop  ax               ; restore the protocol of this port
           mov  fs:[ebx+USB_DEVICE->xhci_protocol],al
           
           mov  al,es:[esi+USB_CONTROLLER->device_cnt]
           mov  fs:[ebx+USB_DEVICE->device_num],al

           ; we have to give a default speed, until we determine the speed
           call xhci_default_mps
           mov  fs:[ebx+USB_DEVICE->mps],ax
           mov  fs:[ebx+USB_DEVICE->speed],cl

           ; we have something connected and enabled
           call xhci_get_a_slot
           or   ax,ax
           jnz  short @f

           ; enumerate the device
           call xhci_enumerate
           or   ax,ax
           jnz  short @f
           
           ; mark the controller type (and index)
           mov  ax,bp            ; controller index
           shl  al,4             ; index is in bits 5:4
           or   al,USB_CONTROLLER_XHCI
           mov  fs:[ebx+USB_DEVICE->controller],al
           
           ; mount the drive
           call usb_mount_device
           or   al,al
           jz   short @f
           
           ; increment the count of devices found
           inc  byte es:[esi+USB_CONTROLLER->device_cnt]
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],USB_DEVICE_MAX
           je   short xhci_dev_detection0
           
           ; try the next port
@@:        inc  edx
           movzx eax,byte es:[esi+USB_CONTROLLER->numports]
           cmp  edx,eax
           jb   xhci_dev_detection

           ; if no devices found, stop the controller
xhci_dev_detection0:
           cmp  byte es:[esi+USB_CONTROLLER->device_cnt],0
           jne  short @f
           
           ; simply clear the run bit
           mov  eax,es:[esi+USB_CONTROLLER->base]
           movzx edx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           and  dword fs:[eax+edx+XHCI_OP_REGS->xHcOPS_USBCommand],(~(1<<0))

           ; loop so that we can see if there are any more
@@:        pop  esi
init_xhci_boot_next:
           inc  esi
           cmp  esi,MAX_USB_CONTROLLERS
           jb   xhci_cntrlr_detection

init_xhci_boot_done:
           ret
init_xhci_boot  endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the found xhci controller
; on entry:
;  es -> EBDA
;  bh = bus
;  bl = dev/func
;  esi = 0 for first controller, 1 for second, 2 for third, etc
; on return
;  carry clear if successful
; destroys none
xhci_initialize proc near uses alld ds
           
           ; the xHCI is memmapped, so find the address
           mov  ax,0xB10A
           mov  di,0x10
           int  1Ah
           ; is it Port IO?
           test cl,1
           jnz  xhci_initialize_error
           and  cl,(~0xF)
           push ecx              ; save the base

           ; we need to make sure the high-order dword is zero
           xor  ecx,cx
           mov  ax,0xB10C
           mov  di,0x14
           int  1Ah
           
           pop  edi              ; restore the address in edi

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

           ; start to save information
           imul esi,sizeof(USB_CONTROLLER)
           add  esi,EBDA_DATA->usb_xhci_cntrls
           
           mov  byte es:[esi+USB_CONTROLLER->valid],0  ; not valid for now
           mov  es:[esi+USB_CONTROLLER->busdevfunc],bx
           mov  es:[esi+USB_CONTROLLER->base],edi
           mov  byte es:[esi+USB_CONTROLLER->flags],0

           push edi
           ; get the irq
           mov  ax,0xB108
           mov  di,0x3C
           int  1Ah
           mov  es:[esi+USB_CONTROLLER->irq],cl

           ; we need to write to the FLADJ register
           mov  cl,0x20
           mov  ax,0xB10B
           mov  di,0x61
           int  1Ah
           pop  edi

           ; get the Operational Register Set offset
           mov  edx,fs:[edi+XHCI_CAP_REGS->xHcCaps]
           and  edx,0x000000FF
           cmp  dl,0x20
           jb   xhci_initialize_error
           test dl,0x03
           jnz  xhci_initialize_error
           mov  es:[esi+USB_CONTROLLER->op_reg_offset],dl

           ; make sure the run/stop bit is clear
           and  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCommand],(~(1<<0))

           ; wait for/make sure the Halted bit is set
@@:        test dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus],(1<<0)
           jz   short @b

           ; reset using the HCReset bit
           or   dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCommand],(1<<1)
           ; wait for this bit to be clear
@@:        test dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCommand],(1<<1)
           jnz  short @b
           ; and the CtlrNotReady bit to be clear
           test dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus],(1<<11)
           jnz  short @b

           ; wait for the recovery time
           mov  eax,USB_TRSTRCY
           call mdelay

           ; get context size
           mov  byte es:[esi+USB_CONTROLLER->context_size],32
           mov  ecx,fs:[edi+XHCI_CAP_REGS->xHcHCCParams1]
           test cl,(1<<2)
           jz   short @f
           mov  byte es:[esi+USB_CONTROLLER->context_size],64
           ; do we use 64-bit addressing
@@:        and  cl,(1<<0)
           or   es:[esi+USB_CONTROLLER->flags],cl

           ; check the defaults of the Operation Registers
           cmp  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCommand],0
           jne  xhci_initialize_error
           mov  ecx,fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus]
           and  ecx,(~((1<<4) | (1<<3)))
           cmp  ecx,1
           jne  xhci_initialize_error
           cmp  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBDnctrl],0
           jne  xhci_initialize_error
           cmp  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCrcr],0
           jne  xhci_initialize_error
           cmp  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBDcbaap],0
           jne  xhci_initialize_error
           cmp  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBConfig],0
           jne  xhci_initialize_error
           
           ; get the count of ports
           mov  ecx,fs:[edi+XHCI_CAP_REGS->xHcHCSParams1]
           shr  ecx,24
           mov  es:[esi+USB_CONTROLLER->numports],cl

           ; get the page size
           mov  ecx,fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBPageSize]
           and  ecx,0x0000FFFF
           shl  ecx,12
           mov  es:[esi+USB_CONTROLLER->page_size],cx

           ; get max slots
           mov  ecx,fs:[edi+XHCI_CAP_REGS->xHcHCSParams1]
           mov  es:[esi+USB_CONTROLLER->max_slots],cl
           
           ; get max scratch pad buffers, and allocate the memory for them
           ; this also allocates the DCBAAP buffer
           mov  ecx,fs:[edi+XHCI_CAP_REGS->xHcHCSParams2]
           mov  eax,ecx
           shr  eax,27
           and  ecx,0x03E00000
           shr  ecx,16
           or   eax,ecx
           movzx ecx,word es:[esi+USB_CONTROLLER->page_size]
           call xhci_allocate_scratch
           jc   xhci_initialize_error
           mov  fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBDcbaap+0],eax
           mov  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBDcbaap+4],0
           mov  es:[esi+USB_CONTROLLER->dcbaap_addr],eax
           
           ; allocate the slots
           movzx eax,byte es:[esi+USB_CONTROLLER->max_slots]
           imul eax,(64 * 32)    ; max slots * max slot size * 32 contexts each
           ;push dx
           ;mov  dx,offset mem_xhci_slots
           call memory_allocate  ; ecx still = alignment
           ;pop  dx
           mov  es:[esi+USB_CONTROLLER->slots_buffer],eax

           ; allocate the command ring
           push esi
           lea  esi,[esi+USB_CONTROLLER->command_ring]
           push es               ;
           pop  ax               ;
           movzx eax,ax          ; make the esi pointer a physical address pointer
           shl  eax,4            ;
           add  esi,eax          ;
           mov  eax,32           ; count of TRBs to create
           call xhci_alloc_ring
           pop  esi
           jc   short xhci_initialize_error
           mov  fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCrcr+0],eax
           mov  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBCrcr+4],0

           ; configure register
           movzx eax,byte es:[esi+USB_CONTROLLER->max_slots]
           mov  fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBConfig],eax

           ; Device Notification Control
           mov  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBDnctrl],(1<<1)

           ; initialize the interrupters
           ;mov  eax,fs:[edi+XHCI_CAP_REGS->xHcHCSParams2]
           ;and  eax,0x000000F0
           ;shr  eax,4
           ;mov  es:[esi+USB_CONTROLLER->max_event_segs],al

           ;mov  ecx,fs:[edi+XHCI_CAP_REGS->xHcHCSParams1]
           ;and  ecx,0x0007FF00
           ;shr  ecx,8
           ;mov  es:[esi+USB_CONTROLLER->max_interrupters],cx
           
           ; create the event ring for the interrupter
           push esi
           lea  esi,[esi+USB_CONTROLLER->event_ring]
           mov  eax,64           ; count of TRBs to create
           call xhci_alloc_event_ring
           pop  esi
           
           ; make sure the status register is cleared
           mov  dword fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus],((1<<10) | (1<<4) | (1<<3) | (1<<2))

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we have found and initialized a xHCI
           ; mark this information valid
           mov  byte es:[esi+USB_CONTROLLER->valid],1

           ; print that we found a xHCI
           mov  ax,BIOS_BASE2
           mov  ds,ax
           movzx ax,byte es:[esi+USB_CONTROLLER->irq]
           push ax
           movzx ax,byte es:[esi+USB_CONTROLLER->numports]
           push ax
           push dword es:[esi+USB_CONTROLLER->base]
           mov  si,offset xhci_found_str0
           call bios_printf
           add  sp,8

           ; successful return
           clc
           ret
           
xhci_initialize_error:
           stc
           ret
xhci_initialize endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; allocate the scratch pad area and DCBAAP
; on entry:
;  es -> EBDA
;  fs:edi -> CAPS registers
;  edx = OPS register set offset (edi+edx -> op registers)
;  es:esi -> this USB_CONTROLLER structure
;  eax = count of scratchpad buffers to allocate (could be zero)
;  ecx = page size
; on return
;  carry clear if success
;   eax = DCBAAP buffer address
;  carry set if error
; destroys none
xhci_allocate_scratch proc near uses ebx ecx edx edi

           ; save the count of scratchpad buffers requested
           mov  edx,eax

           ; we only support up to 64 scratch pad buffers,
           ;  and at least a 512-byte alignment.
           cmp  eax,64
           ja   short xhci_allocate_scratch_error
           cmp  ecx,512
           jb   short xhci_allocate_scratch_error
                      
           ; allocate (1 + 1 + eax) * ecx sized buffer ecx aligned 
           ; dcbaap = the start of this buffer
           inc  eax              ; one for the dcbaap
           cmp  eax,1            ; if no scratchpad, only allocate the dcbaap
           je   short @f
           inc  eax              ; one for the scratchpad pointers
@@:        imul eax,ecx
           ;push dx
           ;mov  dx,offset mem_xhci_dcbaap
           call memory_allocate
           ;pop  dx
           
           ; if no scratchpad buffers needed, we are done
           or   edx,edx
           jz   short xhci_allocate_scratch_done

           ; scratchpad = dcbaap + ecx
           ; for (eax) { scratchpad[x] = scrachpad + ecx + (eax[] * 4) }
           lea  edi,[eax+ecx]    ; skip over dcbaap
           mov  fs:[eax+0],edi      ; write the address of the scratchpad to dcbaap[0]
           mov  dword fs:[eax+4],0  ;
           lea  ebx,[edi+ecx]    ; skip over buffer pointer list
@@:        mov  fs:[edi+0],ebx
           mov  dword fs:[edi+4],0
           add  edi,8            ; move to next pointer
           add  ebx,ecx          ; move to next buffer
           dec  edx
           jnz  short @b

           ; success (eax -> buffer)
xhci_allocate_scratch_done:
           clc
           ret

xhci_allocate_scratch_error:
           stc
           ret
xhci_allocate_scratch endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; allocate and create a command style ring
; (must not cross a 64k boundary)
; (must not be more than 64 entries)
; on entry:
;  eax = count of TRBs to include in ring
;  fs:esi -> ring to create (struct xHCI_RING)
; on return
;  carry clear if success
;   eax = value to write to the CRCR register, etc.
;  carry set if error
; destroys none
xhci_alloc_ring proc near uses ebx ecx edx edi

           ; this should be an internal check
           cmp  eax,64
           ja   xhci_alloc_ring_error
           
           ; save count in edx
           mov  edx,eax

           ; only try 4 times
           mov  ebx,4
@@:        mov  eax,edx          ; restore the count
           mov  ecx,64           ; must be 64-byte aligned
           imul eax,sizeof(xHCI_TRB)
           ;push dx
           ;mov  dx,offset mem_xhci_ring
           call memory_allocate
           ;pop  dx

           ; check to see if this address + size crosses a 64k boundary
           imul ecx,edx,sizeof(xHCI_TRB)
           add  ecx,eax
           dec  ecx
           xor  ecx,eax
           test ecx,0x00010000
           jz   short @f

           ; crosses a 64k boundary so try again?
           ; (this will leave the affending buffer allocated)
           ; (but it will be at most 1024 bytes)
           dec  ebx
           jnz  short @b
           jmp  short xhci_alloc_ring_error

           ; found an address (in eax) that is 64-byte aligned and does not cross a 64k boundary
@@:        mov  fs:[esi+xHCI_RING->address],eax
           mov  fs:[esi+xHCI_RING->cur_trb],eax
           mov  byte fs:[esi+xHCI_RING->cycle_bit],TRB_CYCLE_ON

           ; clear the trbs
           mov  edi,eax
           imul eax,edx,sizeof(xHCI_TRB)
           call memset32

           ; point the last TRB to the first TRB
           sub  eax,sizeof(xHCI_TRB)
           mov        fs:[edi+eax+xHCI_TRB->param+0],edi
           mov  dword fs:[edi+eax+xHCI_TRB->param+4],0
           mov  dword fs:[edi+eax+xHCI_TRB->status],0
           mov  dword fs:[edi+eax+xHCI_TRB->command],((LINK << 10) | TRB_IOC_OFF | TRB_CHAIN_OFF | TRB_TOGGLE_CYCLE_ON | TRB_CYCLE_ON)

           mov  eax,edi
           or   eax,TRB_CYCLE_ON

           ; success
           clc
           ret

xhci_alloc_ring_error:
           stc
           ret
xhci_alloc_ring endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; allocate and create a segmented ring (with table)
; (must not be more than 64 entries)
; updates the interrupter registers for this event ring
;
; on entry:
;  es -> EBDA
;  fs:edi -> CAPS registers
;  edx = OPS register set offset (edi+edx -> op registers)
;  es:esi -> this USB_CONTROLLER structure -> ring to create (struct xHCI_EVENT_RING)
;  eax = count of TRBs to include in ring
; on return
;  carry clear if success
;  carry set if error
; destroys none
xhci_alloc_event_ring proc near uses alld
           
           ; this should be an internal check
           cmp  eax,64
           ja   xhci_alloc_event_ring_error
           cmp  eax,16
           jb   xhci_alloc_event_ring_error
           
           ; save count in edx
           mov  edx,eax
           push edi              ; save pointer to CAPS registers
           
           ; allocate 16-byte segment table entry + (eax * sizeof(TRB))
           mov  ecx,64
           inc  eax
           imul eax,sizeof(xHCI_TRB)
           ;push dx
           ;mov  dx,offset mem_xhci_event_ring
           call memory_allocate
           ;pop  dx
           
           ; create the one and only segment entry
           push eax              ; save address to table
           mov  edi,eax
           add  eax,16
           mov  fs:[edi+0],eax
           mov  dword fs:[edi+4],0
           mov  fs:[edi+8],edx
           mov  dword fs:[edi+12],0
           
           ; clear the trbs
           mov  edi,eax
           imul eax,edx,sizeof(xHCI_TRB)
           call memset32

           pop  eax              ; restore address to table

           mov  es:[esi+xHCI_EVENT_RING->address],eax
           mov  es:[esi+xHCI_EVENT_RING->table_size],dl
           mov  es:[esi+xHCI_EVENT_RING->first_trb],edi
           mov  es:[esi+xHCI_EVENT_RING->cur_trb],edi
           mov  byte es:[esi+xHCI_EVENT_RING->cycle_bit],TRB_CYCLE_ON
           mov  byte es:[esi+xHCI_EVENT_RING->cur_index],0

           pop  edi              ; restore pointer to CAPS registers
           mov  eax,fs:[edi+XHCI_CAP_REGS->xHcRTSOffset]
           add  eax,0x20
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_IMAN],((1 << 1) | (1 << 0))
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_IMOD],0
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_TAB_SIZE],1
           mov  ecx,es:[esi+xHCI_EVENT_RING->first_trb]
           or   ecx,(1 << 3)
           mov  fs:[edi+eax+xHC_INTERRUPTER_DEQUEUE+0],ecx
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_DEQUEUE+4],0
           mov  ecx,es:[esi+xHCI_EVENT_RING->address]
           mov  fs:[edi+eax+xHC_INTERRUPTER_ADDRESS+0],ecx
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_ADDRESS+4],0
           
           clc
           ret
           
xhci_alloc_event_ring_error:
           stc
           ret
xhci_alloc_event_ring endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; insert command into the command ring
; on entry:
;  es -> EBDA
;  edx:eax = param field
;  ebx = status field
;  ecx = command field
;  es:esi -> this USB_CONTROLLER structure
; on return
;  fs:eax -> address to the TRB we added
; destroys none
xhci_insert_command proc near uses ecx edi
           
           ; point esi to the command ring
           push esi
           lea  esi,[esi+USB_CONTROLLER->command_ring]

           mov  edi,es:[esi+xHCI_RING->cur_trb]
           push eax
           push esi
           ; get the physical address: esi -> es:esi
           mov  eax,es
           shl  eax,4
           add  esi,eax
           mov  al,0  ; no chain bit
           call xhci_get_next_trb
           pop  esi
           pop  eax

           ; write the TRB
           mov  fs:[edi+xHCI_TRB->param+0],eax
           mov  fs:[edi+xHCI_TRB->param+4],edx
           mov  fs:[edi+xHCI_TRB->status],ebx
           or   cl,es:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],ecx

           mov  eax,edi
           pop  esi
           
           ; ring the command doorbell and wait for the event
           push eax
           xor  ax,ax     ; doorbell (0 = command, x = endpoint)
           call xhci_process_doorbell
           pop  eax
       
           ; return, eax -> this TRB
           ret
xhci_insert_command endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; process a command insertion
; on entry:
;  es -> EBDA
;  al  = slot ( 0 = command, 1 = slot 1, etc.)
;  ah  = doorbell to ring (1 = ep 1, etc.)
;  es:esi -> this USB_CONTROLLER structure
; on return
;  returns nothing
; destroys none
xhci_process_doorbell proc near uses alld
           push bp
           mov  bp,sp
           sub  sp,6

xhci_event_cur_trb      equ  [bp-4]  ; dword (current event trb)
xhci_doorbell_slot      equ  [bp-5]  ; byte
xhci_doorbell_endpt     equ  [bp-6]  ; byte

           mov  xhci_doorbell_slot,al
           mov  xhci_doorbell_endpt,ah

           ; make sure the status register is cleared
           movzx edx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           mov  edi,es:[esi+USB_CONTROLLER->base]
           mov  eax,fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus]
           mov  fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus],eax

           ; ring the door bell
           movzx eax,byte xhci_doorbell_slot
           shl  eax,2
           add  eax,fs:[edi+XHCI_CAP_REGS->xHcDBOffset]
           movzx ebx,byte xhci_doorbell_endpt
           mov  fs:[edi+eax],ebx
           
           ; wait for the 'interrupt' to happen
@@:        mov  eax,fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus]
           test eax,(1<<3)
           jz   short @b
           mov  fs:[edi+edx+XHCI_OP_REGS->xHcOPS_USBStatus],eax

           mov  eax,fs:[edi+XHCI_CAP_REGS->xHcRTSOffset]
           add  eax,0x20
@@:        mov  ebx,fs:[edi+eax+xHC_INTERRUPTER_IMAN]
           and  ebx,(xHC_INTERRUPTER_IMAN_IE | xHC_INTERRUPTER_IMAN_IP)
           cmp  ebx,(xHC_INTERRUPTER_IMAN_IE | xHC_INTERRUPTER_IMAN_IP)
           jne  short @b
           mov  fs:[edi+eax+xHC_INTERRUPTER_IMAN],ebx
           
           ; get the interrupter ring
           lea  eax,[esi+USB_CONTROLLER->event_ring]
xhci_process_doorbell_loop:
           ; make ebx -> current Event TRB
           mov  ebx,es:[eax+xHCI_EVENT_RING->cur_trb]
           mov  xhci_event_cur_trb,ebx
           mov  ecx,fs:[ebx+xHCI_TRB->command]
           push ecx           
           and  cl,1
           mov  dl,es:[eax+xHCI_EVENT_RING->cycle_bit]
           cmp  cl,dl
           pop  ecx
           jne  xhci_process_doorbell_done_1

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; eax -> xHCI_EVENT_RING
           ; ebx -> current TRB
           ; ecx = trb->command
           ; edx will -> original TRB that 'triggered' this event
           test ecx,(1<<2)       ; ED bit set?
           jnz  xhci_process_doorbell_ed

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ED bit cleared, so get the type and process the command
           ; make edx -> original TRB that 'triggered' this event
           mov  edx,fs:[ebx+xHCI_TRB->param]
           and  edx,(~0xF)
           mov  ecx,fs:[ebx+xHCI_TRB->status]
           shr  ecx,24
           and  cl,0x7F
           cmp  cl,TRB_SUCCESS
           jne  xhci_process_doorbell_not_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; returned TRB_SUCCESS, so get type
           mov  ecx,fs:[ebx+xHCI_TRB->command]
           shr  ecx,10
           and  cl,0x3F

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; NECs command completion?
           cmp  cl,NEC_TRB_TYPE_CMD_COMP
           jne  short @f
           ; get the type of the original TRB sent
           mov  ecx,fs:[edx+xHCI_TRB->command]
           shr  ecx,10
           and  cl,0x3F

           cmp  cl,NEC_TRB_TYPE_GET_FW
           jne  short xhci_process_nec_0
           ; it is the NEC get FW version
           ; major version is ((fs:[ebx+xHCI_TRB->status] & 0x0000FF00) >> 8)
           ; minor version is ((fs:[ebx+xHCI_TRB->status] & 0x000000FF) >> 0)
             ;mov  ecx,fs:[ebx+xHCI_TRB->status]  ; ecx = 0x____3021
             ;xchg cx,cx
           jmp  short xhci_process_compl_0

xhci_process_nec_0:
           cmp  cl,NEC_TRB_TYPE_GET_UN
           jne  short xhci_process_nec_1
           ; it is the NEC verification command
           ; org_trb->command = event_trb->command
           mov  ecx,fs:[ebx+xHCI_TRB->command]
           mov  fs:[edx+xHCI_TRB->command],ecx
           jmp  short xhci_process_compl_0

xhci_process_nec_1:
           ; unknown NEC completion 
             xchg cx,cx
           jmp  short xhci_process_compl_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Port status change?
@@:        cmp  cl,PORT_STATUS_CHANGE
           jne  short @f
           ; we don't do anything here
           jmp  xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Transfer Event?
@@:        cmp  cl,TRANS_EVENT
           jne  short @f
           ; this is an error: Transfer Event with ED = 0
           jmp  xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Command completion
@@:        cmp  cl,COMMAND_COMPLETION
           jne  short @f
           mov  ecx,fs:[edx+xHCI_TRB->command]
           shr  ecx,10
           and  cl,0x3F
           
           cmp  cl,ENABLE_SLOT
           jne  short xhci_process_compl_0
           ; enable slot completion code
           and  dword fs:[edx+xHCI_TRB->command],0x00FFFFFF
           mov  ecx,fs:[ebx+xHCI_TRB->command]
           and  ecx,0xFF000000
           or   fs:[edx+xHCI_TRB->command],ecx
xhci_process_compl_0:
           ; org_trb->status = event_trb->status
           mov  ecx,fs:[ebx+xHCI_TRB->status]
           mov  fs:[edx+xHCI_TRB->status],ecx
           jmp  short xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown type found
@@:        xchg cx,cx
           jmp  short xhci_process_doorbell_done_0

xhci_process_doorbell_not_success:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; cl = comp_code
           cmp  cl,SHORT_PACKET
           jne  short @f
           ; do nothing
           jmp  short xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; cl = comp_code
@@:      xchg cx,cx
           jmp  short xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; ED bit is set
           ; eax -> xHCI_EVENT_RING
           ; ebx -> current TRB
           ; ecx = trb->command
           ; edx -> original TRB that 'triggered' this event
xhci_process_doorbell_ed:
           ;mov  edx,fs:[ebx+xHCI_TRB->param]
           ;and  edx,(~0xF)
           mov  ecx,fs:[ebx+xHCI_TRB->command]
           shr  ecx,10
           and  cl,0x3F
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           cmp  cl,TRANS_EVENT
           jne  short @f

           ; Transfer Event with ED=1
           mov  ecx,fs:[ebx+xHCI_TRB->status]
           push eax
           mov  eax,fs:[ebx+xHCI_TRB->param+0]
           or   eax,eax
           jz   short xhci_process_doorbell_trans_done
           push ecx
           and  ecx,0x00FFFFFF
           mov  fs:[eax+xHCI_EVENT_STATUS->count],ecx
           pop  ecx
           shr  ecx,24
           mov  fs:[eax+xHCI_EVENT_STATUS->status],cl
xhci_process_doorbell_trans_done:
           pop  eax
           jmp  short xhci_process_doorbell_done_0

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown event with ED=1
@@:        xchg cx,cx
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; advance to next trb
           ; eax -> xHCI_EVENT_RING
xhci_process_doorbell_done_0:
           push eax
           mov  esi,eax
           call xhci_get_next_event_trb
           pop  eax
           jmp  xhci_process_doorbell_loop

xhci_process_doorbell_done_1:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; xHCI, Version 1.0, section 5.5.2.3.3
           ; "When software finishes processing an Event TRB, it will write the address of that Event TRB to the ERDP."
           ; write the dequeue pointer (clearing the busy bit)
           ; note: if there was a cycle bit mis-match, we still write the value of the
           ;  current location to the register, which is given by 'event' above
           mov  eax,fs:[edi+XHCI_CAP_REGS->xHcRTSOffset]
           add  eax,0x20
           mov  ebx,xhci_event_cur_trb
           or   ebx,(xHC_INTERRUPTER_DEQUEUE_EHB | 0)   ; DESI = 0 (we only have 1 segment)
           mov  fs:[edi+eax+xHC_INTERRUPTER_DEQUEUE+0],ebx
           mov  dword fs:[edi+eax+xHC_INTERRUPTER_DEQUEUE+4],0
           
           mov  sp,bp
           pop  bp
           ret
xhci_process_doorbell endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the next TRB address
; on entry:
;  es -> EBDA
;  fs:esi -> xHCI_RING
;  al = 1 = chain bit
; on return
;  fs:eax -> address to the next TRB
; destroys none
xhci_get_next_trb proc near uses ebx ecx
           mov  bl,al            ; save the chain bit

           mov  eax,fs:[esi+xHCI_RING->cur_trb]
           add  eax,sizeof(xHCI_TRB)

xhci_get_next_trb_link:
           mov  ecx,fs:[eax+xHCI_TRB->command]
           shr  ecx,10
           and  cl,0x3F
           cmp  cl,LINK
           jne  short xhci_get_next_trb_done

           ; is a link, so get linked address
           mov  ecx,fs:[eax+xHCI_TRB->command]
           and  cl,(~1)
           or   cl,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[eax+xHCI_TRB->command],ecx

           ; are we to toggle it
           test ecx,(1<<1)
           jz   short @f
           xor  byte fs:[esi+xHCI_RING->cycle_bit],1

           ; do the chain bit?
@@:        and  ecx,(~TRB_CHAIN_ON)
           or   bl,bl
           jz   short @f
           or   ecx,TRB_CHAIN_ON
@@:        mov  fs:[eax+xHCI_TRB->command],ecx
           
           ; get the address of the next TRB
           mov  eax,fs:[eax+xHCI_TRB->param+0]
           jmp  short xhci_get_next_trb_link

xhci_get_next_trb_done:
           mov  fs:[esi+xHCI_RING->cur_trb],eax
           ret
xhci_get_next_trb endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; return the next TRB address (event ring)
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure -> xHCI_RING
; on return
;  fs:eax -> address to the next TRB
; destroys none
xhci_get_next_event_trb proc near
           ; increment to the next event ring trb
           inc  byte es:[esi+xHCI_EVENT_RING->cur_index]

           movzx eax,byte es:[esi+xHCI_EVENT_RING->cur_index]
           cmp  al,es:[esi+xHCI_EVENT_RING->table_size]
           jb   short @f

           ; we are at the end of the ring, so start over
           mov  byte es:[esi+xHCI_EVENT_RING->cur_index],0
           xor  byte es:[esi+xHCI_EVENT_RING->cycle_bit],1
           xor  eax,eax

           ; calculate the current trb and write it to xHCI_EVENT_RING->cur_trb
@@:        imul eax,sizeof(xHCI_TRB)
           add  eax,es:[esi+xHCI_EVENT_RING->first_trb]
           mov  es:[esi+xHCI_EVENT_RING->cur_trb],eax

           ret
xhci_get_next_event_trb endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; retrieve the extended caps of this controller
; on entry:
;  es -> EBDA
;  fs:edi -> CAPS registers
;  es:esi -> this USB_CONTROLLER structure
; on return
;  eax -> buffer allocated and filled
; destroys none
xhci_get_ext_caps proc near uses ecx edx edi
           ; get the extended capabilities data
           ; we have to read the data as dwords (QEMU feature/bug), so
           ;  allocate a buffer and place it there.
           mov  eax,fs:[edi+XHCI_CAP_REGS->xHcHCCParams1]
           shr  eax,16           ;
           shl  eax,2            ; dwords
           add  edi,eax          ; fs:edi -> points to extended caps registers

           ; calculate the size needed
           xor  eax,eax          ; start at offset 0 of the extended caps
@@:        mov  ecx,fs:[edi+eax] ;
           shr  ecx,8
           and  ecx,0x000000FF   ;
           jz   short @f         ; if zero, we are done
           shl  ecx,2            ; dwords
           add  eax,ecx
           cmp  eax,32787        ; make sure we don't run away
           jb   short @b         ;

@@:        add  eax,16           ; make sure we get the last 16 bytes
           
           ; eax = size in bytes of the extended caps
           push eax              ; save it in ecx
           mov  ecx,1
           ;push dx
           ;mov  dx,offset mem_xhci_ext_caps
           call memory_allocate
           ;pop  dx
           pop  ecx              ; ecx = size in bytes
           push eax              ; save the address

           shr  ecx,2            ; in dwords
@@:        mov  edx,fs:[edi]
           add  edi,4
           mov  fs:[eax],edx
           add  eax,4
           .adsize
           loop @b

           pop  eax              ; restore the address
           ret
xhci_get_ext_caps endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the protocol of the given port
; on entry:
;  es -> EBDA
;  fs:edi -> CAPS registers
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
; on return
;  al = XHCI_USB2 or XHCI_USB3
; destroys none
xhci_get_port_protocol proc near uses ecx edi
           
           mov  edi,es:[esi+USB_CONTROLLER->base_memory]
xhci_get_port_protocol_0:
           mov  al,fs:[edi+0]
           cmp  al,2             ; 2 = ECP ID Proto
           jne  short @f
           
           ; is protocol id
           movzx eax,byte fs:[edi+8]  ; offset
           dec  eax                   ; must be zero based
           movzx ecx,byte fs:[edi+9]  ; count
           cmp  edx,eax
           jb   short @f
           add  eax,ecx
           cmp  edx,eax
           jae  short @f
           
           ; we are within the offset and count
           mov  al,fs:[edi+3]         ; major
           ret
           
@@:        movzx eax,byte fs:[edi+1]
           or   eax,eax
           jz   short @f
           shl  eax,2
           add  edi,eax
           jmp  short xhci_get_port_protocol_0

@@:        mov  al,0  ; shouldn't get here
           ret
xhci_get_port_protocol endp

;  default speed =  full, low, high, super
xhci_def_speed  dw    64,   8,   64,   512

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the default max packet size of the port
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
; on return
;  ax = default mps
;  cl = speed of device
; destroys none
xhci_default_mps proc near
           ; calculate which port it is
           imul eax,edx,sizeof(XHCI_PORT_REGS)
           add  eax,es:[esi+USB_CONTROLLER->base]
           movzx ecx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           add  eax,ecx
           add  eax,xHC_OPS_USBPortSt

           mov  eax,fs:[eax+XHCI_PORT_REGS->xHcPORT_PORTSC]
           shr  eax,10
           and  eax,0x0F
           mov  cl,al            ; return the speed of the device in cl
           cmp  al,XHCI_SPEED_SUPER  ; clamp to super-speed (gen 1)
           jbe  short @f
           mov  al,XHCI_SPEED_SUPER
@@:        dec  eax              ; make it zero based
           mov  ax,cs:[xhci_def_speed + eax*2]
           ret
xhci_default_mps endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; reset a xhci port
  ; The following tests were done on real hardware (NEC/Renesas):
  ; USB2 (always is HOT_RESET)
  ;   bit 21 = 1 if CCS = 1, bit 19 always 0
  ;   bit 21 = 0 if CCS = 0, bit 19 always 0
  ; USB3 (if HOT_RESET) (same as USB2 port)
  ;   bit 21 = 1 if CCS = 1, bit 19 always 0
  ;   bit 21 = 0 if CCS = 0, bit 19 always 0
  ; USB3 (if WARM_RESET)
  ;   bit 21 = 1 if CCS = 1, bit 19 always 1
  ;   bit 21 = 1 if CCS = 0, bit 19 always 1
; on entry:
;  es -> EBDA
;  bl = protocol of this port
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
; on return
;  al = 1 = port connected/enabled
;     = 0 = no device attached
; destroys none
xhci_port_reset proc near uses ecx edx edi
           ; calculate which port it is
           mov  edi,es:[esi+USB_CONTROLLER->base]
           imul edx,sizeof(XHCI_PORT_REGS)
           movzx ecx,byte es:[esi+USB_CONTROLLER->op_reg_offset]
           add  edx,ecx
           add  edx,xHC_OPS_USBPortSt

           ; make sure the status change bits are clear
           mov  dword fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],(xHC_PortUSB_POWER | xHC_PortUSB_CHANGE_BITS)

           ; do we do a USB2 reset?
           cmp  bl,XHCI_USB2
           jne  short @f

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-           
           ; a USB2 reset uses bit 4 (HOT_RESET)
           mov  eax,(xHC_PortUSB_POWER | (1<<4))
           mov  fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],eax
           ; wait for the reset to happen
           mov  eax,USB_TDRSTR
           call mdelay
           ; if bit 21 is clear, we do not have a device attached
           test dword fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],(1<<21)
           jz   short xhci_port_reset_none
           jmp  short xhci_port_reset_comp

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
@@:        ; is a USB3 reset
           mov  eax,(xHC_PortUSB_POWER | (1<<31))
           mov  fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],eax
           ; wait for the reset to happen
           mov  eax,USB_TDRSTR
           call mdelay

xhci_port_reset_comp:
           ; delay the recovery time
           mov  eax,USB_TRSTRCY
           call mdelay

           ; if after the reset, the enable bit is set, there was a successful reset/enable
           mov  eax,fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC]
           test al,(1<<1)
           jz   short xhci_port_reset_none

           ; was a successful reset, enable, and a connection is present
           mov  dword fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTSC],(xHC_PortUSB_POWER | xHC_PortUSB_CHANGE_BITS)
           ; should preserved the high word of xHcPORT_PORTPMSC when writing to it
           ;mov  eax,fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTPMSC]
           ;mov  ax,0xFFF8 ; disable the pm timeout ??????
           ;mov  fs:[edi+edx+XHCI_PORT_REGS->xHcPORT_PORTPMSC],eax

           ; connected and enabled
           mov  al,1
           ret

           ; nothing connected and/or did not enable
xhci_port_reset_none:
           xor  al,al
           ret
xhci_port_reset endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the slot context
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_get_a_slot proc near uses ebx ecx edx
           
           ; find and enable a slot
           push edx
           push ebx
           xor  edx,edx          ; high dword of param
           xor  eax,eax          ; low dword of param
           xor  ebx,ebx          ; status
           mov  ecx,((0 << 16) | (ENABLE_SLOT << 10)) ; command
           call xhci_insert_command
           pop  ebx
           pop  edx
           
           ; return status is in bits 31:24 of the status field
           ; slot id is in bits 31:24 of the command field
           mov  ecx,fs:[eax+XHCI_TRB->status]
           shr  ecx,24
           cmp  cl,TRB_SUCCESS
           jne  short xhci_get_a_slot_error
           mov  eax,fs:[eax+XHCI_TRB->command]
           shr  eax,24
           jz   short xhci_get_a_slot_error
           mov  fs:[ebx+USB_DEVICE->slot_id],al
           
           ; initialize the slot
           call xhci_initialize_slot

           ; set the address, with block to device
           mov  ah,1
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           call xhci_set_address
           
           ; if unsuccessful, we need to remove block
           or   ax,ax
           jz   short xhci_get_a_slot_success

           ; remove the slot
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           call xhci_remove_slot

xhci_get_a_slot_error:
           mov  ax,-1
           ret

xhci_get_a_slot_success:
           xor  ax,ax
           ret
xhci_get_a_slot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the slot data
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  fs:ebx -> USB_DEVICE
;  es:esi -> this USB_CONTROLLER structure
;  al = slot id
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_initialize_slot proc near uses ecx edx edi ebp
           inc  dl               ; make it 1 based
           
           ; point the DCBAAP[slot_id] -> slots_buffer[slot_id]
           movzx ecx,al
           shl  ecx,3            ; 8-byte pointers
           add  ecx,es:[esi+USB_CONTROLLER->dcbaap_addr]
           movzx eax,al
           imul eax,(64 * 32)    ; 64-byte slot context, 32 each context
           add  eax,es:[esi+USB_CONTROLLER->slots_buffer]
           mov  fs:[ecx+0],eax
           mov  dword fs:[ecx+4],0

           ; point to this device's slot data
           mov  ax,sizeof(xHCI_SLOT_CONTEXT)
           lea  edi,[ebx+USB_DEVICE->slot_context]
           call memset32

           ; initialize the slot
           mov  dword fs:[edi+xHCI_SLOT_CONTEXT->route_string],0
           mov  al,fs:[ebx+USB_DEVICE->speed]
           mov  fs:[edi+xHCI_SLOT_CONTEXT->speed],al
           mov  byte fs:[edi+xHCI_SLOT_CONTEXT->entries],1
           mov  fs:[edi+xHCI_SLOT_CONTEXT->rh_port_num],dl
          ;mov  word fs:[edi+xHCI_SLOT_CONTEXT->int_target],0 ; primary
          ;mov  byte fs:[edi+xHCI_SLOT_CONTEXT->mtt],0
          ;mov  byte fs:[edi+xHCI_SLOT_CONTEXT->tt_port_num],0
          ;mov  byte fs:[edi+xHCI_SLOT_CONTEXT->tt_hub_slot_id],0
          ;mov  byte fs:[edi+xHCI_SLOT_CONTEXT->ttt],0

           ; initialize the control ep
           mov  al,xHCI_CONTROL_EP            ; endpoint to initialize
           mov  ah,0                          ; type = control ep
           mov  cx,fs:[ebx+USB_DEVICE->mps]   ; max packet size
           mov  dl,0                          ; no direction needed
           mov  dh,fs:[ebx+USB_DEVICE->speed] ; speed of device
           xor  ebp,ebp                       ; interval = 0, max burst = 0
           call xhci_initialize_ep

           xor  ax,ax
           ret
xhci_initialize_slot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize an ep's data
; on entry:
;  es -> EBDA
;  al = ep index
;  ah = type (0 = control, 1 = iso, 2 = bulk, 3 = int)
;  cx = max packet size
;  dl = direction (0x80 = in, 0 = out)
;  dh = speed of device (xhci speed, not USB speed)
;  ebp = high word = interval (0 or endpoint->interval), low word = max_burst size
;  fs:ebx -> USB_DEVICE
;  es:esi -> this USB_CONTROLLER structure
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_initialize_ep proc near uses ebx ecx edx esi edi ebp
           
           ; point to this device's endpoint[ep_num]
           push eax
           movzx eax,al
           imul eax,sizeof(xHCI_EP_CONTEXT)
           lea  edi,[ebx+USB_DEVICE->ep_contexts]
           add  edi,eax
           mov  ax,sizeof(xHCI_EP_CONTEXT)
           call memset32
           pop  eax

           ; initialize the ep
           mov  byte fs:[edi+xHCI_EP_CONTEXT->max_pstreams],0
           mov  byte fs:[edi+xHCI_EP_CONTEXT->lsa],0
           mov  byte fs:[edi+xHCI_EP_CONTEXT->hid],1
           mov       fs:[edi+xHCI_EP_CONTEXT->max_packet_size],cx
           mov  byte fs:[edi+xHCI_EP_CONTEXT->mult],0
           mov  byte fs:[edi+xHCI_EP_CONTEXT->ep_state],EP_STATE_DISABLED

           ; create the ring for this endpoint
           push eax
           lea  esi,[edi+xHCI_EP_CONTEXT->ring]
           mov  eax,64           ; count of TRBs to create
           call xhci_alloc_ring
           push ax
           and  al,1
           mov  fs:[edi+xHCI_EP_CONTEXT->dcs],al
           pop  ax
           and  eax,(~0xF)
           mov  fs:[edi+xHCI_EP_CONTEXT->tr_dequeue_pointer],eax
           pop  eax

           ; we only support CONTROL and BULK endpoints
           cmp  ah,0  ; control
           jne  short @f

           mov  byte fs:[edi+xHCI_EP_CONTEXT->ep_type],4
           mov  word fs:[edi+xHCI_EP_CONTEXT->average_trb_len],8
           mov  byte fs:[edi+xHCI_EP_CONTEXT->cerr],3
           mov  word fs:[edi+xHCI_EP_CONTEXT->max_burst_size],0
           mov  dword fs:[edi+xHCI_EP_CONTEXT->max_esit_payload],0
           jmp  short xhci_initialize_ep_0

@@:        cmp  ah,2 ; bulk
           jne  short xhci_initialize_ep_error

           mov  byte fs:[edi+xHCI_EP_CONTEXT->ep_type],6  ; assume in direction
           cmp  dl,0x80
           je   short @f
           mov  byte fs:[edi+xHCI_EP_CONTEXT->ep_type],2  ; is out direction
@@:        mov  word fs:[edi+xHCI_EP_CONTEXT->average_trb_len],3072   ; ((ep->max_packet_size + 1) & ~1) / 2;  at least two TRB's per transfer (xhci 1.0, page 187, last line of note on page 188)
           mov  byte fs:[edi+xHCI_EP_CONTEXT->cerr],3

           mov  word fs:[edi+xHCI_EP_CONTEXT->max_burst_size],0
           mov  dword fs:[edi+xHCI_EP_CONTEXT->max_esit_payload],0
           cmp  dh,4       ; 4+ is superspeed
           jb   short xhci_initialize_ep_0
           push ebp
           mov  fs:[edi+xHCI_EP_CONTEXT->max_burst_size],bp
           shr  ebp,16
           mov  fs:[edi+xHCI_EP_CONTEXT->max_esit_payload],ebp  ; interval
           pop  ebp

xhci_initialize_ep_0:
           ; calculate interval
           ; low/full/super speeds, interval = 0
           ; high speed, interval = end_point->interval
           mov  word fs:[edi+xHCI_EP_CONTEXT->interval],0
           cmp  dh,3 ; high speed
           jne  short @f
           shr  ebp,16
           mov  fs:[edi+xHCI_EP_CONTEXT->interval],bp

@@:        xor  ax,ax
           ret

xhci_initialize_ep_error:
           mov  ax,-1
           ret
xhci_initialize_ep endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; remove a slot
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  al = slot id
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_remove_slot proc near

       xchg cx,cx

           ret
xhci_remove_slot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; get the address to our EP Context(s)
; on entry:
;  es -> EBDA
;  eax = ep context index
;  fs:ebx -> USB_DEVICE
; on return
;  fs:eax -> ep context
; destroys none
xhci_get_ep_context proc near uses ebx
           imul eax,sizeof(xHCI_EP_CONTEXT)
           lea  ebx,[ebx+USB_DEVICE->ep_contexts]
           add  eax,ebx
           ret
xhci_get_ep_context endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send the set address command
;  updates the USB_DEVICE->mps and USB_DEVICE->dev_addr fields too.
; on entry:
;  es -> EBDA
;  edx = port number (0, 1, 2, ...)
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  al = slot id
;  ah = 1 = block (don't send to device)
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_set_address proc near uses ecx edx
           push bp
           mov  bp,sp
           sub  sp,6

xhci_address_slot_id    equ  [bp-1]
xhci_address_block      equ  [bp-2]
xhci_address_address    equ  [bp-6]
           
           mov  xhci_address_slot_id,al
           mov  xhci_address_block,ah

           ; xHCI version 1.0 states that the ep_state must be 0
           ; xHCI version 1.1 states that the ep_state must be running (1) or stopped (3).
           ; I chose the first just to be sure
           mov  eax,xHCI_CONTROL_EP
           call xhci_get_ep_context
           mov  byte fs:[eax+xHCI_EP_CONTEXT->ep_state],0
           push eax              ; save the address of this ep context

           ; allocate temp slot
           mov  eax,(64 + (64 * 32))  ; bitmap + slot and eps
           movzx ecx,word es:[esi+USB_CONTROLLER->page_size]
           call memory_allocate
           mov  xhci_address_address,eax

           movzx ecx,byte es:[esi+USB_CONTROLLER->context_size]
           mov  dword fs:[eax+0],0x00000000
           mov  dword fs:[eax+4],0x00000003   ; slot context and ep0
           
           ; write the slot context
           add  eax,ecx
           call xhci_write_slot
           
           ; write the ep context
           imul ecx,ecx,xHCI_CONTROL_EP
           add  eax,ecx
           mov  cl,xHCI_CONTROL_EP
           call xhci_write_ep

           push ebx              ; save device pointer
           mov  ecx,(ADDRESS_DEVICE << 10) ; command
           mov  dl,xhci_address_slot_id
           shl  edx,(24-9)
           mov  dl,xhci_address_block
           shl  edx,9
           or   ecx,edx
           xor  ebx,ebx          ; status
           xor  edx,edx          ; high dword of param
           mov  eax,xhci_address_address ; low dword of param
           call xhci_insert_command
           pop  ebx              ; restore device pointer

           mov  ecx,fs:[eax+XHCI_TRB->status]
           shr  ecx,24
           mov  ax,-1            ; if error, ax = -1
           cmp  cl,TRB_SUCCESS
           jne  short xhci_set_address_done

           ; calculate our slot address
           movzx eax,byte xhci_address_slot_id
           imul eax,(64*32)
           add  eax,es:[esi+USB_CONTROLLER->slots_buffer]
           mov  ecx,xhci_address_address
           call xhci_read_slot

           push eax
           lea  eax,fs:[ebx+USB_DEVICE->slot_context]
           mov  dl,fs:[ecx+xHCI_SLOT_CONTEXT->slot_state]
           mov  fs:[eax+xHCI_SLOT_CONTEXT->slot_state],dl
           ;mov  dl,fs:[ecx+xHCI_SLOT_CONTEXT->device_address]
           ;mov  fs:[eax+xHCI_SLOT_CONTEXT->device_address],dl
           ;mov  fs:[ebx+USB_DEVICE->dev_addr],dl
           pop  eax
           
           ; calculate our ep address
           ; eax -> slot address from above
           movzx ecx,byte es:[esi+USB_CONTROLLER->context_size]
           imul ecx,ecx,xHCI_CONTROL_EP
           add  eax,ecx
           mov  ecx,xhci_address_address
           call xhci_read_ep

           pop  eax              ; restore the address of this ep context
           mov  dl,fs:[ecx+xHCI_EP_CONTEXT->ep_state]
           mov  fs:[eax+xHCI_EP_CONTEXT->ep_state],dl
           mov  dx,fs:[ecx+xHCI_EP_CONTEXT->max_packet_size]
           mov  fs:[eax+xHCI_EP_CONTEXT->max_packet_size],dx
           mov  fs:[ebx+USB_DEVICE->mps],dx

           xor  ax,ax
xhci_set_address_done:
           ; free the memory block used
           push ax
           mov  eax,xhci_address_address
           call memory_free
           pop  ax
           
           mov  sp,bp
           pop  bp
           ret
xhci_set_address endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send the set config EP command
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
;  al = slot id
;  ah = ep index
; on return
;  ax =  0 = good enumeration
;     = -1 = error
; destroys none
xhci_config_ep proc near uses ecx edx
           push bp
           mov  bp,sp
           sub  sp,6

xhci_config_ep_slot_id    equ  [bp-1]
xhci_config_ep_index      equ  [bp-2]
xhci_config_ep_addr       equ  [bp-6]
           
           mov  xhci_config_ep_slot_id,al
           mov  xhci_config_ep_index,ah

           ; allocate temp slot
           mov  eax,(64 + (64 * 32))  ; bitmap + slot and eps
           movzx ecx,word es:[esi+USB_CONTROLLER->page_size]
           call memory_allocate
           mov  xhci_config_ep_addr,eax

           movzx ecx,byte xhci_config_ep_index
           mov  edx,1
           shl  edx,cl
           mov  fs:[eax+0],edx
           or   dl,1
           mov  fs:[eax+4],edx
           
           ; update and write the slot context
           push eax
           lea  eax,fs:[ebx+USB_DEVICE->slot_context]
           mov  dl,xhci_config_ep_index
           cmp  fs:[eax+xHCI_SLOT_CONTEXT->entries],dl
           jnb  short @f
           mov  fs:[eax+xHCI_SLOT_CONTEXT->entries],dl
@@:        mov  dl,es:[esi+USB_CONTROLLER->numports]
           mov  fs:[eax+xHCI_SLOT_CONTEXT->num_ports],dl
           pop  eax
           movzx ecx,byte es:[esi+USB_CONTROLLER->context_size]
           add  eax,ecx
           call xhci_write_slot

           ; write the ep context
           movzx edx,byte xhci_config_ep_index
           imul ecx,edx
           add  eax,ecx
           mov  cl,dl
           call xhci_write_ep

           push ebx              ; save device pointer
           mov  ecx,(CONFIG_EP << 10) ; command
           mov  dl,xhci_config_ep_slot_id
           shl  edx,24
           or   ecx,edx
           xor  ebx,ebx          ; status
           xor  edx,edx          ; high dword of param
           mov  eax,xhci_config_ep_addr ; low dword of param
           call xhci_insert_command
           pop  ebx              ; restore device pointer

           mov  ecx,fs:[eax+XHCI_TRB->status]
           shr  ecx,24
           mov  ax,-1            ; if error, ax = -1
           cmp  cl,TRB_SUCCESS
           jne  short xhci_config_ep_done

           ; calculate our slot address
           movzx eax,byte xhci_config_ep_slot_id
           imul eax,(64*32)
           add  eax,es:[esi+USB_CONTROLLER->slots_buffer]
           mov  ecx,xhci_config_ep_addr
           call xhci_read_slot

           push eax
           lea  eax,fs:[ebx+USB_DEVICE->slot_context]
           mov  dl,fs:[ecx+xHCI_SLOT_CONTEXT->slot_state]
           mov  fs:[eax+xHCI_SLOT_CONTEXT->slot_state],dl
           pop  eax
           
           ; calculate our ep address
           ; eax -> slot address from above
           movzx edx,byte xhci_config_ep_index
           movzx ecx,byte es:[esi+USB_CONTROLLER->context_size]
           imul ecx,edx
           add  eax,ecx
           mov  ecx,xhci_config_ep_addr
           call xhci_read_ep

           ; get address to our ep context data
           movzx eax,byte xhci_config_ep_index
           call xhci_get_ep_context
           mov  dl,fs:[ecx+xHCI_EP_CONTEXT->ep_state]
           mov  fs:[eax+xHCI_EP_CONTEXT->ep_state],dl
           mov  dx,fs:[ecx+xHCI_EP_CONTEXT->max_packet_size]
           mov  fs:[eax+xHCI_EP_CONTEXT->max_packet_size],dx

           xor  ax,ax
xhci_config_ep_done:
           ; free the memory block used
           push ax
           mov  eax,xhci_config_ep_addr
           call memory_free
           pop  ax
           
           mov  sp,bp
           pop  bp
           ret
xhci_config_ep endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write our slot data to the physical slot
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:eax -> address to write the slot
;  fs:ebx -> USB_DEVICE
; on return
;  nothing
; destroys none
xhci_write_slot proc near uses ebx ecx edx
           lea  ebx,[ebx+USB_DEVICE->slot_context]
           
           ; dword 0
           movzx ecx,byte fs:[ebx+xHCI_SLOT_CONTEXT->entries]
           shl  ecx,27
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->hub]
           shl  edx,26
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->mtt]
           shl  edx,25
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->speed]
           shl  edx,20
           or   ecx,edx
           
           mov  edx,fs:[ebx+xHCI_SLOT_CONTEXT->route_string]
           or   ecx,edx
           mov  fs:[eax+0],ecx
           
           ; dword 1
           movzx ecx,byte fs:[ebx+xHCI_SLOT_CONTEXT->num_ports]
           shl  ecx,24
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->rh_port_num]
           shl  edx,16
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->max_exit_latency]
           or   ecx,edx
           mov  fs:[eax+4],ecx
           
           ; dword 2
           movzx ecx,word fs:[ebx+xHCI_SLOT_CONTEXT->int_target]
           shl  ecx,22
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->ttt]
           shl  edx,16
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->tt_port_num]
           shl  edx,8
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->tt_hub_slot_id]
           or   ecx,edx
           mov  fs:[eax+8],ecx
           
           ; dword 3
           movzx ecx,byte fs:[ebx+xHCI_SLOT_CONTEXT->slot_state]
           shl  ecx,27
           
           movzx edx,byte fs:[ebx+xHCI_SLOT_CONTEXT->device_address]
           or   ecx,edx
           mov  fs:[eax+12],ecx
           
           ret
xhci_write_slot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read our slot data from the physical slot
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:eax -> address to read the slot
;  fs:ebx -> USB_DEVICE
;  fs:ecx -> address to write the slot data
; on return
;  nothing
; destroys none
xhci_read_slot proc near uses edx
           
           ; dword 0
           mov  edx,fs:[eax+0]
           shr  edx,27
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->entries],dl
           
           mov  edx,fs:[eax+0]
           shr  edx,26
           and  dl,1
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->hub],dl
           
           mov  edx,fs:[eax+0]
           shr  edx,25
           and  dl,1
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->mtt],dl

           mov  edx,fs:[eax+0]
           shr  edx,20
           and  dl,0x0F
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->speed],dl

           mov  edx,fs:[eax+0]
           and  edx,0x000FFFFF
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->route_string],edx
           
           ; dword 1
           mov  edx,fs:[eax+4]
           shr  edx,24
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->num_ports],dl

           mov  edx,fs:[eax+4]
           shr  edx,16
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->rh_port_num],dl

           mov  edx,fs:[eax+4]
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->max_exit_latency],dx

           ; dword 2
           mov  edx,fs:[eax+8]
           shr  edx,22
           and  dx,0x03FF
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->int_target],dx

           mov  edx,fs:[eax+8]
           shr  edx,16
           and  dl,0x03
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->ttt],dl

           mov  edx,fs:[eax+8]
           shr  edx,8
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->tt_port_num],dl

           mov  edx,fs:[eax+8]
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->tt_hub_slot_id],dl

           ; dword 3
           mov  edx,fs:[eax+12]
           shr  edx,27
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->slot_state],dl

           mov  edx,fs:[eax+12]
           mov  fs:[ecx+xHCI_SLOT_CONTEXT->device_address],dl

           ret
xhci_read_slot endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write our ep[x] data to the physical ep
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:eax -> address to write the ep
;  fs:ebx -> USB_DEVICE
;  cl = endpoint index
; on return
;  nothing
; destroys none
xhci_write_ep proc near uses ebx ecx edx
           lea  ebx,[ebx+USB_DEVICE->ep_contexts]
           and  ecx,0x000000FF
           imul ecx,sizeof(xHCI_EP_CONTEXT)
           add  ebx,ecx

           ; dword 0
           mov  ecx,fs:[ebx+xHCI_EP_CONTEXT->max_esit_payload]
           shl  ecx,8
           and  ecx,0xFF000000

           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->interval]
           shl  edx,16
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->lsa]
           shl  edx,15
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->max_pstreams]
           shl  edx,10
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->mult]
           shl  edx,8
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->ep_state]
           or   ecx,edx
           mov  fs:[eax+0],ecx
           
           ; dword 1
           movzx ecx,word fs:[ebx+xHCI_EP_CONTEXT->max_packet_size]
           shl  ecx,16
           
           movzx edx,word fs:[ebx+xHCI_EP_CONTEXT->max_burst_size]
           shl  edx,8
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->hid]
           shl  edx,7
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->ep_type]
           shl  edx,3
           or   ecx,edx
           
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->cerr]
           shl  edx,1
           or   ecx,edx
           mov  fs:[eax+4],ecx
           
           ; dword 2
           mov  ecx,fs:[ebx+xHCI_EP_CONTEXT->tr_dequeue_pointer]
           movzx edx,byte fs:[ebx+xHCI_EP_CONTEXT->dcs]
           or   ecx,edx
           mov  fs:[eax+8],ecx
           
           ; dword 3
           xor  ecx,cx
           mov  fs:[eax+12],ecx
           
           ; dword 4
           movzx ecx,word fs:[ebx+xHCI_EP_CONTEXT->max_esit_payload]
          ;and  ecx,0x0000FFFF
           shl  ecx,16
           
           movzx edx,word fs:[ebx+xHCI_EP_CONTEXT->average_trb_len]
           or   ecx,edx
           mov  fs:[eax+16],ecx

           ret
xhci_write_ep endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read our ep[x] data from the physical ep
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:eax -> address to read the ep
;  fs:ebx -> USB_DEVICE
;  fs:ecx -> address to write the ep data
; on return
;  nothing
; destroys none
xhci_read_ep proc near

           ; dword 0
           mov  edx,fs:[eax+0]
           shr  edx,8
           and  edx,0x00FF0000
           mov  fs:[ecx+xHCI_EP_CONTEXT->max_esit_payload],edx

           mov  edx,fs:[eax+0]
           shr  edx,16
           mov  fs:[ecx+xHCI_EP_CONTEXT->interval],dl

           mov  edx,fs:[eax+0]
           shr  edx,15
           and  dl,1
           mov  fs:[ecx+xHCI_EP_CONTEXT->lsa],dl

           mov  edx,fs:[eax+0]
           shr  edx,10
           and  dl,0x1F
           mov  fs:[ecx+xHCI_EP_CONTEXT->max_pstreams],dl

           mov  edx,fs:[eax+0]
           shr  edx,8
           and  dl,0x03
           mov  fs:[ecx+xHCI_EP_CONTEXT->mult],dl

           mov  edx,fs:[eax+0]
           and  dl,0x07
           mov  fs:[ecx+xHCI_EP_CONTEXT->ep_state],dl
           
           ; dword 1
           mov  edx,fs:[eax+4]
           shr  edx,16
           mov  fs:[ecx+xHCI_EP_CONTEXT->max_packet_size],dx

           mov  edx,fs:[eax+4]
           shr  edx,8
           mov  fs:[ecx+xHCI_EP_CONTEXT->max_burst_size],dl

           mov  edx,fs:[eax+4]
           shr  edx,7
           and  dl,1
           mov  fs:[ecx+xHCI_EP_CONTEXT->hid],dl

           mov  edx,fs:[eax+4]
           shr  edx,3
           and  dl,0x7
           mov  fs:[ecx+xHCI_EP_CONTEXT->ep_type],dl

           mov  edx,fs:[eax+4]
           shr  edx,1
           and  dl,0x3
           mov  fs:[ecx+xHCI_EP_CONTEXT->cerr],dl

           ; dword 2
           mov  edx,fs:[eax+8]
           and  dl,0xF0
           mov  fs:[ecx+xHCI_EP_CONTEXT->tr_dequeue_pointer],edx

           mov  edx,fs:[eax+8]
           and  dl,1
           mov  fs:[ecx+xHCI_EP_CONTEXT->dcs],dl

           ; dword 3

           ; dword 4
           mov  edx,fs:[eax+16]
           shr  edx,16
           mov  fs:[ecx+xHCI_EP_CONTEXT->max_esit_payload],dx

           mov  edx,fs:[eax+16]
           mov  fs:[ecx+xHCI_EP_CONTEXT->average_trb_len],dx

           ret
xhci_read_ep endp

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
xhci_enumerate proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,4

xhci_enum_buffer    equ  [bp-4]
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the address to our return buffer
           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  xhci_enum_buffer,eax ; save for later

           ; count of bytes to transfer (should only return 18)
           mov  cx,fs:[ebx+USB_DEVICE->mps]
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the devices descriptor
           push dx
           mov  edi,offset request_device_str
           mov  dx,cs:[edi+USB_REQUEST->value]
           mov  al,PID_IN
           call xhci_control_packet
           pop  dx

           ; if we didn't return at least 8 bytes, there was an error
           cmp  eax,8
           jl   xhci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the max packet size for this device (control ep)
           mov  edi,xhci_enum_buffer
           call usb_get_mps
           mov  fs:[ebx+USB_DEVICE->mps],ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; reset the device again
           push ebx
           mov  bl,fs:[ebx+USB_DEVICE->xhci_protocol]
           call xhci_port_reset
           pop  ebx

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the address, without block to device
           mov  ah,0
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           call xhci_set_address
           call usb_get_address_id
           mov  fs:[ebx+USB_DEVICE->dev_addr],al
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we need to reset the control ep's dequeue pointer
           mov  eax,xHCI_CONTROL_EP
           call xhci_get_ep_context
           lea  ecx,[eax+xHCI_EP_CONTEXT->ring]
           mov  eax,fs:[ecx+xHCI_RING->address]
           mov  fs:[ecx+xHCI_RING->cur_trb],eax
           mov  byte fs:[ecx+xHCI_RING->cycle_bit],TRB_CYCLE_ON

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the devices descriptor
           mov  cx,18
           mov  edi,offset request_device_str
           mov  dx,cs:[edi+USB_REQUEST->value]
           mov  al,PID_IN
           call xhci_control_packet
           ; if we didn't return 18 bytes, there was an error
           cmp  eax,18
           jl   short xhci_enumerate_done

           ; if the class and subclass are not 0x00 & 0x00, then return
           mov  edi,xhci_enum_buffer
           cmp  word fs:[edi+4],0x0000   ; class and subclass == 0 ?
           jne  short xhci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; we need to get the configuration descriptor
           mov  cx,512
           mov  edi,offset request_config_str
           mov  dx,cs:[edi+USB_REQUEST->value]
           mov  al,PID_IN
           call xhci_control_packet
           ; if returned -1, error
           cmp  eax,-1
           jle  short xhci_enumerate_done
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now find the interface descriptor 
           ; check the class (08), subclass (06), and protocol (0x50)  BBB
           ; check the class (08), subclass (06), and protocol (0x62)  UASP
           ; check the class (08), subclass (04), and protocol (0x50)  CB(i) with BBB
           ; check the class (08), subclass (04), and protocol (0x01)  CBI
           ; check the class (08), subclass (04), and protocol (0x00)  CB
           ; and if so, retreive the device data
           mov  edi,xhci_enum_buffer    ; start address of config desc
           mov  cx,ax              ; length of config descriptor
           call usb_configure_device
           cmp  ax,2               ; must have at least 2 bulk endpoints found
           jb   short xhci_enumerate_done

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize the two endpoints
           call xhci_initialize_bulk_eps

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now send the Set Configuration Request
           xor  cx,cx                 ; length = 0
           movzx dx,byte fs:[edi + 5] ; configuration value
           mov  edi,offset request_set_config
           mov  al,PID_OUT
           call xhci_control_packet
           cmp  eax,-1
           jle  short xhci_enumerate_done

           ; return good enumeration
           xor  ax,ax
           mov  sp,bp
           pop  bp
           ret

xhci_enumerate_done:
           mov  ax,-1
           mov  sp,bp
           pop  bp
           ret
xhci_enumerate endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the two bulk endpoints
; on entry:
;  es -> EBDA
;  es:esi -> this USB_CONTROLLER structure
;  fs:ebx -> USB_DEVICE
; on return
;  nothing
; destroys none
xhci_initialize_bulk_eps proc near uses eax ecx edx ebp
           
           ; fs:esi -> endpoint info (in endpoint)
           lea  eax,[ebx+USB_DEVICE->endpoint_in]
           push eax              ; save location of endpoint context data

           ; ebp = high word = interval, low word = max_burst size
           movzx ebp,byte fs:[eax+USB_DEVICE_EP->ep_interval]
           shl  ebp,16
           movzx bp,byte fs:[eax+USB_DEVICE_EP->ep_max_burst]
           mov  cx,fs:[eax+USB_DEVICE_EP->ep_mps]
           mov  ah,fs:[eax+USB_DEVICE_EP->ep_val]
           mov  al,PID_IN
           call xhci_epnum_to_endpoint
           push eax              ; save the ep index
           mov  ah,BULK_EP       ; bulk
           mov  dl,0x80          ; IN
           mov  dh,fs:[ebx+USB_DEVICE->speed] ; speed of device
           call xhci_initialize_ep
           pop  eax              ; restore the ep index

           ; update the configuration by updating the controller's context
           mov  ah,al
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           call xhci_config_ep

           pop  eax              ; restore location of endpoint context data
           add  eax,sizeof(USB_DEVICE_EP)

           ; ebp = high word = interval, low word = max_burst size
           movzx ebp,byte fs:[eax+USB_DEVICE_EP->ep_interval]
           shl  ebp,16
           movzx bp,byte fs:[eax+USB_DEVICE_EP->ep_max_burst]
           mov  cx,fs:[eax+USB_DEVICE_EP->ep_mps]
           mov  ah,fs:[eax+USB_DEVICE_EP->ep_val]
           mov  al,PID_OUT
           call xhci_epnum_to_endpoint
           push eax              ; save the ep index
           mov  ah,BULK_EP       ; bulk
           mov  dl,0x00          ; OUT
           mov  dh,fs:[ebx+USB_DEVICE->speed] ; speed of device
           call xhci_initialize_ep
           pop  eax              ; restore the ep index

           ; update the configuration by updating the controller's context
           mov  ah,al
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           call xhci_config_ep
           
           ret
xhci_initialize_bulk_eps endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; send a control transfer to the controller
; on entry:
;  es -> EBDA
;  al = direction (PID_IN or PID_OUT)
;  cx = length of bytes to request
;  dx = request->value (dx = different purpose than uhci, ohci, ehci)
;  es:esi -> this USB_CONTROLLER structure
;  cs:edi -> request packet to send
;  fs:ebx -> USB_DEVICE
; on return
;  eax = size of buffer received
;      = negative value if error
; destroys none
xhci_control_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,24

xhci_ct_running_cnt    equ  [bp-2]   ; word
xhci_ct_tx_buffer      equ  [bp-6]   ; dword
xhci_ct_requ_buffer    equ  [bp-10]  ; dword
xhci_ct_requ_packet    equ  [bp-14]  ; dword
xhci_ct_event_status   equ  [bp-18]  ; dword
xhci_ct_mps            equ  [bp-20]  ; word
xhci_ct_value          equ  [bp-22]  ; word
xhci_ct_direction      equ  [bp-23]  ; byte

           ; save some items
           mov  xhci_ct_direction,al
           mov  xhci_ct_running_cnt,cx
           mov  xhci_ct_value,dx
           mov  xhci_ct_requ_packet,edi
           lea  eax,[ebx+USB_DEVICE->rxtx_buffer]
           mov  xhci_ct_tx_buffer,eax
           lea  eax,[ebx+USB_DEVICE->request]
           mov  xhci_ct_requ_buffer,eax
           lea  eax,[ebx+USB_DEVICE->event_status]
           mov  xhci_ct_event_status,eax
           mov  ax,fs:[ebx+USB_DEVICE->mps]
           mov  xhci_ct_mps,ax

           push esi              ; save the USB_CONTROLLER pointer
           push ebx              ; save the USB_DEVICE pointer

           ; point to this device's control endpoint
           lea  eax,[ebx+USB_DEVICE->ep_contexts]
           add  eax,sizeof(xHCI_EP_CONTEXT)
           lea  esi,[eax+xHCI_EP_CONTEXT->ring]

           ; eax -> xHCI_EP_CONTEXT
           ; esi -> xHCI_RING

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create SETUP packet
           mov  ebx,xhci_ct_requ_packet
           mov  cx,xhci_ct_running_cnt
           mov  dx,xhci_ct_value
           mov  al,xhci_ct_direction
           call xhci_setup_stage

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create DATA packet(s)
           mov  cx,xhci_ct_running_cnt
           or   cx,cx
           jz   short @f
           mov  edi,xhci_ct_event_status
           mov  ebx,xhci_ct_tx_buffer
           mov  ah,DATA_STAGE
           mov  al,xhci_ct_direction
           mov  dx,xhci_ct_mps
           call xhci_data_stage
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; create STATUS packet
@@:        mov  al,xhci_ct_direction
           call xhci_status_stage

           pop  ebx              ; restore the USB_DEVICE pointer
           pop  esi              ; restore the USB_CONTROLLER pointer
           
           ; ring the doorbell and wait for the event
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           mov  ah,xHCI_CONTROL_EP
           call xhci_process_doorbell

           xor  eax,eax
           cmp  word xhci_ct_running_cnt,0
           jz   short xhci_control_packet_done

           ; if successful, fs:eax -> xHCI_EVENT_STATUS block
           mov  ebx,xhci_ct_event_status
           mov  eax,fs:[ebx+xHCI_EVENT_STATUS->count]
           mov  cl,fs:[ebx+xHCI_EVENT_STATUS->status]
           cmp  cl,SHORT_PACKET
           je   short xhci_control_packet_done
           cmp  cl,TRB_SUCCESS
           je   short xhci_control_packet_done

           mov  eax,-1
xhci_control_packet_done:
           mov  sp,bp
           pop  bp
           ret
xhci_control_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; convert a given end point value (using direction) to EP context index
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  ah = endpoint number
; on return
;  eax = context index
; destroys none
xhci_epnum_to_endpoint proc near
           xchg ah,al

           ; is it the control ep?
           or   al,al
           jnz  short @f
           mov  eax,xHCI_CONTROL_EP
           ret

           ; convert ep to: xHCI_EPx_OUT or xHCI_EPx_IN
           ; endpoint = (epnum * 2) + ((dir == IN) ? 1 : 0)
@@:        shl  al,1
           cmp  ah,PID_IN
           jne  short @f
           inc  al
@@:        and  eax,0x000000FF
           ret
xhci_epnum_to_endpoint endp

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
xhci_do_bulk_packet proc near uses ebx ecx edx esi edi
           push bp
           mov  bp,sp
           sub  sp,18

xhci_bk_running_cnt    equ  [bp-2]   ; word
xhci_bk_tx_buffer      equ  [bp-6]   ; dword
xhci_bk_requ_packet    equ  [bp-10]  ; dword
xhci_bk_event_status   equ  [bp-14]  ; dword
xhci_bk_mps            equ  [bp-16]  ; word
xhci_bk_direction      equ  [bp-17]  ; byte
xhci_bk_ep_indx        equ  [bp-18]  ; byte
           
           ; save some items
           mov  xhci_bk_direction,al
           mov  xhci_bk_running_cnt,cx
           mov  xhci_bk_tx_buffer,edi
           lea  eax,[ebx+USB_DEVICE->event_status]
           mov  xhci_bk_event_status,eax

           push esi              ; save the USB_CONTROLLER pointer
           push ebx              ; save the USB_DEVICE pointer

           ; are we doing an in or an out
           lea  esi,[ebx+USB_DEVICE->endpoint_in]
           cmp  byte xhci_bk_direction,PID_IN
           je   short @f
           add  esi,sizeof(USB_DEVICE_EP)

           ; fs:esi -> endpoint info
           ; get the enpoint's mps
@@:        mov  ax,fs:[esi+USB_DEVICE_EP->ep_mps]
           mov  xhci_bk_mps,ax
           
           ; point to this device's bulk in/out ring
           mov  al,xhci_bk_direction
           mov  ah,fs:[esi+USB_DEVICE_EP->ep_val]
           call xhci_epnum_to_endpoint
           mov  xhci_bk_ep_indx,al
           imul eax,sizeof(xHCI_EP_CONTEXT)
           lea  ecx,[ebx+USB_DEVICE->ep_contexts]
           add  eax,ecx
           lea  esi,[eax+xHCI_EP_CONTEXT->ring]

           ; eax -> xHCI_EP_CONTEXT
           ; esi -> xHCI_RING

           mov  al,xhci_bk_direction
           mov  ah,NORMAL
           mov  cx,xhci_bk_running_cnt
           mov  dx,xhci_bk_mps
           mov  ebx,xhci_bk_tx_buffer
           mov  edi,xhci_bk_event_status
           call xhci_data_stage
           
           pop  ebx              ; restore the USB_DEVICE pointer
           pop  esi              ; restore the USB_CONTROLLER pointer

           ; ring the doorbell and wait for the event
           mov  al,fs:[ebx+USB_DEVICE->slot_id]
           mov  ah,xhci_bk_ep_indx
           call xhci_process_doorbell

           ; if successful, fs:eax -> xHCI_EVENT_STATUS block
           mov  ebx,xhci_bk_event_status
           mov  eax,fs:[ebx+xHCI_EVENT_STATUS->count]
           mov  cl,fs:[ebx+xHCI_EVENT_STATUS->status]
           cmp  cl,SHORT_PACKET
           je   short xhci_do_bulk_packet_done
           cmp  cl,TRB_SUCCESS
           je   short xhci_do_bulk_packet_done

           mov  eax,-1
xhci_do_bulk_packet_done:
           mov  sp,bp
           pop  bp
           ret
xhci_do_bulk_packet endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; create and insert Setup Packet
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  cx = length requested
;  dx = request->value
;  cs:ebx -> request packet to send
;  fs:esi -> XHCI_RING
; on return
;  nothing
; destroys none
xhci_setup_stage proc near uses eax edx edi
           push bp
           mov  bp,sp
           sub  sp,2

xhci_setup_value  equ  [bp-2]   ; word

           mov  xhci_setup_value,dx
           
           xor  edx,edx          ; assume no data
           or   cx,cx            ; if no data, no direction
           jz   short xhci_setup_nodir
           cmp  al,PID_IN
           jne  short @f
           mov  dl,3             ; in direction
           jmp  short xhci_setup_nodir
@@:        cmp  al,PID_OUT
           jne  short xhci_setup_nodir
           mov  dl,2             ; out direction
xhci_setup_nodir:
           push edx
           
           ; point to the current TRB
           mov  edi,fs:[esi+xHCI_RING->cur_trb]
           
           ; build request packet in param
           movzx eax,word xhci_setup_value ; USB_REQUEST->value
           shl  eax,16
           mov  ah,cs:[ebx+USB_REQUEST->request]
           mov  al,cs:[ebx+USB_REQUEST->request_type]
           shl  ecx,16           ; cx = USB_REQUEST->length
           mov  cx,cs:[ebx+USB_REQUEST->index]
           mov  fs:[edi+xHCI_TRB->param+0],eax
           mov  fs:[edi+xHCI_TRB->param+4],ecx
           mov  dword fs:[edi+xHCI_TRB->status],((0 << 22) | 8)
           
           pop  eax              ; restore direction
           shl  eax,16           ; at bit 16
           or   eax,((SETUP_STAGE << 10) | (1 << 6) | (0 << 5))
           or   al,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],eax

           mov  al,1  ; chain bit
           call xhci_get_next_trb

           mov  sp,bp
           pop  bp
           ret
xhci_setup_stage endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; create and insert Data Packet(s)
; on entry:
;  al = direction (PID_IN or PID_OUT)
;  ah = type
;  cx = count of bytes to transfer
;  dx = max packet size for this endpoint
;  fs:ebx -> buffer to store data
;  fs:esi -> XHCI_RING
;  fs:edi -> event status return buffer
; on return
;  fs:eax -> EVENT_DATA TRB
; destroys none
xhci_data_stage proc near uses ecx edx edi
           push bp
           mov  bp,sp
           sub  sp,12

xhci_data_stage_mps    equ  [bp-2]
xhci_data_stage_cnt    equ  [bp-4]
xhci_data_stage_indx   equ  [bp-6]
xhci_data_stage_dir    equ  [bp-7]
xhci_data_stage_type   equ  [bp-8]
xhci_data_event_status equ  [bp-12]

           mov  xhci_data_stage_mps,dx
           mov  xhci_data_stage_cnt,cx
           mov  xhci_data_stage_type,ah
           mov  xhci_data_event_status,edi

           mov  byte xhci_data_stage_dir,0  ; assume out direction
           cmp  al,PID_IN
           jne  short @f
           mov  byte xhci_data_stage_dir,1  ; in direction

           ; calculate the count of trbs we will need
@@:        xor  dx,dx
           mov  ax,xhci_data_stage_cnt
           add  ax,xhci_data_stage_mps
           dec  ax
           div  word xhci_data_stage_mps
           dec  ax
           mov  xhci_data_stage_indx,ax

xhci_data_stage_loop:
           ; point to the current TRB
           mov  edi,fs:[esi+xHCI_RING->cur_trb]

           mov  fs:[edi+xHCI_TRB->param+0],ebx
           mov  dword fs:[edi+xHCI_TRB->param+4],0
           
           movzx eax,word xhci_data_stage_indx
           shl  eax,17
           movzx ecx,word xhci_data_stage_cnt
           cmp  cx,xhci_data_stage_mps
           jbe  short @f
           mov  cx,xhci_data_stage_mps
@@:        or   eax,ecx
           mov  fs:[edi+xHCI_TRB->status],eax
           
           movzx eax,byte xhci_data_stage_dir
           shl  eax,16           ; at bit 16
           movzx ecx,byte xhci_data_stage_type
           shl  ecx,10
           or   eax,ecx
           or   eax,((0 << 9) | (0 << 6) | (0 << 5) | (1 << 4) | (0 << 3) | (0 << 2))
           cmp  word xhci_data_stage_indx,0
           jne  short @f
           or   eax,(1<<1)
@@:        or   al,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],eax
           
           ; move to next position
           movzx ecx,word xhci_data_stage_mps
           add  ebx,ecx

           mov  al,1  ; chain bit
           call xhci_get_next_trb

           dec  word xhci_data_stage_indx

           mov  cx,xhci_data_stage_mps
           sub  xhci_data_stage_cnt,cx
           cmp  word xhci_data_stage_cnt,0
           jnle xhci_data_stage_loop

           ; do event data trb
           mov  edi,fs:[esi+xHCI_RING->cur_trb]
           mov  eax,xhci_data_event_status
           mov  fs:[edi+xHCI_TRB->param+0],eax
           mov  dword fs:[edi+xHCI_TRB->param+4],0
           mov  dword fs:[edi+xHCI_TRB->status],0
           mov  eax,((EVENT_DATA << 10) | (1 << 5) | (0 << 4) | (0 << 1))
           or   al,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],eax

           mov  al,0  ; chain bit
           call xhci_get_next_trb

           mov  eax,edi
           mov  sp,bp
           pop  bp
           ret
xhci_data_stage endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; create and insert Status Packet
; on entry:
;  al = direction (PID_IN or PID_OUT) (must be opposite)
;  fs:esi -> XHCI_RING
; on return
;  fs:eax -> EVENT_DATA TRB
; destroys none
xhci_status_stage proc near uses edx edi
           push bp
           mov  bp,sp
           sub  sp,2

xhci_status_stage_dir   equ  [bp-1]

           mov  byte xhci_status_stage_dir,0  ; assume out direction
           cmp  al,PID_IN
           je   short @f
           mov  byte xhci_status_stage_dir,1  ; in direction

@@:        ; point to the current TRB
           mov  edi,fs:[esi+xHCI_RING->cur_trb]
           
           mov  dword fs:[edi+xHCI_TRB->param+0],0
           mov  dword fs:[edi+xHCI_TRB->param+4],0
           mov  dword fs:[edi+xHCI_TRB->status],(0 << 22)
           
           movzx eax,byte xhci_status_stage_dir
           shl  eax,16           ; at bit 16
           or   eax,((STATUS_STAGE << 10) | (0 << 5) | (1 << 4) | (0 << 1))
           or   al,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],eax
           
           ; move to next position
           mov  al,1  ; chain bit
           call xhci_get_next_trb
           mov  edi,eax

           ; do event data trb
           mov  dword fs:[edi+xHCI_TRB->param+0],0
           mov  dword fs:[edi+xHCI_TRB->param+4],0
           mov  dword fs:[edi+xHCI_TRB->status],0
           mov  eax,((EVENT_DATA << 10) | (1 << 5) | (0 << 4) | (0 << 1))
           or   al,fs:[esi+xHCI_RING->cycle_bit]
           mov  fs:[edi+xHCI_TRB->command],eax

           mov  al,0  ; chain bit
           call xhci_get_next_trb

           mov  eax,edi

           mov  sp,bp
           pop  bp
           ret
xhci_status_stage endp

.endif  ; DO_INIT_BIOS32

.end
