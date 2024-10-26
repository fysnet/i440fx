comment |*******************************************************************
*  Copyright (c) 1984-2024    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: escd.asm                                                           *
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
*   escd include file                                                      *
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

FLASH_READ_ARRAY    equ  0xFF
FLASH_INT_ID        equ  0x90
FLASH_READ_STATUS   equ  0x70
FLASH_CLR_STATUS    equ  0x50
FLASH_ERASE_SETUP   equ  0x20
FLASH_ERASE_SUSP    equ  0xB0
FLASH_PROG_SETUP    equ  0x40
FLASH_ERASE         equ  0xD0

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; the following is the format of the ESCD that we use.
; the first part is specification correct, while the last part is this bios defined.
;
ESCD_DATA  struct
  size           word    ; size of the 'ESCD correct' data (right now, just this header = 12)
  signature      dword   ; "ACFG"
  minor_ver      byte    ; minor version number
  major_ver      byte    ; major version number (0x02)
  board_cnt      byte    ; number of board entries
  resv0          dup 3   ; reserved



  ; data items specific to this bios (non-ESCD specs stuff)
  ehci_legacy    byte    ; 0 = enumerate ehci devices, 1 = enumerate all hs devices as fs on companion controllers
  num_lock       byte    ; 0 = leave the num lock off, 1 = turn on num_lock at boot time
  boot_delay     byte    ; number of seconds to wait for a F12 press before boot (0 means no delay, 3 = default)
  ahci_legacy    byte    ; 0 = enumerate ahci devices, 1 = enumerate all capable ahci devices as edi devices

  ; floppy boot signature check (cmos item as well) ???


ESCD_DATA  ends

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; was the ESCD read from the flash memory?
; if not, clear it to initialize it
; on entry:
;  nothing
; on return
;  nothing
; destroys none
bios_escd_init proc near uses ax bx cx ds es
           mov  ax,BIOS_BASE2
           mov  ds,ax
           mov  ax,EBDA_SEG
           mov  es,ax

           ; if the data was read from the flash memory,
           ;  the ESCD header will be present
           cmp  dword [0xC000 + ESCD_DATA->signature],"ACFG"
           je   short bios_escd_init_done
           
           ; if it was not read, we need to clear it out
           ; and create default values
           xor  al,al
           mov  bx,0xC000
           mov  cx,0x2000
@@:        mov  [bx],al
           inc  bx
           loop @b

           mov  bx,0xC000
           mov  word [bx+ESCD_DATA->size],12
           mov  dword [bx+ESCD_DATA->signature],"ACFG"
          ;mov  byte [bx+ESCD_DATA->minor_ver],0
           mov  byte [bx+ESCD_DATA->major_ver],2
          ;mov  byte [bx+ESCD_DATA->board_cnt],0



          ;mov  byte [bx+ESCD_DATA->ehci_legacy],0
           mov  byte [bx+ESCD_DATA->num_lock],1
           mov  byte [bx+ESCD_DATA->boot_delay],3
          ;mov  byte [bx+ESCD_DATA->ahci_legacy],0
           
           ; mark it as dirty
           mov  byte es:[EBDA_DATA->escd_dirty],1

bios_escd_init_done:
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; now per the escd data, initialize a few items
           ; ds:bx -> BIOS_BASE2:ESCD
           mov  bx,0xC000
           
           ; es now set to 0x0040
           mov  ax,0x0040
           mov  es,ax

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; make sure all LEDs are off, and corresponding states are set
           ; (may set the num-lock state if the user has set this above)
           mov  al,es:[0x0017]
           and  al,00001111b
           cmp  byte [bx+ESCD_DATA->num_lock],0
           je   short @f
           or   al,00100000b
@@:        mov  es:[0x0017],al
           ; calling any keyboard service (int 16h) will set/clear the
           ;  states and LEDs for us
           mov  ah,02h           ; get the status
           int  16h

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; next item...




           ret
bios_escd_init endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; read a value from the escd
; on entry:
;   bx = offset within escd to read from
;   cx = length of value to write (in bytes)
; on return
;  eax = value read (al, ax, or eax)
; destroys none
bios_read_escd proc near uses bx ds
           mov  ax,BIOS_BASE2
           mov  ds,ax
           
           cmp  bx,0x2000
           jae  short bios_read_escd_done
           
           add  bx,0xC000
           xor  eax,eax
@@:        shl  eax,8
           mov  al,[bx]
           inc  bx
           loop @b
           
bios_read_escd_done:           
           ret
bios_read_escd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write a value to the escd
;  use this routine to write to the escd instead of directly writing
;  to that memory since this will mark it as dirty.
; on entry:
;  eax = value to write (al, ax, or eax)
;   bx = offset within escd to write it to
;   cx = length of value to write (in bytes)
; on return
;  nothing
; destroys none
bios_write_escd proc near uses bx cx dx es ds
           mov  dx,EBDA_SEG
           mov  es,dx
           mov  dx,BIOS_BASE2
           mov  ds,dx
           
           cmp  bx,0x2000
           jae  short bios_write_escd_done
           
           add  bx,offset escd
@@:        mov  [bx],al
           inc  bx
           shr  eax,8
           loop @b
           
           mov  byte es:[EBDA_DATA->escd_dirty],1

bios_write_escd_done:           
           ret
bios_write_escd endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; write the escd back to flash rom
; (* is a far procedure *)
; on entry:
;  nothing
; on return
;  nothing
; destroys none
bios_commit_escd proc far uses all es ds
           mov  ax,EBDA_SEG
           mov  es,ax
           mov  ax,BIOS_BASE2
           mov  ds,ax

           cmp  byte es:[EBDA_DATA->escd_dirty],0
           je   short bios_commit_escd_done
           
           ; did we find the i440x pci to isa bridge?
           mov  bx,es:[EBDA_DATA->i440_pciisa]
           or   bx,bx
           jz   short bios_commit_escd_done

           ; activate the BIOS eeprom (set bit 2 in register 0x4E)
           mov  ax,0xB108
           mov  di,0x4E
           int  1Ah
           or   cl,0x4
           mov  ax,0xB10B
           int  1Ah

           ; erase the area from 0x000FC000 to 0x000FCFFFF
           mov  byte [0xC000],FLASH_ERASE_SETUP
           mov  byte [0xC000],FLASH_ERASE

           ; copy the area from 0x000FC000 to 0x000FCFFF to the chip
           mov  cx,0x1000
           mov  bx,0xC000
@@:        mov  al,[bx]
           mov  byte [0xC000],FLASH_PROG_SETUP
           mov  [bx],al
           inc  bx
           loop @b

           ; erase the area from 0x000FD000 to 0x000FDFFF
           mov  byte [0xD000],FLASH_ERASE_SETUP
           mov  byte [0xD000],FLASH_ERASE

           ; copy the area from 0x000FD000 to 0x000FDFFF to the chip
           mov  cx,0x1000
          ;mov  bx,0xD000
@@:        mov  al,[bx]
           mov  byte [0xD000],FLASH_PROG_SETUP
           mov  [bx],al
           inc  bx
           loop @b

           ; deactivate the BIOS eeprom (clear bit 2 in register 0x4E)
           mov  ax,0xB108
           mov  di,0x4E
           int  1Ah
           and  cl,(~0x4)
           mov  ax,0xB10B
           int  1Ah

           mov  byte es:[EBDA_DATA->escd_dirty],0

bios_commit_escd_done:
           retf
bios_commit_escd endp

.end
