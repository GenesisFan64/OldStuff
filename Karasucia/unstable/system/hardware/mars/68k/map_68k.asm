;-------------------------------------------------------;
;	MARS Sample Program
;	Mega Drive Map
;
;	Copyright SEGA ENTERPRISES,LTD. 1994
;-------------------------------------------------------;

wordram		equ	$600000

framebuffer	equ	$840000
overwrite	equ	$860000
marsipl		equ	$880000
marsbank	equ	$900000

*---------------------------------------------------------------*
zprg_ram	equ	$a00000

*---------------------------------------------------------------*
_versionflag	equ	0
_version	equ	$a10001		; byte		 md version
_port_a		equ	$a10003		; byte		 joy pad a
_port_b		equ	$a10005		; byte		 joy pad b
_port_c		equ	$a10007		; byte		 joy pad c
_pa_cont	equ	$a10009		; byte		 joy pad a control
_pb_cont	equ	$a1000b		; byte		 joy pad b control
_pc_cont	equ	$a1000d		; byte		 joy pad c control
_cartmode	equ	$a11000		; word

*---------------------------------------------------------------*
z_brq		equ	$a11100				; Z80 bus request
z_res		equ	$a11200				; Z80 reset

*---------------------------------------------------------------*
mars_ID		equ	$a130ec		; long		 MARS ID "MARS"
bankchip	equ	$a130f1		;		 Bank Chip Reg.0

*---------------------------------------------------------------*
_securityflag	equ	1
_securityaddr	equ	$a14000		; long		 md security
_v6os		equ	$a14100		; word

*---------------------------------------------------------------*
marsreg		equ	$a15100
access		equ	$00		; byte		; MARS VDP access control
adapter		equ	$01		; byte		; MARS adapter control
intctl		equ	$03		; byte		; SH2 interrupt control
bankctl		equ	$05		; byte		; BANK conterol
dreqctl		equ	$07		; byte		; DREQ control
dreqsource	equ	$08		; long		; 68 to SH DREQ source address
dreqdest	equ	$0c		; long		; 68 to SH DREQ destination address
dreqlength	equ	$10		; word		; 68 to SH DREQ length
dreqfifo	equ	$12		; word		; 68 to SH DREQ FIFO
segatv		equ	$1b		; byte		; SEGA TV Reg.
comm0		equ	$20		; 		; Communcation Reg.
comm2		equ	$22		; 		; Communcation Reg.
comm4		equ	$24		; 		; Communcation Reg.
comm6		equ	$26		; 		; Communcation Reg.
comm8		equ	$28		; 		; Communcation Reg.
comm9		equ	$29		; 		; Communcation Reg.
comm10		equ	$2a		; 		; Communcation Reg.
comm12		equ	$2c		; 		; Communcation Reg.
comm14		equ	$2e		; 		; Communcation Reg.

tvmode		equ	$80		; byte		; NTSC/PAL
bitmapmode	equ	$81		; byte		; BitMap Mode Reg.
shift		equ	$83		; byte		; Packed Pixel Dot Shift
filllength	equ	$85		; byte		; DRAM Fill Length
fillstart	equ	$86		; word		; DRAM Fill Start Address
filldata	equ	$88		; word		; DRAM Fill Data
vdpsts		equ	$8a		; byte		; VDP status
framectl	equ	$8b		; byte		; Frame Buffer Control

palette		equ	$a15200		; 256 words	; Palette Data


_vdpdata	equ	$c00000				; vdp data port
_vdpreg		equ	$c00004				; vdp register



;---------------------------------------------------------------;
;	Bit Assign
;---------------------------------------------------------------;

;-------------------------------------------------------;
; access
;-------------------------------------------------------;
FM		equ	7		; 0:MD		/1: SH

;-------------------------------------------------------;
; adapter
;-------------------------------------------------------;
ADEN		equ	0		; 0: disenable 	/1: enable
RES		equ	1		; 0: SH2 reset 	/1: SH2 reset off

;-------------------------------------------------------;
; intctl
;-------------------------------------------------------;
INTM		equ	0		; 0: NOP	/1: master CMD INT
INTS		equ	1		; 0: NOP	/1: slave  CMD INT

;-------------------------------------------------------;
; dreqctl
;-------------------------------------------------------;
RV		equ	0		; 0: NOP	/1: ROM to VRAM DMA
DMA		equ	1		; 0: CPU write	/1: DMA write (TODO: conflicto)
D68S		equ	2		; 0: NOP	/1: DREQ start
DSEL		equ	3		; 0: FIFO to SD /1: ROM to PWM
FULL		equ	7		; 0: empty	/1: full

;-------------------------------------------------------;
; segatv
;-------------------------------------------------------;
CM		equ	0		; 0: ROM	/1: DRAM

;-------------------------------------------------------;
; tvmode
;-------------------------------------------------------;
PAL		equ	7		; 0:NTSC	/1: PAL

;-------------------------------------------------------;
; bitmapmode
;-------------------------------------------------------;
L240		equ	6		; 0:224line	/1: 240line
PRI		equ	7

;-------------------------------------------------------;
; shift
;-------------------------------------------------------;
SFT		equ	0		; 0:Nomal	/1: Dot Shift

;-------------------------------------------------------;
; vdpsts
;-------------------------------------------------------;
PEN		equ	5		; 0:Palette EN	/1: Palette DisEN
HBLK		equ	6		; 0:Disp	/1: Blank
VBLK		equ	7		; 0:Disp	/1: Blank

;-------------------------------------------------------;
; framectl
;-------------------------------------------------------;
FS		equ	0		; 0:DRAM0	/1: DRAM1
FEN		equ	1		; 0:access EN	/1: access DisEN

