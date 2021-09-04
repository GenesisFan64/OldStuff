; ====================================================================
; System
; ====================================================================

; ====================================================================
; -------------------------------------------------
; RAM
; -------------------------------------------------

                rsset	RAM_System
RAM_HintJumpTo	rs.w	1				; DONT
RAM_HintAddr	rs.l	1				; SEPARATE
RAM_VIntJumpTo	rs.w	1				; THESE
RAM_VintAddr	rs.l	1				; ONES
RAM_VIntRegs	rs.l	16
RAM_ModeReset	rs.w	1
RAM_IntFlags	rs.b	1
RAM_GameMode	rs.b	1

sizeof_sys	rs.l	0
; 		inform 0,"system ram: %h",(sizeof_sys-RAM_System)
 				
; ====================================================================
; -------------------------------------------------
; Variables
; -------------------------------------------------

; --------------------------------------------
				
; ====================================================================
; -------------------------------------------------
; Macros
; -------------------------------------------------

; --------------------------------------------

; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

System_init:
		lea	(RAM_ModeBuffer),a0
		move.w	#($1800/2)-1,d0
@clear_buff:
		clr.w	(a0)+
		dbf	d0,@clear_buff
		
		move.l	#MD_Vint,(RAM_VIntAddr)
		move.l	#MD_Hint,(RAM_HIntAddr)
		move.w	#$4EF9,d0
 		move.w	d0,(RAM_VIntJumpTo)
		move.w	d0,(RAM_HIntJumpTo)
		
 		clr.b	(RAM_GameMode)
		rts
		
; ---------------------------------------------
; SRAM
; ---------------------------------------------

SRAM_Init:
		move.b	#%11,($A130F1)		;read+write
		lea	($200000),a0
		movep.w	1(a0),d0
		cmp.l	#"GE",d0
		beq.s	@exit
		lea	@SramHead(pc),a1
		moveq	#7-1,d0
@header:
		move.b	(a1)+,d0
		move.b	d0,1(a0)
		adda	#2,a0
		dbf	d0,@header
@exit:
		move.b	#0,($A130F1)
		rts

; ---------------------------------------------

@SramHead:	dc.b "GENYSAVE",0
		even
		
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
	
; ---------------------------------------------
; HexToByte_Byte
; 
; Uses:
; d4-d5
; ---------------------------------------------

; HexToDec_Byte:
; 		move.w	d0,d4
; 		and.w	#$FF,d4
; 		clr.w	d0
; @hexloop:
; 		sub.w	#1,d4
; 		bcs.s	@finish
; 		add.w	#1,d0
; 		move.w	d0,d5
;  		and.w	#$F,d5
; 		cmp.w	#$A,d5
; 		bcs.s	@lowbyte1
; 		add.w	#6,d0
; @lowbyte1:
; 		move.w	d0,d5
;  		and.w	#$F0,d5
; 		cmp.w	#$A0,d5
; 		bcs.s	@lowbyte2
; 		add.w	#$60,d0
; @lowbyte2:
; 		bra.s	@hexloop
; @finish:
; 		rts

; ---------------------------
; Convert HEX to DEC
; MAX: 65535 ($FFFF)
; 
; input:
; d2
; 
; output:
; d2
; Uses:
; d4 WORD (swapped)
; d5 LONG
; ---------------------------

HexToDec:
		moveq	#0,d5
		swap	d4

		swap	d2
		move.w	d2,d4
		swap	d2
		tst.w	d4
		beq	@jumpy
		
		move.w	d2,d4
		lsr.w	#8,d4
		and.w	#$F,d4
		add.w	d4,d4
		move.w	@grab256(pc,d4.w),d5
		move.w	d2,d4
		lsr.w	#8,d4
		lsr.w	#2,d4
		and.w	#%111100,d4
		add.l	@grab4096(pc,d4.w),d5
		bsr	@fixhexdec
		swap	d2
		move.w	d2,d4
		swap	d2
		lsl.w	#2,d4
		and.w	#%111100,d4
		add.l	@grab65536(pc,d4.w),d5
		bsr	@fixhexdec
		bra	@jumpy
; --------------------------------
@grab256:	dc.w 0
		dc.w $256
		dc.w $512
		dc.w $768
		dc.w $1024
		dc.w $1280
		dc.w $1536
		dc.w $1792
		dc.w $2048
		dc.w $2304
		dc.w $2560
		dc.w $2816
		dc.w $3072
		dc.w $3328
		dc.w $3584
		dc.w $3840
		even
@grab4096:	dc.l 0
		dc.l $4096
		dc.l $8192
		dc.l $12288
		dc.l $16384
		dc.l $20480
		dc.l $24576
		dc.l $28672
		dc.l $32768
		dc.l $36864
		dc.l $40960
		dc.l $45056
		dc.l $49152
		dc.l $53248
		dc.l $57344
		dc.l $61440
		even
@grab65536: 	dc.l 0
		dc.l $65536
		dc.l $131072
		dc.l $196608
		dc.l $262144
		dc.l $327680
		dc.l $393216
		dc.l $458752
		dc.l $524288
		dc.l $589824
		dc.l $655360
		dc.l $720896
		dc.l $786432
		dc.l $851968
		dc.l $917504
		dc.l $983040
		even
; --------------------------------

@jumpy:
		btst	#7,d2
		beq.s	@not80
		add.l	#$128,d5
		bsr	@fixhexdec
@not80:
		and.l	#$7F,d2
		tst.l	d2
		beq.s	@lowrend
		sub.w	#1,d2
@lelno:
		add.l	#1,d5
		bsr	@fixhexdec
		dbf	d2,@lelno
@lowrend:
		move.l	d5,d2
		swap	d4
		rts

; --------------------------------

@fixhexdec:
		move.w	d5,d4
		and.w	#$F,d4
		cmp.w	#$A,d4
		blt.s	@lowr1
		add.l	#6,d5
@lowr1:
		move.w	d5,d4
		and.w	#$F0,d4
		cmp.w	#$A0,d4
		blt.s	@lowr2
		add.l	#$60,d5
@lowr2:
		move.w	d5,d4
		and.w	#$F00,d4
		cmp.w	#$A00,d4
		blt.s	@lowr3
		add.l	#$600,d5
@lowr3:
		move.w	d5,d4
		and.w	#$F000,d4
		cmp.w	#$A000,d4
		bcs.s	@lowr4
		add.l	#$6000,d5
@lowr4:
		swap	d5
		move.w	d5,d4
		and.w	#$F,d4
		cmp.w	#$A,d4
		bcs.s	@lowr5
		add.l	#$6,d5
@lowr5:
		move.w	d5,d4
		and.w	#$F0,d4
		cmp.w	#$A0,d4
		bcs.s	@lowr6
		add.l	#$60,d5
@lowr6:
		move.w	d5,d4
		and.w	#$F00,d4
		cmp.w	#$A00,d4
		bcs.s	@lowr7
		add.l	#$600,d5
@lowr7:
		swap	d5
		rts
