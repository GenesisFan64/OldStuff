; ====================================================================
; ---------------------------------------------
; VDP
; ---------------------------------------------

Plane_FG	equ	$40000003
Plane_WD	equ	$50000003
Plane_BG	equ	$60000003

vdp_Xpos	equ	$20000
vdp_Ypos_32	equ	$400000
vdp_Ypos_40	equ	$800000
vdp_Ypos_128	equ	$1000000

bit_vdpHint	equ	4

vdp_H40		equ	$81
vdp_H32		equ	$00
vdp_Double	equ	%00000110

vdpReg_HMode	equ	$C
vdpReg_PlnSize	equ	$10

; --------------------------------------------
; Clear planes
; --------------------------------------------

VDP_ClearPlanes:
		bsr	VDP_ClrPlane_FG

VDP_ClrPlane_BG:
		move.l	#Plane_BG,($C00004).l
		move.w	#$7FF,d0
@ClrBG:
		clr.l	($C00000).l
		dbf	d0,@ClrBG
		rts

VDP_ClrPlane_FG:
		move.l	#Plane_FG,($C00004).l
		move.w	#$7FF,d0
@ClrFG:
		clr.l	($C00000).l
		dbf	d0,@ClrFG
		rts

; --------------------------------------------
; VDP_ClearScroll
;
; Set both scrollings to $0000
; --------------------------------------------

VDP_ClearScroll:
		lea	(RAM_HorBuffer),a0
		move.w	#$37F,d0
@ClrScrl:
		clr.l	(a0)+
		dbf	d0,@ClrScrl
		
		lea	(RAM_VerBuffer),a0
		move.w	#$7F,d0
@ClrVScrl:
		clr.l	(a0)+
		dbf	d0,@ClrVScrl
		rts

; --------------------------------------------
; VDP_SendData_W, VDP_SendData_L
;
; Input:
; a0 - Data address
;
; d0 | VRAM Address
; d1 | Data size
; --------------------------------------------

VDP_SendData_W:
		bsr	VDP_VramAddr
		move.l	d0,($C00004)
@Loop:
		move.w	(a0)+,($C00000).l
		dbf	d1,@Loop
		rts

VDP_SendData_L:
		bsr	VDP_VramAddr
		move.l	d0,($C00004)
@Loop:
		move.l	(a0)+,($C00000).l
		dbf	d1,@Loop
		rts

; --------------------------------------------
; VDP_VramAddr
;
; Input:
; d0 | WORD - VRAM to convert
;
; Output:
; d0 | LONG - VDP Command (Write mode)
; --------------------------------------------

VDP_VramAddr:
		swap	d0
		move.w	#0,d0
		swap	d0
		cmp.w	#$200,d0
		blt.s	@NoBank
		swap	d0
		move.w	#1,d0
		swap	d0
		cmp.w	#$400,d0
		blt.s	@NoBank
		swap	d0
		move.w	#2,d0
		swap	d0
		cmp.w	#$600,d0
		blt.s	@NoBank
		swap	d0
		move.w	#3,d0
		swap	d0
@NoBank:
 		and.w	#$1FF,d0
		lsl.w	#5,d0
 		add.w	#$4000,d0
		swap	d0
		rts
		
; --------------------------------------------
; VDP_ShowVal
;
; Input:
; d0 | B/W/L - Value
; d1 | LONG - VDP
; d2 | WORD - VRAM
;
; Breaks:
; d4
; --------------------------------------------

VDP_ShowVal_Long:
		movem.l	d0/d2,-(sp)
		move.l	d1,d4
		swap	d0
		bsr	VDP_ShowVal_Word
                add.l	#$40000,d4
                move.l	d4,d1

		movem.l	(sp)+,d0/d2

VDP_ShowVal_Word:
		movem.l	d0/d2,-(sp)
		move.l	d1,d4
		lsr.w	#8,d0
		bsr	VDP_ShowVal_Byte
		add.l	#$40000,d4
                move.l	d4,d1

		movem.l	(sp)+,d0/d2

