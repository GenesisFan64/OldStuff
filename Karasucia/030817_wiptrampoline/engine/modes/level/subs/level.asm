; ====================================================================
; ---------------------------------------------
; Level system
; ---------------------------------------------

; *** NOTES ***
; MAX Prize size: $7FFF

; --------------------------------------------
; Variables
; --------------------------------------------

		rsreset
lvl_objects	rs.l 1
lvl_blocks	rs.l 1
lvl_przblocks	rs.l 1
lvl_layout	rs.l 1
lvl_hilayout	rs.l 1
lvl_collision	rs.l 1
lvl_prizes	rs.l 1
lvl_x		rs.l 1
lvl_y		rs.l 1
lvl_x_camspd	rs.l 1
lvl_y_camspd	rs.l 1
lvl_timer	rs.l 1
lvl_size_x	rs.w 1
lvl_size_y	rs.w 1
lvl_maxcam_x	rs.w 1
lvl_maxcam_y	rs.w 1
lvl_camflags	rs.w 1
lvl_flags	rs.w 1
lvl_type	rs.w 1
lvl_lastx	rs.w 1
lvl_lasty	rs.w 1
sizeof_lvlpln	rs.l 0

; --------------------------------------------

max_lvlobj	equ	70

bitLvlDirR	equ	0
bitLvlDirL	equ	1
bitLvlDirD	equ	2
bitLvlDirU	equ	3
bitLvlDontUpd	equ	4

; RAM_LevelPrizes	equ	$FF0000

; --------------------------------------------
; RAM
; --------------------------------------------

		rsset RAM_Level
RAM_LvlPlanes	rs.b sizeof_lvlpln
RAM_LevelObjPos	rs.w (max_lvlobj)*5
RAM_LvlAnim	rs.w 16
RAM_PrizeHide	rs.w 1+(2*16)
RAM_PrizeShow	rs.w 1+(2*16)
RAM_PrizeUsed	rs.w 1+(2*16)

sizeof_lvl2	rs.l 0
;    		inform 0,"Level system uses: %h",(sizeof_lvl2-RAM_Level)
		
; ====================================================================	
; --------------------------------------------
; Init
; --------------------------------------------

Level_Init:
		clr.w	(RAM_P1_Coins)
		tst.w	(RAM_P1_Lives)
		bne.s	@firsttime
		move.w	#3,(RAM_P1_Lives)
@firsttime:
  		move.b	#%11,(RAM_VidRegs+$B)		; H: line V: full
;      		move.b	#%10000111,(RAM_VidRegs+$C)	; H40 + Double interlace
  		move.b	#1,(RAM_VidRegs+$10)		; 512x256 layer size
  		bsr	Video_Update
 		
		lea	(Art_LvlPrizes),a0
		move.l	#$70000002,(vdp_ctrl)
		move.w	#((Art_LvlPrizes_e-Art_LvlPrizes)/4)-1,d0
@doprzart:
		move.l	(a0)+,(vdp_data)
		dbf	d0,@doprzart
		
; 		move.w	#-1,(RAM_LvlPlanes+lvl_lastx)b
; 		move.w	#-1,(RAM_LvlPlanes+lvl_lasty)		
		rts
		
; ====================================================================		
; --------------------------------------------
; Loop
; --------------------------------------------

Level_Run:
		lea	(RAM_LvlPlanes),a6
		
 		bsr	Lvl_RefreshObj
		bsr	Lvl_DrawScrl
		bsr	Lvl_Animation
		bra	Lvl_Deform
		
; -----------------------------------
 
Level_BlockUpd:
		lea	(RAM_LvlPlanes),a6
		lea	(RAM_PrizeHide),a5
		move.w	(a5),d6
		clr.w	(a5)+
		tst.w	d6
		beq.s	@skip_hide
		sub.w	#1,d6
@next_hide:
		move.l	(a5),d0
 		bsr	Lvl_DoHidePrz
 		clr.l	(a5)+
 		dbf	d6,@next_hide
@skip_hide:

		lea	(RAM_PrizeShow),a5
		move.w	(a5),d6
		clr.w	(a5)+
		tst.w	d6
		beq.s	@skip_show
		sub.w	#1,d6
@next_show:
		move.l	(a5),d0
 		bsr	Lvl_DoShowPrz
 		clr.l	(a5)+
 		dbf	d6,@next_show
@skip_show:
		
		rts
		
; ====================================================================
; --------------------------------------------
; Subs
; --------------------------------------------

Lvl_DrawScrl:

; -----------------------------------
; RIGHT
; -----------------------------------

		move.w	lvl_lastx(a6),d0
		move.w	lvl_x(a6),d1
		cmp.w	d0,d1
		beq	@dontupdL
		move.w	d1,lvl_lastx(a6)
		
		btst	#bitLvlDirR,lvl_flags(a6)
		beq	@dontupdR
		bclr	#bitLvlDirR,lvl_flags(a6)
		move.w	#$4000,d0
		movea.l	lvl_layout(a6),a5
		movea.l lvl_hilayout(a6),a4
		movea.l	lvl_prizes(a6),a3
		
		move.w	lvl_y(a6),d4
		move.w	d4,d2
		lsr.w	#4,d2
		mulu.w	lvl_size_x(a6),d2
 		adda	d2,a5
 		adda 	d2,a4
 		adda	d2,a3
 		
 		move.w	d4,d3
		move.w	lvl_x(a6),d4		; VDP XPOS
		add.w	#$150,d4
		move.w	d4,d1
		lsr.w	#4,d1
 		adda	d1,a5
 		adda 	d1,a4
 		adda	d1,a3

		lsr.w	#2,d4
		and.w	#$7C,d4
		lsl.w	#4,d3			; VDP YPOS
		and.w	#$F00,d3
		add.w	d3,d4
		or.w	d0,d4
		swap	d4
 		move.w	#3,d4
 		
 		move.w	#$F,d3
