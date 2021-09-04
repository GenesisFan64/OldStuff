; ====================================================================
; -------------------------------------------------
; Macros
; -------------------------------------------------

align		macro
		cnop 0,\1
		endm

; --------------------------------------------
; Pick ROM section
; --------------------------------------------

romSection	macro where

CODE		=	*+$880000
DATA		=	*+marsbank
RAM		=	$FF0000
WRAM		=	$200000

; ---------------------------

		if MCD|MARS == True
		obj \1
		endif
		
		endm
		
; ---------------------------

romSectionEnd	macro

		if MCD
		objend
		elseif MARS
		objend
		endif
		
		endm

; --------------------------------------------
; Video
; --------------------------------------------

; --------------------------------------------
; dmaTask
; --------------------------------------------

dmaTask		macro

FILL		=	$C0000000+1
COPY		=	$C0000000+2
		
; ---------------------------
; DMA FILL
; (FILL,byte,to,size)
; 
; USES d0
; ---------------------------

		if \1=FILL
		
		move.w	#$8F01,(vdp_ctrl)
 		move.l	#$9400+(((\4)&$FF00)>>9)|(($9300+(((\4)&$FF)>>1))<<16),(vdp_ctrl)
		move.w	#$9780,(vdp_ctrl)
		move.l	#\3|$80,(vdp_ctrl)
		move.w	#\2&$FFFF,(vdp_data)
@wait1\@:
		move.w	(vdp_ctrl),d0
		btst	#1,d0
		bne.s	@wait1\@
		move.w	#$8F02,(vdp_ctrl)
		
; ---------------------------
; DMA COPY
; (COPY,from,to,size)
; 
; USES d0
; ---------------------------

		elseif \1=COPY
		move.w	#$8F01,(vdp_ctrl)
 		move.l	#$9400+(((\4)&$FF00)>>9)|(($9300+(((\4)&$FF)>>1))<<16),(vdp_ctrl)
 		move.l	#$9600+(((\2>>1)&$FF00)>>8)|(($9500+((\2>>1)&$FF))<<16),(vdp_ctrl)
		move.w	#$97C0,(vdp_ctrl)
		move.l	#\3|$C0,(vdp_ctrl)
		move.w	#\2&$FFFF,(vdp_data)
@wait2\@:
		move.w	(vdp_ctrl),d0
		btst	#1,d0
		bne.s	@wait2\@
		move.w	#$8F02,(vdp_ctrl)
		
; ---------------------------
; DMA ROM/RAM to VDP
; (from,to,size)
; ---------------------------

		else

		;\1 from | \2 to | \3 size
 		move.l	#$9400+(((\3)&$FF00)>>9)|(($9300+(((\3)&$FF)>>1))<<16),(vdp_ctrl)
 		move.l	#$9600+(((\1>>1)&$FF00)>>8)|(($9500+((\1>>1)&$FF))<<16),(vdp_ctrl)
		move.w	#$9700+((((\1>>1)&$FF0000)>>16)&$7F),(vdp_ctrl)
		
; 		move.l	#\2|$80,(vdp_ctrl)		;new attempt

		move.w	#((\2&$FFFF))|$80,-(sp)
		move.w	#(((\2)>>16)&$FFFF),-(sp)
		move.w	(sp)+,(vdp_ctrl)
 		move.w	#$100,($A11100)
@WaitZ80_\@:
 		btst	#0,($A11100)
  		bne.s	@WaitZ80_\@
		move.w	(sp)+,(vdp_ctrl)
 		move.w	#0,($A11100).l
		
		endif
		
		endm
		
; --------------------------------------------

fade		macro

in = 1
out = 0

		if \1=in
 		move.l	#$0101003F,(RAM_PalFadeSys)
@wait_fade\@	tst.l	(RAM_PalFadeSys)
 		bne.s	@wait_fade\@
		
		elseif \1=out
		
		move.l	#$0201003F,(RAM_PalFadeSys)
@wait_fade\@	tst.l	(RAM_PalFadeSys)
 		bne.s	@wait_fade\@
		
		endif
		
		endm
		
; --------------------------------------------
; System
; --------------------------------------------

z80		macro

ON = 1
OFF = 0

		if \1=OFF
		
 		move.w	#$100,($A11100).l
@WaitZ80_\@:
 		btst	#0,($A11100).l
  		bne.s	@WaitZ80_\@

		elseif \1=ON
		
  		move.w	#0,($A11100).l

		endif
		
		endm
		