VDP_ShowVal_Byte:
		move.l	d1,($C00004)

		move.b	d0,d3
		lsr.b	#4,d0
		bsr	@PrevVal
		move.b	d3,d0
@PrevVal:
		andi.w	#$F,d0
		cmp.w	#$A,d0
		bcs	@Less
		add.w	#7,d0
@Less
		add.w	d2,d0
		move.w	d0,($C00000)
		rts

; --------------------------------------------
; Tamaño 8x16
;
; Input:
; d0 | B/W/L - Value
; d1 | LONG - VDP
; d2 | WORD - VRAM
; --------------------------------------------

VDP_ShowVal_Long_L:
		movem.l	d0/d2,-(sp)
		move.l	d1,d6
		swap	d0
		bsr	VDP_ShowVal_Word_L
                add.l	#$40000,d6
                move.l	d6,d1

		movem.l	(sp)+,d0/d2

VDP_ShowVal_Word_L:
		movem.l	d0/d2,-(sp)
		move.l	d1,d6
		lsr.w	#8,d0
		bsr	VDP_ShowVal_Byte_L
                add.l	#$40000,d6
                move.l	d6,d1

		movem.l	(sp)+,d0/d2


VDP_ShowVal_Byte_L:
		lea	($C00000).l,a6

                move.w	d0,d4
                move.l	d1,d5

                lsr.b	#4,d0
		bsr	@ShowNextVal

                add.l	#$20000,d5
		add.w	#1,d0

                move.w	d4,d0
                move.l	d5,d1

@ShowNextVal:
		add.w	d0,d0

		and.w	#$1F,d0

		add.w	d2,d0
		move.l	d1,4(a6)		;Set VDP Command

        	move.w	d0,d3
		move.w	d0,(a6)

         	add.w	#1,d3
                add.l	#$800000,d1

		move.w	d3,d0
		move.l	d1,4(a6)		;Set VDP Command
		move.w	d0,(a6)
		rts

; --------------------------------------------

VDP_LoadAsc_List:
		move.w	(a1),d0
                bpl.s	@GoodPointer
		rts

@GoodPointer:
		movea.l	(a1)+,a0
		move.l	(a0)+,d1
		move.w	(a0)+,d2
		bsr.s	VDP_LoadAsc

		bra.s	VDP_LoadAsc_List

; --------------------------------------------
; VDP_LoadMaps
; 
; Input:
; d0 | LONG - VDP Command
; d1 | WORD - X size - 1
; d2 | WORD - Y size - 1
; d3 | WORD - VRAM
;
; OLD: d4 | WORD - Horizontal mode ID
; --------------------------------------------

VDP_LoadMaps:
		move.b	(RAM_VdpRegs+vdpReg_PlnSize),d4
		and.w	#%00000011,d4
		lsl.w	#2,d4
		lea	VDP_LineAddr(pc),a5
		move.l	(a5,d4.w),d4

@Y_Loop:
		move.l	d0,($C00004).l		;Set VDP location from d0
		move.w	d1,d5	  		;Move X-pos value to d3

@X_Loop:
		move.w	(a0)+,d6
                add.w	d3,d6
                move.w	d6,($C00000)		;Put data
		dbf	d5,@X_Loop		;X-pos loop (from d1 to d3)
		add.l	d4,d0                   ;Next line
		dbf	d2,@Y_Loop		;Y-pos loop
		rts

; --------------------------------------------
; VDP_LoadAsc
;
; Input:
; a0 - String
; 
; d1 | LONG - VDP
; d2 | WORD - VRAM
; d3 | WORD - Horizontal mode ID
; --------------------------------------------

VDP_LoadAsc:
		move.l	d1,($C00004).l

@Loop_Text:
		moveq	#0,d4
		move.b	(a0)+,d4
		move.w	d4,d5
		cmp.w	#$0A,d5
		beq	@NextLine
		cmp.w	#$0D,d5
		beq	@NewLine
		tst.w	d5
		bne	@TypeChar
		rts

