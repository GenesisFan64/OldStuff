; =====================================================================================
; DMA
; =====================================================================================

; -----------------------------------
; Read
; -----------------------------------

DMA_Read:
		lea	(RAM_DMA_Buffer),a1
		adda	(RAM_DMA_Buffer+(sizeof_dmabuff-4)),a1
@Next:
		tst.w	(a1)
		beq.s	@EndRead
		
		move.w	#$8174,(a2)

		move.l	(a1)+,(a2)
		move.l	(a1)+,(a2)
		move.w	(a1)+,(a2)
		move.w	(a1)+,d5
		lsl.w	#5,d5
		and.l	#$FFFF,d5
		lsl.l	#2,d5
		lsr.w	#2,d5
		swap	d5
		ori.l	#$40000080,d5
		move.l	d5,(a2)
		
		bra.s	@Next

@EndRead:
		move.w	#$8164,(a2)
		rts

; -----------------------------------
; Set new
; -----------------------------------

DMA_Set:
		lea	(RAM_DMA_Buffer),a3
		adda	(RAM_DMA_Buffer+(sizeof_dmabuff-4)),a3

		move.w	#$9300,d0
		move.b	d3,d0
		move.w	d0,(a3)+
		move.w	#$9400,d0
		lsr.w	#8,d3
		move.b	d3,d0
		move.w	d0,(a3)+

    		if MARS
  		sub.l	#marsbank,d2
    		endif
		
		move.w	#$9500,d0
		lsr.l	#1,d2
		move.b	d2,d0
		if SegaCD
		add.b	#1,d0
		endif
		move.w	d0,(a3)+
		move.w	#$9600,d0
		lsr.l	#8,d2
		move.b	d2,d0
		move.w	d0,(a3)+
		move.w	#$9700,d0
		lsr.l	#8,d2
		move.b	d2,d0
		move.w	d0,(a3)+
		move.w	d4,(a3)+

		move.w	a3,(RAM_DMA_Buffer+(sizeof_dmabuff-4))
		cmpa.l	#RAM_DMA_Buffer+$1FA,a3
		bgt.s	@Free
		move.w	#0,(a3)		
@Free:		
		sub.w	#(RAM_DMA_Buffer&$FFFF),(RAM_DMA_Buffer+(sizeof_dmabuff-4))
		
@Return:
		rts

; -----------------------------------
; Reset
; -----------------------------------

DMA_Reset:
		clr.w	(RAM_DMA_Buffer+(sizeof_dmabuff-4))
		move.w	#$8164,(a2)
		rts

; -----------------------------------
; Quick set
; 
; d0 - Destiantion
; d1 - Source
; d2 - Size
; -----------------------------------

DMA_QuickSet:
		movem.l	a1-a2,-(sp)
		move.l	d1,a1
;  		addq.l	#2,d1
		asr.l	#1,d1
 		lea	($C00004).l,a2
		move.w	#$8F02,(a2)
		move.w	#$8164,d3
		bset	#4,d3
		move.w	d3,(a2)
		move.l	#$940000,d3
		move.w	d2,d3
		lsl.l	#8,d3
		move.w	#$9300,d3
		move.b	d2,d3
		move.l	d3,(a2)
		move.l	#$960000,d3
		move.w	d1,d3
		lsl.l	#8,d3
		move.w	#$9500,d3
		move.b	d1,d3
		move.l	d3,(a2)
		swap	d1
		move.w	#$9700,d3
		move.b	d1,d3
		move.w	d3,(a2)
		or.l	#$40000080,d0
		swap	d0
		move.w	d0,(a2)
		swap	d0
		move.w	d0,-(sp)
		move.w	(sp)+,(a2)
		move.w	#$8164,(a2)
		and.w	#$FF7F,d0
		move.l	d0,(a2)
		move.l	(a1),-4(a2)
		move.w	#$8F02,(a2)
		movem.l	(sp)+,a1-a2
		rts
		
; -----------------------------------
; Wait DMA
; -----------------------------------

DMA_Wait:
		move.w	($C00004),d0
		btst	#1,d0
		bne.s	DMA_Wait
		rts		

