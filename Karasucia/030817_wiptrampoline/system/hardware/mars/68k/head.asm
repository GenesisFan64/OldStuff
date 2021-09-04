; ====================================================================
; -------------------------------------------------
; Header
; 
; MARS
; -------------------------------------------------

		dc.l	0
		dcb.l	$B,$3F0
		align	$70
		dc.l	RAM_HintJumpTo
		align	$78
		dc.l	RAM_VintJumpTo

		align $100
		dc.b "SEGA 32X        "
		align $120
		dc.b "Las aventuras de Dominoe"
		align $150
		dc.b "Dominoe Adventures"
		
		align $1A0
		dc.l 0
		dc.l ROM_END
		dc.l $FF0000
		dc.l $FFFFFF
		dc.b "RA",$E8,$20
		dc.l $200000
		dc.l $203FFF

		align $1F0
		dc.b "U               "

; -------------------------------------------------

		jmp	MD_Entry
		align	$2A2
		jmp	RAM_HintJumpTo
		align	$2AE
		jmp	RAM_VintJumpTo
		
; -------------------------------------------------
; MARS User Header
; -------------------------------------------------

		align	$3C0
		dc.b "*32x Check Mode*"				; module name
		dc.l 0						; version
		dc.l SH2_Start					; SH2 Program start address
		dc.l 0						; SH2 Program write address
		dc.l SH2_End-SH2_Start				; SH2 Program length
		dc.l MasterEntry+$120				; Master SH2 initial PC
		dc.l SlaveEntry+$120				; Slave SH2 initial PC
		dc.l MasterEntry				; Master SH2 initial VBR address
		dc.l SlaveEntry					; Slave SH2 intitial VBR address
		incbin	"system/hardware/mars/68k/security.bin"
		
; -------------------------------------------------

 		bcs	MARS_Error
		move	#$2700,sr
		lea	(marsreg),a5
		
@M_OK:		cmp.l	#"M_OK",$20(a5)
		bne	@M_OK
@S_OK:		cmp.l	#"S_OK",$24(a5)
		bne	@S_OK

		moveq	#0,d0
		move.l	d0,$20(a5)
		move.l	d0,$24(a5)
		
; ===========================================================================
; -----------------------------------------------------------------
; Startup code
; -----------------------------------------------------------------

MD_Entry:	
 		jmp	MD_Main
 		
; ===========================================================================
; -------------------------------------------------
; 32X Not connected
; -------------------------------------------------

MARS_Error:
		move.w	#$2700,sr
		tst.w	(vdp_ctrl)
		
		jsr	(Video_Init&$FFFF)
		jsr	(Video_Update&$FFFF)
		
		move.l	#$C0020000,(vdp_ctrl)
		move.l	#$08880EEE,(vdp_data)

		move.l	#$40000000,(vdp_ctrl)
		lea	(Art_DebugFont&$FFFF),a0
		move.w	#((Art_DebugFont_e-Art_DebugFont)/4)-1,d0
@dbg_loop:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@dbg_loop
		
		lea	@asc_oops(pc),a0
		moveq	#0,d0
		move.l	#$0003000C,d1
		moveq	#0,d2
		jsr	(Video_PrintText&$FFFF)
@loop:		
		nop
		nop
		bra	@loop
		
@asc_oops:	dc.b "This game requires the 32X addon.",0
		even
		
; ====================================================================
; -------------------------------------------------
; MARS SH2 CODE
; -------------------------------------------------

SH2_Start:	incbin	"system/hardware/mars/sh2/code.bin"
SH2_End:
		align 4
		
		obj *+marsipl
