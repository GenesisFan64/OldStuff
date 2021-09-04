; ====================================================================
; MARS VDP
; ====================================================================

; -------------------------------------------------
; Variables
; -------------------------------------------------

VIDEO_XSIZE	equ	384
VIDEO_YSIZE	equ	256

; ====================================================================
; -------------------------------------------------
; Structures
; -------------------------------------------------

; -------------------------------------------------
; RAM
; -------------------------------------------------

		rsset RAM_Video
frame_count_m	rs.l 1
frame_count_s	rs.l 1
frame_wait	rs.l 1
fb_num		rs.l 1
layer_topleft	rs.l 1

RAM_ScrlHor	rs.l 240
RAM_ScrlVer	rs.l 1
RAM_Palette	rs.w 256
RAM_PalFade	rs.w 256
RAM_Layer	rs.b 512*256
RAM_PolygonSys	rs.b $18000
sizeof_video	rs.l 0
		inform 0,"MARS SH2 Video size: %h",(sizeof_video-RAM_Video)
		
; ====================================================================
; -------------------------------------------------
; Init
; -------------------------------------------------

Video_Init:
		mov 	#0,r0
  		mov.b	@(adapter,gbr),r0
  		mov 	r0,r1
@chk_md:
  		mov	@r1,r0
  		and 	#%10000000,r0		; MD is using FB?
  		bf	@chk_md
		mov 	#FM,r0			; FB to MARS
  		mov.b	r0,@(adapter,gbr)
  		
; ----------------------------
; Line array init
; ----------------------------

		mov	pr,@-r15
		bsr	VideoRender_Init
		nop
		bsr	VideoRender_Init
		nop
		mov	@r15+,pr

		rts
		nop
		align 4
		lits
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

; ----------------------------
; Video_Render
; 
; apply scroll and
; swap framebuffer
; ----------------------------

Video_Render:
		mov	#RAM_Palette,r7		;palette Copy
		mov	#_palette,r8
 		mov	#256/16,r6
  		mov	#_vdpreg,r5
  		
@wait		mov.b	@(vdpsts,r5),r0
		tst	#0x20,r0
		bt	@wait
@nextpal:
		rept	16
		mov.w	@r7+,r0
		mov.w	r0,@r8
		add 	#2,r8
		endr	
		dt	r6
		bf	@nextpal
		
; --------------------------
; SCROLLING
; --------------------------

VideoRender_Init:
		mov	#RAM_ScrlHor,r7
		mov	#RAM_ScrlVer,r8
		
; 		mov 	@r7,r0
; 		mov 	#$4000,r1
; 		add 	r1,r0
; 		mov 	r0,@r7
; 		mov 	@r8,r0
; 		mov 	#$10000,r1
; 		add 	r1,r0
; 		mov 	r0,@r8
		
; Fix the X

		mov 	@r7,r0
		shlr16	r0
		exts	r0,r0
		cmp/pl	r0
		bt	@right
		mov 	#$80,r1
		sub 	r1,r0
@right:
		mov 	r0,r1
		mov 	#$7F,r2
		and 	r2,r1
		mov 	#$7F80,r2
		and 	r2,r0
		shlr2	r0
		shlr2	r0
		shlr	r0
		mov 	#tableVidHorCrop,r2
		mov 	@(r2,r0),r0
		add 	r1,r0
		mov 	@r7,r1
		shlr16	r1
		mov 	#0,r2
		and 	r2,r1
		or	r1,r0
		mov	#layer_topleft,r2
		mov 	r0,@r2
		
 		mov	#_framebuffer,r9
		mov	#$100,r6
		mov	#((VIDEO_XSIZE))/2,r5
		mov	#240,r4
		mov	#layer_topleft,r2
		mov 	@r2,r0
		shlr 	r0
		mov 	r0,r10
		mov 	@r8,r3
		shlr16	r3
@mapset1:
		mov 	r10,r0
		
		; Vertical
		mov 	r3,r1
		mov 	#$FF,r2
		and 	r2,r1
		mulu	r5,r1
		mov 	macl,r1
		add 	r1,r0	
		add 	r6,r0
		
		mov.w	r0,@r9
		add	#2,r9
		add	#1,r3
		
		dt	r4
		bf	@mapset1
; 
; ; Set SFT and Swap frame
; 
		mov	#_vdpreg,r9
		mov 	@r7,r0
		shlr16	r0
		and 	#1,r0
		mov.w 	r0,@(2,r9)
 		mov.b	@(framectl,r9),r0
		not	r0,r0
 		and	#1,r0
		rts
		mov.b	r0,@(framectl,r9)
		align 4
		
; -------------------------
; Grab a fixed X for
; framebuffer
; -------------------------

@draw_scroll:
		mov 	#layer_topleft,r1
		mov	@r1,r0
		mov 	#_framebuffer+$200,r1
		add 	r0,r1
		mov	#$FF,r0
		rts
		mov.b	r0,@r1
		align 4
		
; ----------------------------
; Clear full framebuffer
; ----------------------------

