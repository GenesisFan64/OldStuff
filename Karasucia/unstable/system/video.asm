; ====================================================================
; VDP
; ====================================================================

; -------------------------------------------------
; Variables
; -------------------------------------------------

		rsreset
palFd_mode	rs.b 1
palFd_delay	rs.b 1
palFd_from	rs.b 1			;TODO: poner funcionar esto
palFd_num	rs.b 1
palFd_timer	rs.w 1

		rsreset
sprite_free	rs.l 1
sprite_link	rs.w 1
sprite_used	rs.w 1

; ====================================================================
; -------------------------------------------------
; RAM
; -------------------------------------------------

		rsset RAM_Video
RAM_ScrlHor	rs.l 240
RAM_ScrlVer	rs.l $20			; Normal
RAM_Sprites	rs.l (80*2)			; Normal
RAM_SprControl	rs.l 2				; Normal
RAM_HSprites	rs.l (80*2)			; For HBlank
RAM_HScrlVer	rs.l $20			; For HBlank
RAM_HSprLast	rs.l 2				; For HBlank
RAM_Palette	rs.w 64				; Normal
RAM_HPalette	rs.w 64				; For HBlank
RAM_PalFade	rs.w 64				; Normal
RAM_HPalFade	rs.w 64				; For HBlank
RAM_PalFadeSys	rs.l 8*2
RAM_DMA_Buffer	rs.b $200
RAM_VidRegs	rs.b 16				; Unused regs included (always zero) | WINDOW and DMA regs ignored, use them separately

sizeof_vid	rs.l 0
;       		inform 0,"video ram: %h",(sizeof_vid-RAM_Video)

; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

; -------------------------------------------------
; Video control
; -------------------------------------------------

Video_init:
		lea	reg_data(pc),a0
		lea	(RAM_VidRegs),a1
		move.w	#$8000,d0
		moveq	#17-1,d1
@reg_list:
		move.b	(a0)+,d0
		move.b	d0,(a1)+
		move.w	d0,(vdp_ctrl)
		add.w	#$100,d0
		dbf	d1,@reg_list
		move.l	#$91009200,(vdp_ctrl)	;WINDOW LEFT/TOP clear
		move.l	#$93009400,(vdp_ctrl)	;DMA len low/high clear
		move.l	#$95009600,(vdp_ctrl)	;DMA addr mid/low clear
		move.w	#$9700,(vdp_ctrl)	;DMA addr high clear
  	
; --------------------------------------------
; Video_ClearAll
; --------------------------------------------

Video_ClearAll:
		move.l	#$91009200,(vdp_ctrl)
		
		bsr.s	Video_ClrAllLyrs
		bsr.s	Video_ClearScroll
		bsr	Sprites_Clear
		bra	Sprites_Reset
		
Video_ClearSprites:
		bsr	Sprites_Clear
		bra	Sprites_Reset
		
; --------------------------------------------
; Video_ClrAllLyrs
; --------------------------------------------

Video_ClrAllLyrs:
		move.l	#$40000003,d0
		bsr.s	Video_ClrLyr
		move.l	#$50000003,d0
		bsr.s	Video_ClrLyr
		move.l	#$60000003,d0
; 		bsr.s	Video_ClrLyr
; 		rts
		
; --------------------------------------------
; Video_ClrLyr
; 
; d0 | LONG - VDP VRAM Command for the layer
; --------------------------------------------

Video_ClrLyr:
		move.l	d0,(vdp_ctrl)
		move.w	#$7FF,d0
@loop:
		move.w	#0,(vdp_data)
		dbf	d0,@loop
		rts
	
; --------------------------------------------
; Video_ClrHScrl
; --------------------------------------------

Video_ClrHScrl:
		lea	(RAM_ScrlHor),a0
		move.w	#224-1,d0
		bra.s	VidClrScrl_loop

; --------------------------------------------
; Video_ClearScroll
; --------------------------------------------

