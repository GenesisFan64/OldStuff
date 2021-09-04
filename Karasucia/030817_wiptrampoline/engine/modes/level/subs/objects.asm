; ====================================================================
; -------------------------------------------------
; Objects system
; -------------------------------------------------

; NOTES:
; Current object Slots:
;   00   | Player 1 (HARD-CODED)
;   01   | PLANNED (Second player if needed)
;   02   | HUD (TODO)
;   03   | Eng flag
;   04   | FREE
;   05   | FREE
;   06   | FREE
;   07   | FREE
; 08-15  | Blocks+Action objects (Auto-arrangled)
; 16-MAX | Level objects (Auto-arrangled)

; --------------------------------------------
; Variables
; --------------------------------------------

max_objects	equ	64
max_microspr	equ	64

; --------------------------------------------

		rsreset
obj_code	rs.l	1		; Object code 
obj_size	rs.l	1		; Object size (see below)

obj_x		rs.l	1		; Object X Position
obj_y		rs.l	1		; Object Y Position
obj_x_spd	rs.l	1		; Object X Speed
obj_y_spd	rs.l	1		; Object Y Gravity
; obj_maps	rs.l	1

obj_anim_next	rs.w	1		; Object animation increment (obj_anim + obj_anim_next)
obj_anim_id	rs.w	1		; Object animation to read (current|saved)
; obj_vram	rs.w	1		; Object VRAM
obj_anim_spd	rs.b	1		; Object animation delay
obj_index	rs.b	1		; Object code index
obj_status	rs.b	1		; Object status
obj_subid	rs.b	1		; Object SubID
obj_frame	rs.b	1		; Object display frame
; obj_frame_old	rs.b	1		; Object last frame (DMA)
obj_spwnindx	rs.b	1		; Object respawn index (this - 1)
obj_col		rs.b	1		; Object collision
obj_null	rs.b	1		; FILLER

obj_ram		rs.b	$40		; Object RAM
sizeof_obj	rs.l	0

; --------------------------------
; obj_size
; --------------------------------

		rsreset
objsize_l	rs.b	1
objsize_r	rs.b	1
objsize_u	rs.b	1
objsize_d	rs.b	1

; --------------------------------
; obj_status
; --------------------------------

bitobj_flipH	equ	0		; set to flip Sprite Horizontally
bitobj_flipV	equ	1		; set to flip Sprite Vertically
bitobj_air	equ	2		; set if floating/jumping
bitobj_hurt	equ	3		; set if we are hurt (Touched by enemy or player)

bitobj_hit	equ	6		; set to we can hit objects
bitobj_stay	equ	7		; set to stay on-screen

; --------------------------------
; obj_col
; --------------------------------

bitcol_floor	equ	0		; Set for Touching floor
bitcol_ceiling	equ	1		; 
bitcol_wall_r	equ	2		; set for Touching floor/wall/Ceiling
bitcol_wall_l	equ	3		;
bitcol_obj	equ	4
bitcol_obju	equ	5
bitcol_objl	equ	6
bitcol_objr	equ	7

; =================================================================
; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset RAM_ObjectSys
RAM_ObjBuffer	rs.b (sizeof_obj*max_objects)
RAM_ObjBackup	rs.l 2
RAM_MicrSprBuff	rs.l max_microspr*2
RAM_ObjMaxCoins	rs.l 16
RAM_MicrSprCntr	rs.w 1
RAM_ObjCount	rs.w 1
sizeof_objbuff	rs.l 0
; 		inform 0,"Objects system uses: %h",sizeof_objbuff-RAM_ObjectSys
		
; ====================================================================		
; --------------------------------------------
; Init
; --------------------------------------------

Objects_Init:
 		lea	(RAM_ObjBuffer),a0
		move.w	#(sizeof_obj*max_objects)-1,d0
@ClrObjs:
 		clr.b	(a0)+
 		dbf	d0,@ClrObjs
 		clr.w	(RAM_MicrSprCntr)
		rts
 
; ====================================================================	
; --------------------------------------------
; Loop
; --------------------------------------------

Objects_Run:
  		bsr	Sprites_Reset

; -----------------------------
; Run objects
; -----------------------------

		clr.w	(RAM_ObjCount)
 		lea	(RAM_ObjBuffer),a6
 		move.w	#max_objects-1,d7
@Next:
 		tst.l	(a6)
 		beq.s	@NoAddr
 		
 		movem.l	a6/d7,(RAM_ObjBackup)
  		movea.l	obj_code(a6),a5
  		jsr	(a5)
 		movem.l	(RAM_ObjBackup),a6/d7
  		add.w	#1,(RAM_ObjCount)
@NoAddr:
 		adda	#sizeof_obj,a6
 		dbf	d7,@Next
 		
; -----------------------------
; Show the sprites
; -----------------------------

; Object_DrawObjects:
 		lea	(RAM_MicrSprBuff),a2
@NextFrm:
 		tst.l	(a2)
 		beq.s	@NoAddrFrm
 		bsr	Object_MicroToSpr
 		clr.l	(a2)+
 		clr.l	(a2)+
  		bra.s	@NextFrm
@NoAddrFrm:
  		clr.w	(RAM_MicrSprCntr)
		rts
; 		inform 0,"%h",RAM_MicrSprBuff
		
; ====================================================================
; ----------------------------------------------
; Subs
; ----------------------------------------------

; **********************************************
; Object display
; **********************************************

; ----------------------------------------------
; Object_DynArt
; 
; Input:
; d0 | LONG - VRAM|Frame
; d1 | LONG - DPLC data
; d2 | LONG - Art data
;
; Uses:
; a3/d3-d7
; ----------------------------------------------
 
Object_DPLC:
; 		cmp.b	obj_frame_old(a6),d0
; 		beq.s	@EndAll
		and.w	#$FF,d0
; 		move.b	d0,obj_frame_old(a6)
		movea.l	d1,a3
		lsl.w	#1,d0
    		adda	(a3,d0.w),a3
   		moveq	#0,d6
   		move.w	(a3)+,d6
   		beq	@EndAll
   		sub.w	#1,d6
   		swap	d0
   		and.w	#$7FF,d0
   		moveq	#0,d5
   		move.w	d0,d5		;d5 - VRAM (base)
   		move.l	d2,d7
@Next:
     		move.w	(a3),d1
     		lsr.w	#8,d1
     		move.w	d1,d4
     		lsr.w	#4,d4		;d4 - Next VRAM
     		and.w	#$F,d4
     		add.w	#1,d4
     		add.w	#$10,d1		;Size + 1
     		swap	d1		;Size|ROM+Here
      		move.w	(a3)+,d1
      		and.w	#$FFF,d1
     		lsl.w	#5,d1
     		move.l	d7,d0
      		moveq	#0,d3
      		move.w	d1,d3
      		add.l	d3,d0		;ROM Addr + Cell number
     		
		swap	d1		;(Broken)|Size
		move.w	d5,d2
    		bsr	DMA_Set		;** TODO **
		add.w	d4,d5		;Next VRAM
   		dbf	d6,@Next
 
@EndAll:
 		rts
 
; ----------------------------------------------
; Object_Show
; 
; Input:
; a6 - Current object
; d0 - VRAM | Frame
; 
; Uses:
; a3/d0-d1
; 
; WARNING: WITH THIS METHOD, OBJECTS MUST BE
; AFTER $FF8000 SO IT CAN CORRECTLY
; CHECK BETWEEN OBJECTS AND
; SEPARATE SPRITES
; ----------------------------------------------

Object_Show:	
		lea	(RAM_MicrSprBuff),a3
		move.w	(RAM_MicrSprCntr),d2
		lsl.w	#3,d2
		adda	d2,a3
; @next:		
; 		tst.l	(a3)
; 		beq.s	@free
; 		adda	#8,a3
; 		bra.s	@next
@free:
 		cmpa.w	#(RAM_MicrSprBuff+($200))&$FFFF,a3	; TODO: mejor check
 		bge.s	@full
 		
		lea	(RAM_LvlPlanes),a5
 		move.w	obj_x(a6),d2
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_X
 		sub.w	lvl_x(a5),d2
@onscrn_X:
 		add.w	#$80,d2
  		cmp.w	#$40,d2
  		blt	@full
 		cmp.w	#(320+$80)+$40,d2
 		bgt	@full

 		swap	d2
 		move.w	obj_y(a6),d2
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_Y
		sub.w	lvl_y(a5),d2
@onscrn_Y:
 		add.w	#$80,d2
 		cmp.w	#$40,d2
 		blt	@full
		cmp.w	#(224+$80)+$40,d2
		bgt	@full
    		
		move.w	a6,(a3)+	; (Object_RAM & $FFFF)
		and.w	#$FF,d0
		lsl.w	#8,d0
		swap	d0
		move.w	d0,(a3)+	; VRAM
		clr.w	d0
 		or.l	d0,d1	
		move.l	d1,(a3)+	; Frame | Maps data
		
		add.w	#1,(RAM_MicrSprCntr)
@full:		
 		rts

; ----------------------------------------------
; Object_ExtSprite
; 
; Input:
; d0 -    X | Y
; d1 - Size | VRAM
; 
; Uses:
; d4-d5, a3/d5
; ----------------------------------------------

Object_ExtSprite:
		lea	(RAM_MicrSprBuff),a3
		move.w	(RAM_MicrSprCntr),d4
		lsl.w	#3,d4
		adda	d4,a3
