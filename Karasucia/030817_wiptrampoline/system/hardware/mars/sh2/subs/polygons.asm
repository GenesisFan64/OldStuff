; ====================================================================
; Polygons system
; ====================================================================

; -------------------------------------------------
; Model format
; 
; Faces:
; dc.w TYPE (3/4)
; dc.w Material/Color
; dc.w ... Points (3 or 4)
; 
; Vertices:
; dc.w X,Y,Z
; 
; Material:
; TODO
; -------------------------------------------------

; -------------------------------------------------
; Variables
; -------------------------------------------------

MAX_POLYGONS	equ	512		; 128 normal
MAX_MODELS	equ	32
MAX_DDALIST	equ	64
SCREEN_WIDTH	equ	320+128		; framebuffer X size
SCREEN_WDTHVIEW	equ	320		; view X size (always 320)
SCREEN_HEIGHT	equ	224
CODE_OLDRENDER	equ	0

; ------------------------------------

		rsreset
POINT_X		rs.l	1
POINT_Y		rs.l	1
SIZEOF_POINT	rs.l	0

; ------------------------------------

		rsreset
DDA_DST_X	rs.l	1
DDA_DST_DX	rs.l	1
DDA_DST_H	rs.l	1
DDA_SRC_X	rs.l	1
DDA_SRC_DX	rs.l	1
DDA_SRC_Y	rs.l	1
DDA_SRC_DY	rs.l	1
DDA_DST_POINT	rs.l	1
DDA_DST_HIGH	rs.l	1
DDA_DST_LOW	rs.l	1
DDA_SRC_POINT	rs.l	1
DDA_SRC_LOW	rs.l	1
DDA_SRC_HIGH	rs.l	1
DDA_EXIT_FLAG	rs.l	1
sizeof_dda	rs.l	0


; ------------------------------------

		rsreset
DDAL_SRC_LX	rs.l	1
DDAL_SRC_LY	rs.l	1
DDAL_DST_LX	rs.l	1
DDAL_SRC_RX	rs.l	1
DDAL_SRC_RY	rs.l	1
DDAL_DST_RX	rs.l	1
DDAL_BUSY	rs.l	1
sizeof_ddalist	rs.l	0
		
; ------------------------------------

		rsreset
TML_SRC_TXTR	rs.l	1
TML_SRC_TXTWDH	rs.l	1
TML_DDA_ENTRY	rs.l	1
TML_DDA_COUNT	rs.l	1
TML_SRC_LX	rs.l	1
TML_SRC_LY	rs.l	1
TML_SRC_RX	rs.l	1
TML_SRC_RY	rs.l	1
TML_DST_LX	rs.l	1
TML_DST_RX	rs.l	1
TML_DST_Y	rs.l	1
TML_BOTTOM_Y	rs.l	1
TML_FLAGS	rs.l	1
sizeof_tml	rs.l	0

; ------------------------------------
		
		rsreset
ppnt_x		rs.l 1
ppnt_y		rs.l 1
ppnt_z		rs.l 1
sizeof_ppnt	rs.l 0

; ------------------------------------
; Playfield buffer
; ------------------------------------
		
		rsreset
plyfld_x	rs.l 1
plyfld_y	rs.l 1
plyfld_z	rs.l 1
plyfld_layout	rs.l 1
plyfld_material	rs.l 1
sizeof_plyfld	rs.l 0

; ------------------------------------
; Models buffer
; ------------------------------------

		rsreset
model_addr	rs.l 1
model_x		rs.l 1
model_y		rs.l 1
model_z		rs.l 1
model_x_rot	rs.l 1
model_y_rot	rs.l 1
model_z_rot	rs.l 1
model_flags	rs.l 1				; 0 - normal, 1 - world algorithm NOT DONE
sizeof_model	rs.l 0

; ------------------------------------
; 3D Face
; ------------------------------------

		rsreset
face_type	rs.l 1			; polygon(3) quad(4)
face_texture	rs.l 1			; texture data, if -1 = solid color mode
face_texwidth	rs.l 1			; texture add | width / color $00-$FF
face_texsrc	rs.l 2*4		; texture source points
face_points	rs.l 3*4		; x/y/z points (with perspective)
sizeof_plygn	rs.l 0

; ------------------------------------

		rsset RAM_PolygonSys
plyfield_buffer	rs.b sizeof_plyfld
models_buffer	rs.b sizeof_model*MAX_MODELS
polygon_out	rs.b sizeof_plygn*MAX_POLYGONS		; one list to read (X/Y/Z gone)
polygon_z_list	rs.l MAX_POLYGONS*2

; ----------------------------------

polygon_list 	rs.l MAX_POLYGONS
DDA_List 	rs.b (sizeof_dda*2)*224			; 224 or 240
TML_data_M	rs.b sizeof_tml
TML_data_S	rs.b sizeof_tml
DDA_Left	rs.b sizeof_dda				; DONT SEPARATE
DDA_Right 	rs.b sizeof_dda				; THESE

mdltask_slave	rs.l 1
polygon_len	rs.l 1
sizeof_this	rs.l 0

; ------------------------------------
; NOTE: quitarlo si MAX_POLYGONS es mas de 1024

		rsset $C0000000
face_dest	rs.l 2*4		; screen dest points

; ------------------------------------

; 		inform 0,"Polygons system: %h %h",RAM_PolygonSys,sizeof_this-RAM_PolygonSys
;    		inform 0,"%h %h",polygon_list,polygon_z_list
		
; ====================================================================
; -------------------------------------------------
; Polygons
; 
; Master side
; -------------------------------------------------

Polygons_Read:
		mov	pr,@-r15

		mov	#polygon_len,r1
		mov	#0,r0
		mov	r0,@r1
		
; --------------------------------
; Draw the faces
; --------------------------------		

		mov	#models_buffer,r14
 		mov	#polygon_out,r13
		mov	#MAX_MODELS,r12
@next_model:
		mov	@(model_addr,r14),r0
		cmp/pl	r0
		bf	@skip_model
		mov	r12,@-r15
		
; --------------------------------
; Read model, set faces
; --------------------------------

		bsr	Model_Read
		nop

; --------------------------------
; Next model
; --------------------------------

		mov	@r15+,r12
@skip_model:
		add 	#sizeof_model,r14
		dt	r12
		bf	@next_model
		
; --------------------------------
; Draw the faces
; --------------------------------

		bsr	Polygon_ZSort
		nop

		bsr	Polygon_Draw
		nop
		
; --------------------------------
; Exit
; --------------------------------

@exit_all:
		mov	#polygon_len,r1
		mov	@r1,r0
		mov.w	r0,@(comm14,gbr)
		
		mov 	@r15+,pr
		rts
		nop
		align	4
		lits
	
; ====================================================================
; -------------------------------------------------
; Subs MASTER
; -------------------------------------------------

; *******************************
; Polygon
; *******************************

; -------------------------------
; Draw_Texture
; 
; Input:
; r1 - Dest points
; r2 - Type 3 or 4
; r3 - Texture or Solid color
; r4 - Texture ADD | Texture WIDTH
; r5 - Source points
;
; Uses:
; r0-r13 MASTER + SLAVE
; -------------------------------

Draw_Texture:
		mov	pr,@-r15
		
		mov	#TML_data_M,r8
		mov	r3,@(TML_SRC_TXTR,r8)
 		mov	r4,@(TML_SRC_TXTWDH,r8)
		
		bsr	Preinit_DDA
		nop

		cmp/eq	r5,r6
		bt	@exit;_old
		
 		mov	#TML_data_M,r1
		cmp/pl	r6
		bt	@not_top
		mov	#-1,r5	
@not_top:	
		cmp/gt	r5,r6
		bf	@exit;_old	
		mov	r5,@(tml_dst_y,r1)
		add	#1,r6
		mov	r6,@(tml_bottom_y,r1)

		mov	#DDA_Left,r6
		bsr	Init_DDA
		nop
		mov	#DDA_Right,r6
		bsr	Init_DDA
		nop
		
; ---------------------------------
; line loop
; ---------------------------------

; 		mov	#TML_data_M,r1
; 		mov 	@(tml_bottom_y,r1),r0
; 		cmp/pz	r0
; 		bt	@SuperRender
; 		
; @loop_old:
; 		mov	#TML_data_M,r11
; 		
;  		mov	#DDA_Right,r8
;  		bsr	Update_DDA_Right
;  		nop
; 		mov	#DDA_Left,r8
; 		bsr	Update_DDA_Left
;  		nop
;  
;  		mov	@(TML_DST_Y,r11),r0
; 		cmp/pz	r0
; 		bf	@bad_y_old
; 		mov	#DDA_Left,r3
; 		mov	@(DDA_SRC_X,r3),r7
;  		mov	@(DDA_SRC_Y,r3),r5
;  		mov	@(DDA_DST_X,r3),r8
; 		mov	#DDA_Right,r3
; 		mov	@(DDA_SRC_X,r3),r6
; 		mov	@(DDA_SRC_Y,r3),r4
; 		mov	@(DDA_DST_X,r3),r9
; 		bsr	Texture_Map_Line
;  		nop
; @bad_y_old:
; 		mov	@(TML_DST_Y,r11),r0
; 		add	#1,r0
; 		mov	r0,@(TML_DST_Y,r11)
; 
; 		mov	#SCREEN_HEIGHT,r1
; 		cmp/gt	r1,r0
; 		bt	@exit
; 		mov	@(TML_BOTTOM_Y,r11),r1
; 		cmp/ge	r1,r0
; 		bt	@loop_old
; 
; @exit_old:
; 		bra	@exit
; 		nop
		
