comment |*******************************************************************
*  Copyright (c) 1984-2025    Forever Young Software  Benjamin David Lunt  *
*                                                                          *
*                         i440FX BIOS ROM v1.0                             *
* FILE: rtc.asm                                                            *
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
*   rtc include file                                                       *
*                                                                          *
* BUILT WITH:   NewBasic Assembler                                         *
*                 http://www.fysnet/newbasic.htm                           *
*               NBASM ver 00.27.14                                         *
*          Command line: nbasm i440fx /z<enter>                            *
*                                                                          *
* Last Updated: 6 Jan 2025                                                 *
*                                                                          *
****************************************************************************
* Notes:                                                                   *
*                                                                          *
***************************************************************************|

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; initialize the RTC
; on entry:
;  nothing
; on return
;  nothing
; destroys all general
init_rtc   proc near
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set the interrupt vectors
           mov  ax,0x1A
           mov  bx,offset int1A_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           mov  ax,0x1C
           mov  bx,offset int1C_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           mov  ax,0x4A
           mov  bx,offset dummy_handler
           mov  cx,BIOS_BASE
           call set_int_vector
           mov  ax,0x70
           mov  bx,offset int70_handler
           mov  cx,BIOS_BASE
           call set_int_vector

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; Setup the Timer Ticks Count (0x46C:dword) and
           ;   Timer Ticks Roller Flag (0x470:byte)
           ; The Timer Ticks Count needs to be set according to
           ; the current CMOS time, as if ticks have been occurring
           ; at 18.2hz since midnight up to this point.  Calculating
           ; this is a little complicated.  Here are the factors I gather
           ; regarding this.  14,318,180 hz was the original clock speed,
           ; chosen so it could be divided by either 3 to drive the 5Mhz CPU
           ; at the time, or 4 to drive the CGA video adapter.  The div3
           ; source was divided again by 4 to feed a 1.193Mhz signal to
           ; the timer.  With a maximum 16bit timer count, this is again
           ; divided down by 65536 to 18.2hz.
           ;
           ; 14,318,180 Hz clock
           ;   /3 = 4,772,726 Hz fed to original 5Mhz CPU
           ;   /4 = 1,193,181 Hz fed to timer
           ;   /65536 (maximum timer count) = 18.20650736 ticks/second
           ; 1 second = 18.20650736 ticks
           ; 1 minute = 1092.390442 ticks
           ; 1 hour   = 65543.42651 ticks
           ;
           ; Given the values in the CMOS clock, one could calculate
           ; the number of ticks by the following:
           ;   ticks = (BcdToBin(seconds) * 18.206507) +
           ;           (BcdToBin(minutes) * 1092.3904)
           ;           (BcdToBin(hours)   * 65543.427)
           ; To get a little more accuracy, since Im using integer arithmetic, I use:
           ;   ticks = (((BcdToBin(hours) * 60 + BcdToBin(minutes)) * 60 + BcdToBin(seconds)) * (18 * 4294967296 + 886942379)) / 4294967296
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get CMOS hours
           mov  ah,0x04
           call cmos_get_byte
           and  eax,0xFF
           call bcd_to_bin       ; eax now has hours in binary
           imul edx,eax,60

           ; get CMOS minutes
           mov  ah,0x02
           call cmos_get_byte
           and  eax,0xFF
           call bcd_to_bin       ; eax now has minutes in binary
           add  eax,edx
           imul edx,eax,60

           ; get CMOS seconds
           mov  al,0x00
           call cmos_get_byte
           and  eax,0xFF
           call bcd_to_bin       ; eax now has seconds in binary
           add  eax,edx
           
           ; multiplying 18.2065073649
           mov  ecx,eax
           imul ecx,18
           
           mov  edx,886942379
           mul  edx
           add  ecx,edx
           
           mov  es:[0x046C],ecx  ; Timer Ticks Count
           xor  al,al
           mov  es:[0x0470],al   ; Timer Ticks Rollover Flag

           ret
init_rtc   endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Check to see if the RTC is currently in the update stage
; on entry:
;  nothing
; on return
;  al = 1 if never transitions out of the update stage
; destroys nothing
rtc_updating proc near uses cx
           mov  cx,25000
           mov  ah,0x0A
@@:        call cmos_get_byte
           and  al,0x80
           jz   short @f
           loop @b
           mov  al,1