; @next:		
; 		tst.l	(a3)
; 		beq.s	@free
; 		adda	#8,a3
; 		bra.s	@next
@free:
 		cmpa.w	#(RAM_MicrSprBuff+($200))&$FFFF,a3	; TODO: mejor check
 		bge.s	@full
 		
		lea	(RAM_LvlPlanes),a5
		
		move.l	d0,d5
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_Y
  		sub.w	lvl_y(a5),d5
@onscrn_Y:
  		add.w	#$80,d5
 		cmp.w	#$40,d5
 		blt	@full
		cmp.w	#(224+$80)+$40,d5
		bgt	@full
 		and.w	#$7FFF,d5
  		move.w	d5,(a3)

		swap	d5
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_X
   		sub.w	lvl_x(a5),d5
@onscrn_X:
  		add.w	#$80,d5
  		cmp.w	#$40,d5
  		blt	@full
 		cmp.w	#(320+$80)+$40,d5
 		bgt	@full
		and.w	#$7FFF,d5
  		move.w	d5,6(a3)

  		move.l	d1,d4
 		move.w	d4,4(a3)
 		swap	d4
 		move.w	d4,d5
 		and.w	#$F,d5
   		move.w	d5,2(a3)
   		swap	d4
   		
   		add.w	#1,(RAM_MicrSprCntr)
@full:		
 		rts
 		
; ----------------------------------------------
; Object_Delete
; 
; Input:
; a6 - Current object
; ----------------------------------------------

Object_Delete:
		moveq	#0,d0
		move.b 	obj_spwnindx(a6),d0
		tst.b	d0
		beq.s	@offindx
		sub.w	#1,d0
		mulu.w	#$A,d0
		lea	(RAM_LevelObjPos),a5
		adda	d0,a5
		bclr	#7,(a5)			;Reset ON SCREEN flag
@offindx:

;  		clr.l	obj_code(a6)
; 		clr.b	obj_index(a6)
		
		move.w	#sizeof_obj-1,d0
@delete:
		clr.b	(a6)+
		dbf	d0,@delete
 		rts
 		
; ----------------------------------------------
; Object_MicroToSpr
; 
; grab an entry from the microlist
; and convert it to sprites
; ----------------------------------------------

Object_MicroToSpr:
		moveq	#0,d0
		move.w	(a2),d0
		tst.w	d0
		bmi.s	@FromObject
		
 		lea	(RAM_SprControl),a5
		movea.l	sprite_free(a5),a4
 		cmpa	#((RAM_Sprites+$280)&$FFFF),a4
 		bgt	Object_Return
 		
  		move.w	(a2),d2
 		cmp.w	#$40,d2
 		blt	@no_sprite
		cmp.w	#(224+$80)+$40,d2
		bgt	@no_sprite
 		move.w	d2,(a4)
 		move.w	6(a2),d2
  		cmp.w	#$40,d2
  		blt	@no_sprite
 		cmp.w	#(320+$80)+$40,d2
 		bgt	@no_sprite
 		move.w	d2,6(a4)
	
		move.w	2(a2),d2
		move.w	sprite_link(a5),d0
 		add.w	#1,sprite_link(a5)
     		lsl.w	#8,d2
		and.w	#$0F00,d2
		or.w	d2,d0
		move.w	d0,2(a4)
		move.w	4(a2),4(a4)
 
  		adda	#8,a4
		move.l	a4,sprite_free(a5)
		rts

@no_sprite:
		clr.l	(a4)
		clr.l	4(a4)
		rts
		
; ----------------------------------------------

@FromObject:
		or.l	#$FF0000,d0
		movea.l	d0,a6
 		move.w	2(a2),d0
		swap	d0
		move.b	4(a2),d0
		and.w	#$FF,d0
		move.l	4(a2),d1
		and.l	#$FFFFFF,d1
		
		lea	(RAM_LvlPlanes),a5
 		move.w	obj_x(a6),d2
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_X_obj
 		sub.w	lvl_x(a5),d2
@onscrn_X_obj:
 		add.w	#$80,d2
  		cmp.w	#$40,d2
  		blt	Object_Return
 		cmp.w	#(320+$80)+$40,d2
 		bgt	Object_Return
 		swap	d2
 		move.w	obj_y(a6),d2
 		btst	#bitobj_stay,obj_status(a6)
 		bne.s	@onscrn_Y_obj
		sub.w	lvl_y(a5),d2
@onscrn_Y_obj:
 		add.w	#$80,d2
 		cmp.w	#$40,d2
 		blt	Object_Return
		cmp.w	#(224+$80)+$40,d2
		bgt	Object_Return

		clr.w	d3
		btst	#bitobj_flipH,obj_status(a6)
		beq.s	@Right_LR
		bset	#0,d3
@Right_LR:
		btst	#bitobj_flipV,obj_status(a6)
		beq.s	@Right_UD
		bset	#1,d3
@Right_UD:

; ----------------------------------------------
; Object_BldSpr_List
; 
; Input:
; d0 - VRAM|Frame
; d1 - Mappings data address
; d2 - X-pos|Y-pos 
; d3 - Flags
;
; Output:
; d3 - New sprite link
; 
; Uses:
; a3-a5/d4
; ----------------------------------------------

; TODO: esto no checa el final

Object_BldSpr_List:
 		lea	(RAM_SprControl),a5
		movea.l	sprite_free(a5),a4
 		cmpa	#((RAM_Sprites+$280)&$FFFF),a4
 		bgt	Object_Return
 		
 		movea.l	d1,a3
 		lsl.w	#1,d0
 		adda	(a3,d0.w),a3
 		
		and.l	#$FFFF,d3
 		moveq	#0,d6
 		move.b	(a3)+,d6
 		beq	Object_Return
 		sub.w	#1,d6
@Next:

; ------------
; Ypos check
; ------------

; TODO: hacer el mismo fix de abajo despues

		move.w	d2,d1
 		move.b	(a3),d0
 		ext.w	d0
 		
   		btst	#1,d3		; VFlip flag?
  		beq	@DontFlip
 		move.b	1(a3),d4
  		and.w	#%11,d4
  		lsl.w	#3,d4
  		add.w	d4,d0
		neg.w	d0
@DontFlip:
 		add.w	d0,d1
 		move.b	(RAM_VidRegs+$C),d0
 		and.w	#%00000110,d0
 		beq.s	@normal
		add.w	#$70,d1	
@normal:
 		move.w	d1,(a4)+
		
; ------------
; Size
; ------------

 		move.b	1(a3),(a4)+		; Size
 		clr.w	d0
 		move.b	5(a5),d0
 		add.b	sprite_link(a5),d0
 		move.b	d0,(a4)+		; Link
 		add.w	#1,sprite_link(a5)
 
; ------------
; Vram
; ------------

  		clr.w	d0			; Vram
  		move.b	2(a3),d0
  		lsl.w	#8,d0
  		move.b	3(a3),d0
  		swap	d0
  		move.w	d0,d1
  		swap	d0
  		add.w	d0,d1
  	
   		btst	#0,d3			;Left flag?
   		beq.s	@Right
   		or.w	#$800,d1
@Right:
   		btst	#1,d3			;V flag?
   		beq.s	@Down
   		or.w	#$1000,d1
@Down:
  		move.w	d1,(a4)+
		
; ------------
; Xpos check
; ------------

 		clr.w	d0
 		moveq	#0,d1
 		moveq	#0,d4
 		swap	d2
 		move.w	d2,d1
 		swap	d2
 		
 		move.b	4(a3),d0
 		ext.w	d0
   		btst	#0,d3			;Left flag?
  		beq	@ContX

 		move.b	1(a3),d4
  		and.w	#%1100,d4
  		lsl.w	#1,d4
  		add.w	d4,d0
		neg.w	d0
  		sub.w	#8,d0			;TODO: mala idea

@ContX:
 		add.w	d0,d1
 		move.w	d1,(a4)+
 		adda 	#5,a3
 		dbf	d6,@Next
 		move.l	a4,sprite_free(a5)
 		
 		cmpa	#((RAM_Sprites+$280)&$FFFF),a4
 		bgt.s	Object_Return
 		clr.l	(a4)+
 		clr.l	(a4)+
Object_Return:
 		rts
 		
; ----------------------------------------------
; Object_IsGone
; ----------------------------------------------

Object_IsGone:
		moveq	#0,d0
		move.b 	obj_spwnindx(a6),d0
		tst.b	d0
		beq.s	@offindx
		sub.w	#1,d0
		mulu.w	#$A,d0
		lea	(RAM_LevelObjPos),a5
		adda	d0,a5
		bset	#6,(a5)			; Set GONE flag
@offindx:
		rts
		
; ----------------------------------------------
; Object_OffCheck
; ----------------------------------------------

Object_OffCheck:
		lea	(RAM_LvlPlanes),a5
		lea	(RAM_LevelObjPos),a4
		
		moveq	#0,d0
		move.b 	obj_spwnindx(a6),d0
		tst.b	d0
		beq.s	@return
		sub.w	#1,d0
		mulu.w	#$A,d0
		adda	d0,a4
		
   		move.w	lvl_y(a5),d0
   		move.w	d0,d2
     		move.w	obj_y(a6),d1
     		add.w	#$60,d1
     		cmp.w	d0,d1
     		blt.s	Object_OffDelete
       		add.w	#224+$60,d2
      		move.w	obj_y(a6),d1
      		cmp.w	d2,d1
      		bgt.s	Object_OffDelete
     		
  		move.w	lvl_x(a5),d0
  		move.w	d0,d2
    		move.w	obj_x(a6),d1
    		add.w	#$40,d1
    		cmp.w	d0,d1
    		blt.s	Object_OffDelete
      		add.w	#320+$40,d2		;TODO: horizontal mode 
     		move.w	obj_x(a6),d1
     		cmp.w	d2,d1
     		bgt.s	Object_OffDelete
     		