; --------------------------
; NEW render (MASTER+SLAVE)
; --------------------------

@SuperRender:
  		mov	#mdltask_slave,r1
@wait:  	mov 	@r1,r0
  		cmp/eq	#0,r0
  		bf	@wait
  		
 		mov	#DDA_List,r10
		mov	#TML_data_M,r11
 		mov	@(TML_DST_Y,r11),r9
@loop:
 		mov	#DDA_Right,r8
 		bsr	Update_DDA_Right
 		nop
		mov	#DDA_Left,r8
		bsr	Update_DDA_Left
 		nop

		cmp/pz	r9
		bf	@bad_y
		mov	#224,r1
		cmp/gt	r1,r9
		bt	@endquik
	
		mov 	#DDA_Left,r0
 		mov	@(DDA_SRC_X,r0),r1
 		mov	@(DDA_SRC_Y,r0),r2
 		mov	@(DDA_DST_X,r0),r3
		mov 	#DDA_Right,r0
		mov	@(DDA_SRC_X,r0),r4
		mov	@(DDA_SRC_Y,r0),r5
		mov	@(DDA_DST_X,r0),r6
 		mov	r1,@(DDAL_SRC_LX,r10)
 		mov	r2,@(DDAL_SRC_LY,r10)
 		mov	r3,@(DDAL_DST_LX,r10)
		mov	r4,@(DDAL_SRC_RX,r10)
		mov	r5,@(DDAL_SRC_RY,r10)
		mov	r6,@(DDAL_DST_RX,r10)
		mov 	#0,r0
		mov 	r0,@(DDAL_BUSY,r10)
		mov 	#sizeof_ddalist,r0
		add 	r0,r10
		
; 		mov	#(sizeof_dda*2),r2
; 		mov	#_DMASOURCE0,r1
; 		mov	r8,@r1			; Source address
; 		add 	r2,r8
; 		mov	r10,@(4,r1)		; Destination address
; 		add 	r2,r10
; 		shlr2	r2			; /4
; 		mov	r2,@(8,r1)		; Length
;  		mov	#$5000|$800|$2E1,r0	; $5000|Size|
; 		mov	r0,@($C,r1)		; load mode
; 		add	#1,r2
; 		mov	#_DMAOPERATION,r3 	; _DMAOPERATION = $ffffffb0
; 		mov	r2,@r3

@bad_y:
		mov	@(TML_BOTTOM_Y,r11),r1
		cmp/gt	r1,r9
		bf/s	@loop
		add 	#1,r9
@endquik:

		mov	@(TML_DST_Y,r11),r0
		mov	r0,r1
		add 	#1,r1
		cmp/pz	r0
		bt	@dontzero
		mov	#0,r0
		mov	#1,r1
@dontzero:
		mov	r0,@(TML_DST_Y,r11)
		
; -----------------
; Read lines
; -----------------

 		mov	#TML_data_M,r11
 		mov	#TML_data_S,r2
 		mov	r1,@(TML_DST_Y,r2)
 		
 		mov	@(TML_BOTTOM_Y,r11),r0
 		mov	r0,@(TML_BOTTOM_Y,r2)
 		mov	@(TML_SRC_TXTR,r11),r0
 		mov	r0,@(TML_SRC_TXTR,r2)
 		mov	@(TML_SRC_TXTWDH,r11),r0
 		mov	r0,@(TML_SRC_TXTWDH,r2) 
 		
		mov	#DDA_List,r0
 		mov	r0,@(TML_DDA_ENTRY,r11)
 		add 	#sizeof_ddalist,r0
 		mov	r0,@(TML_DDA_ENTRY,r2)
		mov	@(TML_SRC_TXTR,r11),r0
		mov	r0,@(TML_SRC_TXTR,r2)
		mov	@(TML_SRC_TXTWDH,r11),r0
		mov	r0,@(TML_SRC_TXTWDH,r2)

  		mov	#mdltask_slave,r1
 		mov	#1,r0
    		mov	r0,@r1
    		
@line_do:
  		mov	@(TML_DDA_ENTRY,r11),r3
  		mov	@(DDAL_BUSY,r3),r0
  		mov	#-1,r1
  		cmp/eq	r1,r0
  		bt	@busy_line
  		mov	r1,@(DDAL_BUSY,r3)
  		
 		mov	@(DDAL_SRC_LX,r3),r7
 		mov	@(DDAL_SRC_LY,r3),r5
 		mov	@(DDAL_DST_LX,r3),r8
		mov	@(DDAL_SRC_RX,r3),r6
		mov	@(DDAL_SRC_RY,r3),r4
		mov	@(DDAL_DST_RX,r3),r9
		
; 		mov	@(DDA_SRC_X,r3),r7
;  		mov	@(DDA_SRC_Y,r3),r5
;  		mov	@(DDA_DST_X,r3),r8
; 		add 	#sizeof_dda,r3
; 		mov	@(DDA_SRC_X,r3),r6
; 		mov	@(DDA_SRC_Y,r3),r4
; 		mov	@(DDA_DST_X,r3),r9
		bsr	Texture_Map_Line
 		nop
 		
@busy_line:
  		mov	@(TML_DDA_ENTRY,r11),r3
		add 	#sizeof_ddalist,r3
  		mov	r3,@(TML_DDA_ENTRY,r11)
		mov	@(TML_DST_Y,r11),r0
		add	#1,r0
		mov	r0,@(TML_DST_Y,r11)
		
		mov	@(TML_BOTTOM_Y,r11),r1
		cmp/gt	r1,r0
		bt	@exit_here
		mov	#SCREEN_HEIGHT,r1
		cmp/gt	r1,r0
		bf	@line_do
@exit_here:	
		
; --------------------------

@exit:
		mov	@r15+,pr
		rts
		nop
		align 4
		lits

; ---------------------------------
; Find top point
;
; Entry:
;
;   r1: Dest   point list pointer
;   r2: Num of points
;   r4: Source point list pointer
;
; Returns:
;
;    r5: Start Y position
;    r6: End Y position
;    r7: Start dest point
;    r8: Start source point
;    r9: First dest point
;   r10: Last  dest point
;   r11: First source point
; ---------------------------------

Preinit_DDA:
		mov	r2,r8			; Load number of points

		mov	r1,r9			; Set pointer to first dest point
		mov	r5,r11			; Set pointer to first source point

		mov	r8,r10			; Set pointer to last dest point
		add	#-1,r10
		shll2	r10			; (Assumes SIZEOF_POINT == 8)
		shll	r10
		add	r9,r10

		mov	r9,r4			; Search for dest start point
		mov	#$7FFFFFFF,r5
		mov	#$FFFFFFFF,r6

@loop		mov	@(POINT_Y,r4),r0
		cmp/gt	r5,r0
		bt	@check

		mov	r4,r7
		mov	r0,r5

@check		cmp/ge	r0,r6
		bt	@next

		mov	r0,r6

@next		add	#SIZEOF_POINT,r4
		dt	r8
		bf	@loop

		mov	r7,r8			; Set source start point
		sub	r9,r8
		add	r11,r8
		rts
		nop
		align 4
		lits
	
;
; Init DDA
;
; Entry:
;
;    r7: Start dest point
;    r8: Start source point
;    r9: First dest point
;   r10: Last  dest point
;   r11: First source point
;   r6: DDA pointer
;
; Usage:
;
; r0-r4: Temporaries
;    r5: Next dest point
;    r6: Next source point
;
; Return:
;
; r7-r12: Unchanged
;

Init_DDA:

; Set limits

	mov	r7,@(DDA_DST_POINT,r6)	; Set destination points
	mov	r9,@(DDA_DST_LOW,r6)
	mov	r10,@(DDA_DST_HIGH,r6)

	mov	r10,r0
	sub	r9,r0
	add	r11,r0

	mov	r8,@(DDA_SRC_POINT,r6) ; Set source point
	mov	r11,@(DDA_SRC_LOW,r6)
	mov	r0,@(DDA_SRC_HIGH,r6)

	mov	#0,r0			; Set height to zero
	mov	r0,@(DDA_DST_H,r6)
	rts
	mov	r0,@(DDA_EXIT_FLAG,r6)

; ----------------------------------
; Update left DDA
;
; Input:
; r8: LEFT DDA pointer
; 
; Uses:
; r0-r8
; ----------------------------------

Update_DDA_Left:

; Start critical section

	mov	@(DDA_DST_H,r8),r0	; Decrement height
	cmp/eq	#0,r0
	bt	@next_point
	add	#-1,r0
	mov	r0,@(DDA_DST_H,r8)

	mov	@(DDA_DST_X,r8),r0 	; Update dest horizontal position
	mov	@(DDA_DST_DX,r8),r1
	add	r1,r0
	mov	r0,@(DDA_DST_X,r8)

	mov	@(DDA_SRC_X,r8),r0	; Update source horizontal position
	mov	@(DDA_SRC_DX,r8),r1
	add	r1,r0
	mov	r0,@(DDA_SRC_X,r8)

	mov	@(DDA_SRC_Y,r8),r0	; Update source vertical position
	mov	@(DDA_SRC_DY,r8),r1
	add	r1,r0
	rts
	mov	r0,@(DDA_SRC_Y,r8)
	align 4
	lits
	