Video_ClearFrame:
		mov	#_vdpreg,r1
@wait2		mov.w	@(10,r1),r0	; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	@wait2
		
		mov	#255,r2			; 256 words per pass
		mov	#$100,r3		; Starting address
		mov	#0,r4		; Clear to zero
		mov	#256,r5			; Increment address by 256
		mov	#(((VIDEO_XSIZE)*224)/256)/2,r6	; 140 passes
@loop
		mov	r2,r0
		mov.w	r0,@(4,r1)	; Set length
		mov	r3,r0
		mov.w	r0,@(6,r1)	; Set address
		mov	r4,r0
		mov.w	r0,@(8,r1)	; Set data
		add	r5,r3
		
@wait		mov.w	@(10,r1),r0	; Wait for FEN to clear
		and	#%10,r0
		cmp/eq	#2,r0
		bt	@wait
		
		dt	r6
		bf	@loop
		rts
		nop
		align 4
		lits
		
; ----------------------------------
; Load TGA picture
; 
; Uses slave
; 
; r1 - file
; r2 - include palette yes/no
; ----------------------------------

Video_LoadTga:
  		mov	#RAM_Palette,r8
  		add 	r2,r8
  		
  		mov	#5,r0
  		add	r0,r1
 		mov	#0,r0
 		mov.b	@(1,r1),r0
 		and	#$FF,r0
 		shll8	r0
 		mov	r0,r6
 		mov.b	@r1,r0
 		and 	#$FF,r0
 		or	r0,r6
 		
 		mov	#$D,r0
 		add	r0,r1
		
@nextpal:
 		mov	#0,r4
		mov	#$F8,r3
		
		mov	#0,r5
 		mov.b	@r1+,r5
 		and	r3,r5
 		shll8	r5
 		shlr	r5
 		or	r5,r4
		mov	#0,r5
 		mov.b	@r1+,r5
 		and	r3,r5
 		shll2	r5
 		or	r5,r4
		mov	#0,r5
 		mov.b	@r1+,r5
 		and	r3,r5
 		shlr2	r5
 		shlr	r5
 		or	r5,r4
 		mov.w	r4,@r8
 		add	#2,r8
 		dt	r6
 		bf	@nextpal
;  		bra	@skipthis
;  		nop
; @no_pal:
; 		mov	#3,r0
; 		mulu	r0,r6
; 		mov 	macl,r0
; 		add	r0,r1
; 		
; @skipthis:
		rts
		nop 
		align 4
		lits
		
; ------------------
; grab the frame
; ------------------

;   		mov	#_framebuffer+$200,r8
; 		mov	#224,r6
; @next_y:
;  		mov	#(VIDEO_XSIZE)/2,r7
; @next_x:
; 		rept 2
;  		mov 	#0,r0
;  		mov.b	@r1+,r0
;  		mov.b	r0,@r8
;  		add	#1,r8
;  		endr
;  		
;  		dt	r7
;  		bf	@next_x
;  		
; ;  		mov	#(VIDEO_XSIZE)*4,r0
; ;  		add 	r0,r1
; ;  		add 	r0,r8
;  		dt	r6
;  		bf	@next_y
; 		rts
; 		nop
; 		align 4
; 		lits
		
; ----------------------------------
; VSync
; ----------------------------------

Vsync:
		mov 	#frame_wait,r1
		mov 	#1,r0
		mov 	r0,@r1
@wait_frame:
		mov	@r1,r0
		cmp/eq	#0,r0
		bf	@wait_frame
		rts
		nop
		align 4
		lits

		
;
; Switch frame buffers
;
; Tells frame buffer to swap next frame
;
; We separate out Switch_Frame_Buffer and Wait_Swap so we can start on
; calculations before frame buffer has swapped, then call Wait_Frame_Swap
; before we actually start rendering. This salvages CPU time which
; would normally be spent busy-waiting for frame buffer to swap.
;

Switch_Frame_Buffers

	mov	#_vdpreg,r1

	mov	#fb_num,r2
	mov.b	@(framectl,r1),r0
	xor	#1,r0
	mov.b	r0,@(framectl,r1)


	rts
	mov.b	r0,@r2
	align 4
	lits

;
; Wait frame swap
;
; Make sure frame buffer has swapped
;

Wait_Frame_Swap

	mov	#_vdpreg,r1
	mov	#fb_num,r2
	mov.b	@r2,r0
	mov	r0,r2

@wait3	mov.b	@(framectl,r1),r0
	cmp/eq	r0,r2
	bf	@wait3

	rts
	nop
	align 4
	lits
	
; ====================================================================
; -------------------------------------------------
; SLAVE helper
; -------------------------------------------------

Video_Slave:
; 		mov	#vid_slavecomm,r1
; 		mov	@r1,r0
; 		cmp/eq	#0,r0
; 		bt	@end
		
@end:
		rts
		nop 
		align 4
		lits

; ------------------------------------------------
; Data
; ------------------------------------------------	
	
tableVidHorCrop:
		rept 96
		dc.l $00
		dc.l $80
		dc.l $100
		endr
		