;      		; Check for suicide
; 		move.w	lvl_size_y(a5),d0		; Bottomless pit
; 		lsl.w	#4,d0
; 		move.w	obj_y(a6),d1
; 		moveq	#0,d2
; 		move.b	obj_size+2(a6),d2
; 		lsl.w	#3,d2
; 		sub.w	d2,d1
; 		cmp.w	d0,d1
; 		blt	@return
; 		
; 		bset	#7,(a4)
; 		clr.l	obj_code(a6)
; 		clr.b	obj_index(a6)
@return:
		rts
		
; a4 - respawn slot of this object

Object_OffDelete:
		bclr	#7,(a4)			; Reset ON SCREEN flag
@offindx:

		clr.l	obj_code(a6)
		clr.b	obj_index(a6)
@Return:
 		rts
		
; ----------------------------------------------
; Object animation
; 
; Input
; d1 | LONG - Animation data
; 
; Output
; d0 | WORD - Frame
; 
; Uses:
; d2
; ----------------------------------------------
 
Object_Animate:
 		tst.l	d1
  		beq.s	@Return
 		moveq	#0,d2
 		move.b	obj_anim_id+1(a6),d2
 		cmp.b	obj_anim_id(a6),d2
 		beq.s	@SameThing
 		move.b	obj_anim_id(a6),obj_anim_id+1(a6)
 		clr.w	obj_anim_next(a6)
@SameThing:
 		move.b	obj_anim_id(a6),d2
 		cmp.b	#-1,d2
 		beq.s	@Return
 		lsl.w	#1,d2
		movea.l	d1,a0
 		adda	(a0,d2.w),a0
 
 		move.b	(a0)+,d2
 		cmp.b	#-1,d2
 		beq.s	@keepspd
 		sub.b	#1,obj_anim_spd(a6)
 		bpl.s	@Return
		move.b	d2,obj_anim_spd(a6)
@keepspd:
 		moveq	#0,d1
 		move.w	obj_anim_next(a6),d2
 		move.b	(a0),d1
 		adda	d2,a0
 
 		and.l	#$FFFF0000,d0
 		move.b	(a0),d0
 		cmp.b	#$FF,d0
 		beq.s	@NoAnim
 		cmp.b	#$FE,d0
 		beq.s	@GoToFrame
 		cmp.b	#$FD,d0
 		beq.s	@LastFrame
 		
 		move.b	d0,obj_frame(a6)
 		add.w	#1,obj_anim_next(a6)
@Return:
 		rts
 
@NoAnim:
 		move.w	#1,obj_anim_next(a6)
 		move.w	d1,d0
 		move.b	d0,obj_frame(a6)
		rts
@LastFrame:
 		clr.b	obj_anim_spd(a6)
		rts
@GoToFrame:
		clr.w	obj_anim_next(a6)
		move.b	1(a0),obj_anim_next+1(a6)
		rts
	
; ------------------------------------------------

Object_ShowPoints:
 		move.w	obj_x(a6),d0
 		sub.w	#4,d0
 		swap	d0
 		move.w	obj_y(a6),d0
 		sub.w	#4,d0
 		moveq	#0,d1
 		move.w	#$587,d1
 		bra	Object_ExtSprite
 		
 		
 		move.w	obj_y(a6),d4
 		moveq	#0,d2
 		move.b	obj_size+3(a6),d2
 		lsl.w	#3,d2
 		add.w	d2,d4
 		bsr	@leftright
 		move.w	obj_y(a6),d4
 		moveq	#0,d2
 		move.b	obj_size+2(a6),d2
 		lsl.w	#3,d2
 		sub.w	d2,d4

;  		rts
@leftright:
 		move.w	obj_x(a6),d0
 		sub.w	#2,d0
 		swap	d0
 		move.w	d4,d0
 		moveq	#0,d1
 		move.w	#$587,d1
 		bsr	Object_ExtSprite
 		
 		move.w	obj_x(a6),d0
 		moveq	#0,d2
 		move.b	obj_size(a6),d2
 		lsl.w	#3,d2
 		sub.w	d2,d0
 		swap	d0
 		move.w	d4,d0
 		bsr	Object_ExtSprite
 		
 		move.w	obj_x(a6),d0
 		sub.w	#3,d0
 		moveq	#0,d2
 		move.b	obj_size+1(a6),d2
 		lsl.w	#3,d2
 		add.w	d2,d0
 		swap	d0
 		move.w	d4,d0
 		bra	Object_ExtSprite
 	
; **********************************************
; Object level collision
; **********************************************

; ************************
; Find floor collision
; CENTER
; 
; Input:
; a6 - Object to read
; a5 - Level buffer
; a4 - Layout data
; 
; Output:
; d0 | LONG - Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3-a4 | d4-d5
; ************************

object_FindPrz_Floor:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_Floor
  		
object_FindCol_Floor:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4

objSearchCol_Floor:
		moveq	#0,d0
		moveq	#0,d4
		moveq	#0,d5
 		move.w	obj_y(a6),d4
 		move.b	obj_size+3(a6),d5
 		lsl.w	#3,d5
 		add.w	d5,d4
 		tst.w	d4
 		bmi	@no_col
 		move.w	lvl_size_y(a5),d5
 		lsl.w	#4,d5
 		cmp.w	d5,d4
 		bge	@no_col
 		move.w	d4,d5
   		lsl.l	#4,d5
    		move.l	d5,d0
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a4
 		
; ------------------------
; X check
; ------------------------

  		movea.l	a4,a3
 		move.w	obj_x(a6),d4
 		tst.w	d4
 		bmi.s	@force_on
 		move.w	lvl_size_x(a5),d5
 		lsl.w	#4,d5
  		cmp.w	d5,d4
  		bge.s	@force_on
 		lsr.w	#4,d4
 		adda 	d4,a3
;  		btst	#7,(a3)
;  		bne.s	@no_col
;  		tst.b	(a3)
;  		beq.s	@no_col
 		lsl.w	#4,d4
 		swap	d4
 		or.l	d4,d0			;XXXYYY00
   		
 		move.b	(a3),d0	
 		rts
 		
@force_on:
 		moveq	#1,d0
@no_col:
		rts
		
; ************************
; Find side collision
; CENTER
;
; Input:
; a6 - Object to read
; a5 - Level buffer
; a4 - Layout data
; 
; Output:
; d0 | LONG - Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3-a4 | d4-d5
; ************************

object_FindPrz_Wall:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_Wall
  		
object_FindCol_Wall:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4

objSearchCol_Wall:
		moveq	#0,d0
		moveq	#0,d4
		moveq	#0,d5
 		move.w	obj_y(a6),d4
 		move.b	obj_size+3(a6),d5
 		lsl.w	#3,d5
 		add.w	d5,d4
 		sub.w	#1,d4
 		tst.w	d4
 		bmi	@no_col
 		move.w	lvl_size_y(a5),d5
 		lsl.w	#4,d5
 		cmp.w	d5,d4
 		bge	@no_col
 		lsr.w	#4,d4
 		mulu.w	lvl_size_x(a5),d4
 		adda	d4,a4
 		lsl.l	#8,d4
 		move.l	d4,d0
 		
; ------------------------
; X check
; ------------------------

 		movea.l	a4,a3
 		move.w	obj_x(a6),d4
 		tst.w	d4
 		bmi.s	@force_on
 		move.w	lvl_size_x(a5),d5
 		lsl.w	#4,d5
  		cmp.w	d5,d4
  		bge.s	@force_on
 		lsr.w	#4,d4
 		adda 	d4,a3
 		lsl.w	#4,d4
 		swap	d4
 		
		moveq	#0,d5
   		move.w	obj_y(a6),d4
   		move.b	obj_size+3(a6),d5
   		lsl.w	#3,d5
   		add.w	d5,d4
   		
   		sub.w	#1,d4
 		move.w	lvl_size_y(a5),d5
 		lsl.w	#4,d5
 		swap	d5
 		move.b	obj_size+2(a6),d5
  		and.w	#$FF,d5
  		lsr.w	#1,d5
   		tst.w	d5
   		beq.s	@nxt_y
   		sub.w	#1,d5
@nxt_y:
		swap	d5
 		tst.w	d4
 		bmi.s	@force_on
 		cmp.w	d5,d4
 		bge.s	@zero_y
 		btst	#7,(a3)
 		bne.s	@zero_y
		tst.b	(a3)
		beq.s	@zero_y
  		or.l	d4,d0
  		swap	d4
  		lsl.l	#4,d4
  		and.l	#$000FFF00,d4
  		or.l	d4,d0
 		move.b	(a3),d0
 		rts
@zero_y:
 		suba	lvl_size_x(a5),a3
 		sub.w	#$10,d4
		swap	d5
  		dbf	d5,@nxt_y

@force_on:
		move.b	#0,d0
@no_col:
		rts