;   		move.l	#$00010001,d1
@nextblkR:
		moveq	#0,d0
		movea.l	lvl_blocks(a6),a2
		move.b	(a3),d0
 		tst.b	d0
 		beq.s	@noPrzR
 		btst	#7,d0
 		bne.s	@noPrzR
 		and.w	#$7F,d0
		movea.l	lvl_przblocks(a6),a2
		bra.s	@hasprzR
@noPrzR:
		move.b	(a5),d0
		tst.b 	(a4)
		beq.s 	@hasprzR
		move.b 	(a4),d0
@hasprzR:
		
		lsl.w	#3,d0
		move.w	2(a2,d0.w),d1
		swap	d1
		move.w	(a2,d0.w),d1
 		move.w	6(a2,d0.w),d2
 		swap	d2
 		move.w	4(a2,d0.w),d2

 		move.l	d4,(vdp_ctrl)
 		add.l	#$00800000,d4
  		and.l	#$4FFE0003,d4
  		
  		swap	d3
 		move.b	(RAM_VidRegs+$C),d3
 		and.w	#%110,d3
 		beq.s	@dontShftV_R
 		lsr.w	#1,d1
 		lsr.w	#1,d2
@dontShftV_R:
		swap	d3
		tst.b 	(a4)
		beq.s 	@nohiprioR
		or.w 	#$8000,d1
		or.w 	#$8000,d2
@nohiprioR:
 		move.w	d1,(vdp_data)
 		move.w	d2,(vdp_data)
 		
 		move.b	(RAM_VidRegs+$C),d1
 		and.w	#%110,d1
 		bne.s	@dontupdR_2
 		
 		swap	d1
 		swap	d2
 		move.l	d4,(vdp_ctrl)
 		add.l	#$00800000,d4
  		and.l	#$4FFE0003,d4
  		tst.b 	(a4)
		beq.s 	@nohiprioR_2
		or.w 	#$8000,d1
		or.w 	#$8000,d2
@nohiprioR_2:
 		move.w	d1,(vdp_data)
 		move.w	d2,(vdp_data)
 		
@dontupdR_2:
 		add.w	lvl_size_x(a6),a5
 		add.w 	lvl_size_x(a6),a4
 		add.w	lvl_size_x(a6),a3
		dbf	d3,@nextblkR
@dontupdR:
	
; -----------------------------------
; LEFT
; -----------------------------------

		btst	#bitLvlDirL,lvl_flags(a6)
		beq	@dontupdL
		bclr	#bitLvlDirL,lvl_flags(a6)
		move.w	#$4000,d0
		movea.l	lvl_layout(a6),a5
		movea.l lvl_hilayout(a6),a4
		movea.l	lvl_prizes(a6),a3
		
		move.w	lvl_y(a6),d4
		move.w	d4,d2
		lsr.w	#4,d2
		mulu.w	lvl_size_x(a6),d2
 		adda	d2,a5
 		adda	d2,a4
 		adda	d2,a3
 		move.w	d4,d3
 		
		move.w	lvl_x(a6),d4		; VDP XPOS
     		sub.w	#$010,d4		; TODO CHECAR SI FUNCIONA BIEN
		move.w	d4,d1
		lsr.w	#4,d1
 		adda	d1,a5
 		adda	d1,a4
 		adda	d1,a3
 		
		lsr.w	#2,d4
		and.w	#$7C,d4
		lsl.w	#4,d3			; VDP YPOS
		and.w	#$F00,d3
		add.w	d3,d4
		or.w	d0,d4
		swap	d4
 		move.w	#3,d4
 		
 		move.w	#$F,d3
;  		move.l	#$00010001,d1
@nextblkL:
		moveq	#0,d0
		movea.l	lvl_blocks(a6),a2
		move.b	(a3),d0
 		tst.b	d0
 		beq.s	@noPrzL
 		btst	#7,d0
 		bne.s	@noPrzL
 		and.w	#$7F,d0
		movea.l	lvl_przblocks(a6),a2
		bra.s	@hasprzL
@noPrzL:
		move.b	(a5),d0
		tst.b 	(a4)
		beq.s 	@hasprzL
		move.b 	(a4),d0
@hasprzL:
		lsl.w	#3,d0
		move.w	2(a2,d0.w),d1
		swap	d1
		move.w	(a2,d0.w),d1
 		move.w	6(a2,d0.w),d2
 		swap	d2
 		move.w	4(a2,d0.w),d2

 		move.l	d4,(vdp_ctrl)
 		add.l	#$00800000,d4
  		and.l	#$4FFE0003,d4
  		
  		swap	d3
 		move.b	(RAM_VidRegs+$C),d3
 		and.w	#%110,d3
 		beq.s	@dontShftV_L
 		lsr.w	#1,d1
 		lsr.w	#1,d2
@dontShftV_L:
		swap	d3
		tst.b 	(a4)
		beq.s 	@nohiprioL
		or.w	#$8000,d1
		or.w 	#$8000,d2
@nohiprioL:
 		move.w	d1,(vdp_data)
 		move.w	d2,(vdp_data)
 		
 		move.b	(RAM_VidRegs+$C),d1
 		and.w	#%110,d1
 		bne.s	@dontupdL_2
 		
 		swap	d1
 		swap	d2
 		move.l	d4,(vdp_ctrl)
 		add.l	#$00800000,d4
  		and.l	#$4FFE0003,d4
		tst.b 	(a4)
		beq.s 	@nohiprioL_2
		or.w	#$8000,d1
		or.w 	#$8000,d2