Video_ClearScroll:
		bsr.s	Video_ClrHScrl
		lea	(RAM_ScrlVer),a0
		bsr.s	Video_ClrVScrl
		lea	(RAM_HScrlVer),a0
; 		bsr.s	Video_ClrVScrl
		
; --------------------------------------------
; Video_ClrVScrl
; 
; a0 - Vertical scroll data
; --------------------------------------------

Video_ClrVScrl:
		move.w	#$20-1,d0
VidClrScrl_loop:
		clr.l	(a0)+
		dbf	d0,VidClrScrl_loop
		rts
		
; ------------------------------------

reg_data:
		dc.b %00000100			; $80: [4] HInt interrupt OFF | [2] ALWAYS ON | [1] HV Counter OFF
		dc.b %01110100			; $81: [6] Display ON, [5] Vint interrupt ON, [4] DMA OFF, [3] V28 (V30 PAL ONLY) | [2] ALWAYS ON
		dc.b ($C000>>10)&%00111000	; $82: Plane A pattern table
		dc.b ($D000>>10)&%00111110	; $83:  WINDOW pattern table (%00111110 H32, %00111100 H40)
		dc.b ($E000>>13)&%00000111	; $84: Plane B pattern table
		dc.b ($F800>>09)&%01111111	; $85:  Sprite attribute table (%01111111 H32, %01111110 H40)
		dc.b 0				; $86: NOTHING
		dc.b 0				; $87: BG Color
		dc.b 0				; $88: NOTHING
		dc.b 0				; $89: NOTHING
		dc.b 0				; $8A: HInt counter
		dc.b %00000011			; $8B: [3] External interrupt OFF | [2] Vscrl: full | [1|0] Hscrl: full
		dc.b %10000001			; $8C: [7+0] H40 | [3] Prio/Shadow | [2|1] Interlace mode: None
		dc.b ($FC00>>10)&%00111111	; $8D: Hscroll attribute table
		dc.b 0				; $8E: NOTHING
		dc.b 2				; $8F: VDP Auto increment
		dc.b %00000001			; $90: Plane size [5|4] Y size | [1|0] X size
		even

; -------------------------------------------------
; Subs
; -------------------------------------------------

Video_Update:
		lea	(RAM_VidRegs),a0
		move.w	#$8000,d0
		moveq	#17-1,d1
@reg_list:
		move.b	(a0)+,d0
		move.w	d0,(vdp_ctrl)
		add.w	#$100,d0
		dbf	d1,@reg_list
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
		lsl.w	#5,d0
		bsr	VDP_VramToCmd
		move.l	d0,(vdp_ctrl)
@Loop:
		move.w	(a0)+,(vdp_data).l
		dbf	d1,@Loop
		rts

VDP_SendData_L:
		lsl.w	#5,d0
		bsr	VDP_VramToCmd
		move.l	d0,(vdp_ctrl)
@Loop:
		move.l	(a0)+,(vdp_data).l
		dbf	d1,@Loop
		rts
		
; -----------------------
; Uses: d4 (LONG)
;       d5 (WORD)
; -----------------------

vdpshv_findvdppos:
		;Check plane to use
		swap	d5
		move.w	d0,d5
		moveq	#0,d0
		move.b	(RAM_VidRegs+2),d0
		btst	#1,d5				;%10? (WD)
		beq.s	@FG
		move.b	(RAM_VidRegs+3),d0
@FG:
		lsl.w	#8,d0
		lsl.w	#2,d0
		btst	#0,d5				;%01? (BG)
		beq.s	@FGWD
		moveq	#0,d0
		move.b	(RAM_VidRegs+4),d0
		lsl.w	#8,d0
		lsl.w	#5,d0
@FGWD:

		;Start Y
		moveq	#0,d4
   		move.w	d1,d4
  		lsl.l	#6,d4
 		btst	#1,d5
 		beq.s	@def_fgbg
 		
 		;TODO: WD resolution check