; End critical section

@next_point

@loop	mov	#$80000000,r5

	mov	@(DDA_DST_POINT,r8),r6	; Set dest to target point
	mov	@(POINT_X,r6),r1
	mov	r5,r0
	xtrct	r1,r0
	mov	r0,@(DDA_DST_X,r8)
	mov	@(POINT_Y,r6),r2

	mov	@(DDA_SRC_POINT,r8),r7	; Set source to target point
	mov	@(POINT_X,r7),r3
	mov	r5,r0
	xtrct	r3,r0
	mov	r0,@(DDA_SRC_X,r8)
	mov	@(POINT_Y,r7),r4
	mov	r5,r0
	xtrct	r4,r0
	mov	r0,@(DDA_SRC_Y,r8)

	mov	@(DDA_DST_HIGH,r8),r5	; Calculate next target point
	add	#SIZEOF_POINT,r6
	add	#SIZEOF_POINT,r7
	cmp/gt	r5,r6
	bf	@save_new_target
	mov	@(DDA_DST_LOW,r8),r6
	mov	@(DDA_SRC_LOW,r8),r7

@save_new_target

	mov	r6,@(DDA_DST_POINT,r8)
	mov	r7,@(DDA_SRC_POINT,r8)

	mov	@(POINT_X,r6),r5	; Calculate dest dx and dy
	sub	r1,r5
	mov	@(POINT_Y,r6),r6
	sub	r2,r6

	mov	r6,r0
	cmp/eq	#0,r0
	bt	@loop
	cmp/pz	r0
	bf	@exit

	mov	r6,@(DDA_DST_H,r8)

	mov	#div_table,r0		; Calculate divisor
	shll2	r6
	mov	@(r0,r6),r0

	shll16	r5			; Calculate dest dx
	dmuls	r5,r0
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	mov	r1,@(DDA_DST_DX,r8)

	mov	@(POINT_X,r7),r5	; Calculate source dx and dy
	sub	r3,r5
	mov	@(POINT_Y,r7),r6
	sub	r4,r6

	shll16	r5
	dmuls	r5,r0			; Calculate source dx
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	mov	r1,@(DDA_SRC_DX,r8)

	shll16	r6
	dmuls	r6,r0			; Calculate source dy
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	rts
	mov	r1,@(DDA_SRC_DY,r8)

@exit	rts
	mov	r0,@(DDA_EXIT_FLAG,r8)
	align 4
	lits
	
; ----------------------------------
; Update Right DDA
;
; Input:
; r8: RIGHT DDA pointer
; 
; Uses:
; r0-r8
; ----------------------------------

Update_DDA_Right:

; Start critical section

	mov	@(DDA_DST_H,r8),r0	; Decrement height
	cmp/eq	#0,r0
	bt	@next_point
	add	#-1,r0
	mov	r0,@(DDA_DST_H,r8)

	mov	@(DDA_DST_X,r8),r0 	; Update dest horizontal position
	mov	@(DDA_DST_DX,r8),r1
	add	r1,r0
	mov	r0,@(DDA_DST_X,r8)

	mov	@(DDA_SRC_X,r8),r0	; Update source horizontal position
	mov	@(DDA_SRC_DX,r8),r1
	add	r1,r0
	mov	r0,@(DDA_SRC_X,r8)

	mov	@(DDA_SRC_Y,r8),r0	; Update source vertical position
	mov	@(DDA_SRC_DY,r8),r1
	add	r1,r0
	rts
	mov	r0,@(DDA_SRC_Y,r8)
	align 4
	lits
	
; End critical section

@next_point

@loop	mov	#$80000000,r5

	mov	@(DDA_DST_POINT,r8),r6	; Set dest to target point
	mov	@(POINT_X,r6),r1
	mov	r5,r0
	xtrct	r1,r0
	mov	r0,@(DDA_DST_X,r8)
	mov	@(POINT_Y,r6),r2

	mov	@(DDA_SRC_POINT,r8),r7	; Set source to target point
	mov	@(POINT_X,r7),r3
	mov	r5,r0
	xtrct	r3,r0
	mov	r0,@(DDA_SRC_X,r8)
	mov	@(POINT_Y,r7),r4
	mov	r5,r0
	xtrct	r4,r0
	mov	r0,@(DDA_SRC_Y,r8)

	mov	@(DDA_DST_LOW,r8),r5	; Calculate next target point
	add	#-SIZEOF_POINT,r6
	add	#-SIZEOF_POINT,r7
	cmp/ge	r5,r6
	bt	@save_new_target
	mov	@(DDA_DST_HIGH,r8),r6
	mov	@(DDA_SRC_HIGH,r8),r7

@save_new_target

	mov	r6,@(DDA_DST_POINT,r8)
	mov	r7,@(DDA_SRC_POINT,r8)

	mov	@(POINT_X,r6),r5	; Calculate dest dx and dy
	sub	r1,r5
	mov	@(POINT_Y,r6),r6
	sub	r2,r6

	mov	r6,r0
	cmp/eq	#0,r0
	bt	@loop
	cmp/pz	r0
	bf	@exit

	mov	r6,@(DDA_DST_H,r8)

	mov	#div_table,r0		; Calculate divisor
	shll2	r6
	mov	@(r0,r6),r0

	shll16	r5			; Calculate dest dx
	dmuls	r5,r0
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	mov	r1,@(DDA_DST_DX,r8)

	mov	@(POINT_X,r7),r5	; Calculate source dx and dy
	sub	r3,r5
	mov	@(POINT_Y,r7),r6
	sub	r4,r6

	shll16	r5
	dmuls	r5,r0			; Calculate source dx
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	mov	r1,@(DDA_SRC_DX,r8)

	shll16	r6
	dmuls	r6,r0			; Calculate source dy
; 	mov	macl,r2
	mov	mach,r1
; 	shal	r2
	rotcl	r1
	rts
	mov	r1,@(DDA_SRC_DY,r8)

@exit	rts
	mov	r0,@(DDA_EXIT_FLAG,r8)
	align 4
	lits
	
; ----------------------------------
; Texture map line
;
; Notes:
;
; Should take 13 clocks per pixel, once started. It's possible to reduce this
; to 10 clocks per pixel by using a slightly different algorithm, though.
;
; This texture-mapper works best with textures smaller than 4k, since they
; will fit in the SH2's cache.
;
; This texture mapper will not work with textures larger than 32k since
; we're using a 16-bit multiply (mulu.w).
;
; Register usage:
;
; r2: Bitmap width
; r3: Bitmap data pointer
; r4: Bitmap X position        (fixed pt, 16:16)
; r5: Bitmap DX                (fixed pt, 16:16)
; r6: Bitmap Y position        (fixed pt, 16:16)
; r7: Bitmap DY                (fixed pt, 16:16)
; r8: Destination line pointer (last pixel address + 1)
; r9: Destination line length
; ----------------------------------

; r14 - TML_data_M

Texture_Map_Line:
		mov	@(TML_DST_Y,r11),r3	; -1?
		cmp/pz	r3
		bf	@exit
		mov	#SCREEN_HEIGHT,r0	; +224?
		cmp/ge	r0,r3
		bt	@exit
		
  		mov	@(TML_SRC_TXTR,r11),r0
  		cmp/pl	r0
  		bf	@solid_map

 		mov	r8,r0
 		sub 	r9,r0
 		cmp/pz	r0
 		bf	@backwrdsdst
 		mov	r9,r0			; swap dest L/R
 		mov	r8,r1
 		mov	r0,r8
 		mov	r1,r9
 		
 		mov	r7,r0			; swap texture X
 		mov	r6,r1
 		mov	r0,r6
 		mov	r1,r7		
 		mov	r5,r0			; swap texture Y
 		mov	r4,r1
 		mov	r0,r4
 		mov	r1,r5	
@backwrdsdst:

		;r9 - RIGHT point
		;r8 - LEFT point
		
 		shlr16	r9
  		exts	r9,r9
   		mov	r9,r2
  		cmp/pl	r9			; right < 0?
  		bf	@exit
  		shlr16	r8
  		exts	r8,r8
  		mov	r8,r1
 		mov	#SCREEN_WIDTH,r0
  		cmp/ge	r0,r8			; left > 320?
  		bt	@exit
		mulu	r3,r0

   		sub 	r1,r2
  		mov	#div_table,r0
 		shll2	r2			; Calculate width divisor
  		mov	@(r0,r2),r1
   				
; --------------------------
; Set texture
; --------------------------

		mov	macl,r2
 		mov	r5,r10
 		mov	r4,r0
		
; 		mov	@(TML_SRC_RX,r11),r4	; Set texture X
; 		mov	@(TML_SRC_LX,r11),r0	; Set texture DX
		mov	r7,r4
		sub 	r4,r6
		dmuls	r6,r1
		mov	mach,r5
		rotcl	r5