@@:        ret
rtc_updating endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; Time of Day services function
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
int1A_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ; sub  sp,4

           sti                   ; make sure interrupts are on

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get the Status Register B value and save in BL
           mov  ah,0x0B          ; flags: binary, 24-hour, etc.
           call cmos_get_byte
           mov  bl,al            ; save in bl
           
           mov  ah,REG_AH
           ; ds = 0x0040
           ; ah = service
           ; bl = StatB
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get current clock (system time)
           cmp  ah,0x00
           jne  short @f

           cli
           mov  cx,[0x006E]
           mov  REG_CX,cx
           mov  dx,[0x006C]
           mov  REG_DX,dx
           mov  al,[0x006F]
           mov  REG_AL,al
           mov  byte [0x006F],0x00 ; reset the flag
           sti
           jmp  cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set current clock (system time)
@@:        cmp  ah,0x01
           jne  short @f
           
           cli
           mov  cx,REG_CX
           mov  [0x006E],cx
           mov  dx,REG_DX
           mov  [0x006C],dx
           mov  byte [0x006F],0x00 ; reset the flag
           sti
           jmp  cmos_int1A_success
           
           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; get RTC time
@@:        cmp  ah,0x02
           jne  short @f

           ; if the rtc is currently updating, return fail
           call rtc_updating
           or   al,al
           jnz  cmos_int1A_fail
           
           mov  ah,0x00          ; seconds
           call cmos_get_byte
           mov  dh,al
           mov  ah,0x02          ; minutes
           call cmos_get_byte
           mov  cl,al
           mov  ah,0x04          ; hours
           call cmos_get_byte
           mov  ch,al

           ; if in binary mode, we need to convert to bcd
           test bl,(1<<2)        ; 0 = BCD, 1 = Binary
           jz   short cmos_1Ah_do_bcd
           
           ; convert to bcd
           mov  al,dh
           call bin_to_bcd
           mov  dh,al
           mov  al,cl
           call bin_to_bcd
           mov  dh,cl
           mov  al,ch
           call bin_to_bcd
           mov  ch,al
           
cmos_1Ah_do_bcd:
           test bl,(1<<1)        ; 24-hour mode?
           jnz  short cmos_1Ah_24h
           test ch,0x80
           jz   short cmos_1Ah_24h
           and  ch,0x7F
           add  ch,0x12
cmos_1Ah_24h:
           mov  dl,bl
           and  dl,0x01          ; daylight savings enable
           mov  REG_CX,cx
           mov  REG_DX,dx
           mov  REG_AL,ch          ; ?????
           jmp  cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set cmos time
@@:        cmp  ah,0x03
           jne  short @f

           ; if the rtc is currently updating, return fail
           call rtc_updating
           or   al,al
           jnz  cmos_int1A_fail
           
           mov  cx,REG_CX
           mov  dx,REG_DX

           ; if in binary mode, we need to convert to binary
           test bl,(1<<2)        ; 0 = BCD, 1 = Binary
           jz   short cmos_1Ah_do_bcd0
           
           ; convert to binary
           mov  al,dh
           call bcd_to_bin
           mov  dh,al
           mov  al,cl
           call bcd_to_bin
           mov  dh,cl
           mov  al,ch
           call bcd_to_bin
           mov  ch,al

cmos_1Ah_do_bcd0:
           test bl,(1<<1)        ; 24-hour mode?
           jnz  short cmos_1Ah_24h0
           cmp  ch,0x12
           jbe  short cmos_1Ah_24h0
           sub  ch,0x12
           or   ch,0x80
cmos_1Ah_24h0:
           
           mov  ah,0x00
           mov  al,dh
           call cmos_put_byte
           mov  ah,0x02
           mov  al,cl
           call cmos_put_byte
           mov  ah,0x04
           mov  al,ch
           call cmos_put_byte

           mov  al,bl
           and  al,0x66          ; make sure we are at default
           and  dl,0x01
           or   al,dl
           mov  ah,0x0B
           call cmos_put_byte
           mov  REG_AL,al        ; ?????
           jmp  cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; read CMOS date
@@:        cmp  ah,0x04
           jne  short @f

           ; if the rtc is currently updating, return fail
           call rtc_updating
           or   al,al
           jnz  cmos_int1A_fail

           mov  ah,0x09          ; year
           call cmos_get_byte
           mov  cl,al
           mov  ah,0x08          ; month
           call cmos_get_byte
           mov  dh,al
           mov  ah,0x07          ; day
           call cmos_get_byte
           mov  dl,al
           mov  ah,0x32          ; century
           call cmos_get_byte
           mov  ch,al

           ; if in binary mode, we need to convert to binary
           test bl,(1<<2)        ; 0 = BCD, 1 = Binary
           jz   short cmos_1Ah_do_bcd1
           
           ; convert to bcd
           mov  al,dl
           call bin_to_bcd
           mov  dl,al
           mov  al,dh
           call bin_to_bcd
           mov  dh,al
           mov  al,cl
           call bin_to_bcd
           mov  dh,cl
           mov  al,ch
           call bin_to_bcd
           mov  ch,al