;    		move.b	(RAM_VidRegs+vdpReg_HMode),d5
;    		and.w	#%10000001,d5
;    		bne.s	@Not128
    		lsl.l	#1,d4
		bra.s	@Not128
@def_fgbg:
 		btst	#0,(RAM_VidRegs+$10)
 		beq.s	@Not40
  		lsl.l	#1,d4
@Not40:
 		btst	#1,(RAM_VidRegs+$10)
 		beq.s	@Not128
    		lsl.l	#1,d4
@Not128:
 		add.w	d4,d0			;+Y Start
		swap	d1
		lsl.w	#1,d1
		add.w	d1,d0			;+X Start
		swap	d5
		
; --------------------------------------------
; VDP_VramToCmd
;
; Input:
; d0 | WORD - VRAM to convert
;
; Output:
; d0 | LONG - VDP Command (Write mode)
; --------------------------------------------

VDP_VramToCmd:
		cmp.w	#$4000,d0
		bcs.s	@NoBank
		swap	d0
		move.w	#1,d0
		swap	d0
		cmp.w	#$8000,d0
		bcs.s	@NoBank	
		swap	d0
		move.w	#2,d0
		swap	d0
		cmp.w	#$C000,d0
		bcs.s	@NoBank	
		swap	d0
		move.w	#3,d0
		swap	d0
@NoBank:
  		and.w	#$3FFF,d0
  		or.w	#$4000,d0
   		swap	d0
		rts
		
; --------------------------------------------
; VDP_LoadMaps
; 
; Input:
; a0 - Pattern data
; d0 | WORD - Plane type: 0-FG 1-BG 2-Window
; d1 | LONG - XPos  (WORD) | YPos  (WORD)
; d2 | LONG - Value
; d3 | WORD - VRAM (ASCII start)
; d4 | WORD - Type:
;             00 Byte | 01 Word | 02 Long HEX
;             04 Byte | 05 Word | 06 Long DEC
;             08 Byte | 09 Word | 0A Long DEC
; Uses:
; d4-d6
; 
; NOTE: clear d2 FIRST and then set the value
; --------------------------------------------

Video_PrintVal:
		and.w	#%111,d4
		btst	#2,d4
		beq.s	@hexy
		bsr	HexToDec
@hexy:
		move.w	d4,d5
		bsr	vdpshv_findvdppos
		move.w	d5,d4
		
		move.l	d0,(vdp_ctrl)
		add.w	#"0",d3
		
   		moveq	#(8)-1,d5
		btst	#1,d4
		bne.s	@setit
   		moveq	#(4)-1,d5
 		swap	d2
   		move.b	d4,d0
   		and.b	#%11,d0
 		tst.b	d0
 		bne.s	@setit
 		moveq	#(2)-1,d5
 		rol.l	#8,d2
@setit:
		btst	#2,d4
		beq.s	@next
		btst	#1,d4
		bne.s	@next
		ror.l	#4,d2
		add.w	#1,d5
@next:
 		rol.l	#4,d2
		move.w	d2,d0
		and.w	#$F,d0
		cmp.w	#$A,d0
		bcs.s	@lessF
		add.w	#7,d0
@lessF
		add.w	d3,d0
		move.w	d0,(vdp_data)
		dbf	d5,@next
		rts

; --------------------------------------------
; Video_MakeMap
; 
; Input:
; a0 - Pattern data
; d0 | WORD - Plane type: 0-FG 1-BG 2-Window
; d1 | LONG - XPos  (WORD) | YPos  (WORD)
; d2 | LONG - XSize (WORD) | YSize (WORD)
; d3 | WORD - VRAM
; 
; Uses:
; d4-d6
; --------------------------------------------

Video_MakeMap:
		;Check plane to use
		bsr	vdpshv_findvdppos
		
		move.l	#$400000,d4
		btst	#0,(RAM_VidRegs+$10)
		beq.s	@JpNot40
 		lsl.l	#1,d4