@nohiprioL_2:
 		move.w	d1,(vdp_data)
 		move.w	d2,(vdp_data)
 		
@dontupdL_2:
 		add.w	lvl_size_x(a6),a5
 		add.w	lvl_size_x(a6),a4
 		add.w	lvl_size_x(a6),a3
		dbf	d3,@nextblkL
@dontupdL:

; -----------------------------------
; DOWN
; -----------------------------------

		move.w	lvl_lasty(a6),d0
		move.w	lvl_y(a6),d1
		cmp.w	d0,d1
		beq	@dontupdU
		move.w	d1,lvl_lasty(a6)
		
		btst	#bitLvlDirD,lvl_flags(a6)
		beq	@dontupdD
		bclr	#bitLvlDirD,lvl_flags(a6)
			
		movea.l	lvl_layout(a6),a5
		movea.l lvl_hilayout(a6),a4
		movea.l	lvl_prizes(a6),a3

		move.w	lvl_y(a6),d4
		move.w	#$4000,d0
		add.w	#$0E0,d4
		move.w	d4,d2
		lsr.w	#4,d2
		mulu.w	lvl_size_x(a6),d2
 		adda	d2,a5
 		adda	d2,a4
 		adda	d2,a3
 		move.w	d4,d3

		move.w	lvl_x(a6),d4		; VDP XPOS
		move.w	d4,d2
		move.w	d4,d1
		lsr.w	#4,d1
 		adda	d1,a5
 		adda 	d1,a4
 		adda	d1,a3
		lsr.w	#2,d4
		and.w	#$7C,d4
		lsl.w	#4,d3			; VDP YPOS
		and.w	#$F00,d3
		or.w	d3,d4
		or.w	d0,d4
		swap	d4
 		move.w	#3,d4

 		move.w	#$15,d3
;  		move.l	#$00010001,d1
 		move.l	d4,d5
 		and.l	#$4F800003,d5
 		and.l	#$007E0000,d4
@nextblkD:

		moveq	#0,d0
		movea.l	lvl_blocks(a6),a2
		move.b	(a3),d0
		tst.b	d0
		beq.s	@noPrzD
		btst	#7,d0
		bne	@noPrzD
		and.w	#$7F,d0
		movea.l	lvl_przblocks(a6),a2
		bra.s	@hasprzD
@noPrzD:
		move.b	(a5),d0
		tst.b 	(a4)
		beq.s 	@hasprzD
		move.b 	(a4),d0
@hasprzD:


; 		moveq	#0,d0
; 		movea.l	lvl_przblocks(a6),a2
; 		move.b	(a3),d0
; 		tst.b	d0
; 		bne.s	@hasprzD
; 		movea.l	lvl_blocks(a6),a2
; 		move.b	(a5),d0
; 		tst.b 	(a4)
; 		beq.s 	@hasprzD
; 		move.b	(a4),d0
; @hasprzD:
		lsl.w	#3,d0
		
		move.w	(a2,d0.w),d1
		swap	d1
		move.w	4(a2,d0.w),d1
 		move.w	2(a2,d0.w),d2
 		swap	d2
 		move.w	6(a2,d0.w),d2
 		
		or.l	d5,d4
 		move.l	d4,(vdp_ctrl)
 		
*  		move.b	(RAM_VidRegs+$C),d2
*  		and.w	#%110,d2
*  		beq.s	@dontshftD
*  		swap 	d1
*  		move.w	d1,d2
*  		and.w	#$7FF,d2
*  		and.w	#$F800,d1
*  		lsr.w	#1,d2
*  		or.w	d2,d1
*  		swap 	d1
*  		move.w	d1,d2
*  		and.w	#$7FF,d2
*  		and.w	#$F800,d1
*  		lsr.w	#1,d2
*  		or.w	d2,d1
*  		
* @dontshftD:
 		
  		tst.b 	(a4)
 		beq.s	@nohiprioD
 		or.l	#$80008000,d1
@nohiprioD:
 		move.l	d1,(vdp_data)

*   		move.b	(RAM_VidRegs+$C),d0
*  		and.w	#%110,d0
*  		bne.s	@dontshftD_2
 		
  		move.l	d5,d0
		or.l	d4,d0
  		add.l	#$00800000,d0
  		move.l	d0,(vdp_ctrl)
  		tst.b 	(a4)
 		beq.s	@nohiprioD_2
 		or.l	#$80008000,d2
@nohiprioD_2:
 		move.l	d2,(vdp_data)
 		
@dontshftD_2:
 		add.l	#$040000,d4
  		and.l	#$7E0000,d4
  		
 		add.w	#1,a5
 		add.w	#1,a4
 		add.w	#1,a3
		dbf	d3,@nextblkD
@dontupdD:

; -----------------------------------
; UP
; -----------------------------------

		btst	#bitLvlDirU,lvl_flags(a6)
		beq	@dontupdU
		bclr	#bitLvlDirU,lvl_flags(a6)
		movea.l	lvl_layout(a6),a5
		movea.l lvl_hilayout(a6),a4
		movea.l	lvl_prizes(a6),a3

		move.w	#$4000,d0
		move.w	lvl_y(a6),d4
		move.w	d4,d1
		swap	d1
		move.w	d4,d2
		lsr.w	#4,d2
		mulu.w	lvl_size_x(a6),d2
 		adda	d2,a5
 		adda 	d2,a4
 		adda	d2,a3
 		move.w	d4,d3
 		
		move.w	lvl_x(a6),d4		; VDP XPOS
		move.w	d4,d2
		move.w	d4,d1
		lsr.w	#4,d1
 		adda	d1,a5
 		adda 	d1,a4
 		adda	d1,a3
		lsr.w	#2,d4
		and.w	#$7C,d4
		lsl.w	#4,d3			; VDP YPOS
		and.w	#$F00,d3
		or.w	d3,d4
		or.w	d0,d4
		swap	d4
 		move.w	#3,d4
 		
 		swap	d1
 		move.w	d1,d2
 		move.w	#$15,d3
