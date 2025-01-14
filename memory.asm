comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: memory.asm                                                         *
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
*   memory services file                                                   *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.15                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 8 Dec 2024                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

memory_panic_string  db  'PANIC: file: ', %FILE, ' -- line: %i',13,10,0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; build the memory table
; on entry:
;  nothing
; on return
;  nothing
; destroys none
; this builds an 15h/E820 style memory table where said service
;  can then simply copy the selected entry.
;  (other functions will be able to add/merge entries)
; this uses the EBDA to store the table
build_mem_table proc near uses eax ebx ecx edx si di es
           
           ; es = EBDA_SEG
           mov  ax,EBDA_SEG
           mov  es,ax

           ; clear out the table
           ;mov  word es:[EBDA_DATA->memory_count],0
           mov  di,EBDA_DATA->memory_table
           mov  cx,(sizeof(MEM_TABLE) * MEM_TABLE_ENTRIES)
           xor  al,al
           rep
             stosb
           
           ; start with entry 0
           mov  di,EBDA_DATA->memory_table
           xor  si,si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 0
           ; Low memory, start of first megabyte
           ;  base: 0x0000000000000000
           ;  size: BASE_MEM_IN_K * 1024
           xor  edx,edx                     ; base high dword
           xor  eax,eax                     ; base low dword
           xor  ecx,ecx                     ; size high dword
           mov  ebx,(BASE_MEM_IN_K * 1024)  ; size low dword
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RAM
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 1
           ; Extended BIOS Data Area
           ;  size: EBDA_SIZE * 1024
           ;xor  ecx,ecx                     ; size high dword
           mov  ebx,(EBDA_SIZE * 1024)      ; size low dword
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RESERVED
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; the space between 0xA0000 -> 0xE8000 is not accounted for ???

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 2
           ; Video RAM / BIOS, etc to 1Meg
           ;  size: 1Meg - 0xE8000
           ;xor  ecx,ecx                     ; size high dword
           mov  ebx,((1024 * 1024) - 0xE8000) ; size low dword
           mov  eax,0xE8000
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RESERVED
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 3
           ; User Memory starting at 1Meg
           ;  size: 1Meg - to end of physical memory
           ;  (not to be more than 0x2FC000 (~3Gig))
           ; (This block will be resized if we have ACPI or other items)
           xor  ebx,ebx
           push ax
           mov  ah,0x34          ; extended memory in 64k (low byte)
           call cmos_get_byte
           mov  bl,al
           mov  ah,0x35          ; extended memory in 64k (high byte)
           call cmos_get_byte
           mov  bh,al            ; ebx = extended memory in 64k
           pop  ax
           shl  ebx,6            ; multiply by 64 (65536 * 64 will still fit in a 32-bit register)
           cmp  ebx,0x2FC000
           jbe  short @f
           mov  ebx,0x2FC000     ; limit to ~3 gig
@@:        ;xor  ecx,ecx
           ;shld ecx,ebx,10      ; multiply by 1024
           shl  ebx,10
           add  ebx,(15 * 1024 * 1024) ; above 16 meg (minus the meg we are at)
.if DO_INIT_BIOS32
           sub  ebx,BIOS_EXT_MEMORY_USE
           sub  ebx,ACPI_DATA_SIZE
.endif
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RAM
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si

.if DO_INIT_BIOS32
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 4
           ; RAM reserved for the BIOS
           mov  ebx,BIOS_EXT_MEMORY_USE
           ;xor  ecx,ecx
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RESERVED
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; store this base memory size in the EBDA
           mov  es:[EBDA_DATA->mem_base_ram_size],eax

.if DO_INIT_BIOS32
           add  dword es:[EBDA_DATA->mem_base_ram_size],ACPI_DATA_SIZE

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 5
           ; ACPI 64k at end of physical RAM
           ; (only add this entry if ACPI is not already
           ;  within the 0xFFFC0000->0xFFFFFFFF area)
           ; *todo*: we do this before we detect the ACPI
           ;         we should not add this entry now.
           ;         in the ACPI code, all mem_add_entry() or something like that...
           cmp  eax,0xFFFC0000
           ja   short @f
           ;xor  edx,edx                     ;
           ;xor  ecx,ecx                     ; size high dword
           mov  ebx,ACPI_DATA_SIZE           ; size low dword
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_ACPI
           add  di,sizeof(MEM_TABLE)
           add  eax,ACPI_DATA_SIZE
           ;adc  edx,ecx
           inc  si
.endif

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 6
           ; 256k BIOS area at the end of 4Gig
           ;  size: 256k