;  		mov	@(TML_SRC_RY,r11),r6	; Set texture Y
; 		mov	@(TML_SRC_LY,r11),r0	; Set texture DY
 		mov	r10,r6
		sub	r6,r0
		dmuls	r0,r1
		mov	mach,r7
		rotcl	r7

 		cmp/pz	r8
 		bt	@dontcropr
 		mov	r8,r3
 		neg 	r3,r3
@ogt:					;TODO: este fix es muy pendejo
  		add	r5,r4		; Update X
  		add	r7,r6		; Update Y
 		dt	r3
 		bf	@ogt
  		mov	#0,r8
@dontcropr:
 		mov	#SCREEN_WIDTH,r0
 		cmp/ge	r0,r9
 		bf	@dontcropl
 		mov	r0,r9
@dontcropl:
 		
		mov	r2,macl
		mov	#$FFFF,r2
		mov	@(TML_SRC_TXTWDH,r11),r0
		shlr16	r0
		and	r2,r0
		mov	r0,r2
  		mov	#_framebuffer+$200,r1
  		mov	macl,r0
  		add 	r0,r1			; Y add
 		add 	r8,r1			; X add
 		
		mov	@(TML_SRC_TXTR,r11),r3	; Set texture struct pointer
  		mov	@(TML_SRC_TXTWDH,r11),r0
 		and	#$FF,r0
 		mov	r0,mach			; pffft, but it works.
 		
;  		mov	#0,r10
		mov	r9,r0
		mov	r1,r9
 		sub 	r8,r0
  		mov	r0,r8
  		mov	#0,r0
  		cmp/eq	r0,r8
  		bt	@exit
		
; --------------------------
; *** Heavy loop ***
;
; r2 - Texture width
; r3 - Texture data
; r4 - X position
; r5 - X update
; r6 - Y position
; r7 - Y add
; r8 - Length
; r9 - Output (framebuffer)
; --------------------------
		
@loop:
		swap	r6,r1			; Build row offset
		mulu	r2,r1
		
		mov	r4,r1	   		; Build column index
		mov	macl,r0
		shlr16	r1
		add	r1,r0
 		mov.b	@(r3,r0),r1		; Read pixel
 		mov	mach,r0
 		add 	r0,r1
		mov.b	r1,@r9
 		
		add 	#1,r9
   		add	r5,r4			; Update X
 		add	r7,r6			; Update Y
 		dt	r8
 		bf	@loop
 		
@exit:
 		rts
 		nop

; --------------------------
; Solid color map
; --------------------------

@solid_map:
		mov	#SCREEN_WIDTH,r7
 		mov	r8,r0
 		sub 	r9,r0
 		cmp/pz	r0
 		bf	@backwrdsdst2
 		mov	r9,r0			; swap dest L/R
 		mov	r8,r1
 		mov	r0,r8
 		mov	r1,r9
@backwrdsdst2:
 		shlr16	r9
  		exts	r9,r9
   		mov	r9,r2
  		cmp/pl	r9			; right < 0?
  		bf	@exit
  		shlr16	r8
  		exts	r8,r8
  		mov	r8,r1
  		cmp/ge	r7,r8			; left > 320?
  		bt	@exit
		mulu	r3,r7
   				
 		cmp/pz	r8
 		bt	@dontcropr2
  		mov	#0,r8
@dontcropr2:
 		mov	#SCREEN_WIDTH,r0
 		cmp/ge	r0,r9
 		bf	@dontcropl2
 		sub 	#1,r0
 		mov	r0,r9
@dontcropl2:
 
;   		mov	#_vdpreg,r4
; @wait_fb	mov.w	@(10,r4),r0	; Wait framebuffer
; 		and	#%10,r0
; 		cmp/eq	#2,r0
; 		bt	@wait_fb
; 
; 		mov	#2,r0
; ; 		shlr	r0
; 		mov.w	r0,@(4,r4)	; Set length
; 		
; 		mov 	#$100,r0
; 		mov 	#$A0,r2
; 		muls	r3,r2
; 		mov 	macl,r2
; 		add 	r2,r0
; 		mov 	r8,r2
; 		shlr	r2
; 		add 	r2,r0
; 		mov.w	r0,@(6,r4)	; Set address
; 		
;   		mov	@(TML_SRC_TXTWDH,r11),r0
;   		and 	#$FF,r0
;   		mov 	r0,r1
;   		shll8	r1
;   		or	r1,r0
; 		mov.w	r0,@(8,r4)	; Set data
; 	
; @wait_fb2	mov.w	@(10,r4),r0	; Wait framebuffer
; 		and	#%10,r0
; 		cmp/eq	#2,r0
; 		bt	@wait_fb2
; 		rts
; 		nop
		
  		mov	#_framebuffer+$200,r1
  		mov	macl,r0
  		add 	r0,r1		; Y add
 		add 	r8,r1		; X add
		mov	r9,r2
		mov	r1,r9
 		sub 	r8,r2
 		add 	#1,r2
 		mov	#0,r0
  		cmp/eq	r0,r2
  		bt	@exit
  		mov	@(TML_SRC_TXTWDH,r11),r0
  		and 	#$FF,r0
	
; --------------------------
; *** Heavy loop ***
; --------------------------

@loop2:
		mov.b	r0,@r1
		add 	#1,r1
 		dt	r2
 		bf	@loop2
		rts
		nop
		align 4
		lits
		
; ------------------------------
; Rotate point around Z axis
;
; Entry:
;
; r5: x
; r6: y
; r0: theta
;
; Returns:
;
; r0: (x  cos @) + (y sin @)
; r1: (x -sin @) + (y cos @)
; ------------------------------

Rotate_Point:
		mov	#sin_table,r1
		mov	#cos_table,r2
		mov	@(r0,r1),r3
		mov	@(r0,r2),r4

		dmuls	r5,r4		; x cos @
		mov	macl,r0
		mov	mach,r1
		xtrct	r1,r0
		dmuls	r6,r3		; y sin @
		mov	macl,r1
		mov	mach,r2
		xtrct	r2,r1
		add	r1,r0

		neg	r3,r3
		dmuls	r5,r3		; x -sin @
		mov	macl,r1
		mov	mach,r2
		xtrct	r2,r1
		dmuls	r6,r4		; y cos @
		mov	macl,r2
		mov	mach,r3
		xtrct	r3,r2
		add	r2,r1
 		rts
		nop
		lits
		align 4
	
; -------------------------------
; Autosort Z
; -------------------------------

Polygon_ZSort:
		mov 	#polygon_len,r9
		mov 	@r9,r0
		mov 	r0,r9
		cmp/pl	r0
		bf	@out
		cmp/eq	#0,r0
		bt	@out
		
		mov 	#polygon_z_list,r8
		mov 	@r8,r4
		mov 	@(4,r8),r1
		add 	#8,r8
		mov 	#polygon_list,r7
		mov 	r1,@r7
		
		cmp/eq	#1,r0
		bt	@out
		
; ----------------------
; Check the farest away
; ----------------------

		mov 	r9,r7
@loop:
		mov 	@r8,r0
		cmp/gt	r4,r0
		bt	@not
		mov 	r0,r4
@not:
		add 	#8,r8
		dt	r7
		bf	@loop
		
; ----------------------
; Now sort
; 
; r4 - start
; ----------------------

; 		mov 	#-512,r4
		mov 	r9,r6
		mov 	r9,r5
		mov 	#polygon_z_list,r8
		mov 	#polygon_list,r7
@loopZ:
		mov 	@r8,r1
         	cmp/gt	r1,r4
           	bf	@next
		
		mov 	@(4,r8),r0
		cmp/eq	#-1,r0
		bt	@next
		
		mov 	#TH,r1
		or	r1,r0
		mov 	r0,@r7
		add 	#4,r7
		sub 	#1,r6
		
		mov 	#-1,r0
		mov 	r0,@(4,r8)
@next:
		cmp/pl	r6
		bf	@out
		
		add 	#8,r8
		dt 	r5
		bf	@loopZ
; 		
		mov 	r9,r5
		mov 	#polygon_z_list,r8
		bra	@loopZ
		add 	#1,r4
		
; ----------------------

@out:
		rts
		nop
		align 4
		lits
		
; -------------------------------
; Draw polygons from list to
; framebuffer
; -------------------------------

Polygon_Draw:
  		mov	#polygon_list,r13
  		mov	#polygon_len,r1
  		mov	@r1,r12
  		cmp/pl	r12
  		bf	@exit	
@next:
		mov 	@r13,r11
		mov 	#0,r0
		cmp/eq	r0,r11
		bt	@skip
  		mov	@(face_type,r11),r0
  		cmp/pl	r0			;Fail-Safe
  		bf	@skip
  		
		mov	r0,r5
		mov	r11,r3
		add 	#face_points,r3
		mov 	#face_dest,r4