;  		move.l	#$00010001,d1
 		move.l	d4,d5
 		and.l	#$4F800003,d5
 		and.l	#$007E0000,d4
@nextblkU:
		moveq	#0,d0
		movea.l	lvl_blocks(a6),a2
		move.b	(a3),d0
		tst.b	d0
		beq.s	@noPrzU
		btst	#7,d0
		bne	@noPrzU
		and.w	#$7F,d0
		movea.l	lvl_przblocks(a6),a2
		bra.s	@hasprzU
@noPrzU:
		move.b	(a5),d0
		tst.b 	(a4)
		beq.s 	@hasprzU
		move.b 	(a4),d0
@hasprzU:

; 		moveq	#0,d0
; 		movea.l	lvl_przblocks(a6),a2
; 		move.b	(a3),d0
; 		tst.b	d0
; 		bne.s	@hasprzU
; 		movea.l	lvl_blocks(a6),a2
; 		move.b	(a5),d0
; 		tst.b 	(a4)
; 		beq.s 	@hasprzU
; 		move.b 	(a4),d0
; @hasprzU:
		lsl.w	#3,d0
		
		move.w	(a2,d0.w),d1
		swap	d1
		move.w	4(a2,d0.w),d1
 		move.w	2(a2,d0.w),d2
 		swap	d2
 		move.w	6(a2,d0.w),d2
 		
		or.l	d5,d4
 		move.l	d4,(vdp_ctrl)
 		tst.b 	(a4)
 		beq.s	@nohiprioU
 		or.l	#$80008000,d1
@nohiprioU:
 		move.l	d1,(vdp_data)
  		move.l	d5,d0
		or.l	d4,d0
  		add.l	#$00800000,d0
 		move.l	d0,(vdp_ctrl)
 		tst.b 	(a4)
 		beq.s	@nohiprioU_2
 		or.l	#$80008000,d2
@nohiprioU_2:
 		move.l	d2,(vdp_data)
 		
@nohiprioU_3:
 		add.l	#$040000,d4
  		and.l	#$7E0000,d4
  		
 		add.w	#1,a5
 		add.w 	#1,a4
 		add.w	#1,a3
		dbf	d3,@nextblkU
@dontupdU:
		rts
	
; --------------------------------------------
; Lvl_Animation
; --------------------------------------------

Lvl_Animation
		lea	(RAM_LvlAnim),a5
; 		lea	(Art_AnimCoin),a4
		
		sub.w	#1,(a5)
		bpl	@pluswait
		move.w	#5,(a5)
		
		moveq	#0,d1
		moveq	#0,d2
		move.l	#Art_AnimCoin,d0
		move.w	2(a5),d1
		add.w	#1,d1
		cmp.w	#6,d1
		bne.s	@stay
		clr.w	d1
@stay:
		move.w	d1,2(a5)
		lsl.w	#8,d1
		add.l	d1,d0
		
		move.l	#$94009380,(vdp_ctrl)	; Size: $40

     		if MARS
		and.l	#$FFFFF,d0
 		elseif MCD
 		add.l	#2,d0
 		endif
 		
 		lsr.l	#1,d0
		move.l	d0,d1
		swap	d1
		and.w	#$FF,d1
		or.w	#$9700,d1
		move.w	d0,d2
		and.w	#$FF,d0
		or.w	#$9500,d0
		lsr.w	#8,d2
		and.w	#$FF,d2
		or.w	#$9600,d2
		swap	d2
		or.l	d2,d0
		move.l	d0,(vdp_ctrl)
		move.w	d1,(vdp_ctrl)
		
		;At: $380
		move.w	#$0002|$80,-(sp)
		move.w	#$7400,-(sp)
		move.w	(sp)+,(vdp_ctrl)
 		move.w	#$100,($A11100)
@WaitZ80:
 		btst	#0,($A11100)
  		bne.s	@WaitZ80
		move.w	(sp)+,(vdp_ctrl)
 		move.w	#0,($A11100).l
@pluswait:
		rts
		
; --------------------------------------------
; Lvl_Deform
; --------------------------------------------

Lvl_Deform:
		move.w	lvl_y(a6),d0
		move.w	d0,(RAM_ScrlVer)
		move.w	d0,d4
		asr.w	#4,d4
		move.w	d4,(RAM_ScrlVer+2)
		moveq	#0,d5
		lea	(RAM_ScrlHor),a0
		move.w	lvl_x(a6),d3
		neg.w	d3
		
; Sun
		moveq	#0,d0
		move.w	#(28)-1,d2
		sub.w	d4,d2
		bmi	@rest_fg
@lyr1:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt	@exit_now
		dbf	d2,@lyr1
		
; Clouds 1
		move.w	d3,d0
		asr.w	#4,d0
		move.w	#(28)-1,d2
		cmp.w	#28,d4
		blt.s	@lyr2
		sub.w	d4,d2
		bmi.s	@rest_fg
@lyr2:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt.s	@exit_now
		dbf	d2,@lyr2
		
; Clouds 2
		move.w	d3,d0
		asr.w	#5,d0
		move.w	#(32)-1,d2
; 		cmp.w	#28,d4
; 		blt.s	@lyr3
; 		sub.w	d4,d2
; 		bmi.s	@rest_fg
@lyr3:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt.s	@exit_now
		dbf	d2,@lyr3