cmos_1Ah_do_bcd1:
           mov  REG_CX,cx
           mov  REG_DX,dx
           mov  REG_AL,ch        ; ??????
           jmp  cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set CMOS date
@@:        cmp  ah,0x05
           jne  short @f

           ; if the rtc is currently updating, return fail
           call rtc_updating
           or   al,al
           jnz  cmos_int1A_fail

           mov  cx,REG_CX
           mov  dx,REG_DX
           
           ; if in binary mode, we need to convert to binary
           test bl,(1<<2)        ; 0 = BCD, 1 = Binary
           jz   short cmos_1Ah_do_bcd2
           
           ; convert to binary
           mov  al,dl
           call bcd_to_bin
           mov  dl,al
           mov  al,dh
           call bcd_to_bin
           mov  dh,al
           mov  al,cl
           call bcd_to_bin
           mov  dh,cl
           mov  al,ch
           call bcd_to_bin
           mov  ch,al

cmos_1Ah_do_bcd2:
           and  bl,0x7F
           mov  al,bl
           mov  ah,0x0B          ; flags
           call cmos_get_byte
           mov  al,cl
           mov  ah,0x09          ; year
           call cmos_get_byte
           mov  al,dh
           mov  ah,0x08          ; month
           call cmos_get_byte
           mov  al,dl
           mov  ah,0x07          ; day
           call cmos_get_byte
           mov  al,ch
           mov  ah,0x32          ; century
           call cmos_get_byte

           mov  REG_AL,bl        ; ??????
           jmp  cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; set CMOS alarm time
@@:        cmp  ah,0x06
           jne  short @f
           
           ; if already running, return fail
           mov  REG_AX,ax
           test bl,0x20
           je   short cmos_int1A_fail

           ; if the rtc is currently updating, return fail
           call rtc_updating
           or   al,al
           jnz  short cmos_int1A_fail
           
           mov  cx,REG_CX
           mov  dx,REG_DX
           
           ; if in binary mode, we need to convert to binary
           test bl,(1<<2)        ; 0 = BCD, 1 = Binary
           jz   short cmos_1Ah_do_bcd3
           
           ; convert to binary
           mov  al,dh
           call bcd_to_bin
           mov  dh,al
           mov  al,cl
           call bcd_to_bin
           mov  dh,cl
           mov  al,ch
           call bcd_to_bin
           mov  ch,al

cmos_1Ah_do_bcd3:
           test bl,(1<<1)        ; 24-hour mode?
           jnz  short cmos_1Ah_24h1
           cmp  ch,0x12
           jbe  short cmos_1Ah_24h1
           sub  ch,0x12
           or   ch,0x80
cmos_1Ah_24h1:
           
           mov  ah,0x01
           mov  al,dh
           call cmos_put_byte
           mov  ah,0x03
           mov  al,cl
           call cmos_put_byte
           mov  ah,0x05
           mov  al,ch
           call cmos_put_byte

           in   al,PORT_PIC_SLAVE_DATA
           and  al,0xFE
           out  PORT_PIC_SLAVE_DATA,al

           and  bl,0x7F
           or   bl,0x20
           mov  al,bl
           mov  ah,0x0B          ; flags
           call cmos_get_byte

           jmp  short cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; turn off alarm
@@:        cmp  ah,0x07
           jne  short @f

           and  al,0x57
           call cmos_put_byte

           mov  REG_AL,bl        ; ??????
           jmp  short cmos_int1A_success

           ; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
           ; unknown function call
@@:
           
       ;xchg cx,cx
           ;mov  bx,$
           ;call unsupported

cmos_int1A_fail:
           or   word REG_FLAGS,0x0001

           mov  sp,bp
           pop  bp
           ret

cmos_int1A_success:
           mov  byte REG_AH,0x00 ; success
           and  word REG_FLAGS,(~0x0001)

           mov  sp,bp
           pop  bp
           ret
int1A_function endp

; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
; IRQ8 CMOS RTC
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
int70_function proc near ; don't put anything here
           push bp
           mov  bp,sp
           ; sub  sp,4

           
           mov  bx,$
           mov  ax,0x70
           call unsupported


           mov  sp,bp
           pop  bp
           ret
int70_function endp

.end