@JpNot40:
		btst	#1,(RAM_VidRegs+$10)
		beq.s	@Y_Loop
     		lsl.l	#1,d4
     		
@Y_Loop:
		move.l	d0,(vdp_ctrl).l		; Set VDP location from d0
		swap	d2
		move.w	d2,d5	  		; Move X-pos value to d3
		swap	d2
@X_Loop:
		move.w	(a0)+,d6
                add.w	d3,d6
                swap	d5
                move.b	(RAM_VidRegs+$C),d5
                and.w	#%110,d5
                beq.s	@normal
                lsr.w	#1,d6
@normal:
                swap	d5
                move.w	d6,(vdp_data)		; Put data
		dbf	d5,@X_Loop		; X-pos loop (from d1 to d3)
		add.l	d4,d0                   ; Next line
		dbf	d2,@Y_Loop		; Y-pos loop
		rts

; --------------------------------------------
; Video_PrintText
;
; Input:
; a0 - String
; d0 | WORD - Plane type: 0-FG 1-BG 2-Window
; d1 | LONG - XPos  (WORD) | YPos  (WORD)
; d2 | VRAM
; 
; Uses:
; d3-d4
; --------------------------------------------

Video_PrintText:
		;Check plane to use
		move.w	d0,d5
		bsr	vdpshv_findvdppos
		
 		move.l	#$800000,d4
;  		cmp.w	#2,d5
;  		bne.s	@NotWindow
; 		
;  		tst.b	(RAM_VidRegs+$C)
;  		beq.s	@Reset
;  		lsl.l	#1,d4
; 		bra.s	@Reset
; 		
; @NotWindow:
; 		btst	#0,(RAM_VidRegs+$10)
; 		beq.s	@JpNot40
;  		lsl.l	#1,d4
; @JpNot40:
; 		btst	#1,(RAM_VidRegs+$10)
; 		beq.s	@Space
;      		lsl.l	#1,d4
     		
@Reset:
		move.l	d0,(vdp_ctrl).l
@Next:
		moveq	#0,d3
		move.b	(a0)+,d3
		cmp.b	#$A,d3
		beq.s	@Space
		tst.b	d3
		bne.s	@Char
		rts
@Char:
		add.w	d2,d3
		move.w	d3,(vdp_data).l
		bra.s	@Next
@Space:
		add.l	d4,d0                   ; Next line
		bra.s	@Reset
@Exit:
		rts
		
; --------------------------------------------
; Video_VSync
; 
; Wait VBlank
; --------------------------------------------

Video_VSync:
 		bset	#0,(RAM_IntFlags)
@vint:
		btst	#0,(RAM_IntFlags)
		bne.s	@vint
		rts

; ====================================================================
; ---------------------------------------------
; Palette fading
; ---------------------------------------------

PalFade_Upd:
		lea	(RAM_PalFadeSys),a6
 		moveq	#4-1,d6
@NextPalReq:
		tst.l	(a6)
		beq.s	@Unused
 		lea	(RAM_Palette),a5
 		lea	(RAM_PalFade),a4
  		bsr	@Active
@Unused:
 		adda	#8,a6
 		dbf	d6,@NextPalReq
		
		moveq	#4-1,d6
@NextHPalReq:
		tst.l	(a6)
		beq.s	@UnusedH
		lea	(RAM_HPalette),a5
		lea	(RAM_HPalFade),a4
		bsr	@Active
@UnusedH:
		adda	#8,a6
		dbf	d6,@NextHPalReq
		rts
		
; ---------------------------------
; Active palette
; ---------------------------------

@Active:
		moveq	#0,d0
		move.b	palFd_mode(a6),d0
		add.w	d0,d0
		move.w	@list(pc,d0.w),d1
		jmp	@list(pc,d1.w)
		
; ---------------------------------

