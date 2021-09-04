; =================================================================
; Object (SPECIAL)
; 
; Action script
; =================================================================

; =================================================================
; ------------------------------------------------
; Variables
; ------------------------------------------------

		rsset obj_ram
gotMaps		rs.l 1
gotVram		rs.w 1
gotFrame	rs.w 1 		;its a byte
gotWho		rs.l 1

; =================================================================
; ------------------------------------------------
; Code start
; ------------------------------------------------

obj_actionscript:
		moveq	#0,d0
		move.b	obj_index(a6),d0
		add.w	d0,d0
		move.w	@list(pc,d0.w),d1
		jmp	@list(pc,d1.w)
	
; ------------------------------------------------

@list:
		dc.w @killobj_init-@list
		dc.w @killobj_main-@list

		dc.w 0
		dc.w 0
		
; ------------------------------------------------
; Action: kill object
; ------------------------------------------------

@killobj_init:
		or.b	#1,obj_index(a6)
		bclr	#bitobj_hurt,obj_status(a6)
		bclr	#bitobj_hit,obj_status(a6)
		
		bset	#bitobj_FlipV,obj_status(a6)
		move.l	#-$40000,obj_y_spd(a6)

		;Read player
		move.l	gotWho(a6),d0
		cmp.l	#RAM_ObjBuffer,d0
		bne.s	@notplayer
		lea	(RAM_ObjBuffer),a4
		move.l	#-$30000,obj_y_spd(a4)
 		move.b	#varPlyAniJump,obj_anim_id(a4)
		bset 	#bitobj_air,obj_status(a4)
@notplayer:
  		move.l	#SndSfx_HitEnemy,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
  		
; --------------------------

@killobj_main:
		move.l	obj_x_spd(a6),d6
		move.l	obj_y_spd(a6),d7
		add.l	#$4000,d7
		add.l	d6,obj_x(a6)
		add.l	d7,obj_y(a6)
		move.l	d6,obj_x_spd(a6)
		move.l	d7,obj_y_spd(a6)
		
 		bsr	Object_OffCheck
		moveq	#0,d0
    		move.w	gotVram(a6),d0
    		swap	d0
 		move.b	gotFrame(a6),d0
		move.l	gotMaps(a6),d1
 		bra	Object_Show
		
; ------------------------------------------------
; Action: hurt the enemy
; ------------------------------------------------

; =================================================================