; ************************
; Find Ceiling collision
; CENTER
; 
; Input:
; a6 - Object to read
; a5 - Level buffer
; a4 - Layout data

; Output:
; d0 | LONG - Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3-a4 | d4-d5
; ************************

object_FindPrz_Ceiling:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_Ceiling
  		
object_FindCol_Ceiling:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4
  		
objSearchCol_Ceiling:
		moveq	#0,d0
		moveq	#0,d4
		moveq	#0,d5
 		move.w	obj_y(a6),d4
    		move.b	obj_size+2(a6),d5
    		lsl.w	#3,d5
    		sub.w	d5,d4			;UP SIZE
 		tst.w	d4
 		bmi	@no_col
 		move.w	lvl_size_y(a5),d5
 		lsl.w	#4,d5
 		cmp.w	d5,d4
 		bge	@no_col
 		lsr.w	#4,d4
 		and.w	#$FFF,d4
 		move.w	d4,d0
 		lsl.l	#8,d0			;000YYY00
 		mulu.w	lvl_size_x(a5),d4
 		adda	d4,a4
		
; ------------------------
; X check
; ------------------------

 		movea.l	a4,a3
 		move.w	obj_x(a6),d4
 		sub.w	#1,d4
 		tst.w	d4
 		bmi.s	@no_col
 		move.w	lvl_size_x(a5),d5
 		lsl.w	#4,d5
   		cmp.w	d5,d4
   		bge.s	@no_col
 		lsr.w	#4,d4
 		adda 	d4,a3
;  		btst	#7,(a3)
;  		bne.s	@no_col
;  		tst.b	(a3)
;  		beq.s	@no_col
 		lsl.w	#4,d4
 		swap	d4
 		or.l	d4,d0			;XXXYYY00
 		move.b	(a3),d0	
@no_col:
		rts
		
; ************************
; Find floor collision
; Left/Right points
;
; Input:
; a6 - Object to read
; a5 - Level buffer
; a4 - Layout data
; 
; Output:
; d0 | LONG - RIGHT FEET Xpos|Ypos|ID $XXXYYYID
; d1 | LONG - LEFT FEET Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3 | d4-d5
; ************************

object_FindPrz_FloorSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
		bra.s	objSearchCol_FloorSides
		
object_FindCol_FloorSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4
  		
objSearchCol_FloorSides:
		moveq	#0,d0
		moveq	#0,d1

		moveq	#0,d4
		moveq	#0,d5
 		move.w	obj_y(a6),d4
  		move.b	obj_size+3(a6),d5
 		lsl.w	#3,d5
 		add.w	d5,d4
 		tst.w	d4
 		bmi	@no_col
  		move.w	lvl_size_y(a5),d5
  		lsl.w	#4,d5
  		cmp.w	d5,d4
  		bge	@no_col
 		lsr.w	#4,d4
  		move.w	d4,d0
  		move.w	d4,d1
  		lsl.l	#8,d0			; LEFT 000YYY00
  		lsl.l	#8,d1			;RIGHT 000YYY00
 		mulu.w	lvl_size_x(a5),d4
 		adda	d4,a4

; ------------------------
; X check
; 
; LEFT
; ------------------------

 		moveq	#0,d4
		moveq	#0,d5
  		move.w	obj_x(a6),d5
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
      		cmp.w	d4,d5
      		blt.s	@dontfix_l
      		sub.w	#1,d5
@dontfix_l:
 		tst.w	d5
 		bmi.s	@zero_l
 		
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		; d5 - XRead | Free
 		move.b	obj_size(a6),d5
 		and.w	#$FF,d5		; d5 - XRead | Loop
 		tst.w	d5
 		beq.s	@zero_l
@Next_col_l:
 		swap	d5		; d5 - Loop | Xread
 		
 		tst.b	(a3)
 		beq.s	@No_col_l
 		btst	#7,(a3)
 		bne.s	@No_col_l
 		move.w	d5,d4
 		and.w	#$FFF0,d4
 		swap	d4
 		or.l	d4,d1		; LEFT XXXYYY00
		move.b	(a3),d1
 		bra.s	@zero_l
@No_col_l:

 		sub.w	#8,d5
   		bpl.s	@Fine_l
   		clr.w	d5
@Fine_l:
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		; d5 - XRead | Loop
 		dbf	d5,@Next_col_l
@zero_l:
		
; ------------------------
; X check
; 
; RIGHT
; ------------------------

 		moveq	#0,d4
 		moveq	#0,d5
 		move.w	obj_x(a6),d5
 		sub.w	#1,d5
 		tst.w	d5
 		bmi.s	@no_col
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
   		cmp.w	d4,d5
    		bge.s	@no_col

 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		;d5 - XRead | Free
 		move.b	obj_size+1(a6),d5
 		and.w	#$FF,d5		;d5 - XRead | Loop
 		tst.w	d5
 		beq.s	@no_col
 		
@Next_col_r:
 		swap	d5		;d5 - Loop | Xread
 		tst.b	(a3)
 		beq.s	@No_col_r
 		btst	#7,(a3)
 		bne.s	@No_col_r
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
   		cmp.w	d4,d5
    		bge.s	@no_col
    		
 		move.w	d5,d4
 		and.w	#$FFF0,d4
 		swap	d4
 		or.l	d4,d0		; RIGHT XXXYYY00
		move.b	(a3),d0
 		rts
 		
@No_col_r:
 		add.w	#8,d5
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		;d5 - XRead | Loop
 		dbf	d5,@Next_col_r
 		
; ------------------------

@no_col:
		rts

; ************************
; Find side collision
; LEFT/RIGHT
;
; Input:
; (Nothing)
; 
; Output:
; d0 | LONG - RIGHT FEET Xpos|Ypos|ID $XXXYYYID
; d1 | LONG - LEFT FEET Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3-a4 | d4-d5
; ************************

object_FindPrz_WallSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_WallSides
  		
object_FindCol_WallSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4
  		
objSearchCol_WallSides:
 		moveq	#0,d0
 		moveq	#0,d1
 		moveq	#0,d4
 		moveq	#0,d5

; ------------------------
; Left
; ------------------------

		tst.b	obj_size(a6)
		beq	@ignore_l
			
; --------------
; LEFT DOWN
; --------------

  		move.w	obj_y(a6),d5
  		tst.w	d5
		bmi	@ignore_l
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge	@ignore_l
  		swap	d5
  		clr.w	d5
  		move.b	obj_size+3(a6),d5	
  		tst.w	d5
  		beq	@ignore_l
  		sub.w	#1,d5
@next_passld:
		swap	d5
		tst.w	d5
		bmi	@ignore_l
		move.w	d5,d4
		swap	d4
		move.w	obj_x(a6),d4
		sub.w	#1,d4
		clr.w	d5
		move.b	obj_size(a6),d5
		lsl.w	#3,d5
		sub.w	d5,d4			; left X size
		tst.w	d4
		bmi	@forceset_l
		lsr.w	#4,d4
 		movea.l	a4,a3
		adda	d4,a3
		swap	d4
		move.w	d4,d5
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a3
  		
  		btst	#7,(a3)
  		bne.s	@next_ld
  		tst.b	(a3)
  		bne	@found_l
@next_ld:
		add.w	#8,d5
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge.s	@gone_ld
		
		swap	d5
		dbf	d5,@next_passld
@gone_ld:

; --------------
; LEFT UP
; --------------

  		move.w	obj_y(a6),d5
  		tst.w	d5
		bmi	@ignore_l
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge	@ignore_l
  		swap	d5
  		clr.w	d5
  		move.b	obj_size+2(a6),d5	
  		tst.w	d5
  		beq.s	@ignore_l
  		sub.w	#1,d5
@next_passlu:
		swap	d5
		tst.w	d5
		bmi.s	@ignore_l
		move.w	d5,d4
		swap	d4
		move.w	obj_x(a6),d4
		sub.w	#1,d4
		clr.w	d5
		move.b	obj_size(a6),d5
		lsl.w	#3,d5
		sub.w	d5,d4			; left X size
		tst.w	d4
		bmi.s	@forceset_l
		lsr.w	#4,d4
 		movea.l	a4,a3
		adda	d4,a3
		swap	d4
		move.w	d4,d5
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a3
  		
  		btst	#7,(a3)
  		bne.s	@next_lu
  		tst.b	(a3)
  		bne.s	@found_l	
@next_lu:
		sub.w	#8,d5
		tst.w	d5
		bmi.s	@ignore_l
		swap	d5
		dbf	d5,@next_passlu
		
		bra.s	@ignore_l
		
; --------------
; Found left
; --------------

@forceset_l:
		move.b	#1,d1
		bra.s	@ignore_l
		
@found_l:
		and.l	#$FFF0,d5
		lsl.l	#4,d5
		or.l	d5,d1
 		moveq	#0,d5
		move.w	obj_x(a6),d4
		sub.w	#1,d4
		move.b	obj_size(a6),d5
		lsl.w	#3,d5
		sub.w	d5,d4
		and.l	#$FFF0,d4
		swap	d4
		or.l	d4,d1
 		move.b	(a3),d1
@ignore_l:

; ------------------------
; Right
; ------------------------
 
		tst.b	obj_size+1(a6)
		beq	@ignore_r
		
; --------------
; RIGHT DOWN
; --------------

		moveq	#0,d5
  		move.w	obj_y(a6),d5
  		tst.w	d5
		bmi	@ignore_r
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge	@ignore_r
  		swap	d5
  		clr.w	d5
  		move.b	obj_size+3(a6),d5	
  		tst.w	d5
  		beq	@ignore_r
  		sub.w	#1,d5
