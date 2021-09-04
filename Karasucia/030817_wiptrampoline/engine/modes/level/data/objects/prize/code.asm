; =================================================================
; Object
; 
; The prize
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

vramCoinRed	equ	$C000|$5A8
vramCoinBlue	equ	$C000|$5AC
vram1up		equ	$C000|$5B0
vramJmpBlock	equ	$C000|$594

; =================================================================
; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset obj_ram
this_pos	rs.l 1			; Block type and X/Y position
this_vram	rs.w 1			; Vram (top left)
this_counter	rs.w 1			; Counter (coins, etc.)

y_coin_spd	rs.l 1
y_pos_coin	rs.l 1
x_pos_main	rs.w 1
y_pos_main	rs.w 1
x_pos_l		rs.w 1
x_pos_r		rs.w 1
tmr_1		rs.w 1
block_flags	rs.b 1

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

obj_prize:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jmp	@Index(pc,d1.w)
 		
; ------------------------------------------------

@Index:
		dc.w	@Init-@Index
		dc.w	@Main-@Index
		even
		
; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

@Init:
		add.b	#1,obj_index(a6)
		move.l	this_pos(a6),d0
 		swap	d0
 		and.w	#$FFF0,d0
 		move.w	d0,obj_x(a6)
 		swap	d0
 		lsr.w	#4,d0
 		and.w	#$FFF0,d0
 		move.w	d0,obj_y(a6)

 		move.l	this_pos(a6),d0
		bsr	Level_HidePrize

 		move.l	#-$40000,obj_y_spd(a6)
 		tst.b	obj_subid(a6)
 		beq.s	@not_brick
 		move.l	#-$20000,obj_y_spd(a6)
@not_brick:
 		move.w	obj_x(a6),x_pos_main(a6)
 		move.w	obj_y(a6),d0
 		move.w	d0,y_pos_main(a6)
 		sub.w	#$10,d0
 		swap	d0
 		move.l	d0,y_pos_coin(a6)
 		
 		move.w	obj_x(a6),x_pos_l(a6)
 		move.w	obj_x(a6),x_pos_r(a6)
 		add.w	#8,x_pos_r(a6)
 		move.l	#-$40000,y_coin_spd(a6)
 		
 		move.l	#$01010101,obj_size(a6)
 		bset	#bitobj_hit,obj_status(a6)
 		
; =================================================================
; ------------------------------------------------                  
; Index $01: Main
; ------------------------------------------------

@Main:
		lea	(RAM_LvlPlanes),a5
 		moveq	#0,d0
 		move.b	obj_subid(a6),d0
 		and.b	#$7F,d0
 		add.w	d0,d0
 		move.w	@subtypes(pc,d0.w),d1
 		jmp	@subtypes(pc,d1.w)
		
; ------------------------------------------------
; Subs
; ------------------------------------------------

@subtypes:
		dc.w @destroy-@subtypes		; $00 - Breakable block
		dc.w @bump_solid-@subtypes	; $01 - Bump, normal
		dc.w @bump_coin-@subtypes	; $02 - Bump, add red coin (1)
		dc.w @bump_coin_blue-@subtypes	; $03 - Bump, add blue coin (2)
		dc.w @bump_1up-@subtypes	; $04 - Bump, add extra life
		dc.w @trampoline-@subtypes	; $05 - Trampoline animation
		
; ------------------------------------------------
; Return
; ------------------------------------------------

@return:
		rts
		
; ------------------------------------------------
; Destroy block
; ------------------------------------------------

@destroy:
		move.l	obj_y_spd(a6),d7
		
		move.l	#$0000,d1
		swap	d1
		move.w	this_vram(a6),d1
		or.w	#$8000,d1
		
		move.w	x_pos_r(a6),d3
		add.w	#1,x_pos_r(a6)
		swap	d3
		move.w	x_pos_l(a6),d2
		sub.w	#1,x_pos_l(a6)
		swap	d2
	
		move.l	d2,d0
		move.w	obj_y(a6),d0
		sub.l	#$60000,d0
		sub.w	#$10,d0
		bsr	Object_ExtSprite
		move.l	d3,d0
 		add.w	#2,d1
		move.w	obj_y(a6),d0
		add.l	#$40000,d0	
		sub.w	#$14,d0
		bsr	Object_ExtSprite
		move.l	d2,d0
 		sub.w	#1,d1
		move.w	obj_y(a6),d0
		sub.l	#$10000,d0
		bsr	Object_ExtSprite
		move.l	d3,d0
 		add.w	#2,d1
		move.w	obj_y(a6),d0
		add.l	#$30000,d0
		sub.w	#4,d0
		bsr	Object_ExtSprite
		
 		add.l	#$4000,d7
 		tst.l	d7
 		bmi.s	@minus
 		bclr	#bitobj_hit,obj_status(a6)
@minus:
		add.l	d7,obj_y(a6)
		
		move.w	obj_y(a6),d1
		move.w	#320,d0
		add.w	lvl_y(a5),d0
		cmp.w	d0,d1
		blt.s	@lower_y
		jmp	Object_Delete
@lower_y:
 		move.l	d7,obj_y_spd(a6)
    		rts
		
; ------------------------------------------------
; Bump, nothing (or reveral hidden block)
; ------------------------------------------------