@@:        ;xor  edx,edx                     ;
           mov  eax,0xFFFC0000              ;
           ;xor  ecx,ecx                     ; size high dword
           mov  ebx,(256 * 1024)            ; size low dword
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RESERVED
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           ;adc  edx,ecx
           inc  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; entry 7 (optional)
           ; Any User memory at and above 4 gig
           mov  edx,0x00000001   ;(in 64k)
           xor  eax,eax          ;
           xor  ebx,ebx
           push ax
           mov  ah,0x5D          ; extra memory above 4gig (in 64k) (high byte)
           call cmos_get_byte
           mov  bl,al            
           shl  ebx,8
           mov  ah,0x5C          ; extra memory above 4gig (in 64k) (mid byte)
           call cmos_get_byte
           mov  bl,al            
           shl  ebx,8
           mov  ah,0x5B          ; extra memory above 4gig (in 64k) (low byte)
           call cmos_get_byte
           mov  bl,al            ; ebx = extra memory above 4gig (in 64k)
           pop  ax
           or   ebx,ebx          ; is it zero
           jz   short @f
           xor  ecx,ecx
           shld ecx,ebx,16       ; multiply by 64k
           shl  ebx,16
           mov  es:[di+MEM_TABLE->mem_base+0],eax
           mov  es:[di+MEM_TABLE->mem_base+4],edx
           mov  es:[di+MEM_TABLE->mem_size+0],ebx
           mov  es:[di+MEM_TABLE->mem_size+4],ecx
           mov  dword es:[di+MEM_TABLE->mem_type],E820_RAM
           add  di,sizeof(MEM_TABLE)
           add  eax,ebx
           adc  edx,ecx
           inc  si

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; store this memory size in the EBDA (memory above 4gig)
           mov  es:[EBDA_DATA->mem_base_ext_ram_size+0],ebx
           mov  es:[EBDA_DATA->mem_base_ext_ram_size+4],ecx

@@:        ; store the count of entries
           mov  es:[EBDA_DATA->memory_count],si

.if DO_INIT_BIOS32
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; initialize our memory allocation routine
           mov  eax,es:[EBDA_DATA->mem_base_ram_size]
           sub  eax,ACPI_DATA_SIZE
           sub  eax,BIOS_EXT_MEMORY_USE
           mov  es:[EBDA_DATA->mem_base_ram_alloc],eax
           call memory_initial_mcb
.endif

           ret
build_mem_table endp

;;; need to add a function to 'split' a memE820 entry above



.if DO_INIT_BIOS32

; 16 bytes
MEMORY_MCB struct
  signature  dword   ; 'FREE' or 'USED' (little-endian)
  base       dword   ; the address of this MCB
  size       dword   ; size in bytes (not counting this MCB)
  reserved   dword   ; 
MEMORY_MCB ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize our MCB memory allocator
;  this starts at 64k (ACPI) minus BIOS_EXT_MEMORY_USE from top of memory
;  we use a simple MCB DOS style memory allocator
; on entry:
;  eax = base of memory used ([EBDA_DATA->mem_base_ram_alloc])
; on return
;  nothing
; destroys none
memory_initial_mcb proc near uses ds
           ; create a single free block at the base
           mov  dword fs:[eax+MEMORY_MCB->signature],'FREE'
           mov        fs:[eax+MEMORY_MCB->base],eax
           mov  dword fs:[eax+MEMORY_MCB->size],(BIOS_EXT_MEMORY_USE - sizeof(MEMORY_MCB))
           mov  dword fs:[eax+MEMORY_MCB->reserved],0

           ret
memory_initial_mcb endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; allocate an aligned physical memory block
; on entry:
;  eax = size
;  ecx = alignment (must be 1 or a power of 2, and not zero)
;    will return a minimum of a 16-byte alignment
;    will create a MCB between found MCB and newly aligned memory
;    if alignment is 32 and a 16-byte MCB is needed for this aligment,
;     an MCB with a size of zero will be created.
;  cs:dx = offset to debug string
; on return
;  eax = physical base address (MCB + sizeof(MCB))
; destroys none
memory_allocate proc near uses ebx ecx edx edi esi ebp ds
           movzx esi,dx

           push ax
           call bios_get_ebda
           mov  ds,ax
           pop  ax

           ; memory size must be of 16-byte blocks
           add  eax,15
           and  eax,(~15)

           ; at least a 16-byte alignment
           cmp  ecx,16
           jnb  short @f
           mov  ecx,16

           ; scroll through the MCB's until we find an entry that fits
@@:        mov  edi,[EBDA_DATA->mem_base_ram_alloc]
           mov  ebp,edi
           add  ebp,BIOS_EXT_MEMORY_USE
           ; ebp = end of allocation block
