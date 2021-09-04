;---------------------
; Code start
;---------------------
		
Entrypoint:

		tst.l	($A10008).l		;Test Port A control
		bne	PortA_Ok
		tst.w	($A1000C).l		;Test Port C control
PortA_Ok:
		bne	SkipSetup

		move.b	($A10001).l,d0		;version
		andi.b	#$F,d0
		beq	SkipSecurity		;if the smd/gen model is 1, skip the security
		move.l	#'SEGA',($A14000).l
SkipSecurity:
		move.w	($C00004).l,d0		;test if VDP works

		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp			;set usp to $0

		move.l	#$40000080,($C00004).l
		move.w	#0,($C00000).l		;clean the screen


;---------------------
; Init the Z80
;---------------------	

		move.w	#$100,($A11100).l	;Stop the Z80
		move.w	#$100,($A11200).l	;Reset the Z80
		
Waitforz80:
		btst	#0,($A11100).l
		bne	Waitforz80		;Wait for z80 to halt

		lea	(Z80Init),a0
		lea	($A00000).l,a1
		move.w	#Z80InitEnd-Z80Init,d1
		
InitZ80:
		move.b	(a0)+,(a1)+
		dbf	d1,InitZ80

		move.w	#0,($A11200).l
		move.w	#0,($A11100).l		;Start the Z80
		move.w	#$100,($A11200).l

;---------------------
; Reset the RAM
;---------------------

		lea	($FFFF0000).l,a0
		move.w	#$3fff,d1
		
ClearRAM:
		move.l	#0,(a0)+
		dbf	d1,ClearRAM
		
		
;---------------------
; VDP again
;---------------------			
		
		move.w	#$8174,($C00004).l
		move.w	#$8F02,($C00004).l
		
		
;---------------------
; Clear the CRAM
;---------------------	

		move.l	#$C0000000,($C00004).l	;Set VDP ctrl to CRAM write
		move.w	#$3f,d1
		
ClearCRAM:
		move.w	#0,($C00000).l
		dbf	d1,ClearCRAM
		
			
;---------------------
; Clear the VDP stuff
;---------------------		

		move.l	#$40000010,($C00004).l
		move.w	#$13,d1
		
ClearStuff:
		move.l	#0,($C00000).l
		dbf	d1,ClearStuff
		

;---------------------
; Init the PSG
;---------------------	

		move.b	#$9F,($C00011).l
		move.b	#$BF,($C00011).l
		move.b	#$DF,($C00011).l
		move.b	#$FF,($C00011).l
		
		
		move.w	#0,($A11200).l
		
		
;---------------------
; Load the z80 driver
;---------------------

		move.w	#$100,($A11100).l	;Stop the Z80
		move.w	#$100,($A11200).l	;Reset the Z80
		
Waitforz80a:
		btst	#0,($A11100).l
		bne	Waitforz80a		;Wait for z80 to halt

		move.w	#0,($A11100).l		;Start the Z80

;---------------------
; Clear the registers
; and set the SR
;---------------------	

		movem.l	($FF0000).l,d0-a6	
		lea	($FFFE00).l,a7
		move	#$2700,sr
		
SkipSetup:
		bra	GameProgram

; =============================================================================
Z80Init:
		dc.w	$af01, $d91f, $1127, $0021, $2600, $f977
		dc.w    $edb0, $dde1, $fde1, $ed47, $ed4f, $d1e1
		dc.w    $f108, $d9c1, $d1e1, $f1f9, $f3ed, $5636
		dc.w	$e9e9
Z80InitEnd:
