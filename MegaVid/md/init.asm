; ====================================================================
; -----------------------------------------------------------------
; Header
; -----------------------------------------------------------------

		dc.l 0
		dc.l MD_Entry
		dc.l MD_BusError
		dc.l MD_AddrError
		dc.l MD_IllegalError
		dc.l MD_ZeroDivError
		dc.l MD_ChkError
		dc.l MD_TrapVError
		dc.l MD_PrivilegeError
		dc.l MD_TraceError
		dc.l MD_LineA_Error
		dc.l MD_LineF_Error

		cnop 0,$70
                dc.l MD_Hint
		cnop 0,$78
                dc.l MD_Vint

		cnop 0,$100
		dc.b "SEGA GENESIS    "
		cnop 0,$110
		dc.b "(C)KMA  2015.???"
                cnop 0,$120
                dc.b "MEGAVID                                         "
                cnop 0,$150
                dc.b "MEGAVID                                         "
                dc.b "GM HOMEBREW-00"
                cnop 0,$190
		dc.b "J               "

		dc.l 0
		dc.l MD_RomEnd
		dc.l $FF0000
		dc.l $FFFFFF
		dc.b "RA",$E8,$20
		dc.l $200000
		dc.l $203FFF

		cnop 0,$1F0
		dc.b "U               "
		            
; -----------------------------------------------------------------
; Codigo para iniciar correctamente el Software
;
; Original: (C)SEGA
; -----------------------------------------------------------------

                cnop 0,$200
MD_Entry:
		tst.l	($A10008).l	; test port A control
		bne.s	@PortA_Ok
		tst.w	($A1000C).l	; test port C control
@PortA_Ok:
		bne.s	@PortC_Ok

		lea	@SetupValues(pc),a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version
		andi.b	#$F,d0
		beq.s	@Skip
		move.l	($100),$2F00(a1)

@Skip:
		move.w	(a4),d0		; check	if VDP works
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp		; set usp to $0
		moveq	#$17,d1

@VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to	VDP register
		add.w	d7,d5		; next register
		dbf	d1,@VDPInitLoop
		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear	the screen
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset	the Z80

@WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	@WaitForZ80	; if not, branch
		moveq	#$25,d2

@Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,@Z80InitLoop
		move.w	d0,(a2)
		move.w	d0,(a1)		; start	the Z80
		move.w	d7,(a2)		; reset	the Z80

@ClrRAMLoop:
		move.l	d0,-(a6)
		dbf	d6,@ClrRAMLoop	; clear	the entire RAM
		move.l	(a5)+,(a4)	; set VDP display mode and increment
		move.l	(a5)+,(a4)	; set VDP to CRAM write
		moveq	#$1F,d3

@ClrCRAMLoop:
		move.l	d0,(a3)
		dbf	d3,@ClrCRAMLoop	; clear	the CRAM
		move.l	(a5)+,(a4)
		moveq	#$13,d4

@ClrVDPStuff:
		move.l	d0,(a3)
		dbf	d4,@ClrVDPStuff
		moveq	#3,d5

@PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset	the PSG
		dbf	d5,@PSGInitLoop
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear	all registers
		move	#$2700,sr	; set the sr

@PortC_Ok:
		bra	@LastJob
; ===========================================================================
@SetupValues:	dc.w $8000		; XREF: PortA_Ok
		dc.w $3FFF
		dc.w $100

		dc.l $A00000		; start	of Z80 RAM
		dc.l $A11100		; Z80 bus request
		dc.l $A11200		; Z80 reset
		dc.l $C00000
		dc.l $C00004		; address for VDP registers

		dc.b 4,	$14, $30, $3C	; values for VDP registers
		dc.b 7,	$6C, 0,	0
		dc.b 0,	0, $FF,	0
		dc.b $81, $37, 0, 1
		dc.b 1,	0, 0, $FF
		dc.b $FF, 0, 0,	$80

		dc.l $40000080

		dc.b $AF, 1, $D9, $1F, $11, $27, 0, $21, $26, 0, $F9, $77 ; Z80	instructions
		dc.b $ED, $B0, $DD, $E1, $FD, $E1, $ED,	$47, $ED, $4F
		dc.b $D1, $E1, $F1, 8, $D9, $C1, $D1, $E1, $F1,	$F9, $F3
		dc.b $ED, $56, $36, $E9, $E9

		dc.w $8164		; value	for VDP	display	mode
		dc.w $8F02		; value	for VDP	increment
		dc.l $C0000000		; value	for CRAM write mode
		dc.l $40000010

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; -------------------------------------------------------

@LastJob:
;  		lea	($FFFF0000),a0
;  		move.w	#((RAM_VIntAddr)-$FFFF0000)/4,d0
; @ClrRam:
;  		clr.l	(a0)+
;  		dbf	d0,@ClrRam
 		
		move.b	#0,(RAM_GameMode)
		bra 	MD_Main
		