memory_alloc_loop:
           push ecx
           cmp  dword fs:[edi+MEMORY_MCB->signature],'FREE'
           jne  memory_alloc_next
           
           ; determine if we will fit here including alignment
           mov  edx,fs:[edi+MEMORY_MCB->base]
           add  edx,sizeof(MEMORY_MCB)  ; to skip over current MCB
           dec  ecx
           add  edx,ecx
           not  ecx
           and  edx,ecx
           mov  ebx,edx
           sub  edx,sizeof(MEMORY_MCB)
           sub  edx,fs:[edi+MEMORY_MCB->base]
           mov  ecx,edx
           add  edx,eax
           ; ebx = aligned address
           ; ecx = size between base and aligned address
           ; edx = size needed to fit in this slot
           cmp  fs:[edi+MEMORY_MCB->size],edx
           jb   short memory_alloc_next

           ; eax = size of memory wanted
           ; ebx = aligned address
           ; ecx = size between base and aligned address
           ; edx = size needed to fit in this slot
           ; edi = start of this MCB
           mov  edx,fs:[edi+MEMORY_MCB->size]  ; save current size

           ; if the aligned address is just after our MCB, use this MCB
           or   ecx,ecx
           jz   short @f

           ; adjust the size of the current MCB (could be zero)
           mov  fs:[edi+MEMORY_MCB->size],ecx
           sub  dword fs:[edi+MEMORY_MCB->size],sizeof(MEMORY_MCB)
           
           ; move to the new MCB
           add  edi,ecx

           ; create a new MCB
@@:        mov  dword fs:[edi+MEMORY_MCB->signature],'USED'
           mov        fs:[edi+MEMORY_MCB->base],edi
           mov        fs:[edi+MEMORY_MCB->size],eax
           mov        fs:[edi+MEMORY_MCB->reserved],esi
           
           ; calculate size of slot after this new one and before the next one
           push edi              ; save location of this MCB
           sub  edx,ecx          ; sub the space between original base and aligned base
           sub  edx,eax          ; sub size of wanted memory
           add  edi,sizeof(MEMORY_MCB)
           add  edi,eax          ;
           pop  eax              ; restore location of this MCB for return value

           ; edx = remaining size to next mcb/end of memory blocks
           ; edi = byte just after last created block
           ; calculate size between here and the next block
           or   edx,edx
           jz   short memory_alloc_done

           ; need to create a 'free' MCB here
           sub  edx,sizeof(MEMORY_MCB)
           mov  dword fs:[edi+MEMORY_MCB->signature],'FREE'
           mov        fs:[edi+MEMORY_MCB->base],edi
           mov        fs:[edi+MEMORY_MCB->size],edx
           mov  dword fs:[edi+MEMORY_MCB->reserved],0

           jmp  short memory_alloc_done

memory_alloc_next:
           pop  ecx
           add  edi,fs:[edi+MEMORY_MCB->size]
           add  edi,sizeof(MEMORY_MCB)
           cmp  edi,ebp
           jb   memory_alloc_loop

memory_alloc_panic:
           ; else we didn't find a block....so panic
           push cs
           pop  ds
           push %LINE
           mov  si,offset memory_panic_string
           call bios_printf
           add  sp,2
           call freeze

memory_alloc_done:
 ;xchg cx,cx
 ; writemem "C:\bochs\images\win95\dd.bin" 0x1FFD0000 0x30000
           add  eax,sizeof(MEMORY_MCB)
           pop  ecx

           ret
memory_allocate endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; free a physical memory block
; on entry:
;  eax = memory base
; on return
;  nothing
; destroys none
memory_free proc near uses alld ds
           push ax
           call bios_get_ebda
           mov  ds,ax
           pop  ax
           
           mov  edi,eax
           sub  edi,sizeof(MEMORY_MCB)
           cmp  dword fs:[edi+MEMORY_MCB->signature],'USED'
           jne  short memory_alloc_panic

           ; mark it as free
           mov  dword fs:[edi+MEMORY_MCB->signature],'FREE'

           ; now start at the beginning and combine all free blocks
memory_free_loop_0:
           mov  edi,[EBDA_DATA->mem_base_ram_alloc]
           mov  ebp,edi
           add  ebp,BIOS_EXT_MEMORY_USE
           ; ebp = end of allocation block