@bump_solid:
		move.l	obj_y_spd(a6),d7
		move.l	y_coin_spd(a6),d6
		
; 		move.l	#$0005,d1
; 		swap	d1
; 		move.w	#vramCoinRed,d1
;  		move.l	y_pos_coin(a6),d0
;  		move.w	obj_x(a6),d0
;  		swap	d0
; 		bsr	Object_ExtSprite
		
 		btst	#0,block_flags(a6)
 		bne.s	@stopblock
		move.l	#$0005,d1
		swap	d1
		move.w	this_vram(a6),d1
		or.w	#$8000,d1
		
		move.w	obj_x(a6),d0
		swap	d0
		move.w	obj_y(a6),d0
		bsr	Object_ExtSprite
 		add.l	#$4000,d7
 		tst.l	d7
 		bmi.s	@minus2
 		bclr	#bitobj_hit,obj_status(a6)
@minus2:
		add.l	d7,obj_y(a6)
@stopblock:
 		add.l	#$4000,d6
		add.l	d6,y_pos_coin(a6)
		
		move.w	obj_y(a6),d0
		move.w	y_pos_main(a6),d1
		cmp.w	d1,d0
		ble.s	@return3
		
 		move.l	this_pos(a6),d0
		bsr	Prize_Locate
; 		move.b	#$F,d0
; 		move.b	d0,(a3)
 		bsr	Level_ShowPrize
 		bset	#0,block_flags(a6)
 		jmp	Object_Delete
 		
@return3:

; 		move.w	y_pos_coin(a6),d0
; 		move.w	y_pos_main(a6),d1
; 		sub.w	#$10,d1
; 		cmp.w	d1,d0
; 		ble.s	@return2
;   		jmp	Object_Delete
;   		
; @return2:
		move.l	d6,y_coin_spd(a6)
 		move.l	d7,obj_y_spd(a6)
 		rts
 		
; ------------------------------------------------
; Bump block
; ------------------------------------------------

@bump_1up:
		move.l	#$0005,d1
		swap	d1
		move.w	#vram1up,d1
 		move.l	y_pos_coin(a6),d0
 		move.w	obj_x(a6),d0
 		swap	d0
		bsr	Object_ExtSprite
		bra.s	@from_coin_blue
		
@bump_coin_blue:
		move.l	#$0005,d1
		swap	d1
		move.w	#vramCoinBlue,d1
 		move.l	y_pos_coin(a6),d0
 		move.w	obj_x(a6),d0
 		swap	d0
		bsr	Object_ExtSprite
		bra.s	@from_coin_blue
		
@bump_coin:
		move.l	#$0005,d1
		swap	d1
		move.w	#vramCoinRed,d1
 		move.l	y_pos_coin(a6),d0
 		move.w	obj_x(a6),d0
 		swap	d0
		bsr	Object_ExtSprite
		
@from_coin_blue:
		move.l	obj_y_spd(a6),d7
		move.l	y_coin_spd(a6),d6
		
 		btst	#0,block_flags(a6)
 		bne.s	@stopblock2
		move.l	#$0005,d1
		swap	d1
		move.w	this_vram(a6),d1
		or.w	#$8000,d1
		
		move.w	obj_x(a6),d0
		swap	d0
		move.w	obj_y(a6),d0
		bsr	Object_ExtSprite
 		add.l	#$4000,d7
 		tst.l	d7
 		bmi.s	@minus3
 		bclr	#bitobj_hit,obj_status(a6)
@minus3:
		add.l	d7,obj_y(a6)
@stopblock2:
 		add.l	#$4000,d6
		add.l	d6,y_pos_coin(a6)
		
		move.w	obj_y(a6),d0
		move.w	y_pos_main(a6),d1
		cmp.w	d1,d0
		ble.s	@return4
		
 		move.l	this_pos(a6),d0
		bsr	Prize_Locate
		move.b	#$F,d0
		move.b	d0,(a3)
 		bsr	Level_ShowPrize
 		bset	#0,block_flags(a6)
 		jmp	Object_Delete
 		
@return4:

		move.w	y_pos_coin(a6),d0
		move.w	y_pos_main(a6),d1
		sub.w	#$10,d1
		cmp.w	d1,d0
		ble.s	@return5
  		jmp	Object_Delete
  		
@return5:
		move.l	d6,y_coin_spd(a6)
 		move.l	d7,obj_y_spd(a6)
		rts
		
; ------------------------------------------------
; Trampoline
; ------------------------------------------------

@trampoline:
		add.b	#1,tmr_1(a6)
		cmp.b	#16,tmr_1(a6)
		bge.s	@finish
		
		move.l	#$0005,d1
		swap	d1
		move.w	#vramJmpBlock,d1
		move.b	tmr_1+1(a6),d0
		add.b	#1,d0
		and.w	#%10,d0
		lsl.w	#1,d0
		add.w	d0,d1
		add.b	#1,tmr_1+1(a6)
		
 		move.w	obj_x(a6),d0
 		swap	d0
 		move.w	obj_y(a6),d0
		bra	Object_ExtSprite
		
@finish:
 		move.l	this_pos(a6),d0
		bsr	Level_ShowPrize
  		jmp	Object_Delete
  		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------

		
; =================================================================
		