@list:
		dc.w fadeSet_Return-@list
		dc.w fadeSet_in_timer-@list
		dc.w fadeSet_out_timer-@list
		dc.w fadeSet_in_single-@list
 		dc.w fadeSet_out_single-@list		
		
; ---------------------------------

fadeSet_in_timer:
		sub.w	#1,palFd_timer(a6)
		bpl	fadeSet_Return
		moveq	#0,d4
		moveq	#0,d5
		move.b 	palFd_delay(a6),d4
		move.w	d4,palFd_timer(a6)
		move.b 	palFd_num(a6),d4
@next_in:
 		move.w	(a5),d0
 		move.w	(a4),d1
		move.w	d0,d2
 		move.w	d1,d3
 		and.w	#$00E,d2
 		and.w	#$00E,d3
 		cmp.w	d2,d3
 		beq.s	@goodin_b
		add.w	#2,d2
@goodin_b:
		and.w	#$EE0,d0
 		or.w	d2,d0
		
		move.w	d0,d2
 		move.w	d1,d3
 		and.w	#$0E0,d2
 		and.w	#$0E0,d3
 		cmp.w	d2,d3
 		beq.s	@goodin_g
		add.w	#$020,d2
@goodin_g:
		and.w	#$E0E,d0
 		or.w	d2,d0
  		
		move.w	d0,d2
 		move.w	d1,d3
 		and.w	#$E00,d2
 		and.w	#$E00,d3
 		cmp.w	d2,d3
 		beq.s	@goodin_r
		add.w	#$200,d2
@goodin_r:
		and.w	#$0EE,d0
 		or.w	d2,d0
 		
 		move.w	d0,(a5)+
 		cmp.w	(a4)+,d0
 		bne.s	@nonz_fdin
 		add.w	#1,d5
@nonz_fdin:
		dbf	d4,@next_in
		
		sub.w	#1,d5
		cmp.b	palFd_num(a6),d5
		bne.s	fadeSet_Return
		clr.l	(a6)
fadeSet_Return:
		rts
		
; ---------------------------------

fadeSet_out_timer:
		sub.w	#1,palFd_timer(a6)
		bpl.s	fadeSet_Return
		moveq	#0,d2
		moveq	#0,d3
		move.b 	palFd_delay(a6),d2
		move.w	d2,palFd_timer(a6)
		move.b 	palFd_num(a6),d2
@setcol:
		move.w	(a5),d0
		move.w	d0,d1
		and.w	#$00E,d1
		beq.s	@good_b
		sub.w	#2,d1
@good_b:
		and.w	#$EE0,d0
		or.w	d1,d0
		
		move.w	d0,d1
		and.w	#$0E0,d1
		beq.s	@good_g
		sub.w	#$020,d1
@good_g:
		and.w	#$E0E,d0
		or.w	d1,d0
		move.w	d0,d1
		and.w	#$E00,d1
		beq.s	@good_r
		sub.w	#$200,d1
@good_r:
		and.w	#$0EE,d0
		or.w	d1,d0
		move.w	d0,(a5)+
		tst.w	d0
		bne.s	@nonzero
		add.w	#1,d3
@nonzero:
		dbf	d2,@setcol
		
		sub.w	#1,d3
		cmp.b	palFd_num(a6),d3
		bne.s	fadeSet_Return
		clr.l	(a6)
		rts
		
; ---------------------------------
; fadeSet_in_single
; 
; palFd_delay:
; RGBTTTTT - RGB increment bits
;            TTTTT timer
; ---------------------------------

fadeSet_in_single:
		sub.w	#1,palFd_timer(a6)
		bpl	fadeSet_Return

		moveq	#0,d5
		move.b	palFd_from(a6),d5
		lsl.w	#1,d5
		adda	d5,a5
		move.b 	palFd_delay(a6),d3
		and.w	#$E0,d3
		move.w	#2,palFd_timer(a6)
		
		moveq	#0,d4
		move.b 	palFd_num(a6),d4