memory_free_loop_1:
           cmp  dword fs:[edi+MEMORY_MCB->signature],'FREE'
           jne  short memory_free_next

           ; is the next one free?
           mov  esi,edi
           add  esi,fs:[edi+MEMORY_MCB->size]
           add  esi,sizeof(MEMORY_MCB)
           cmp  esi,ebp
           jae  short memory_free_done
           cmp  dword fs:[esi+MEMORY_MCB->signature],'FREE'
           jne  short memory_free_next

           ; it is free, so update this one
           mov  eax,fs:[esi+MEMORY_MCB->size]
           add  eax,sizeof(MEMORY_MCB)
           add  fs:[edi+MEMORY_MCB->size],eax

           ; clear out the unused one so we don't mistake it as used
           mov  dword fs:[esi+MEMORY_MCB->signature],0
           mov  dword fs:[esi+MEMORY_MCB->base],0
           mov  dword fs:[esi+MEMORY_MCB->size],0
           mov  dword fs:[esi+MEMORY_MCB->reserved],0
           jmp  short memory_free_loop_0 ; start over
           
memory_free_next:
           add  edi,fs:[edi+MEMORY_MCB->size]
           add  edi,sizeof(MEMORY_MCB)
           cmp  edi,ebp
           jb   short memory_free_loop_1

memory_free_done:
           ret
memory_free endp


comment `

mem_uhci_device_data  db  '(UHCI: Device Data)',0
mem_uhci_stack        db  '(UHCI: Stack)',0
mem_ohci_device_data  db  '(OHCI: Device Data)',0
mem_ohci_stack        db  '(OHCI: Stack)',0
mem_ehci_device_data  db  '(EHCI: Device Data)',0
mem_ehci_stack        db  '(EHCI: Async List)',0
mem_xhci_device_data  db  '(XHCI: Device Data)',0
mem_xhci_slots        db  '(XHCI: Slots)',0
mem_xhci_dcbaap       db  '(XHCI: dcbaap)',0
mem_xhci_ring         db  '(XHCI: ring)',0
mem_xhci_event_ring   db  '(XHCI: event ring)',0
mem_xhci_ext_caps     db  '(XHCI: ext caps)',0
mem_null_str          db  0

mem_show_string  db  '%c%c%c%c  base=0x%08lX  size=%li  %s',13,10,0
mem_show_done    db  'Total: Used: %li, Free: %li',13,10,0

memory_show proc near uses alld ds es
           push bp
           mov  bp,sp
           sub  sp,8

memory_show_free    equ  [bp-4]  ; dword
memory_show_used    equ  [bp-8]  ; dword

           mov  ax,EBDA_SEG
           mov  es,ax

           push cs
           pop  ds

           mov  dword memory_show_free,0
           mov  dword memory_show_used,0

           mov  edi,es:[EBDA_DATA->mem_base_ram_alloc]
           xor  esi,esi
memory_show_loop:
           mov  eax,fs:[edi+esi+MEMORY_MCB->signature]
           mov  ebx,fs:[edi+esi+MEMORY_MCB->base]
           add  ebx,16
           mov  ecx,fs:[edi+esi+MEMORY_MCB->size]
           mov  edx,fs:[edi+esi+MEMORY_MCB->reserved]

           cmp  eax,'FREE'
           jne  short @f
           add  memory_show_free,ecx
           jmp  short memory_show_0
@@:        add  memory_show_used,ecx
memory_show_0:

           push esi

           mov  ax,offset mem_null_str
           or   edx,edx
           jz   short @f
           mov  ax,dx
@@:        push ax

           push ecx
           push ebx
           
           xor  ah,ah
           mov  al,fs:[edi+esi+MEMORY_MCB->signature+0]
           push ax
           mov  al,fs:[edi+esi+MEMORY_MCB->signature+1]
           push ax
           mov  al,fs:[edi+esi+MEMORY_MCB->signature+2]
           push ax
           mov  al,fs:[edi+esi+MEMORY_MCB->signature+3]
           push ax

           mov  si,offset mem_show_string
           call bios_printf
           add  sp,((4*2) + (2*4) + (1*2))
           pop  esi

           add  esi,ecx
           add  esi,sizeof(MEMORY_MCB)
           cmp  esi,BIOS_EXT_MEMORY_USE
           jb   short memory_show_loop

           push dword memory_show_free
           push dword memory_show_used
           mov  si,offset mem_show_done
           call bios_printf
           add  sp,(4*2)

 ; writemem "C:\bochs\images\win95\dd.bin" 0x1FFD0000 0x40000
 ; BIOS_EXT_MEMORY_USE   equ  (65536 * 2)  =  0x1FFD0000 -> 0x1FFEFFFF

           mov  sp,bp
           pop  bp
           ret
memory_show endp
`

.endif

.end
