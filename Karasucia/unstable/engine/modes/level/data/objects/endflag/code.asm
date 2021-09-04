; =================================================================
; Object
; 
; Level end flag
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varEndFlagVRAM	equ	$6000|$540

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

Obj_EndFlag:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jsr	@Index(pc,d1.w)
		
		lea	(RAM_ObjBuffer),a4
		move.w	obj_x(a6),d0
		sub.w	#320,d0
		move.w	obj_x(a4),d1
		cmp.w	d0,d1
		blt.s	@im_gone
		
    		move.l	#(varEndFlagVRAM<<16),d0
   		move.b	obj_frame(a6),d0	
 		move.l	#mapObj_EndFlag,d1
  		bsr	Object_Show
 		
   		move.l	#(varEndFlagVRAM<<16),d0
   		move.b	obj_frame(a6),d0
		move.l	#dplcObj_EndFlag,d1
		move.l	#artObj_EndFlag,d2
		bra	Object_DPLC
		
@im_gone:
		rts
		
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
		move.l	#$02020303,obj_size(a6)
		rts
		
; =================================================================
; ------------------------------------------------                  
; Index $01: Main
; ------------------------------------------------

@Main:
		sub.b	#1,obj_anim_spd(a6)
		bpl.s	@plus
		move.b	#6,obj_anim_spd(a6)
		add.b	#1,obj_frame(a6)
		cmp.b	#3,obj_frame(a6)
		blt.s	@plus
		clr.b	obj_frame(a6)
@plus:
		bsr	objTouch
		tst.b	d0
		beq.s	@return

;   		add.w	#1,(RAM_CurrLevel)
		clr.b	(RAM_GameMode)
		move.b	#1,(RAM_ModeReset)
@return:
		rts
		
; =================================================================
		
