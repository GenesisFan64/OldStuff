; ====================================================================
; -------------------------------------------------
; Header
; 
; MD
; -------------------------------------------------

		dc.l 0
		dc.l MD_Entry
		dc.l MD_Err_Bus
		dc.l MD_Err_Addr
		dc.l MD_Err_Illg
		dc.l MD_Err_Div
		dc.l MD_Err_CHK
		dc.l MD_Err_TRAPV
		dc.l MD_Err_Privl
		dc.l MD_Err_TRACE
		dc.l MD_Err_EMU10
		dc.l MD_Err_EMU11
		align	$70
		dc.l RAM_HintJumpTo
		align	$78
		dc.l RAM_VintJumpTo
		align	$100
		dc.b "SEGA MEGA DRIVE "
		align	$120
		dc.b "Las aventuras de Dominoe"
		align	$150
		dc.b "Dominoe Adventures"
		align	$200

; ====================================================================
; -------------------------------------------------
; Entry
; -------------------------------------------------

MD_Entry:
		move.w	#$2700,sr
		tst.l	($A10008).l		;Test Port A control
		bne.s	@PortA_Ok
		tst.w	($A1000C).l		;Test Port C control
@PortA_Ok:
		bne	@Hot

		move.b	(port_ver),d0
		and.b	#%1111,d0
		beq.s	@Skip
		move.l	($100),(port_tmss)
		
		lea	($FFFF0000).l,a0
		move.w	#$7FFF,d1
@ClearRAM:
		clr.w	(a0)+
		dbf	d1,@ClearRAM
		movem.l	($FF0000).l,d0-a6
		
@Skip:
		tst.w	(vdp_ctrl).l		;test if VDP works
@Hot:
		bra	MD_Main
		
; ====================================================================
; -------------------------------------------------
; Error handler
; -------------------------------------------------

MD_Err_Bus:
		move.l	#Asc_ErrBus,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_Addr:
		move.l	#Asc_ErrAddr,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_Illg:
		move.l	#Asc_ErrIllg,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_Div:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_CHK:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_TRAPV:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_Privl:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_TRACE:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_EMU10:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		bra.s	MD_Error
MD_Err_EMU11:
		move.l	#Asc_ErrTEMP,($FFFFBBBC)
		
MD_Error:
		movem.l	d0-a7,($FFFFBBC0)
		move.w	#$2700,sr
		
		move.l	#$C0000000,(vdp_ctrl)
		move.w	#$0000,(vdp_data)

		tst.w	(RAM_Palette+$1E)
		bne.s	@alrdy2
		move.l	#$C01E0000,(vdp_ctrl)
		move.w	#$0EEE,(vdp_data)
@alrdy2:
		move.l	#$58000003,(vdp_ctrl)
		lea	(Art_DebugFont),a0
		move.w	#(($20)/4)-1,d0
@dbg_loop:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@dbg_loop
		
		movea.l	#AscErr_Base,a0
		moveq	#2,d0
		move.l	#$00000000,d1
		move.w	#$8680,d2
		bsr	Video_PrintText
		
		movea.l	($FFFFBBBC),a0
		moveq	#2,d0
		move.l	#$00010001,d1
		move.w	#$8680,d2
		bsr	Video_PrintText
		
; 		movea.l	($FFFFBBFC),a0
; 		moveq	#2,d0
; 		move.l	#$001B0003,d1
; 		move.l	-4(a0),d2
; 		move.w	#$680,d3
; 		moveq	#2,d4
; 		bsr	Video_PrintVal
		
		move.l	#$00020007,d7
		lea	($FFFFBBC0),a1
@loopy:
		moveq	#2,d0
		move.l	#$00040000,d1
		swap	d7
		move.w	d7,d1
		add.w	#1,d7
		swap	d7
		move.l	(a1)+,d2
		move.w	#$8680,d3
		moveq	#2,d4
		bsr	Video_PrintVal
		dbf	d7,@loopy
		
		move.l	#$00020007,d7
		lea	($FFFFBBE0),a1
@loopy2:
		moveq	#2,d0
		move.l	#$00100000,d1
		swap	d7
		move.w	d7,d1
		add.w	#1,d7
		swap	d7
		move.l	(a1)+,d2
		move.w	#$8680,d3
		moveq	#2,d4
		bsr	Video_PrintVal
		dbf	d7,@loopy2
		
		move.l	#$8700920A,(vdp_ctrl)
		bra.s	*

Asc_ErrBus: 	dc.b "BUS ERROR                              ",0
		even
Asc_ErrAddr: 	dc.b "ADDRESS Error (R/W to an odd address)  ",0
		even
Asc_ErrIllg: 	dc.b "ILLEGAL Instruction / Unknown error    ",0
		even
Asc_ErrTEMP: 	dc.b "PONME TITULO CUANDO PUEDAS MIJO        ",0
		even
		
AscErr_Base:
		dc.b "                                        ",$A
		dc.b "                                        ",$A
		dc.b " D0 00000000 A0 00000000                ",$A
		dc.b " D1 00000000 A1 00000000                ",$A
		dc.b " D2 00000000 A2 00000000                ",$A
		dc.b " D3 00000000 A3 00000000                ",$A
		dc.b " D4 00000000 A4 00000000                ",$A
		dc.b " D5 00000000 A5 00000000                ",$A
		dc.b " D6 00000000 A6 00000000                ",$A
		dc.b " D7 00000000 SP 00000000                ",0
		even
		