@NewLine:
		add.l	#$20000,d1
		bra	VDP_LoadAsc
		
@TypeChar:
		add.w	d2,d4
		move.w	d4,($C00000).l
		bra	@Loop_Text
		
@NextLine:
		moveq	#0,d5
		move.b	(RAM_VdpRegs+vdpReg_PlnSize),d5
		and.w	#%00000011,d5
		lsl.w	#2,d5
		move.l	VDP_LineAddr(pc,d5.w),d5
		add.l	d5,d1

		bra	VDP_LoadAsc

; --------------------------------------------
; Vdp_Init
;
; Set the default registers
; --------------------------------------------

Vdp_Init:
		lea	Vdp_RegData(pc),a0
		lea	(RAM_VdpRegs),a1
		move.w	#$8000,d1
		moveq	#$17-1,d0
@Loop:
		move.b	(a0)+,(a1)+
		dbf	d0,@Loop
		rts

; --------------------------------------------
; Vdp_Update
;
; Refresh VDP
; --------------------------------------------

Vdp_Update:
		lea	(RAM_VdpRegs),a0
		move.w	#$8000,d1
		moveq	#$17-1,d0
@Loop:
		move.b	(a0)+,d1
		move.w	d1,($C00004).l
		move.b	#0,d1
		add.w	#$100,d1
		dbf	d0,@Loop
		rts
		
; --------------------------------------------
; VSync
; --------------------------------------------

VSync:
		bset	#bitFrameWait,(RAM_VIntWait)
@StillOn:
		btst	#bitFrameWait,(RAM_VIntWait)
		bne.s	@StillOn
		rts
		
; -----------------------------------------

Vdp_RegData:
		dc.b $04
		dc.b $64
		dc.b $30
		dc.b $34
		dc.b $07
		dc.b $7C
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $03		;Horizontal scroll type
		dc.b $81
		dc.b $3F
		dc.b $00
		dc.b $02
		dc.b $01
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		dc.b $00
		even

; --------------------------------------------

VDP_LineAddr:
		dc.l $400000
		dc.l $800000
		dc.l $1000000
		dc.l $1000000
		even
		
; ======================================================
; *New routines for reading RAW data
; from GIMP*
; (.raw and .raw.pal)
; ======================================================
	