@next_in:
 		move.w	(a5),d0
		move.w	d0,d2
 		and.w	#$00E,d2
		btst	#5,d3
		beq.s	@goodin_b
 		cmp.w	#$00E,d2
 		bge.s	@goodin_b
		add.w	#2,d2
@goodin_b:
		and.w	#$EE0,d0
 		or.w	d2,d0

		move.w	d0,d2
 		and.w	#$0E0,d2
		btst	#6,d3
		beq.s	@goodin_g
 		cmp.w	#$0E0,d2
 		bge.s	@goodin_g
		add.w	#$020,d2
@goodin_g:
		and.w	#$E0E,d0
 		or.w	d2,d0

		move.w	d0,d2
 		and.w	#$E00,d2
		btst	#7,d3
		beq.s	@goodin_r
 		cmp.w	#$E00,d2
 		bge.s	@goodin_r
		add.w	#$200,d2
@goodin_r:
		and.w	#$0EE,d0
 		or.w	d2,d0

 		move.w	d0,(a5)+
		dbf	d4,@next_in
		
		move.b	palFd_delay(a6),d0
		and.w	#$1F,d0
		sub.w	#1,d0
		bpl.s	fadeSet_Return_2
		
; 		sub.w	#1,d5
; 		cmp.b	palFd_num(a6),d5
; 		bne.s	fadeSet_Return
		clr.l	(a6)
		clr.l	4(a6)
		
fadeSet_Return_2:
		and.b	#$E0,palFd_delay(a6)
		or.b	d0,palFd_delay(a6)
		rts
		
; ---------------------------------
; fadeSet_out_single
; 
; palFd_delay:
; RGBTTTTT - RGB increment bits
;            TTTTT timer
; ---------------------------------

fadeSet_out_single:
		sub.w	#1,palFd_timer(a6)
		bpl	fadeSet_Return

		moveq	#0,d5
		move.b	palFd_from(a6),d5
		lsl.w	#1,d5
		adda	d5,a5
		move.b 	palFd_delay(a6),d3
		and.w	#$E0,d3
		move.w	#2,palFd_timer(a6)
		
		moveq	#0,d4
		move.b 	palFd_num(a6),d4
@next_in:
 		move.w	(a5),d0
		move.w	d0,d2
 		and.w	#$00E,d2
		btst	#5,d3
		beq.s	@goodin_b
;  		tst.w	d2
;  		beq.s	@goodin_b
		sub.w	#2,d2
@goodin_b:
		and.w	#$EE0,d0
 		or.w	d2,d0

		move.w	d0,d2
 		and.w	#$0E0,d2
		btst	#6,d3
		beq.s	@goodin_g
;  		tst.w	d2
;  		beq.s	@goodin_g
		sub.w	#$020,d2
@goodin_g:
		and.w	#$E0E,d0
 		or.w	d2,d0

		move.w	d0,d2
 		and.w	#$E00,d2
		btst	#7,d3
		beq.s	@goodin_r
;  		tst.w	d2
;  		beq.s	@goodin_r
		sub.w	#$200,d2
@goodin_r:
		and.w	#$0EE,d0
 		or.w	d2,d0

 		move.w	d0,(a5)+
		dbf	d4,@next_in
		
		move.b	palFd_delay(a6),d0
		and.w	#$1F,d0
		sub.w	#1,d0
		bpl.s	@fadeSet_Return_2
		
; 		sub.w	#1,d5
; 		cmp.b	palFd_num(a6),d5
; 		bne.s	fadeSet_Return
		clr.l	(a6)
		clr.l	4(a6)
		
@fadeSet_Return_2:
		and.b	#$E0,palFd_delay(a6)
		or.b	d0,palFd_delay(a6)
		rts
		
; --------------------------------------------
; PalFade_Set
; --------------------------------------------

PalFade_Set:
		rts
		
; ====================================================================
; ---------------------------------------------
; DMA
; ---------------------------------------------