; Mountains 1
		move.w	d3,d0
		asr.w	#4,d0
		move.w	#(37)-1,d2
@lyr4:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt.s	@exit_now
		dbf	d2,@lyr4

; Mountains 2
		move.w	d3,d0
		asr.w	#3,d0
		move.w	#(37)-1,d2
@lyr5:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt.s	@exit_now
		dbf	d2,@lyr5
		
; Mountains 2
		move.w	d3,d0
		asr.w	#2,d0
		move.w	#(48)-1,d2
@lyr6:
		move.w	d3,(a0)+
		move.w	d0,(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		bgt.s	@exit_now
		dbf	d2,@lyr6
		
; ----------------
; Rest of BG

@rest_fg:
		move.w	d3,(a0)+
		clr.w	(a0)+
		add.w	#1,d5
		cmp.w	#224,d5
		blt.s	@rest_fg

@exit_now:
		add.l	#1,lvl_timer(a6)
		rts
		
; 		lea	(RAM_ScrlHor),a0
; 		move.w	#224-1,d1
; @nxt_h:
; 		move.w	lvl_x(a6),d0
; 		neg.w	d0
; 		move.w	d0,(a0)+
; 		asr.w	#2,d0
; 		move.w	d0,(a0)+
; 		dbf	d1,@nxt_h
; 		
; 		move.w	lvl_y(a6),d0
; 		move.w	d0,(RAM_ScrlVer)
; 		asr.w	#2,d0
; 		move.w	d0,(RAM_ScrlVer+2)

; --------------------------------------------
; Level_Load
; 
; a0 | Data
; --------------------------------------------

Level_Load:
; 		lea	(Level_Test),a0
		lea	($FF0000),a1
		move.w	#(($8000)/4)-1,d0
@clrram:
		clr.l	(a1)+
		dbf	d0,@clrram
		
		lea	(RAM_LvlPlanes),a1
		clr.w	(RAM_PrizeHide)
		clr.w	(RAM_PrizeShow)
		clr.w	lvl_x(a1)
		clr.w	lvl_y(a1)
		move.l	#$FFFF0000,d4
		move.w	(a0)+,d0
		move.w	d0,lvl_size_x(a1)
		move.w	d0,lvl_maxcam_x(a1)
		move.w	(a0)+,d0
		move.w	d0,lvl_size_y(a1)
		move.w	d0,lvl_maxcam_y(a1)
		move.l	(a0)+,lvl_objects(a1)
@loop:
; 		tst.w	(a0)
; 		bmi.s	@exit
		
		move.l	(a0)+,lvl_blocks(a1)
		move.l	(a0)+,d0
		tst.l	d0
		bpl.s	@nullprz
		move.l	#vram_prizes,lvl_przblocks(a1)
@nullprz:
		move.l	(a0)+,lvl_layout(a1)
		move.l	(a0)+,lvl_hilayout(a1)
		
		move.l	(a0)+,lvl_collision(a1)
		move.l	d4,lvl_prizes(a1)
		movea.l	(a0)+,a2
		movea.l	d4,a3
@nextrle:
		moveq	#0,d0
		moveq	#0,d1
		move.b	(a2)+,d0
		cmp.b	#-1,d0
		beq.s	@Finish
		move.b	(a2)+,d1
		tst.w	d0
		beq.s	@oops
		sub.w	#1,d0
@CopyIt:
		move.b	d1,(a3)+
		add.l	#1,d4
		dbf	d0,@CopyIt
@oops:
		bra.s	@nextrle
@Finish:
; 		adda	#sizeof_lvlpln,a1
; 		bra.s	@loop
; @exit:
		
; ----------------------------------		
; Load object from the list
; ----------------------------------

		lea	(RAM_LevelObjPos),a3
		move.w	#max_lvlobj-1,d1
@clrlist:
		clr.l	(a3)+
		clr.l	(a3)+
		clr.w	(a3)+
		dbf	d1,@clrlist
		
		movea.l	(RAM_LvlPlanes+lvl_objects),a2
		lea	(RAM_LevelObjPos),a3
		move.w	#max_lvlobj-1,d1
@NextObj:
		tst.l	(a2)
		beq.s	@Nothing
 		move.l	(a2)+,d0
 		and.l 	#$FFFFFF,d0
 		move.l	d0,(a3)+
		move.l	(a2)+,(a3)+
		move.w	(a2)+,(a3)+
		dbf	d1,@NextObj
@Nothing:
		rts
		
; --------------------------------------------
; Draw the level on screen
; 
; Uses:
; d0-d5/a2-a5
; --------------------------------------------

Level_Draw:
		lea	(RAM_LvlPlanes),a5
		move.l	#$40000003,d0		; VDP Address
  		move.w	lvl_x(a5),d1		; X pos
  		move.w	lvl_y(a5),d2		; Y pos
   		lsr.w	#4,d2			; Ypos: xxx0 > 0xxx
   		and.w	#$F,d2			; 0xxx > 00xx
   		lsl.w	#8,d2			; 00xx > xx00
   		and.w	#$3FFF,d2
   		lsr.w	#4,d1			; Xpos: xxx0 > 0xxx
    		lsl.w	#2,d1			; 0xxx * 2
    		swap	d0
   		add.w	d2,d0			; +Y VDP
  		add.b	d1,d0			; +X VDP
       		and.b	#$7F,d0
      		swap	d0
		
		move.w	lvl_y(a5),d4
		lsr.w	#4,d4
		mulu.w	lvl_size_x(a5),d4
		move.w	lvl_x(a5),d5
		lsr.w	#4,d5
		add.w	d4,d5
		and.w	#$7FFF,d5
		swap 	d5
		
		move.w	#$16,d5
@do_row:
 		movea.l	lvl_layout(a5),a4
 		movea.l	lvl_hilayout(a5),a3
 		movea.l	lvl_prizes(a5),a2
 		swap	d5
 		adda 	d5,a4
 		adda 	d5,a3
 		adda	d5,a2
 		swap 	d5
 		
		move.l	d0,d3
 		moveq	#$F,d4
;  		move.b	(RAM_VidRegs+$C),d2
;   		and.w	#%110,d2
;   		beq.s	@block
;   		moveq	#$1F,d4
;  
@block:
		movea.l	lvl_przblocks(a5),a1
 		moveq	#0,d2	
 		move.b	(a2),d2
 		tst.b	d2
 		beq.s	@noprzblk
 		btst	#7,d2
 		beq.s	@hasPrzDrw
@noprzblk:
  		move.b	(a4),d2
   		movea.l	lvl_blocks(a5),a1
 		tst.b	(a3)
 		beq.s	@hasprzDrw
 		move.b	(a3),d2
@hasprzDrw:
		lsl.w	#3,d2
		move.w	(a1,d2.w),d1
 		swap	d1
 		move.w	4(a1,d2.w),d1
 		
 		swap	d4
 		move.b	(RAM_VidRegs+$C),d4
 		and.w	#%110,d4
 		beq.s	@NoDouble
 		lsr.w	#1,d1
 		swap	d1
 		lsr.w	#1,d1
 		swap	d1
@NoDouble:
		swap	d4
 		move.l	d3,(vdp_ctrl)
 		tst.b	(a3)
 		beq.s	@nohiprio
 		or.l 	#$80008000,d1
@nohiprio:
 		move.l	d1,(vdp_data)
 		add.l	#$00800000,d3
  		
 		move.b	(RAM_VidRegs+$C),d1
 		and.w	#%110,d1
 		bne.s	@NoDouble2
		move.w	2(a1,d2.w),d1
 		swap	d1
 		move.w	6(a1,d2.w),d1
		move.l	d3,(vdp_ctrl)
 		tst.b	(a3)
 		beq.s	@nohiprio2
 		or.l 	#$80008000,d1
@nohiprio2:
 		move.l	d1,(vdp_data)
 		add.l	#$00800000,d3
 		and.l	#$4F7C0003,d3
@NoDouble2:		
		move.w	lvl_size_x(a5),d1
		adda	d1,a4
		adda	d1,a3
		adda	d1,a2
		dbf	d4,@block
	
		add.l	#$40000,d0
		and.l	#$4F7C0003,d0
		swap 	d5
		add.w	#1,d5
		swap 	d5
		dbf	d5,@do_row

; ----------------------------------
; Check for objects ON the
; same screen as the player
; ----------------------------------

		lea	(RAM_LevelObjPos),a5
		lea	(RAM_ObjBuffer+(sizeof_obj*16)),a4	;Start of level objects
		moveq	#1,d3			; Starting at 1
@next_obj:
		tst.l	(a5)
		beq	@finish
 		btst	#7,(a5)			;ON SCREEN flag?
 		bne	@next
@found_obj:
  		moveq	#(max_objects-8)-1,d4
@nxtav_obj:
		tst.l	obj_code(a4)	
		beq.s	@valid
		adda	#sizeof_obj,a4
		dbf	d4,@nxtav_obj
		
@valid:
		move.w	4(a5),obj_x(a4)
		move.w	6(a5),obj_y(a4)
		move.b	d3,obj_spwnindx(a4)
		
   		moveq	#0,d1
    		move.b	8(a5),d1
    		clr.b	obj_status(a4)
    		btst	#7,d1
    		beq.s	@dont_flip_l
  		bset	#bitobj_flipH,obj_status(a4)
@dont_flip_l:
    		btst	#6,d1
    		beq.s	@dont_flip_d
  		bset	#bitobj_flipV,obj_status(a4)
@dont_flip_d:
 		move.b	8(a5),d1
 		and.w	#$3F,d1
		move.b	d1,obj_subid(a4)
 		move.l	(a5),d0
  		and.l 	#$FFFFFF,d0
 		move.l	d0,obj_code(a4)
 		bset	#7,(a5)			;SET ON SCREEN flag
		adda	#sizeof_obj,a4
@next:
		add.w	#1,d3
		adda	#$A,a5
		bra	@next_obj
@finish:
     		rts
		
; ----------------------------------		

Level_HidePrize:
		lea	(RAM_PrizeHide+2),a4
		move.w	(RAM_PrizeHide),d4
		lsl.w	#2,d4
		adda	d4,a4
; @chknext:
; 		tst.l	(a4)
; 		beq.s	@free
; 		adda	#4,a4
; 		bra.s	@chknext
; @free:
		move.l	d0,(a4)
		add.w	#1,(RAM_PrizeHide)
@same:
		rts
		
; ----------------------------------

Level_ShowPrize:
		lea	(RAM_PrizeShow+2),a4
		move.w	(RAM_PrizeShow),d4
		lsl.w	#2,d4
		adda	d4,a4
; @chknext:
; 		tst.l	(a4)
; 		beq.s	@free
; 		adda	#4,a4
; 		bra.s	@chknext
; @free:
		move.l	d0,(a4)
		add.w	#1,(RAM_PrizeShow)
@same:
		rts

; ----------------------------------

; Level_CheckPrize:
;  		moveq	#0,d4
;  		lea	(RAM_PrizeHide),a3
;  		move.w	(a3)+,d5
;  		tst.w	d5
;  		beq.s	@free
; 		sub.w	#1,d5
; @chknext:
;  		cmp.l	(a3)+,d0
;  		beq.s	@found
;  		dbf	d5,@chknext
;  		bra.s	@free
; 
; @found:
;  nop
; ;  		bra.s * ;moveq	#-1,d4
;  		
; @free:
;  		tst.l	d4
; 		rts
		
; ----------------------------------		
; load level objects while moving
; ----------------------------------

Lvl_RefreshObj:
		lea	(RAM_LevelObjPos),a5
		lea	(RAM_ObjBuffer+(sizeof_obj*16)),a4
		moveq	#1,d3			; Starting at 1
@next_obj:
		tst.l	(a5)
		beq	@finish
		btst	#6,(a5)			; GONE flag?
		bne	@next
 		btst	#7,(a5)			; ON SCREEN flag?
 		bne	@next
		
		swap	d3

   		move.w	lvl_x(a6),d0
       		move.w	4(a5),d1
    		move.w	d0,d2
    		add.w	#320,d2
    		
   		add.w	#$38,d2
     		cmp.w	d2,d1
      		bgt	@tooright  		
   		sub.w	#$8,d2
     		cmp.w	d2,d1
      		blt	@tooright
      		move.w	#1,d3
@tooright:
   		sub.w	#$38,d0
      		cmp.w	d0,d1
       		blt	@tooleft
   		add.w	#$8,d0
     		cmp.w	d0,d1
      		bge	@tooleft
      		move.w	#1,d3
@tooleft:

		
    		move.w	lvl_y(a6),d0
       		move.w	6(a5),d1
     		move.w	d0,d2
    		add.w	#224,d2
		
   		add.w	#$58,d2
     		cmp.w	d2,d1
      		bge	@toodown 		
   		sub.w	#$8,d2
     		cmp.w	d2,d1
      		blt	@toodown
      		move.w	#1,d3
@toodown:
   		sub.w	#$58,d0
      		cmp.w	d0,d1
       		blt	@tooup
   		add.w	#$8,d0
     		cmp.w	d0,d1
      		bge	@tooup
      		move.w	#1,d3
@tooup:


		move.w	d3,d0
		swap	d3
		tst.w	d0
		beq.s	@next
  		
@found_obj:
  		moveq	#(max_objects-16)-1,d4
@nxtav_obj:
		tst.l	obj_code(a4)
		beq.s	@valid
		cmp.b	obj_spwnindx(a4),d3
		beq.s	@next
		adda	#sizeof_obj,a4
		dbf	d4,@nxtav_obj
		bra.s	@next
		
@valid:
		movea.l	a4,a3
		move.w	#sizeof_obj,d1
@cleanup:
		clr.b	(a3)+
		dbf	d1,@cleanup
		
		move.w	4(a5),obj_x(a4)
		move.w	6(a5),obj_y(a4)
		move.b	d3,obj_spwnindx(a4)
		
   		moveq	#0,d1
    		move.b	8(a5),d1
    		clr.b	obj_status(a4)
    		btst	#7,d1
    		beq.s	@dont_flip_l
  		bset	#bitobj_flipH,obj_status(a4)

@dont_flip_l:
    		btst	#6,d1
    		beq.s	@dont_flip_d
  		bset	#bitobj_flipV,obj_status(a4)
@dont_flip_d:
 		move.b	8(a5),d1
 		and.w	#$3F,d1
		move.b	d1,obj_subid(a4)
 		move.l	(a5),d0
  		and.l 	#$FFFFFF,d0
 		move.l	d0,obj_code(a4)
 		bset	#7,(a5)			;SET ON SCREEN flag
		adda	#sizeof_obj,a4
@next:
		add.w	#1,d3
		adda	#$A,a5
		bra	@next_obj
@finish:
		rts
 	
; ----------------------------------
; d0 - ID
; ----------------------------------

Lvl_DoHidePrz:
		;TODO: Up/Left checks
		move.l	d0,d4
		lsr.l	#4,d4
		and.w	#$FFF0,d4
 		move.w	lvl_y(a6),d5
 		cmp.w	d5,d4
 		blt.s	LvlPrzReadRet
		move.l	d0,d4
		swap	d4
		and.w	#$FFF0,d4
 		move.w	lvl_x(a6),d5
 		cmp.w	d5,d4
 		blt.s	LvlPrzReadRet
 		
 		move.l	d0,d4			;Postion | XXX?????
 		swap	d4			;????XXX?
 		lsr.w	#2,d4			;????0XXX
 		and.l	#$7C,d4
 		move.l	d0,d5			;???YYY??
  		and.w	#$F00,d5
   		add.w	d5,d4
 		move.l	#$40000003,d5
 		swap	d5
 		or.w	d4,d5
 		swap	d5
 		
  		movea.l	lvl_layout(a6),a4	;Layout data
 		move.l	d0,d4
 		and.l	#$000FFF00,d4
 		lsr.l	#8,d4
 		and.l	#$FFF,d4
 		mulu.w	lvl_size_x(a6),d4
 		adda	d4,a4	
  		move.l	d0,d4
 		and.l	#$FFF00000,d4
  		swap	d4
  		lsr.w	#4,d4
   		add.w 	d4,a4
    		moveq	#0,d4
   		move.b	(a4),d4
		movea.l	lvl_blocks(a6),a4	;Draw blocks
		bra.s	LvlPrzReadBlk
LvlPrzReadRet:
		rts
		
; ----------------------------------
; d0 - ID
; ----------------------------------

Lvl_DoShowPrz:
		;TODO: Up/Left checks
		move.l	d0,d4
		lsr.l	#4,d4
		and.w	#$FFF0,d4
 		move.w	lvl_y(a6),d5
 		cmp.w	d5,d4
 		blt.s	LvlPrzReadRet
		move.l	d0,d4
		swap	d4
		and.w	#$FFF0,d4
 		move.w	lvl_x(a6),d5
 		cmp.w	d5,d4
 		blt.s	LvlPrzReadRet
 		
 		move.l	d0,d4			;Postion | XXX?????
 		swap	d4			;????XXX?
 		lsr.w	#2,d4			;????0XXX
 		and.l	#$7C,d4
 		move.l	d0,d5			;???YYY??
  		and.l	#$F00,d5
   		or.w	d5,d4
 		move.l	#$40000003,d5
 		swap	d5
 		or.w	d4,d5
 		swap	d5 		
  		movea.l	lvl_prizes(a6),a4	;Layout data
 		move.l	d0,d4
 		and.l	#$000FFF00,d4
 		lsr.l	#8,d4
 		and.l	#$FFF,d4
 		mulu.w	lvl_size_x(a6),d4
;  		lsl.w	#1,d4
 		adda	d4,a4	
  		move.l	d0,d4
 		and.l	#$FFF00000,d4
  		swap	d4
  		lsr.w	#4,d4
;    		lsl.w	#1,d4
   		add.w	d4,a4
    		moveq	#0,d4
   		move.b	(a4),d4
		movea.l	lvl_przblocks(a6),a4	;Draw blocks
		
LvlPrzReadBlk:
  		lsl.l	#3,d4
  		and.l	#$FFFF,d4
   		adda 	d4,a4
   		
 		move.l	d5,(vdp_ctrl).l
 		move.w	(a4),d4
 		swap	d4
 		move.w	4(a4),d4
 		move.l	d4,(vdp_data).l
 		add.l	#$800000,d5
 		move.l	d5,(vdp_ctrl).l
 		move.w	2(a4),d4
 		swap	d4
 		move.w	6(a4),d4
 		move.l	d4,(vdp_data).l
@ignore:
 		rts	
		
; ----------------------------------		
; Load art data
; 
; a1 - the list
; ----------------------------------

Level_LoadArtList:
		tst.w	(a1)
		bmi.s	@Finish
		move.l	(a1)+,a0		;Addr
 		move.w	(a1)+,d0		;VRAM
 		move.w	(a1)+,d1		;Size
 		bsr	VDP_SendData_L
 		bra.s	Level_LoadArtList
 		
@Finish:
		rts
		
; =================================================================
; --------------------------------------------
; Data
; --------------------------------------------

vram_prizes:
		dc.l $0001,$0001		; $00 FILLER
		dc.w $580,$581,$582,$583	; $01 Breakable: normal
		dc.w $580,$581,$582,$583	; $02  **  **  : 1 coin
 		dc.w $580,$581,$582,$583	; $03  **  **  : 10 coins
		dc.w $580,$581,$582,$583	; $04  **  **  : ???
		dc.w $580,$581,$582,$583	; $05  **  **  : ???
		dc.w $580,$581,$582,$583	; $06  **  **  : ???
		dc.w $580,$581,$582,$583	; $07  **  **  : 1 up
		dc.w $584,$585,$586,$587	; $08 Block ! : 1 coin
		dc.w $584,$585,$586,$587	; $09  ****   : 10 coins
		dc.w $584,$585,$586,$587	; $0A  ****   : ???
		dc.w $584,$585,$586,$587	; $0B  ****   : ???
		dc.w $584,$585,$586,$587	; $0C  ****   : ???
		dc.w $584,$585,$586,$587	; $0D  ****   : ???
		dc.w $584,$585,$586,$587	; $0E  ****   : 1 up
		dc.w $59C,$59D,$59E,$59F	; $0F Empty block
		
		dc.w $4580,$4581,$4582,$4583	;$10+
		dc.w $4580,$4581,$4582,$4583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583	
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583

		dc.w $4594,$4595,$4596,$4597	;$20+ Bouncing block
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583	
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		
		dc.w $580,$581,$582,$583	;$30+
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583	
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		dc.w $580,$581,$582,$583
		
		dc.w $45A0,$45A1,$45A2,$45A3	;$40 - Coins
		dc.w $45A4,$45A5,$45A6,$45A7
		even

; --------------------------------------------

col_SlopeData:
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00	;$01
		dc.b $0F,$0E,$0D,$0C,$0B,$0A,$09,$08,$07,$06,$05,$04,$03,$02,$01,$00	;$02
		dc.b $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F	;$03
		
		dc.b $0F,$0F,$0E,$0E,$0D,$0D,$0C,$0C,$0B,$0B,$0A,$0A,$09,$09,$08,$08
		dc.b $07,$07,$06,$06,$05,$05,$04,$04,$03,$03,$02,$02,$01,$01,$00,$00
		
		dc.b $00,$00,$01,$01,$02,$02,$03,$03,$04,$04,$05,$05,$06,$06,$07,$07
		dc.b $08,$08,$09,$09,$0A,$0A,$0B,$0B,$0C,$0C,$0D,$0D,$0E,$0E,$0F,$0F
		
		dc.b $0F,$0F,$0F,$0F,$0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0C,$0C,$0C,$0C
		dc.b $0B,$0B,$0B,$0B,$0A,$0A,$0A,$0A,$09,$09,$09,$09,$08,$08,$08,$08
		dc.b $07,$07,$07,$07,$06,$06,$06,$06,$05,$05,$05,$05,$04,$04,$04,$04
		dc.b $03,$03,$03,$03,$02,$02,$02,$02,$01,$01,$01,$01,$00,$00,$00,$00
		
		dc.b $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
		dc.b $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06,$07,$07,$07,$07
		dc.b $08,$08,$08,$08,$09,$09,$09,$09,$0A,$0A,$0A,$0A,$0B,$0B,$0B,$0B
		dc.b $0C,$0C,$0C,$0C,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0F,$0F,$0F,$0F
		even
		
