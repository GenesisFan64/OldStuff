; ====================================================================
; -------------------------------------------------
; Variables
; -------------------------------------------------

; --------------------------------------------
; I/O
; --------------------------------------------

port_ver	equ	$A10001
port_tmss	equ	$A14000

; --------------------------------------------
; VDP
; --------------------------------------------

vdp_data	equ	$C00000
vdp_ctrl	equ	$C00004

; --------------------------------------------
; MD Audio
; --------------------------------------------

sound_psg	equ	$C00011
sound_ym_1	equ	$A04000
sound_ym_2	equ	$A04001
sound_ym_3	equ	$A04002
sound_ym_4	equ	$A04003

; --------------------------------------------
; MARS only
; --------------------------------------------

framebuffer	equ	$840000
overwrite	equ	$860000
marsipl		equ	$880000
marsbank	equ	$900000
mars_ID		equ	$a130ec		; MARS ID "MARS"

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

; --------------------------------------------
; OTHER
; --------------------------------------------

		if MCD
		include	"system/hardware/mcd/map.asm"
		elseif MARS
		include	"system/hardware/mars/map_shared.asm"
		endif