@next_master:
     		mov	@r3,r0
     		shlr8	r0
     		exts	r0,r0
		mov	#(SCREEN_WDTHVIEW/2),r6
             	add 	r6,r0
        	mov	r0,@r4
		mov	@(4,r3),r0
     		shlr8	r0
     		exts	r0,r0
         	mov	#(SCREEN_HEIGHT/2),r6
		add 	r6,r0
		mov	r0,@(4,r4)
 
   		add 	#$C,r3
    		add 	#8,r4
     		dt	r5
     		bf	@next_master

  		mov	@(face_type,r11),r2
		mov 	#face_dest,r1
		mov	@(face_texture,r11),r3
		mov	@(face_texwidth,r11),r4
		mov	r11,r5
		add 	#face_texsrc,r5
		
		mov 	pr,@-r15
		mov	#Draw_Texture,r0
		jsr	@r0
		nop
		mov 	@r15+,pr
		
		mov 	#0,r0
		mov 	r0,@r13
@skip:
		add 	#4,r13
		dt	r12
		bf	@next

@exit:
		rts
		nop
			
; ====================================================================
; -------------------------------------------------
; Polygons
; 
; Slave side
; -------------------------------------------------

Polygons_Slave:
		mov	#mdltask_slave,r1
		mov	@r1,r0
		cmp/eq	#0,r0
		bt	@exit
		
; -----------------
; Read lines
; -----------------

 		mov	#TML_data_S,r11	
@line_do:
  		mov	@(TML_DDA_ENTRY,r11),r3
  		mov	@(DDAL_BUSY,r3),r0
  		mov	#-1,r1
  		cmp/eq	r1,r0
  		bt	@busy_line
  		mov	r1,@(DDAL_BUSY,r3)
  	
 		mov	@(DDAL_SRC_LX,r3),r7
 		mov	@(DDAL_SRC_LY,r3),r5
 		mov	@(DDAL_DST_LX,r3),r8
		mov	@(DDAL_SRC_RX,r3),r6
		mov	@(DDAL_SRC_RY,r3),r4
		mov	@(DDAL_DST_RX,r3),r9
		mov	pr,@-r15
		bsr	Texture_Map_Line
 		nop
 		mov	@r15+,pr
 		
@busy_line:
  		mov	@(TML_DDA_ENTRY,r11),r3
		add 	#sizeof_ddalist,r3
  		mov	r3,@(TML_DDA_ENTRY,r11)
		mov	@(TML_DST_Y,r11),r0
		add	#1,r0
		mov	r0,@(TML_DST_Y,r11)
		
		mov	#SCREEN_HEIGHT,r1
		cmp/gt	r1,r0
		bt	@exit_here
		mov	@(TML_BOTTOM_Y,r11),r1
		cmp/gt	r1,r0
		bf	@line_do
@exit_here:

; -----------------

@finish:
		mov	#mdltask_slave,r1
		mov	#0,r0
		mov	r0,@r1
		
; 		bra	*
; 		nop
		
@exit:
		rts
		nop
		align 4
		lits
	
; ====================================================================

; *******************************
; Model engine
; *******************************

; -------------------------------
; Model read
; 
; r14 - Current model in list
; r13 - Polygon list (current)
; -------------------------------

Model_Read:
		mov	pr,@-r15
		
 		mov	@(model_addr,r14),r0
		mov	@r0,r8			; r8 - Faces
		mov	@(4,r0),r9		; r9 - Points
		mov	@(8,r0),r10		; r10 - Material
 		
;  		mov	#polygon_out,r13
;    		mov 	#polygon_len,r1
;  		mov	@r1,r0
;    		mov 	#MAX_POLYGONS,r2
;    		cmp/ge	r2,r0
;    		bf	@not_out
;    		bra	@end
;    		nop
; @not_out:
;  		mov	@r1,r0
;  		mov	#sizeof_plygn,r1
;  		mulu	r0,r1
;  		mov	macl,r0
;  		add 	r0,r13

; ----------------------------------

@next:
		mov	#0,r0
		mov.w	@r8+,r0
		mov	r0,r11
		mov	#3,r0			; triangle?
		cmp/eq	r0,r11
		bt	@valid
		add 	#1,r0
		cmp/eq	r0,r11			; quad?
		bt	@valid
		bra	@end
		nop

; ----------------------------------
; Valid model
; ----------------------------------

@valid:
		mov	r11,@(face_type,r13)
		
; ----------------------------------
; find texture
; ----------------------------------

		mov	#-1,r0			; Solid color mode
		mov	r0,@(face_texture,r13)
		mov	#0,r0
		mov.w	@r8+,r0			; grab material id
		mov	r0,r1
		mov	r0,r2
		mov	#$7FFF,r0
		and 	r0,r1
		mov	#$8000,r0
		and 	r0,r2
		shll16	r2
		or	r2,r1
		cmp/pl	r1
		bt	@set_solid
		
; ----------------------------------
; Set texture source
; ----------------------------------

		mov	r10,r6
		mov	r10,r3
		
@next_srch:
		mov	@r6,r0			; ID to search
		cmp/eq	#-1,r0
		bt	@not_found
		cmp/eq	r0,r1
		bt	@found
		
		add 	#$8,r6			; skip id/addr/width
		cmp/pz	r0
		bt	@solidadd
		add 	#$24,r6			; skip tex source
@solidadd:
		bra	@next_srch
		nop
		
; -----------------------------
; Material if not found
; -----------------------------
	
@not_found:
		mov	#$FF,r1
		
; -----------------------------
; Use solid color
; -----------------------------

@set_solid:
		bra	@its_solid
		mov	r1,@(face_texwidth,r13)

; -----------------------------
; Found texture
; -----------------------------

@found:	
		add 	#4,r6
		
		mov	@r6,r4
		mov	@(4,r6),r5
		add 	#8,r6
		mov	r4,@(face_texwidth,r13)
		cmp/pz	r0
		bt	@its_solid
		mov	r4,@(face_texture,r13)
		mov	r5,@(face_texwidth,r13)

		mov	r11,r5
		mov	r13,r7
		add 	#face_texsrc,r7
@copysrc:
		mov	@r6+,r0
		mov	r0,@r7
		add 	#4,r7
		mov	@r6+,r0
		mov	r0,@r7
		add 	#4,r7
		dt	r5
		bf	@copysrc
@its_solid:

; ----------------------------------
; Send target points to buffer
; ----------------------------------

		mov	r13,r7
		add	#face_points,r7
		
 		mov	#0,r1
@nextpoints:
		mov	r9,r12
		mov	#0,r0
		mov.w	@r8+,r0
		mov	#6,r1
		mulu	r0,r1
		mov	macl,r0
		add 	r0,r12

; ----------------------------------

  		;Rotated
 		mov	#0,r0
 		mov.w	@r12,r0
  		exts.w	r0,r5
  		mov.w	@(4,r12),r0
  		exts.w	r0,r6
;   		mov 	@(model_z,r14),r0
;   		add 	r0,r6
  		shll8	r5
  		shll8	r6
   		mov	@(model_y_rot,r14),r0
   		shll	r0
    		mov	#$7FF,r1
    		and	r1,r0
 		bsr	Rotate_Point
   		shll2	r0 
   		mov	r0,@r7
   		
  		mov	r1,r6
 		mov	#0,r0
		mov.w	@(2,r12),r0
   		mov	r0,r5
   		shll8	r5
   		mov	@(model_x_rot,r14),r0
   		shll	r0
    		mov	#$7FF,r2
    		and	r2,r0
 		bsr	Rotate_Point
   		shll2	r0
       		mov	r1,@(8,r7)
       		
		mov	@r7,r5			; grab X again
		mov 	r0,r6
   		mov	@(model_z_rot,r14),r0
   		shll	r0
    		mov	#$7FF,r1
    		and	r1,r0
 		bsr	Rotate_Point
   		shll2	r0
   		mov	r0,@r7
  		mov	r1,@(4,r7)

  		
  		;Move object
		mov	@(8,r7),r6
		mov 	@(model_z,r14),r1
		shll8	r1
		shar	r1
; 		shar	r1
        	add 	r1,r6
		mov	r6,@(8,r7)
		mov	@r7,r6
		mov 	@(model_x,r14),r1
		shll8	r1
		shar	r1
; 		shar	r1
        	add 	r1,r6
		mov	r6,@r7		
		mov	@(4,r7),r6
		mov 	@(model_y,r14),r1
		shll8	r1
		shar	r1
; 		shar	r1
        	add 	r1,r6
		mov	r6,@(4,r7)
		
; -----------------------------
; Perspective
; -----------------------------

		bsr	calc_persp
		mov	@(8,r7),r2
		
		mov	@r7,r0
		dmuls	r2,r0
		mov	macl,r0
		mov	mach,r1
		xtrct	r1,r0
		mov	r0,@r7
		
		mov	@(4,r7),r0
		dmuls	r2,r0
		mov	macl,r0
		mov	mach,r1
		xtrct	r1,r0
		mov	r0,@(4,r7)

; -----------------------------

@false:
   		add	#$C,r7
  		dt	r11
  		bf	@nextpoints
	
; ----------------------------------
; Face out check 1
; ----------------------------------

  		mov	r13,r7
  		add	#face_points,r7
   		mov 	#-160,r2		; X end
   		mov 	#-112,r3		; Y end
   		mov 	#-512,r4		; Z end
   		mov 	#0,r6
 		mov	@(face_type,r13),r5