; ; --------------------------------------------
; ; Vdp_RawToPal
; ;
; ; Input:
; ; a0 - RAW pallete input
; ; a1 - RAM pallete output
; ; d0 | WORD - Length
; ; 
; ; Output:
; ; none
; ;
; ; Uses:
; ; d3-d6
; ; --------------------------------------------
; 
; Vdp_RawToPal:		
; 		moveq	#0,d3
; 		move.w	d0,d3		;Length
; 		moveq	#0,d4
; 		move.w	d0,d4
; 		lsr.w	#8,d4		;Start from
; 		adda	d4,a0
; 		adda 	d4,a1
; @Next:
; 		moveq	#0,d4
; 		moveq	#0,d5
; 		moveq	#0,d6
; 		move.b	(a0)+,d4	;RED
; 		move.b	(a0)+,d5	;GREEN
; 		move.b	(a0)+,d6	;BLUE
; 		lsr.w	#5,d4		;Convert to MD
; 		lsl.w	#1,d4
; 		lsr.w	#5,d5
; 		lsl.w	#1,d5
; 		lsr.w	#5,d6
; 		lsl.w	#1,d6
; 		lsl.w	#4,d5
; 		add.w	d5,d4
; 		lsl.w	#8,d6
; 		add.w	d6,d4		;d4 - final MD color
; 		move.w	d4,(a1)+
; 		dbf	d3,@Next
; 		rts
; 		
; ; --------------------------------------------
; ; Vdp_RawToGfx
; ;
; ; Input:
; ; a0 - RAW gfx input
; ; d0 | LONG - VDP Address
; ; d1 | WORD - Width
; ; d2 | WORD - Height
; ; 
; ; Output:
; ; none
; ;
; ; Uses:
; ; d3-d6
; ; --------------------------------------------
; 
; Vdp_RawToArt:
; 		lsr.w	#3,d1
; 		sub.w	#1,d1
; 		sub.w	#1,d2
; 		moveq	#0,d6
; @LoopY:
; 		move.l	d0,d3
; 		move.w	d1,d4
; 		swap	d6
; @LoopX:
; 		bsr	@GetLine
; 		move.l	d3,($C00004)
; 		move.l	d5,($C00000)
; 		add.l	#$200000,d3
; 
; 		tst.l	d3
; 		bpl.s	@Fine2
; 		sub.l	#$40000000,d3
; 		add.w	#1,d3
; @Fine2:
; 
; 		dbf	d4,@LoopX
; 		swap	d6
; 		add.w	#1,d6
; 
; 		add.l	#$40000,d0
; 		bsr	@FixAddr
; 		cmp.w	#8,d6
; 		blt.s	@NotEndCell
; 		clr.w	d6
; 		sub.l	#$200000,d0
; 		bsr	@FixAddr
; 
; 		move.w	d1,d4
; @FindNewCell:
; 		add.l	#$200000,d0
; 		bsr	@FixAddr
; 		dbf	d4,@FindNewCell
; 		
; @NotEndCell:
; 		dbf	d2,@LoopY
; 		rts
; 		
; ; ---------------------------
; 
; @GetLine:
; 		moveq	#0,d5
; 		move.w	#0,d6
; 		move.b	(a0)+,d6
; 		and.b	#$F,d6
; 		add.b	d6,d5
; 		lsl.l	#4,d5
; 		move.b	(a0)+,d6
; 		and.b	#$F,d6
; 		add.b	d6,d5
; 		lsl.l	#4,d5
; 		move.b	(a0)+,d6
; 		and.b	#$F,d6
; 		add.b	d6,d5
; 		lsl.l	#4,d5
; 		move.b	(a0)+,d6
; 		and.b	#$F,d6
; 		add.b	d6,d5
;  		lsl.l	#4,d5
;  		move.b	(a0)+,d6
;  		and.b	#$F,d6
;  		add.b	d6,d5
;  		lsl.l	#4,d5
;  		move.b	(a0)+,d6
;  		and.b	#$F,d6
;  		add.b	d6,d5
;  		lsl.l	#4,d5
;  		move.b	(a0)+,d6
;  		and.b	#$F,d6
;  		add.b	d6,d5
;  		lsl.l	#4,d5
;  		move.b	(a0)+,d6
;  		and.b	#$F,d6
;  		add.b	d6,d5
; 		rts
; 
; ; ---------------------------
; 
; @FixAddr:
; 		tst.l	d0
; 		bpl.s	@Fine
; 		sub.l	#$40000000,d0
; 		add.w	#1,d0
; @Fine:
; 		rts

; --------------------------------------------
; Vdp_RawAutoMap
;
; Input:
; d0 | LONG - VDP Address
; d1 | WORD - Width
; d2 | WORD - Height
; d3 | WORD - Start from this value
; d4 | WORD - Horizontal size type (32,40,128)
;
; Output:
; none
;
; Breaks:
; d5
; --------------------------------------------
		
Vdp_RawAutoMap:
		moveq	#0,d5
		add.w	d3,d5
		move.w	d5,d3

		move.b	(RAM_VdpRegs+vdpReg_PlnSize),d4
		and.w	#%00000011,d4
		lsl.w	#2,d4
		lea	VDP_LineAddr(pc),a5
		move.l	(a5,d4.w),d4		;Space

@Loop_2:
		move.l	d0,($C00004)		;Set VDP location from d0
		move.w	d1,d5	  		;Move X-pos value to d3
@Loop:
		move.w	d3,($C00000)		;Put data
                add.w	#1,d3
		dbf	d5,@Loop		;X-pos loop (from d1 to d3)
		add.l	d4,d0                   ;Next line
		dbf	d2,@Loop_2		;Y-pos loop
		rts
		