; ROM data
; Size
; VRAM Destiantion

DMA_Read:
 		lea	(RAM_DMA_Buffer),a6
;  		move.w	#64,d3
  		move.w	(a6)+,d4
;   		sub.w	d4,d3
;   		bmi	@FinishList
  		tst.w	d4
  		beq	@FinishList
  		sub.w	#1,d4
; 		dma 	on
@NextEntry:
		move.l	(a6)+,d5
     		if MARS
		and.l	#$FFFFF,d5
 		elseif MCD
 		add.l	#2,d5
 		endif
 		
  		lsr.l	#1,d5
 		move.l	#$96009500,d6
 		move.b	d5,d6
 		lsr.l	#8,d5
 		swap	d6
 		move.b	d5,d6
 		move.l	d6,(vdp_ctrl)
 		move.w	#$9700,d6
 		lsr.l	#8,d5
 		move.b	d5,d6
 		move.w	d6,(vdp_ctrl)
 		
  		move.l	#$94009300,d6		;Size
  		move.w	(a6)+,d5
  		move.b	d5,d6
 		swap	d6
  		lsr.w	#8,d5
  		move.b	d5,d6
  		move.l	d6,(vdp_ctrl)
 		
 		move.w	(a6)+,d5
 		lsl.w	#5,d5
 		move.w	d5,d6
 		and.w	#$3FFF,d5
 		or.w	#$4000,d5
 		lsr.w	#8,d6
 		lsr.w	#6,d6
 		and.w	#%11,d6
 		or.w	#$80,d6
 		move.w	d6,-(sp)
 		move.w	d5,-(sp)	
 		move.w	(sp)+,(vdp_ctrl)
 		move.w	#$100,($A11100).l
@hold_on:
 		btst	#0,($A11100).l
  		bne.s	@hold_on
  		
 		move.w	(sp)+,(vdp_ctrl)
  		move.w	#0,($A11100).l
   		
 		dbf	d4,@NextEntry
 		
@FinishList:
		clr.w	(RAM_DMA_Buffer)
 		rts

@ResetAllList:
		rts
		
; -----------------------------------
; Set new entry to the list
; 
; Input:
; d0 - ROM Address
; d1 - Size
; d2 - VRAM
; 
; Uses:
; a2/d3
; -----------------------------------

DMA_Set:
		lea	(RAM_DMA_Buffer),a2
		cmp.w	#64,(a2)
		bge.s	@Return
		move.w	(a2),d3
		lsl.w	#3,d3			;Size: 8
		adda 	d3,a2
		adda	#2,a2
		
		move.l	d0,(a2)+		;ROM Address
		move.w	d1,(a2)+
		move.w	d2,(a2)+
		add.w	#1,(RAM_DMA_Buffer)
@Return:
		rts
		
; ====================================================================
; ---------------------------------------------
; Sprites system
; ---------------------------------------------

; ---------------------------------------------
; Sprites_Reset
; ---------------------------------------------

Sprites_Clear:
;  		lea	(RAM_Sprites),a6
;  		move.w	#$4F,d6
; @clrit:
  		clr.l	(RAM_Sprites)
  		clr.l	(RAM_Sprites+4)
		rts
		
; ---------------------------------------------
; Sprites_Reset
; ---------------------------------------------

Sprites_Reset:
		lea	(RAM_SprControl),a6
		movea.l	sprite_free(a6),a5
		cmpa	#((RAM_Sprites)&$FFFF),a5
		blt.s	@Full
@NextEntry:
 		cmpa	#((RAM_Sprites+$280)&$FFFF),a5
 		bgt.s	@Full
 		clr.l	(a5)+
  		clr.l	(a5)+
  		cmpa	#((RAM_Sprites+$280)&$FFFF),a5
  		blt.s	@NextEntry
@Full:
		move.l	#RAM_Sprites,sprite_free(a6)
		move.w	#1,sprite_link(a6)
@Return:
		rts