@next2:
    		mov	@(8,r7),r0		;TODO: esto causa mucho pedo
    		shlr8	r0
    		exts	r0,r0    		
     		cmp/gt	r4,r0
     		bf	@on_x
    		cmp/pz	r0
    		bt	@on_x
    		
		mov 	r2,r1
    		mov	@r7,r0
    		shlr8	r0
    		exts	r0,r0
    		cmp/gt	r1,r0
    		bf	@on_x
    		neg 	r2,r1
     		cmp/gt	r1,r0
     		bt	@on_x
     		
		mov 	r3,r1
    		mov	@(4,r7),r0
    		shlr8	r0
    		exts	r0,r0
    		cmp/gt	r1,r0
    		bf	@on_x
    		neg 	r3,r1
     		cmp/gt	r1,r0
     		bt	@on_x

     		bra 	@not_x
     		nop
@on_x:
     		add 	#1,r6
    
@not_x:
     		add	#$C,r7
     		dt 	r5
     		bf	@next2
     		
 		mov	@(face_type,r13),r0
     		cmp/ge	r0,r6
     		bt	@is_bad
  
; ----------------------------------
; Face out check 2
; ----------------------------------

;   		mov	r13,r7
;   		add	#face_points,r7
; 
;   		mov	#-256,r1		; Z far  best: -256
;   		mov	#256,r2		; Z near best: 1024
;   		mov 	#-384,r3		; X/Y left best: -384
;    		mov	#384,r4			; X/Y right best: 384
;  		mov	@(face_type,r13),r5
; @next3:
; ;    		mov	@r7,r0
; ;    		shlr8	r0
; ;    		exts	r0,r0
; ;     		cmp/ge	r3,r0
; ;     		bf	@is_bad
; ;    		cmp/ge	r4,r0
; ;    		bt	@is_bad
;    		
; ;    		mov	@(4,r7),r0
; ;    		shlr8	r0
; ;    		exts	r0,r0
; ;     		cmp/ge	r3,r0
; ;     		bf	@is_bad
; ;    		cmp/ge	r4,r0
; ;    		bt	@is_bad
;    		
;     		mov	@(8,r7),r0
;     		shlr8	r0
;     		exts	r0,r0
;    		cmp/ge	r1,r0
;    		bf	@is_bad
;   		cmp/gt	r2,r0
;   		bt	@is_bad
; 
;      		add	#$C,r7
;      		dt 	r5
;      		bf	@next3
     		
; -----------------------------
; Z Check Painters algorithm
; -----------------------------

 		mov	r13,r4
 		add 	#face_points,r4

@check_it:
          	mov 	@(8,r4),r1		;point 1
          	shlr8	r1
          	exts	r1,r1
          	add 	#$C,r4
          	
         	mov	@(8,r4),r0		;point 2
          	shlr8	r0
          	exts	r0,r0
         	add 	#$C,r4
         	cmp/ge	r0,r1
         	bf	@same_1
         	mov	r0,r1
@same_1:
         	mov	@(8,r4),r0		;point 3
          	shlr8	r0
          	exts	r0,r0
         	add 	#$C,r4
         	cmp/ge	r0,r1
         	bf	@same_2
         	mov	r0,r1
@same_2:
		mov	@(face_type,r13),r0
		cmp/eq	#3,r0
		bt	@same_3
         	mov	@(8,r4),r0		;point 4
          	shlr8	r0
          	exts	r0,r0
         	add 	#$C,r4
         	cmp/ge	r0,r1
         	bf	@same_3
         	mov	r0,r1
@same_3:
   		mov 	#polygon_len,r2
 		mov	@r2,r0
   		shll2	r0
   		shll	r0
		mov 	#polygon_z_list,r2
 		add 	r0,r2
		mov 	r1,@r2
		mov 	r13,@(4,r2)
		
; ----------------------------------

; 		mov	@(face_type,r13),r5
; 		mov	r13,r3
; 		add 	#face_points,r3
; 		mov	r13,r4
; 		add 	#face_dest,r4
; @next_master:
;      		mov	@r3,r0
;      		shlr8	r0
;      		exts	r0,r0
; 		mov	#(SCREEN_WIDTH/2),r6
;              	add 	r6,r0
;         	mov	r0,@r4
; 		mov	@(4,r3),r0
;      		shlr8	r0
;      		exts	r0,r0
;          	mov	#(SCREEN_HEIGHT/2),r6
; 		add 	r6,r0
; 		mov	r0,@(4,r4)
;  
;    		add 	#$C,r3
;     		add 	#8,r4
;      		dt	r5
;      		bf	@next_master
		
; ----------------------------------

  		mov	#polygon_len,r1
  		mov	@r1,r0
   		add 	#1,r0
   		mov	r0,@r1
   		mov 	#MAX_POLYGONS,r1
   		cmp/ge	r1,r0
   		bt	@end
 		add 	#sizeof_plygn,r13
 
@is_bad:
     		bra	@next
     		nop

; ----------------------------------
; End
; ----------------------------------

@end:
		mov	@r15+,pr
		rts
		nop
		align 4
		lits

; -----------------------------
; Get perspective value from Z
; 
; r2 - Z
; -----------------------------

calc_persp:
		mov 	#0,r1
		shlr8	r2
		exts	r2,r2
		mov	r2,r1
		mov	#persp_table_max,r0
		cmp/pz	r2
		bt	@calc
		neg	r2,r1
		mov	#persp_table_min,r0
@calc:
		shll2	r1
		mov	@(r0,r1),r2
		rts
		shll8	r2

; -------------------------------
; Model Set
; -------------------------------

Model_Set:
		mov	#models_buffer,r14
		mov	#sizeof_model,r0
		mulu	r1,r0
		mov	macl,r0
		add 	r0,r14

		mov	r2,@(model_addr,r14)
		rts
		nop
		align 4
		lits
		
; -------------------------------
; Model Position
; -------------------------------

Model_Pos:
		mov	#models_buffer,r14
		mov	#sizeof_model,r0
		mulu	r1,r0
		mov	macl,r0
		add 	r0,r14

		mov	r2,@(model_x,r14)
		mov	r3,@(model_y,r14)		
		mov	r4,@(model_z,r14)		
		rts
		nop
		align 4
		lits

; -------------------------------
; Model Set
; -------------------------------

Model_Rot:
		mov	#models_buffer,r14
		mov	#sizeof_model,r0
		mulu	r1,r0
		mov	macl,r0
		add 	r0,r14

		mov	r2,@(model_x_rot,r14)
		mov	r3,@(model_y_rot,r14)		
		mov	r4,@(model_z_rot,r14)		
		rts
		nop
		align 4
		lits
		
; ====================================================================
; -------------------------------------------------
; DATA
; -------------------------------------------------

;
; This table is "off by one" - to get 1/n you must fetch the (n-1)th entry.
;
div_table
	incbin "system/hardware/mars/sh2/subs/data/divtable.bin"
	align 4
	
; COS: sin_table $800
sin_table
	incbin "system/hardware/mars/sh2/subs/data/sinedata.bin",0,$800
cos_table:
	incbin "system/hardware/mars/sh2/subs/data/sinedata.bin",$800
	align 4
	