@next_passrd:
		swap	d5
		tst.w	d5
		bmi	@ignore_r
		
		move.w	d5,d4
		swap	d4
		move.w	obj_x(a6),d4
		clr.w	d5
		move.b	obj_size+1(a6),d5
		lsl.w	#3,d5
		add.w	d5,d4			; left X size
		move.w	lvl_size_x(a5),d5
		lsl.w	#4,d5
		cmp.w	d5,d4
		bge	@forceset_r
		
		lsr.w	#4,d4
 		movea.l	a4,a3
		adda	d4,a3
		swap	d4
		move.w	d4,d5
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a3
  		
  		btst	#7,(a3)
  		bne.s	@next_rd
  		tst.b	(a3)
  		bne	@found_r
@next_rd:
		add.w	#8,d5
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge.s	@gone_rd
		swap	d5
		dbf	d5,@next_passrd
@gone_rd:

; --------------
; RIGHT UP
; --------------

		moveq	#0,d5
  		move.w	obj_y(a6),d5
  		tst.w	d5
		bmi	@ignore_r
		move.w	lvl_size_y(a5),d4
		lsl.w	#4,d4
		cmp.w	d4,d5
		bge	@ignore_r
  		swap	d5
  		clr.w	d5
  		move.b	obj_size+2(a6),d5	
  		tst.w	d5
  		beq.s	@ignore_r
  		sub.w	#1,d5
@next_passru:
		swap	d5
		tst.w	d5
		bmi.s	@ignore_r
		
		move.w	d5,d4
		swap	d4
		move.w	obj_x(a6),d4
		clr.w	d5
		move.b	obj_size+1(a6),d5
		lsl.w	#3,d5
		add.w	d5,d4			; left X size
		move.w	lvl_size_x(a5),d5
		lsl.w	#4,d5
		cmp.w	d5,d4
		bge.s	@forceset_r
		
		lsr.w	#4,d4
 		movea.l	a4,a3
		adda	d4,a3
		swap	d4
		
		move.w	d4,d5
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a3
  		
  		btst	#7,(a3)
  		bne.s	@next_ru
  		tst.b	(a3)
  		bne.s	@found_r
@next_ru:
		sub.w	#8,d5
		tst.w	d5
		bmi.s	@ignore_r
		
		swap	d5
		dbf	d5,@next_passru

		bra.s	@ignore_r

; --------------
; Found right
; --------------

@forceset_r:
		move.b	#1,d0
		bra.s	@ignore_r
		
@found_r:
		and.l	#$FFF0,d5
		lsl.l	#4,d5
		or.l	d5,d0
 		moveq	#0,d5
		move.w	obj_x(a6),d4
		move.b	obj_size+1(a6),d5
		lsl.w	#3,d5
		add.w	d5,d4
		and.l	#$FFF0,d4
		swap	d4
		or.l	d4,d0
 		move.b	(a3),d0	
@ignore_r:
		
; ------------------------
; Finish checking
; ------------------------

		rts
		
; ************************
; Find ceiling collision
; LEFT/RIGHT
; 
; Input:
; (Nothing)
; 
; Output:
; d0 | LONG - RIGHT FEET Xpos|Ypos|ID $XXXYYYID
; d1 | LONG - LEFT FEET Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3-a4 | d4-d5
; ************************

object_FindPrz_CeilingSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_CeilingSides
  		
object_FindCol_CeilingSides:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4
  		
objSearchCol_CeilingSides:
		moveq	#0,d0
		moveq	#0,d1
 		moveq	#0,d4
  		move.w	obj_y(a6),d5
;   		add.w	#4,d5
   		move.b	obj_size+2(a6),d4
   		lsl.w	#3,d4
;     		sub.w	#1,d4
   		sub.w	d4,d5			;UP SIZE
  		tst.w	d5
  		bmi	@no_col
 		move.w	lvl_size_y(a5),d4
 		lsl.w	#4,d4
 		cmp.w	d4,d5
 		bge	@no_col
 		
  		lsr.w	#4,d5
  		move.w	d5,d0
  		move.w	d5,d1
  		lsl.l	#8,d0			; LEFT 000YYY00
  		lsl.l	#8,d1			;RIGHT 000YYY00
 		mulu.w	lvl_size_x(a5),d5
  		adda	d5,a4

; ------------------------
; X check
; 
; LEFT
; ------------------------

 		moveq	#0,d4
		moveq	#0,d5
  		move.w	obj_x(a6),d5
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
      		cmp.w	d4,d5
      		blt.s	@dontfix_l
      		sub.w	#1,d5
@dontfix_l:
 		tst.w	d5
 		bmi.s	@zero_l
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		
 		swap	d5		; d5 - XRead | Free
 		move.b	obj_size(a6),d5
 		and.w	#$FF,d5		; d5 - XRead | Loop
 		tst.w	d5
 		beq.s	@zero_l
@Next_col_l:
 		swap	d5		; d5 - Loop | Xread
 		
 		tst.b	(a3)
 		beq.s	@No_col_l
 		move.w	d5,d4
 		and.w	#$FFF0,d4
 		swap	d4
 		or.l	d4,d1		; LEFT XXXYYY00
		move.b	(a3),d1
 		bra.s	@zero_l
@No_col_l:

 		sub.w	#8,d5
   		bpl.s	@Fine_l
   		clr.w	d5
@Fine_l:
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		; d5 - XRead | Loop
 		dbf	d5,@Next_col_l
@zero_l:
		
; ------------------------
; X check
; 
; RIGHT
; ------------------------

 		moveq	#0,d4
 		moveq	#0,d5
 		move.w	obj_x(a6),d5
 		sub.w	#1,d5
 		tst.w	d5
 		bmi.s	@no_col
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
   		cmp.w	d4,d5
    		bge.s	@no_col

 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		
 		swap	d5		;d5 - XRead | Free
 		move.b	obj_size+1(a6),d5
 		and.w	#$FF,d5		;d5 - XRead | Loop
 		tst.w	d5
 		beq.s	@no_col
 		
@Next_col_r:
 		swap	d5		;d5 - Loop | Xread
 		tst.b	(a3)
 		beq.s	@No_col_r
 		move.w	lvl_size_x(a5),d4
 		lsl.w	#4,d4
   		cmp.w	d4,d5
    		bge.s	@no_col
    		
 		move.w	d5,d4
 		and.w	#$FFF0,d4
 		swap	d4
 		or.l	d4,d0		; RIGHT XXXYYY00
		move.b	(a3),d0
 		rts
 		
@No_col_r:
 		add.w	#8,d5
 		move.w	d5,d4
 		lsr.w	#4,d4
 		movea.l	a4,a3
 		adda 	d4,a3
 		swap	d5		;d5 - XRead | Loop
 		dbf	d5,@Next_col_r
 		
; ------------------------

@no_col:
		rts
 	
; ************************
; Find Center collision
;
; Input:
; a6 - Object
; a5 - RAM_LvlPlanes
; a4 - Collision data
; 
; Output:
; d0 | LONG - Xpos|Ypos|ID $XXXYYYID
; 
; Uses:
; a3 | d4-d5
; ************************

; TODO: no agarra los X/Y

object_FindPrz_Center:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_prizes(a5),a4
  		bra.s	objSearchCol_Center
  		
object_FindCol_Center:
		lea	(RAM_LvlPlanes),a5
  		movea.l	lvl_collision(a5),a4

objSearchCol_Center:
		moveq	#0,d0
		moveq	#0,d4
		moveq	#0,d5
 		move.w	obj_y(a6),d4
 		tst.w	d4
 		bmi	@no_col
 		move.w	lvl_size_y(a5),d5
 		lsl.w	#4,d5
 		cmp.w	d5,d4
 		bge	@no_col
  		lsr.w	#4,d4
  		mulu.w	lvl_size_x(a5),d4
  		adda	d4,a4
  		and.l	#$FFF,d4
  		lsl.l	#8,d4
   		or.l	d4,d0

; ------------------------
		
  		movea.l	a4,a3
 		move.w	obj_x(a6),d4
 		tst.w	d4
 		bmi.s	@force_on
 		move.w	lvl_size_x(a5),d5
  		lsl.w	#4,d5
  		cmp.w	d5,d4
  		bge.s	@force_on
  		move.w	d4,d5
 		swap	d5
 		or.l	d5,d0			; XXXYYY00
 		lsr.w	#4,d4
 		adda 	d4,a3
  		
		tst.b	(a3)
		beq.s	@no_col		
		move.b	(a3),d0
		rts
@force_on:
		moveq	#0,d0
@no_col:
		rts
		
