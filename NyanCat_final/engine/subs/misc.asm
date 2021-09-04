; ====================================================================
; ---------------------------------------------
; Mode cleanup
; ---------------------------------------------

Mode_Cleanup:
		lea	(RAM_PalBuffer),a6
		move.w	#$3F,d0
@PalBuf:
		clr.w	(a6)+
		dbf	d0,@PalBuf

		lea	(RAM_VerBuffer),a6
		move.w	#(($7F)/4),d0
@VerBuf:
		clr.l	(a6)+
		dbf	d0,@VerBuf

		lea	(RAM_SprBuffer),a6
		move.w	#$7F,d0
@SprBuf:
		clr.l	(a6)+
		dbf	d0,@SprBuf

		lea	(RAM_HorBuffer),a6
		move.w	#(($37F)/4),d0
@HorBuf:
		clr.l	(a6)+
		dbf	d0,@HorBuf

		rts

; ; ====================================================================
; ; ---------------------------------------------
; ; Set new HBlank
; ; ---------------------------------------------
; 		
; MD_SetNewHint:
; 		tst.l	d0
; 		beq.s	@ClearHint
; 		bset	#2,(RAM_VIntWait)
; 		move.l	d0,(RAM_HIntAddr)
; 		move.w	#$8004,($C00004)
; 		rts
; @ClearHint:
; 		bclr	#2,(RAM_VIntWait)
; 		move.w	#$8004,($C00004)
; 		rts
		
; ====================================================================
; ---------------------------------------------
; Generic data loaders
;
; NonVDP:
; a0 - Input
; a1 - Output
; d0 - Size (BYTE, WORD or LONG)
; ---------------------------------------------

LoadData_Byte:
		move.b	(a0)+,(a1)+
		dbf	d0,LoadData_Byte
		rts

LoadData_Word:
		move.w	(a0)+,(a1)+
		dbf	d0,LoadData_Word
		rts

LoadData_Long:
		move.l	(a0)+,(a1)+
		dbf	d0,LoadData_Long
		rts
		
; ====================================================================
; ---------------------------------------------
; RLE decompression
; byte $FF is end-of-data
;
; a0 - Input
; a1 - Output
; ---------------------------------------------

RLE_decompress:
		moveq	#0,d0
		moveq	#0,d1
		move.b	(a0)+,d0
		cmp.b	#-1,d0
		beq	@Finish
		
		move.b	(a0)+,d1
@CopyIt:
		move.b	d1,(a1)+
		dbf	d0,@CopyIt
		
		bra.s	RLE_decompress
@Finish:
		rts

; ====================================================================
; ---------------------------------------------
; CalcSine
;
; Input:
; d0 | WORD
;
; Output:
; d0 | WORD
; d1 | WORD
; ---------------------------------------------

CalcSine:
		and.w	#$FF,d0
		add.w	d0,d0
		add.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d1
		sub.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d0
		rts	

Sine_Data:
		dc.w 0,	6, $C, $12, $19, $1F, $25, $2B,	$31, $38, $3E
		dc.w $44, $4A, $50, $56, $5C, $61, $67,	$6D, $73, $78
		dc.w $7E, $83, $88, $8E, $93, $98, $9D,	$A2, $A7, $AB
		dc.w $B0, $B5, $B9, $BD, $C1, $C5, $C9,	$CD, $D1, $D4
		dc.w $D8, $DB, $DE, $E1, $E4, $E7, $EA,	$EC, $EE, $F1
		dc.w $F3, $F4, $F6, $F8, $F9, $FB, $FC,	$FD, $FE, $FE
		dc.w $FF, $FF, $FF, $100, $FF, $FF, $FF, $FE, $FE, $FD
		dc.w $FC, $FB, $F9, $F8, $F6, $F4, $F3,	$F1, $EE, $EC
		dc.w $EA, $E7, $E4, $E1, $DE, $DB, $D8,	$D4, $D1, $CD
		dc.w $C9, $C5, $C1, $BD, $B9, $B5, $B0,	$AB, $A7, $A2
		dc.w $9D, $98, $93, $8E, $88, $83, $7E,	$78, $73, $6D
		dc.w $67, $61, $5C, $56, $50, $4A, $44,	$3E, $38, $31
		dc.w $2B, $25, $1F, $19, $12, $C, 6, 0,	-6, -$C, -$12
		dc.w -$19, -$1F, -$25, -$2B, -$31, -$38, -$3E, -$44, -$4A
		dc.w -$50, -$56, -$5C, -$61, -$67, -$6D, -$75, -$78, -$7E
		dc.w -$83, -$88, -$8E, -$93, -$98, -$9D, -$A2, -$A7, -$AB
		dc.w -$B0, -$B5, -$B9, -$BD, -$C1, -$C5, -$C9, -$CD, -$D1
		dc.w -$D4, -$D8, -$DB, -$DE, -$E1, -$E4, -$E7, -$EA, -$EC
		dc.w -$EE, -$F1, -$F3, -$F4, -$F6, -$F8, -$F9, -$FB, -$FC
		dc.w -$FD, -$FE, -$FE, -$FF, -$FF, -$FF, -$100,	-$FF, -$FF
		dc.w -$FF, -$FE, -$FE, -$FD, -$FC, -$FB, -$F9, -$F8, -$F6
		dc.w -$F4, -$F3, -$F1, -$EE, -$EC, -$EA, -$E7, -$E4, -$E1
		dc.w -$DE, -$DB, -$D8, -$D4, -$D1, -$CD, -$C9, -$C5, -$C1
		dc.w -$BD, -$B9, -$B5, -$B0, -$AB, -$A7, -$A2, -$9D, -$98
		dc.w -$93, -$8E, -$88, -$83, -$7E, -$78, -$75, -$6D, -$67
		dc.w -$61, -$5C, -$56, -$50, -$4A, -$44, -$3E, -$38, -$31
		dc.w -$2B, -$25, -$1F, -$19, -$12, -$C,	-6, 0, 6, $C, $12
		dc.w $19, $1F, $25, $2B, $31, $38, $3E,	$44, $4A, $50
		dc.w $56, $5C, $61, $67, $6D, $73, $78,	$7E, $83, $88
		dc.w $8E, $93, $98, $9D, $A2, $A7, $AB,	$B0, $B5, $B9
		dc.w $BD, $C1, $C5, $C9, $CD, $D1, $D4,	$D8, $DB, $DE
		dc.w $E1, $E4, $E7, $EA, $EC, $EE, $F1,	$F3, $F4, $F6
		dc.w $F8, $F9, $FB, $FC, $FD, $FE, $FE,	$FF, $FF, $FF
		even
		