persp_table_max:
 dc.l 3584
 dc.l 3942
 dc.l 4300
 dc.l 4659
 dc.l 5017
 dc.l 5376
 dc.l 5734
 dc.l 6092
 dc.l 6451
 dc.l 6809
 dc.l 7168
 dc.l 7526
 dc.l 7884
 dc.l 8243
 dc.l 8601
 dc.l 8960
 dc.l 9318
 dc.l 9676
 dc.l 10035
 dc.l 10393
 dc.l 10752
 dc.l 11110
 dc.l 11468
 dc.l 11827
 dc.l 12185
 dc.l 12544
 dc.l 12902
 dc.l 13260
 dc.l 13619
 dc.l 13977
 dc.l 14336
 dc.l 14694
 dc.l 15052
 dc.l 15411
 dc.l 15769
 dc.l 16128
 dc.l 16486
 dc.l 16844
 dc.l 17203
 dc.l 17561
 dc.l 17919
 dc.l 18278
 dc.l 18636
 dc.l 18995
 dc.l 19353
 dc.l 19711
 dc.l 20070
 dc.l 20428
 dc.l 20787
 dc.l 21145
 dc.l 21503
 dc.l 21862
 dc.l 22220
 dc.l 22579
 dc.l 22937
 dc.l 23295
 dc.l 23654
 dc.l 24012
 dc.l 24371
 dc.l 24729
 dc.l 25087
 dc.l 25446
 dc.l 25804
 dc.l 26163
 dc.l 26521
 dc.l 26879
 dc.l 27238
 dc.l 27596
 dc.l 27955
 dc.l 28313
 dc.l 28671
 dc.l 29030
 dc.l 29388
 dc.l 29747
 dc.l 30105
 dc.l 30463
 dc.l 30822
 dc.l 31180
 dc.l 31539
 dc.l 31897
 dc.l 32255
 dc.l 32614
 dc.l 32972
 dc.l 33331
 dc.l 33689
 dc.l 34047
 dc.l 34406
 dc.l 34764
 dc.l 35123
 dc.l 35481
 dc.l 35839
 dc.l 36198
 dc.l 36556
 dc.l 36915
 dc.l 37273
 dc.l 37631
 dc.l 37990
 dc.l 38348
 dc.l 38707
 dc.l 39065
 dc.l 39423
 dc.l 39782
 dc.l 40140
 dc.l 40499
 dc.l 40857
 dc.l 41215
 dc.l 41574
 dc.l 41932
 dc.l 42291
 dc.l 42649
 dc.l 43007
 dc.l 43366
 dc.l 43724
 dc.l 44083
 dc.l 44441
 dc.l 44799
 dc.l 45158
 dc.l 45516
 dc.l 45875
 dc.l 46233
 dc.l 46591
 dc.l 46950
 dc.l 47308
 dc.l 47667
 dc.l 48025
 dc.l 48383
 dc.l 48742
 dc.l 49100
 dc.l 49459
 dc.l 49817
 dc.l 50175
 dc.l 50534
 dc.l 50892
 dc.l 51251
 dc.l 51609
 dc.l 51967
 dc.l 52326
 dc.l 52684
 dc.l 53043
 dc.l 53401
 dc.l 53759
 dc.l 54118
 dc.l 54476
 dc.l 54835
 dc.l 55193
 dc.l 55551
 dc.l 55910
 dc.l 56268
 dc.l 56627
 dc.l 56985
 dc.l 57343
 dc.l 57702
 dc.l 58060
 dc.l 58419
 dc.l 58777
 dc.l 59135
 dc.l 59494
 dc.l 59852
 dc.l 60211
 dc.l 60569
 dc.l 60927
 dc.l 61286
 dc.l 61644
 dc.l 62003
 dc.l 62361
 dc.l 62719
 dc.l 63078
 dc.l 63436
 dc.l 63795
 dc.l 64153
 dc.l 64511
 dc.l 64870
 dc.l 65228
 dc.l 65587
 dc.l 65945
 dc.l 66303
 dc.l 66662
 dc.l 67020
 dc.l 67379
 dc.l 67737
 dc.l 68096
 dc.l 68454
 dc.l 68812
 dc.l 69171
 dc.l 69529
 dc.l 69888
 dc.l 70246
 dc.l 70604
 dc.l 70963
 dc.l 71321
 dc.l 71680
 dc.l 72038
 dc.l 72396
 dc.l 72755
 dc.l 73113
 dc.l 73472
 dc.l 73830
 dc.l 74188
 dc.l 74547
 dc.l 74905
 dc.l 75264
 dc.l 75622
 dc.l 75980
 dc.l 76339
 dc.l 76697
 dc.l 77056
 dc.l 77414
 dc.l 77772
 dc.l 78131
 dc.l 78489
 dc.l 78848
 dc.l 79206
 dc.l 79564
 dc.l 79923
 dc.l 80281
 dc.l 80640
 dc.l 80998
 dc.l 81356
 dc.l 81715
 dc.l 82073
 dc.l 82432
 dc.l 82790
 dc.l 83148
 dc.l 83507
 dc.l 83865
 dc.l 84224
 dc.l 84582
 dc.l 84940
 dc.l 85299
 dc.l 85657
 dc.l 86016
 dc.l 86374
 dc.l 86732
 dc.l 87091
 dc.l 87449
 dc.l 87808
 dc.l 88166
 dc.l 88524
 dc.l 88883
 dc.l 89241
 dc.l 89600
 dc.l 89958
 dc.l 90316
 dc.l 90675
 dc.l 91033
 dc.l 91392
 dc.l 91750
 dc.l 92108
 dc.l 92467
 dc.l 92825
 dc.l 93184
 dc.l 93542
 dc.l 93900
 dc.l 94259
 dc.l 94617
 dc.l 94976
 dc.l 95334
 dc.l 95692
 dc.l 96051
 dc.l 96409
 dc.l 96768
 dc.l 97126
 dc.l 97484
 dc.l 97843
 dc.l 98201
 dc.l 98560
 dc.l 98918
 dc.l 99276
 dc.l 99635
 dc.l 99993
 dc.l 100352
 dc.l 100710
 dc.l 101068
 dc.l 101427
 dc.l 101785
 dc.l 102144
 dc.l 102502
 dc.l 102860
 dc.l 103219
 dc.l 103577
 dc.l 103936
 dc.l 104294
 dc.l 104652
 dc.l 105011
 dc.l 105369
 dc.l 105728
 dc.l 106086
 dc.l 106444
 dc.l 106803
 dc.l 107161
 dc.l 107520
 dc.l 107878
 dc.l 108236
 dc.l 108595
 dc.l 108953
 dc.l 109312
 dc.l 109670
 dc.l 110028
 dc.l 110387
 dc.l 110745
 dc.l 111104
 dc.l 111462
 dc.l 111820
 dc.l 112179
 dc.l 112537
 dc.l 112896
 dc.l 113254
 dc.l 113612
 dc.l 113971
 dc.l 114329
 dc.l 114688
 dc.l 115046
 dc.l 115404
 dc.l 115763
 dc.l 116121
 dc.l 116480
 dc.l 116838
 dc.l 117196
 dc.l 117555
 dc.l 117913
 dc.l 118272
 dc.l 118630
 dc.l 118988
 dc.l 119347
 dc.l 119705
 dc.l 120064
 dc.l 120422
 dc.l 120780
 dc.l 121139
 dc.l 121497
 dc.l 121856
 dc.l 122214
 dc.l 122572
 dc.l 122931
 dc.l 123289
 dc.l 123648
 dc.l 124006
 dc.l 124364
 dc.l 124723
 dc.l 125081
 dc.l 125440
 dc.l 125798
 dc.l 126156
 dc.l 126515
 dc.l 126873
 dc.l 127232
 dc.l 127590
 dc.l 127948
 dc.l 128307
 dc.l 128665
 dc.l 129024
 dc.l 129382
 dc.l 129740
 dc.l 130099
 dc.l 130457
 dc.l 130816
 dc.l 131174
 dc.l 131532
 dc.l 131891
 dc.l 132249
 dc.l 132608
 dc.l 132966
 dc.l 133324
 dc.l 133683
 dc.l 134041
 dc.l 134400
 dc.l 134758
 dc.l 135116
 dc.l 135475
 dc.l 135833
 dc.l 136192
 dc.l 136550
 dc.l 136908
 dc.l 137267
 dc.l 137625
 dc.l 137984
 dc.l 138342
 dc.l 138700
 dc.l 139059
 dc.l 139417
 dc.l 139776
 dc.l 140134
 dc.l 140492
 dc.l 140851
 dc.l 141209
 dc.l 141568
 dc.l 141926
 dc.l 142284
 dc.l 142643
 dc.l 143001
 dc.l 143360
 dc.l 143718
 dc.l 144076
 dc.l 144435
 dc.l 144793
 dc.l 145152
 dc.l 145510
 dc.l 145868
 dc.l 146227
 dc.l 146585
 dc.l 146944
 dc.l 147302
 dc.l 147660
 dc.l 148019
 dc.l 148377
 dc.l 148736
 dc.l 149094
 dc.l 149452
 dc.l 149811
 dc.l 150169
 dc.l 150528
 dc.l 150886
 dc.l 151244
 dc.l 151603
 dc.l 151961
 dc.l 152320
 dc.l 152678
 dc.l 153036
 dc.l 153395
 dc.l 153753
 dc.l 154112
 dc.l 154470
 dc.l 154828
 dc.l 155187
 dc.l 155545
 dc.l 155904
 dc.l 156262
 dc.l 156620
 dc.l 156979
 dc.l 157337
 dc.l 157696
 dc.l 158054
 dc.l 158412
 dc.l 158771
 dc.l 159129
 dc.l 159488
 dc.l 159846
 dc.l 160204
 dc.l 160563
 dc.l 160921
 dc.l 161280
 dc.l 161638
 dc.l 161996
 dc.l 162355
 dc.l 162713
 dc.l 163072
 dc.l 163430
 dc.l 163788
 dc.l 164147
 dc.l 164505
 dc.l 164864
 dc.l 165222
 dc.l 165580
 dc.l 165939
 dc.l 166297
 dc.l 166656
 dc.l 167014
 dc.l 167372
 dc.l 167731
 dc.l 168089
 dc.l 168448
 dc.l 168806
 dc.l 169164
 dc.l 169523
 dc.l 169881
 dc.l 170240
 dc.l 170598
 dc.l 170956
 dc.l 171315
 dc.l 171673
 dc.l 172032
 dc.l 172390
 dc.l 172748
 dc.l 173107
 dc.l 173465
 dc.l 173824
 dc.l 174182
 dc.l 174540
 dc.l 174899
 dc.l 175257
 dc.l 175616
 dc.l 175974
 dc.l 176332
 dc.l 176691
 dc.l 177049
 dc.l 177408
 dc.l 177766
 dc.l 178124
 dc.l 178483
 dc.l 178841
 dc.l 179200
 dc.l 179558
 dc.l 179916
 dc.l 180275
 dc.l 180633
 dc.l 180992
 dc.l 181350
 dc.l 181708
 dc.l 182067
 dc.l 182425
 dc.l 182784
 dc.l 183142
 dc.l 183500
 dc.l 183859
 dc.l 184217
 dc.l 184576
 dc.l 184934
 dc.l 185292
 dc.l 185651
 dc.l 186009
 dc.l 186368
 dc.l 186726




