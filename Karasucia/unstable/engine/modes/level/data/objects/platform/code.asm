; =================================================================
; Object
; 
; Platforms
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

varVramPlatfrm	equ	$2000|$530

; =================================================================
; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset obj_ram
last_x		rs.w	1
last_y		rs.w	1
tanvalue	rs.w	1

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

Obj_Platform:
 		moveq	#0,d0
 		move.b	obj_index(a6),d0
 		add.w	d0,d0
 		move.w	@Index(pc,d0.w),d1
 		jsr	@Index(pc,d1.w)
 		
 		;TODO: si hago este check se 
 		;desincronizan
;  		bsr	Object_OffCheck

;    		move.l	#(varVramPlatfrm<<16),d0
;  		move.l	#ani_chamoy,d1
; 		bsr	Object_Animate
 		move.l	#(varVramPlatfrm<<16),d0
 		move.b	obj_frame(a6),d0
		move.l	#objMap_platform,d1
 		bra	Object_Show
 		
; =================================================================
; ------------------------------------------------
; Code index
; ------------------------------------------------

@Index:
		dc.w	@Init-@Index
		dc.w	@Main-@Index
		even
		
; =================================================================
; ------------------------------------------------
; Sub-id
; ------------------------------------------------

@id_list:
		dc.w @left_right_sin-@id_list,0
		dc.l $03030100
		dc.w @left_right_cos-@id_list,0
		dc.l $03030100
		dc.w @up_down_sin-@id_list,0
		dc.l $03030100
		dc.w @up_down_cos-@id_list,0
		dc.l $03030100
		dc.w @rotate_right-@id_list,0
		dc.l $03030100
		dc.w @rotate_left-@id_list,0
		dc.l $03030100	
		dc.w @stepfall-@id_list,0
		dc.l $03030100
		
; =================================================================
; ------------------------------------------------
; Index $00: Init
; ------------------------------------------------

@Init:
		add.b	#1,obj_index(a6)
		move.l	#$03030001,obj_size(a6)		;failsafe
		move.l	#$8000,obj_y_spd(a6)
		move.w	obj_x(a6),last_x(a6)
		move.w	obj_y(a6),last_y(a6)
		clr.b	obj_frame(a6)
		
; =================================================================
; ------------------------------------------------                  
; Index $01: Main
; ------------------------------------------------

@Main:
 		moveq	#0,d5
 		
		moveq	#0,d0
		move.b	obj_subid(a6),d0
		lsl.w	#3,d0
 		move.l	@id_list+4(pc,d0.w),obj_size(a6)
		move.w	@id_list(pc,d0.w),d1
		jsr	@id_list(pc,d1.w)
 		
		bsr	objTouch_Top
		move.l	a4,d0
		cmp.l	#RAM_ObjBuffer,d0
		bne.s	@return
		tst.b	d0
		beq.s	@return
		cmp.b	#varPlyrMdDead,obj_index(a4)
		beq.s	@return
		bsr	objPlyrSetFloor
		tst.l	obj_y_spd(a4)
		bmi.s	@return
   		sub.w	d5,obj_x(a4)
@return:
		rts
 	
; ---------------------------
; Left/Right
; ---------------------------
	
@left_right_cos:
  		move.w	tanvalue(a6),d0

  		bra	@do_lr
  
@left_right_sin:
  		move.w	tanvalue(a6),d0
  		neg.w	d0
  		
@do_lr:
  		bsr	CalcSine
  		asr.w	#3,d0
  		move.w	last_x(a6),d2
  		add.w	d0,d2
  		move.w	obj_x(a6),d5
  		sub.w	d2,d5
  		move.w	d2,obj_x(a6)
  		
 		add.w	#1,tanvalue(a6)
  		rts
 
; ---------------------------
; Up/Down
; ---------------------------

@up_down_cos:
		move.w	tanvalue(a6),d0
		neg.w	d0
		bra.s	@do_ud
@up_down_sin:
  		move.w	tanvalue(a6),d0
@do_ud:
  		bsr	CalcSine
  		asr.w	#3,d0
  		move.w	last_y(a6),d2
  		add.w	d0,d2
;   		move.w	obj_y(a6),d4
;   		sub.w	d2,d4
   		move.w	d2,obj_y(a6)

 		add.w	#1,tanvalue(a6)
 		rts
 		
; ---------------------------
; rotate_right
; ---------------------------

@rotate_right:
;   		move.w	#$20,d4
  		
  		move.w	tanvalue(a6),d0
  		bsr	CalcSine
  		muls	#$40,d0
  		asr.l	#8,d0
  		move.w	last_x(a6),d2
  		add.w	d0,d2
  		move.w	obj_x(a6),d5
  		sub.w	d2,d5
  		move.w	d2,obj_x(a6)
   		
  		move.w	tanvalue(a6),d0
  		lsl.w	#1,d0
  		bsr	CalcSine
  		muls	#$30,d1
  		asr.l	#8,d1
  		move.w	last_y(a6),d2
  		add.w	d1,d2
   		move.w	d2,obj_y(a6)

 		add.w	#1,tanvalue(a6)
 		rts
 		
; ---------------------------
; rotate_left
; ---------------------------

@rotate_left:
 		add.w	#1,tanvalue(a6)
 		rts

; ---------------------------
; StepFall
; ---------------------------

@stepfall:
		bsr	objTouch_Top
		tst.b	d0
		beq	@return
		move.l	a4,d0
		cmp.l	#RAM_ObjBuffer,d0
		bne	@return
		tst.l	obj_y_spd(a4)
		bmi	@return
		
		add.w	#3,obj_y(a6)
		rts