; ************************
; Sets a object in the floor
; DOWN/UP
; CENTER
; 
; Input:
; d0 - Floor ID
; (Object's current Ypos)
; 
; Output:
; d7 | LONG - Y speed result
; 
; Uses:
; a3-a4 | d3-d4
; ************************

object_SetCol_Floor:
		btst	#6,d0
		bne	@check_special
		cmp.b	#1,d0
		beq	@floorsolid
   		tst.l	d7
   		bmi.s	@NoCol
   		
   		move.l	obj_y(a6),d1
   		move.l	d1,d3
  		lea	(col_SlopeData),a3
  		and.w	#$3F,d0
  		move.w	d0,d1
  		lsl.w	#4,d1
  		adda	d1,a3
 		move.l	obj_x(a6),d0
 		swap	d0
 		and.w	#$F,d0
 		move.b	(a3,d0.w),d0
    		and.l	#$F,d0
    		and.l	#$FFF00000,d1
  		swap	d0
 		add.l	d0,d1
 		
; 		btst	#bitobj_air,obj_status(a6)
; 		beq.s	@dontchk
  		add.l	d7,d3
  		cmp.l	d1,d3
  		blt.s	@NoCol
@dontchk:
  		move.l	d1,obj_y(a6)	; TODO: REPARAME
  		
   		bclr	#bitobj_air,obj_status(a6)
 		clr.l	d7
     		tst.l	d6
     		beq.s	@NoCol
    		move.l	#$10000,d7
@NoCol:
		rts

@floorsolid:
		bclr	#bitobj_air,obj_status(a6)	
		and.l	#$FFF80000,obj_y(a6)		; TODO: REPARAME
		clr.l	d7
		rts

; ---------------------
; Check $80+ collision
; Floor
; ---------------------

@check_special:
		rts
		
; ************************
; Sets collision on the object
; Ceiling
; 
; Input:
; d0 - Floor ID
; 
; Output:
; d7 | LONG - Y speed result
; 
; Uses:
; a3-a4 | d3-d4
; ************************

object_SetCol_Ceiling:
		btst	#6,d0
		bne	@floorsolid
		cmp.b	#1,d0
		beq	@floorsolid
;    		tst.l	d7
;    		bpl.s	@NoCol
   		
;    		move.l	obj_y(a6),d1
;    		move.l	d1,d3
;   		lea	(col_SlopeData),a3
;   		and.w	#$3F,d0
;   		move.w	d0,d1
;   		lsl.w	#4,d1
;   		adda	d1,a3
;  		move.l	obj_x(a6),d0
;  		swap	d0
;  		and.w	#$F,d0
;  		move.b	(a3,d0.w),d0
;     		and.l	#$F,d0
;     		and.l	#$FFF00000,d1
;   		swap	d0
;  		add.l	d0,d1
;  		
; ; 		btst	#bitobj_air,obj_status(a6)
; ; 		beq.s	@dontchk
;   		add.l	d7,d3
;   		cmp.l	d1,d3
;   		blt.s	@NoCol
; @dontchk:
;   		move.l	d1,obj_y(a6)	; TODO: REPARAME
;   		
;    		bclr	#bitobj_air,obj_status(a6)
;  		clr.l	d7
;      		tst.l	d6
;      		beq.s	@NoCol
;     		move.l	#$10000,d7
; @NoCol:
; 		rts
; 
@floorsolid:
		clr.l	d7
		bset	#bitobj_air,obj_status(a6)
		and.l	#$FFF80000,obj_y(a6)
		moveq	#0,d4
		move.b	obj_size+3(a6),d4
		lsl.w	#3,d4
		add.w	d4,obj_y(a6)
@NoCol:
		rts
		
; ************************
; Sets a object in the wall
; LEFT/RIGHT
; CENTER
; 
; Input:
; d0 - Floor ID
; (Object's current Ypos)
; 
; Output:
; d7 | LONG - Y speed result
; 
; Uses:
; a3-a4 | d3-d4
; ************************

; TODO: para que mierdas era esto

object_SetCol_Wall:
; 		move.w	obj_y(a6),d1		;TODO: REPARAME
; 		sub.w	#1,d1
; 		move.w	d1,d3
; 		and.w	#$FFF0,d1 		
;      		lea	(col_SlopeData),a3
;       		and.w	#$FF,d0
;      		lsl.w	#4,d0
;       		adda	d0,a3
;       		move.w	obj_x(a6),d0
;       		and.w	#$F,d0
;       		move.b	(a3,d0.w),d2
;       		and.w	#$F,d2
;       		add.w	d2,d1
;       		
;  		btst	#bitobj_air,obj_status(a6)
; 		beq.s	@dontchkLR
;   		cmp.w	d1,d3
;   		blt.s	@NoCol_LR
; @dontchkLR:
;    		move.w	d1,obj_y(a6)		;TODO: REPARAME

@NoCol_LR:
		rts
	
; **********************************************
; Object interaction
; **********************************************

; ----------------------------------
; objTouch
; 
; touch/hit detection
; 
; Uses: d0-d4
; ----------------------------------

objTouch:
		bsr	objTouch_Top
		move.w	d0,d3
		bsr	objTouch_Bottom
		or.w	d0,d3
		bsr	objTouch_Sides
		or.w	d0,d3
		swap	d0
		or.w	d0,d3
		move.w	d3,d0
		rts
		
; ---------------------------
; Seperate touches
; ---------------------------

objTouch_Top:
		clr.b	d0
		lea	(RAM_ObjBuffer),a4
		moveq	#16-1,d4
@check_again:
		tst.l	obj_code(a4)
		beq	@notfound
		btst	#bitobj_hit,obj_status(a4)
		beq.s	@notfound
		
;  		tst.l	obj_y_spd(a4)
;  		bmi.s	@lowrY
;  		btst	#bitPlyrClimb,plyr_status(a4)
;  		bne.s	@lowrY
		moveq	#0,d1
		
		; Check LEFT
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d1
   		move.w	obj_x(a4),d2
    		swap	d1
   		move.b	obj_size+1(a4),d1
   		lsl.w	#3,d1
      		add.w	d1,d2
    		swap	d1
   		cmp.w	d2,d1
   		bge.s	@lowrY
   		; Check RIGHT
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size+1(a6),d2
   		lsl.w	#3,d2
   		add.w	d2,d1
   		move.w	obj_x(a4),d2
    		swap	d1
   		move.b	obj_size(a4),d1
   		lsl.w	#3,d1
		sub.w	d1,d2
    		swap	d1
    		cmp.w	d2,d1
    		ble.s	@lowrY

    		; Check Top, and $C pixels more
   		move.w	obj_y(a6),d1
   		moveq	#0,d2
   		move.b	obj_size+2(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d1
   		swap	d1
   		move.w	obj_y(a4),d2
   		move.b	obj_size+3(a4),d1
   		lsl.w	#3,d1
   		add.w	d1,d2
   		swap	d1
   		cmp.w	d2,d1
   		bgt.s	@lowrY
     		add.w	#$C,d1
    		cmp.w	d2,d1
    		blt.s	@lowrY
    		
   		move.b	#1,d0
@lowrY:

		tst.b	d0
		bne	@wecanhurt
@notfound:
		adda	#sizeof_obj,a4
		dbf	d4,@check_again
@wecanhurt:
   		rts
   		
; ----------------------------------

objTouch_Bottom:
		clr.b	d0
		lea	(RAM_ObjBuffer),a4
		moveq	#16-1,d4
@check_again:
		tst.l	obj_code(a4)
		beq	@notfound
		btst	#bitobj_hit,obj_status(a4)
		beq	@notfound
		
;  		tst.l	obj_y_spd(a4)
;  		bmi.s	@lowrY
;  		btst	#bitPlyrClimb,plyr_status(a4)
;  		bne.s	@lowrY
		moveq	#0,d1
		
		; Check LEFT
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d1
   		move.w	obj_x(a4),d2
    		swap	d1
   		move.b	obj_size+1(a4),d1
   		lsl.w	#3,d1
      		add.w	d1,d2
    		swap	d1
   		cmp.w	d2,d1
   		bge.s	@lowrY
   		; Check RIGHT
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size+1(a6),d2
   		lsl.w	#3,d2
   		add.w	d2,d1
   		move.w	obj_x(a4),d2
    		swap	d1
   		move.b	obj_size(a4),d1
   		lsl.w	#3,d1
		sub.w	d1,d2
    		swap	d1
    		cmp.w	d2,d1
    		ble.s	@lowrY

    		; Check Top, and $C pixels more
   		move.w	obj_y(a6),d1
   		moveq	#0,d2
   		move.b	obj_size+3(a6),d2
   		lsl.w	#3,d2
   		add.w	d2,d1
   		swap	d1
   		move.w	obj_y(a4),d2
   		move.b	obj_size+2(a4),d1
   		lsl.w	#3,d1
   		sub.w	d1,d2
   		swap	d1
   		cmp.w	d1,d2
   		bgt.s	@lowrY
     		sub.w	#$C,d1
    		cmp.w	d1,d2
    		blt.s	@lowrY
    		
   		move.b	#1,d0
@lowrY:

		tst.b	d0
		bne	@wecanhurt
@notfound:
		adda	#sizeof_obj,a4
		dbf	d4,@check_again
@wecanhurt:
   		rts

; ----------------------------------

objTouch_Sides:
		moveq	#0,d0
		lea	(RAM_ObjBuffer),a4
		moveq	#16-1,d4
@check_again:
		tst.l	obj_code(a4)
		beq	@notfound
		btst	#bitobj_hit,obj_status(a4)
		beq	@notfound
		
;  		btst	#bitPlyrClimb,plyr_status(a4)
;  		bne	@lowrY
 		
     		moveq	#0,d1
   		moveq	#0,d2
    		move.w	obj_y(a6),d1
    		moveq	#0,d2
    		move.b	obj_size+2(a6),d2
    		lsl.w	#3,d2
    		sub.w	d2,d1
    		swap	d1
    		move.w	obj_y(a4),d2
    		move.b	obj_size+3(a4),d1
    		lsl.w	#3,d1
    		add.w	d1,d2
    		swap	d1
    		cmp.w	d2,d1
    		bgt	@lowrY
    		
    		move.w	obj_y(a6),d1
    		moveq	#0,d2
    		move.b	obj_size+3(a6),d2
    		lsl.w	#3,d2
    		add.w	d2,d1
    		swap	d1
    		move.w	obj_y(a4),d2
    		move.b	obj_size+2(a4),d1
    		lsl.w	#3,d1
    		sub.w	d1,d2
    		swap	d1
    		cmp.w	d2,d1
    		blt	@lowrY

     		; X Sides check
     		moveq	#0,d1
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size+1(a6),d2
   		lsl.w	#3,d2
   		add.w	d2,d1
   		move.l	obj_x(a4),d2
   		add.l	obj_x_spd(a4),d2
   		swap	d2
    		swap	d1
    		move.b	obj_size(a4),d1
     		lsl.w	#3,d1
     		sub.w	d1,d2
     		swap	d1
    		cmp.w	d1,d2
    		bgt.s	@lowrY_L
    		sub.w	#8,d1
    		cmp.w	d1,d2
    		blt.s	@lowrY_L 
    		move.w	#1,d0

@lowrY_L:
     		swap	d0
     		moveq	#0,d1
   		moveq	#0,d2
   		move.w	obj_x(a6),d1
   		move.b	obj_size(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d1
   		move.w	obj_x(a4),d2
    		swap	d1
    		move.b	obj_size+1(a4),d1
    		lsl.w	#3,d1
    		add.w	d1,d2
    		swap	d1
   		cmp.w	d2,d1
   		bgt.s	@lowrY
   		add.w	#8,d1
   		cmp.w	d2,d1
   		blt.s	@lowrY 
   		move.w	#1,d0
@lowrY:
		
		tst.l	d0
		bne	@wecanhurt
@notfound:
		adda	#sizeof_obj,a4
		dbf	d4,@check_again
@wecanhurt:
   		rts
   			
; ----------------------------------

objPlyrSetFloor:
		lea	(RAM_ObjBuffer),a4
		tst.l	obj_y_spd(a4)
		bmi.s	@return
		btst	#bitPlyrClimb,plyr_status(a4)
		bne.s	@return
; 		lea	(RAM_LvlPlanes),a5
		
   		clr.l	obj_y_spd(a4)
 		move.w	obj_y(a6),d0
 		move.w	d0,d1
   		moveq	#0,d2
   		move.b	obj_size+2(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d0
   		moveq	#0,d2
   		move.b	obj_size+3(a4),d2
   		lsl.w	#3,d2
   		sub.w	d2,d0
;    		cmp.w	d0,d1
;    		blt.s	@lowrY
   		move.l	#$10000,obj_y_spd(a4)
; @lowrY:
   		move.w	d0,obj_y(a4)
   		
; 		bsr	object_PlyrFlgs_floor
     		bclr	#bitobj_air,obj_status(a4)
     		bset	#bitcol_obj,obj_col(a4)
		btst	#bitJoyC,(RAM_Control_1+OnHold)
		bne	@return
    		move.w	#varJumpTimer,plyr_jumptmr(a4)
@return:
   		rts
  	
; ----------------------------------

objPlyrSetCeiling:
		lea	(RAM_ObjBuffer),a4
		btst	#bitPlyrClimb,plyr_status(a4)
		bne.s	@return
		lea	(RAM_LvlPlanes),a5
		clr.l	obj_y_spd(a4)
     		bset	#bitobj_air,obj_status(a4)
;      		bset	#bitcol_obju,obj_col(a4)
     		
;      		bset	#bitcol_floor,obj_col(a4)
;  		move.w	obj_y(a6),d0
;    		moveq	#0,d2
;    		move.b	obj_size+2(a6),d2
;    		lsl.w	#3,d2
;    		sub.w	d2,d0
;    		move.w	d0,obj_y(a4)
@return:
   		rts
   		
; ----------------------------------

objPlyrSetWall_R:
		lea	(RAM_ObjBuffer),a4
		btst	#bitPlyrClimb,plyr_status(a4)
		bne.s	objPlyrColReturn
		lea	(RAM_LvlPlanes),a5
		clr.l	obj_x_spd(a4)
     		bset	#bitcol_wall_r,obj_col(a4)
 		move.w	obj_x(a6),d0
   		moveq	#0,d2
   		move.b	obj_size(a6),d2
   		lsl.w	#3,d2
   		sub.w	d2,d0
   		moveq	#0,d2
   		move.b	obj_size+1(a4),d2
   		lsl.w	#3,d2
   		sub.w	d2,d0
   		bra.s	objPlyrSetWLX
		
; ----------------------------------

objPlyrSetWall_L:
		lea	(RAM_ObjBuffer),a4
		btst	#bitPlyrClimb,plyr_status(a4)
		bne.s	objPlyrColReturn
		lea	(RAM_LvlPlanes),a5
		clr.l	obj_x_spd(a4)
     		bset	#bitcol_wall_l,obj_col(a4)
 		move.w	obj_x(a6),d0
;  		add.w	#1,d0
   		moveq	#0,d2
   		move.b	obj_size+1(a6),d2
   		lsl.w	#3,d2
   		add.w	d2,d0
   		
   		moveq	#0,d2
   		move.b	obj_size(a4),d2
   		lsl.w	#3,d2
   		add.w	d2,d0
objPlyrSetWLX:
   		tst.w	d0
   		bpl.s	@plus_x
   		clr.w	d0
@plus_x:
		move.w	lvl_size_x(a5),d2
		lsl.w	#4,d2
		cmp.w	d2,d0
		blt.s	@plusr_x
		move.w	d2,d0
@plusr_x:
   		move.w	d0,obj_x(a4)
objPlyrColReturn:
   		rts
   		
; ----------------------------------
; What to do if object touched the
; player
; 
; Input:
; a4 - Player object
; 
; Uses:
; d4
; 
; Returns:
; beq.s Nothing
; bne.s Touched
; ----------------------------------

objPlyrHurtKill:
		moveq	#0,d4
		move.l	a4,d0
		cmp.l	#RAM_ObjBuffer,d0	; Player?
		bne.s	@settrue
		bclr	#bitobj_hurt,obj_status(a4)
		cmp.b	#varPlyrMdDead,obj_index(a4)
		beq.s	@return
		bset	#bitobj_hurt,obj_status(a4)
		cmp.b	#varPlyAniJump,obj_anim_id(a4)
		beq.s	@stomppikudo
 		btst	#bitobj_air,obj_status(a4)
 		bne.s	@stomppikudo
		bra.s	@return
		
@stomppikudo:
		btst	#bitcol_obj,obj_col(a4)
		bne.s	*;@return
 		tst.l	obj_y_spd(a4)
		bmi.s	@return
		beq.s	@return	
@hurtanywy:
		bclr	#bitobj_hurt,obj_status(a4)
@settrue:
		moveq	#1,d4
@return:
		tst.w	d4
		rts
		
; Object_ChkPlyrHit:
; 		lea	(RAM_ObjBuffer),a4
; 		moveq	#0,d5
; 		cmp.b	#varPlyAniJump,obj_anim_id(a4)
; 		bne.s	@objhit
; 		moveq	#-1,d5
; @objhit:
; 		tst.w	d5
; 		rts

; ----------------------------------
; Prize ceiling action
; 
; Output:
; d4 - Collision out
; ----------------------------------

Object_PrzActionCeil:
		lea	(RAM_LvlPlanes),a5
		moveq	#0,d5
		move.b	d0,d5
		btst	#7,d5
		bne.s	@its_hidden
		add.w	d5,d5
		move.w	@block_list(pc,d5.w),d6
		jmp	@block_list(pc,d6.w)
		
; --------------------------
; Reveral hidden block
; --------------------------

@its_hidden:
 		bsr	Prize_Locate
 		and.b	#$7F,d0
 		move.b	d0,(a3)
 		
;  		bsr	Level_HidePrize
		lea	(RAM_ObjBuffer+(sizeof_obj*8)),a4
		movea.l	a4,a3
		move 	#8-1,d1
@chksame2:
		cmp.l	obj_ram(a3),d0
		beq	@solidblock
		adda 	#sizeof_obj,a3
		dbf	d1,@chksame2	

		move 	#4-1,d1
@next_obj2:
		tst.l	obj_code(a4)
		beq.s	@free2
		adda	#sizeof_obj,a4
		dbf	d1,@next_obj2
		bra.s	@ranout2
@free2:
 		bsr	blkobj_setcoords
		move.b	#1,obj_subid(a4)
		move.l	#obj_prize,obj_code(a4)
		move.l	d0,obj_ram(a4)
		
  		move.l	#SndSfx_BONK,d0
  		move.w 	#3,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
@ranout2:
; 		moveq	#0,d4
 		rts
 		
; ----------------------------------

@block_list:
		dc.w 0
		dc.w @break_block-@block_list
		dc.w @bump_1coin-@block_list
		dc.w @bump_10coin-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @bump_1up-@block_list
		dc.w @bump_1coin-@block_list
		dc.w @bump_10coin-@block_list
		dc.w @bump_1up-@block_list
		dc.w @bump_block-@block_list
		dc.w @bump_block-@block_list
		dc.w @bump_block-@block_list
		dc.w @bump_block-@block_list
		dc.w @bump_block-@block_list
		
		dc.w @break_block-@block_list	
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list	
		dc.w @break_block-@block_list
		
		dc.w @trampoline-@block_list	
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list	
		dc.w @break_block-@block_list
		
		dc.w @break_block-@block_list	
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list
		dc.w @break_block-@block_list	
		dc.w @break_block-@block_list
		
		dc.w @coin_red-@block_list
		dc.w @coin_blue-@block_list
		
; ----------------------------------
; Normal breakable block
; ----------------------------------

@break_block:
		bsr	@chk_breakblk
		bne.s	@oops
 		bsr	Prize_Delete
 		bsr	blkobj_overwrite
		
		bsr	blkobj_setcoords
		move.l	d0,obj_ram(a4)
		clr.b	obj_subid(a4)
		move.l	#obj_prize,obj_code(a4)
		
  		move.l	#SndSfx_PUM,d0
  		move.w 	#4,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
@oops:
  		moveq	#1,d4
  		move.l	#$10000,d7
  		rts
		
; ----------------------------------
; BUMP block
; ----------------------------------

@bump_1coin:
		moveq	#1,d3
		bra.s	@bump_coinarg
@bump_10coin:
		moveq	#10,d3
		bra.s	@bump_coinarg

; ----------------------------------

@bump_block:
		moveq	#0,d3
@bump_coinarg:
		bsr	blkobj_chkdupl
		bne.s	@oops

		bsr	blkobj_overwrite
 		bsr	blkobj_setcoords
		move.l	d0,d2
		move.l	d0,obj_ram(a4)
		move.b	#1,obj_subid(a4)
		tst.b	d3
		beq.s	@noexsubid
		move.b	#2,obj_subid(a4)
		cmp.b	#10,d3
		bne.s	@noexsubid
		move.b	#3,obj_subid(a4)
@noexsubid:

		cmp.b	#$F,d2
		beq.s	@SolidOnly
		add.w	d3,(RAM_P1_Coins)
  		cmp.w	#100,(RAM_P1_Coins)
  		blt.s	@dontadd1up2
  		clr.w	(RAM_P1_Coins)
  		add.w	#1,(RAM_P1_Lives)
@dontadd1up2:

; 		add.b	#1,obj_subid(a4)
@SolidOnly:
		move.l	#obj_prize,obj_code(a4)

  		move.l	#SndSfx_BonkCoin,d0
  		moveq 	#2,d1
  		
		cmp.b	#$F,d2
		bne.s	@Alt_Sfx
  		move.l	#SndSfx_BONK,d0
  		move.w 	#3,d1
  		cmp.w	#10,d3
  		bne.s	@Alt_Sfx
  		moveq	#1,d1
@Alt_Sfx:
		moveq	#1,d2
  		bsr	Audio_Track_play
  		
		bra.s	@solidblock
		
; ----------------------------------

@bump_1up:
		bsr	blkobj_chkdupl
		bne	@oops

		bsr	blkobj_overwrite
 		bsr	blkobj_setcoords
		move.l	d0,d2
		move.l	d0,obj_ram(a4)
		move.b	#4,obj_subid(a4)
		add.w	#1,(RAM_P1_Lives)
		move.l	#obj_prize,obj_code(a4)
		
		;TODO: 1up sound
		
@solidblock:
  		moveq	#1,d4
  		move.l	#$10000,d7
  		rts
  		
; ----------------------------------
; A Coin, from top
; ----------------------------------

@coin_red:
		moveq	#1,d4
		bra.s	@setcoin
@coin_blue:
		moveq	#5,d4
@setcoin:
		add.w	d4,(RAM_P1_Coins)
  		cmp.w	#100,(RAM_P1_Coins)
  		blt.s	@dontadd1up
  		clr.w	(RAM_P1_Coins)
  		add.w	#1,(RAM_P1_Lives)
@dontadd1up:
  		
 		bsr	Prize_Delete
		bsr	Level_HidePrize
  		
  		move.l	#SndSfx_COIN,d0
  		moveq 	#2,d1
  		moveq	#1,d2
  		bsr	Audio_Track_play
		moveq	#0,d4		
		rts
		
; ----------------------------------
; Normal breakable block
; ----------------------------------

@trampoline:
		bsr	goToTrampolineWhy
		
		lea	(RAM_ObjBuffer),a4
		move.l	#$80000,d7
		rts
		
; -------------------------------
; check for active object
; d2 - sub-id
; -------------------------------

@chk_breakblk:
		moveq	#1,d2
		moveq	#0,d4
		lea	(RAM_ObjBuffer+(sizeof_obj*8)),a4
		movea.l	a4,a3
		moveq 	#8-1,d1
@checkhdnbmp:
		cmp.l	#obj_prize,obj_code(a3)
		bne.s	@notprz
		cmp.b	obj_subid(a3),d2
		bne.s	@notprz
		moveq	#1,d4
		moveq	#0,d1
@notprz:
		adda 	#sizeof_obj,a3
		dbf	d1,@checkhdnbmp
		tst.w	d4
		rts

; -------------------------------
; check for duplicate object
; using obj_ram
; -------------------------------

blkobj_chkdupl:
		moveq	#0,d4
		lea	(RAM_ObjBuffer+(sizeof_obj*8)),a4
		moveq 	#8-1,d1
@chksame234:
 		cmp.l	obj_ram(a4),d0
 		bne.s	@notequl
 		add.w	#1,d4
@notequl:
 		adda 	#sizeof_obj,a4
 		dbf	d1,@chksame234
 		tst.w	d4
 		rts
 		
; -------------------------------
; Overwrite prize object if its
; the same
; -------------------------------

blkobj_overwrite:
		moveq	#0,d4
		lea	(RAM_ObjBuffer+(sizeof_obj*8)),a4
		moveq 	#8-1,d1
@chksame23:
 		cmp.l	obj_ram(a4),d0
 		bne	@notsame
 		
 		movea.l	a4,a3
 		move.w	#sizeof_obj-1,d2
@delete:
 		clr.b	(a3)+
 		dbf	d2,@delete
@notsame:
		cmp.l	#obj_prize,obj_code(a4)
		bne.s	@found
 		adda 	#sizeof_obj,a4
 		dbf	d1,@chksame23
@found:
		rts
		
; ----------------------------------
; obj_coords
; ----------------------------------

blkobj_setcoords:
		move.l	d0,d4
		lsr.l	#4,d4
		and.w	#$FFF0,d4
 		add.w	#8,d4
 		move.w	d4,obj_y(a4)
		lsr.l	#8,d4
		lsr.l	#4,d4
		and.w	#$FFF0,d4
 		add.w	#8,d4
 		move.w	d4,obj_x(a4)
 		
		movea.l	lvl_przblocks(a5),a0
		move.w	d0,d4
		and.w	#$FF,d4
		lsl.w	#3,d4
		move.w	(a0,d4.w),d4
		move.w	d4,obj_ram+4(a4)
 		rts
 	
goToTrampolineWhy:
		bsr	blkobj_chkdupl
		bne	@oopstr

		bsr	blkobj_overwrite
 		bsr	blkobj_setcoords
		move.l	d0,obj_ram(a4)
		move.b	#5,obj_subid(a4)
		move.l	#obj_prize,obj_code(a4)
		bsr	Level_HidePrize
@oopstr:
		moveq	#1,d4
		rts
		
; ----------------------------------
; block subs
; 
; d0 - XXXYYYID
; a5 - RAM_LvlPlanes
; ----------------------------------

Prize_Locate:
		movea.l	lvl_prizes(a5),a3
		move.l	d0,d4
		lsr.l	#8,d4
		and.l	#$FFF,d4
		mulu.w	lvl_size_x(a5),d4
		adda	d4,a3
		move.l	d0,d4
		swap	d4
		lsr.w	#4,d4
		and.l	#$FFF,d4
		adda	d4,a3
		rts
		
Prize_Delete:
		bsr.s	Prize_Locate
		clr.b	(a3)
		rts
		
; **********************************************
; Object action
; **********************************************

; ---------------------------
; Object action: mark 
; stomped by player
; 
; Input:
; d0 | LONG - Mappings
; d1 | WORD - VRAM
; d2 | BYTE - Frame
; a4 | Object who touched it
; ---------------------------

objAction_SetStomp:
		clr.b	obj_index(a6)		; Clear index
		clr.b	obj_subid(a6)		; Subaction: Stomp
		move.l	d0,obj_ram(a6)		; Last frame
		move.w	d1,obj_ram+4(a6)
		move.b	d2,obj_ram+6(a6)
		move.l	d3,obj_ram+8(a6)
		move.l	#obj_actionscript,obj_code(a6)
		rts
		
; =================================================================
; --------------------------------------------
; Includes
; --------------------------------------------

  		include	"engine/modes/level/data/objects/player/code.asm"
   		include	"engine/modes/level/data/objects/dadou/code.asm"
   		include	"engine/modes/level/data/objects/pikudo/code.asm"
   		include	"engine/modes/level/data/objects/platform/code.asm"
   		include	"engine/modes/level/data/objects/prize/code.asm"
    		include	"engine/modes/level/data/objects/ball/code.asm" 
   		include	"engine/modes/level/data/objects/endflag/code.asm"
    		include	"engine/modes/level/data/objects/actionscript/code.asm"  
    		include	"engine/modes/level/data/objects/hudinfo/code.asm"  
    		