persp_table_min:
 dc.l 3584
 dc.l 3318
 dc.l 3089
 dc.l 2890
 dc.l 2715
 dc.l 2560
 dc.l 2421
 dc.l 2297
 dc.l 2185
 dc.l 2083
 dc.l 1991
 dc.l 1906
 dc.l 1828
 dc.l 1756
 dc.l 1690
 dc.l 1629
 dc.l 1571
 dc.l 1518
 dc.l 1468
 dc.l 1422
 dc.l 1378
 dc.l 1337
 dc.l 1298
 dc.l 1262
 dc.l 1227
 dc.l 1194
 dc.l 1163
 dc.l 1134
 dc.l 1106
 dc.l 1079
 dc.l 1054
 dc.l 1029
 dc.l 1006
 dc.l 984
 dc.l 963
 dc.l 943
 dc.l 923
 dc.l 905
 dc.l 887
 dc.l 869
 dc.l 853
 dc.l 837
 dc.l 822
 dc.l 807
 dc.l 792
 dc.l 779
 dc.l 765
 dc.l 752
 dc.l 740
 dc.l 728
 dc.l 716
 dc.l 705
 dc.l 694
 dc.l 684
 dc.l 673
 dc.l 663
 dc.l 654
 dc.l 644
 dc.l 635
 dc.l 626
 dc.l 617
 dc.l 609
 dc.l 601
 dc.l 593
 dc.l 585
 dc.l 578
 dc.l 570
 dc.l 563
 dc.l 556
 dc.l 549
 dc.l 543
 dc.l 536
 dc.l 530
 dc.l 524
 dc.l 517
 dc.l 512
 dc.l 506
 dc.l 500
 dc.l 495
 dc.l 489
 dc.l 484
 dc.l 479
 dc.l 474
 dc.l 469
 dc.l 464
 dc.l 459
 dc.l 454
 dc.l 450
 dc.l 445
 dc.l 441
 dc.l 437
 dc.l 432
 dc.l 428
 dc.l 424
 dc.l 420
 dc.l 416
 dc.l 412
 dc.l 409
 dc.l 405
 dc.l 401
 dc.l 398
 dc.l 394
 dc.l 391
 dc.l 387
 dc.l 384
 dc.l 381
 dc.l 378
 dc.l 374
 dc.l 371
 dc.l 368
 dc.l 365
 dc.l 362
 dc.l 359
 dc.l 357
 dc.l 354
 dc.l 351
 dc.l 348
 dc.l 345
 dc.l 343
 dc.l 340
 dc.l 338
 dc.l 335
 dc.l 333
 dc.l 330
 dc.l 328
 dc.l 325
 dc.l 323
 dc.l 321
 dc.l 318
 dc.l 316
 dc.l 314
 dc.l 312
 dc.l 310
 dc.l 307
 dc.l 305
 dc.l 303
 dc.l 301
 dc.l 299
 dc.l 297
 dc.l 295
 dc.l 293
 dc.l 291
 dc.l 290
 dc.l 288
 dc.l 286
 dc.l 284
 dc.l 282
 dc.l 280
 dc.l 279
 dc.l 277
 dc.l 275
 dc.l 274
 dc.l 272
 dc.l 270
 dc.l 269
 dc.l 267
 dc.l 265
 dc.l 264
 dc.l 262
 dc.l 261
 dc.l 259
 dc.l 258
 dc.l 256
 dc.l 255
 dc.l 253
 dc.l 252
 dc.l 251
 dc.l 249
 dc.l 248
 dc.l 246
 dc.l 245
 dc.l 244
 dc.l 242
 dc.l 241
 dc.l 240
 dc.l 238
 dc.l 237
 dc.l 236
 dc.l 235
 dc.l 233
 dc.l 232
 dc.l 231
 dc.l 230
 dc.l 229
 dc.l 228
 dc.l 226
 dc.l 225
 dc.l 224
 dc.l 223
 dc.l 222
 dc.l 221
 dc.l 220
 dc.l 219
 dc.l 218
 dc.l 216
 dc.l 215
 dc.l 214
 dc.l 213
 dc.l 212
 dc.l 211
 dc.l 210
 dc.l 209
 dc.l 208
 dc.l 207
 dc.l 206
 dc.l 206
 dc.l 205
 dc.l 204
 dc.l 203
 dc.l 202
 dc.l 201
 dc.l 200
 dc.l 199
 dc.l 198
 dc.l 197
 dc.l 196
 dc.l 196
 dc.l 195
 dc.l 194
 dc.l 193
 dc.l 192
 dc.l 191
 dc.l 191
 dc.l 190
 dc.l 189
 dc.l 188
 dc.l 187
 dc.l 187
 dc.l 186
 dc.l 185
 dc.l 184
 dc.l 184
 dc.l 183
 dc.l 182
 dc.l 181
 dc.l 181
 dc.l 180
 dc.l 179
 dc.l 178
 dc.l 178
 dc.l 177
 dc.l 176
 dc.l 176
 dc.l 175
 dc.l 174
 dc.l 174
 dc.l 173
 dc.l 172
 dc.l 172
 dc.l 171
 dc.l 170
 dc.l 170
 dc.l 169
 dc.l 168
 dc.l 168
 dc.l 167
 dc.l 166
 dc.l 166
 dc.l 165
 dc.l 165
 dc.l 164
 dc.l 163
 dc.l 163
 dc.l 162
 dc.l 162
 dc.l 161
 dc.l 160
 dc.l 160
 dc.l 159
 dc.l 159
 dc.l 158
 dc.l 158
 dc.l 157
 dc.l 156
 dc.l 156
 dc.l 155
 dc.l 155
 dc.l 154
 dc.l 154
 dc.l 153
 dc.l 153
 dc.l 152
 dc.l 152
 dc.l 151
 dc.l 151
 dc.l 150
 dc.l 150
 dc.l 149
 dc.l 149
 dc.l 148
 dc.l 148
 dc.l 147
 dc.l 147
 dc.l 146
 dc.l 146
 dc.l 145
 dc.l 145
 dc.l 144
 dc.l 144
 dc.l 143
 dc.l 143
 dc.l 142
 dc.l 142
 dc.l 142
 dc.l 141
 dc.l 141
 dc.l 140
 dc.l 140
 dc.l 139
 dc.l 139
 dc.l 138
 dc.l 138
 dc.l 138
 dc.l 137
 dc.l 137
 dc.l 136
 dc.l 136
 dc.l 136
 dc.l 135
 dc.l 135
 dc.l 134
 dc.l 134
 dc.l 133
 dc.l 133
 dc.l 133
 dc.l 132
 dc.l 132
 dc.l 132
 dc.l 131
 dc.l 131
 dc.l 130
 dc.l 130
 dc.l 130
 dc.l 129
 dc.l 129
 dc.l 128
 dc.l 128
 dc.l 128
 dc.l 127
 dc.l 127
 dc.l 127
 dc.l 126
 dc.l 126
 dc.l 126
 dc.l 125
 dc.l 125
 dc.l 125
 dc.l 124
 dc.l 124
 dc.l 123
 dc.l 123
 dc.l 123
 dc.l 122
 dc.l 122
 dc.l 122
 dc.l 121
 dc.l 121
 dc.l 121
 dc.l 120
 dc.l 120
 dc.l 120
 dc.l 119
 dc.l 119
 dc.l 119
 dc.l 119
 dc.l 118
 dc.l 118
 dc.l 118
 dc.l 117
 dc.l 117
 dc.l 117
 dc.l 116
 dc.l 116
 dc.l 116
 dc.l 115
 dc.l 115
 dc.l 115
 dc.l 115
 dc.l 114
 dc.l 114
 dc.l 114
 dc.l 113
 dc.l 113
 dc.l 113
 dc.l 113
 dc.l 112
 dc.l 112
 dc.l 112
 dc.l 111
 dc.l 111
 dc.l 111
 dc.l 111
 dc.l 110
 dc.l 110
 dc.l 110
 dc.l 109
 dc.l 109
 dc.l 109
 dc.l 109
 dc.l 108
 dc.l 108
 dc.l 108
 dc.l 108
 dc.l 107
 dc.l 107
 dc.l 107
 dc.l 107
 dc.l 106
 dc.l 106
 dc.l 106
 dc.l 106
 dc.l 105
 dc.l 105
 dc.l 105
 dc.l 105
 dc.l 104
 dc.l 104
 dc.l 104
 dc.l 104
 dc.l 103
 dc.l 103
 dc.l 103
 dc.l 103
 dc.l 102
 dc.l 102
 dc.l 102
 dc.l 102
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 101
 dc.l 100
 dc.l 100
 dc.l 100
 dc.l 100
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 99
 dc.l 98
 dc.l 98
 dc.l 98
 dc.l 98
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 97
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 96
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 95
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 94
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 93
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 92
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 91
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 90
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 89
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 88
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 87
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 86
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 85
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 84
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 83
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 82
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 81
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 80
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 79
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 78
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 77
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 76
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 75
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 74
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 73
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 72
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 71
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 70
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 69
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 68
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 67
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 66
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 65
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 64
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 63
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 62
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 61
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 60
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 59
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 58
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 57
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 56
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 55
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 54
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 53
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 52
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 51
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 50
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 49
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 48
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 47
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 46
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 45
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 44
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43
 dc.l 43


