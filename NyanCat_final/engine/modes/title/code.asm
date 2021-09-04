; =================================================================
; Title
; =================================================================

; ------------------------------------------------
; Variables
; ------------------------------------------------

		rsreset
vid_artstart	rs.l	1
vid_mapstart	rs.l	1
vid_keystart	rs.l	1

vid_artnext	rs.l	1
vid_mapnext	rs.l	1
vid_keynext	rs.l	1

vid_vram	rs.l	1		;FBR1FBR2
vid_keepframe	rs.l	1
vid_sound	rs.l 	1

vid_rate	rs.w	1
vid_timer	rs.w	1
vid_frmswitch	rs.w	1
vid_xsize	rs.w	1
vid_ysize	rs.w	1
vid_dmasize	rs.w	1
sizeof_vid	rs.l	0


vid_Plane_BG	equ	$60000003
vid_Plane_FG	equ	$70000003

; ------------------------------------------------
; RAM
; ------------------------------------------------

		rsset	RAM_ModeBuffer
RAM_FullMotVid	rs.b	sizeof_vid

; =================================================================
; ------------------------------------------------
; Init
; ------------------------------------------------

mode_Title:
		move.l	#ID_FadeOut,d0
 		move.l	#$003F0001,d1
 		bsr	PalFade_Set
 		bsr	PalFade_Wait

		move.w	#$2700,sr
		
; -----------------------------------
; Cleanup
; -----------------------------------

		bsr	Vdp_ClearPlanes
		bsr	Mode_Cleanup
		
; -----------------------------------
; Init stuff
; -----------------------------------

		move.l	#VInt_Default,(RAM_VIntAddr)
		move.l	#Hint_Default,(RAM_HIntAddr)
		lea	(RAM_VdpRegs),a0
		move.b	#vdp_H32,vdpReg_HMode(a0)
		move.b	#0,vdpReg_PlnSize(a0)
		bsr	Vdp_Update
		
; -----------------------------------
		
;                 moveq	#0,d0
;                 move.l	(RAM_Joypads),d0
;                 move.l	#vid_Plane_BG,d1
;                 move.w	#$8000,d2
;                bsr	VDP_ShowVal_Long
               
  		lea	Art_TempFont(pc),a0
  		move.w	#$320,d0
  		move.w	#((Art_TempFont_End-Art_TempFont)/4)-1,d1
  		bsr	VDP_SendData_L
  		
  		lea	(Vid_Data),a0
  		move.w	#2,d0
  		move.w	#$001,d1
  		move.w	#$200,d2
  		bsr	MegaVid_Load
  		
; 		lea	(Map_Title),a0
; 		move.l	#Plane_BG,d0
; 		move.w	#(256/8)-1,d1
; 		move.w	#((224/4)/8)-1,d2
; 		moveq	#0,d3
; 		moveq	#0,d4
; 		bsr	MegaVid_LoadMaps
; 		lea	(Map_Title),a0
; 		move.l	#Plane_BG+(vdp_Ypos_32*7),d0
; 		move.w	#(256/8)-1,d1
; 		move.w	#((224/4)/8)-1,d2
; 		move.w	#($E0)+$2000+1,d3
; 		moveq	#0,d4
; 		bsr	MegaVid_LoadMaps
; 		lea	(Map_Title),a0
; 		move.l	#Plane_BG+(vdp_Ypos_32*(7*2)),d0
; 		move.w	#(256/8)-1,d1
; 		move.w	#((224/4)/8)-1,d2
; 		move.w	#($E0*2)+$4000+2,d3
; 		moveq	#0,d4
; 		bsr	MegaVid_LoadMaps
; 		lea	(Map_Title),a0
; 		move.l	#Plane_BG+(vdp_Ypos_32*(7*3)),d0
; 		move.w	#(256/8)-1,d1
; 		move.w	#((224/4)/8)-1,d2
; 		move.w	#($E0*3)+$6000+3,d3
; 		moveq	#0,d4
; 		bsr	MegaVid_LoadMaps
; 		
; 		lea	(Art_Title),a0
; 		move.w	#0,d0
; 		move.w	#((Art_Title_End-Art_Title)/4)-1,d1
; 		bsr	VDP_SendData_L
  		
;          	move.l	#TestSong,d0
;           	moveq	#2,d1
;           	bsr	Smeg_LoadSong

       		move.w	#$E8,d0
       		btst	#6,($A10001)
       		beq.s	@ntsc
       		move.w	#$C8,d0
@ntsc:
       		move.w	d0,(RAM_ModeBuffer+$80)
       		
; -----------------------------------
 		
		move.w	#$2000,sr
		
@wait:
		bsr	VSync
		sub.w	#1,(RAM_ModeBuffer+$80)
		bpl.s	@wait
		clr.w	(RAM_ModeBuffer+$80)
 		lea	(Pal_Title),a0
   		lea	(RAM_PalBuffer),a1
   		moveq	#((Pal_Title_End-Pal_Title)/2)-1,d0
   		bsr	LoadData_Word
		
; 		move.l	#ID_FadeIn,d0
; 		move.l	#$003F0001,d1
; 		bsr	PalFade_Set
; 		bsr	PalFade_Wait
		
; =================================================================
; ------------------------------------------------
; Loop
; ------------------------------------------------

Title_Loop:
		bsr 	VSync
		
  		bsr	MegaVid_Run
		
;                 moveq	#0,d0
;                 move.l	(RAM_Joypads),d0
;                 move.l	#Plane_FG,d1
;                 move.w	#$8560+"0"+$6000,d2
;                 bsr	VDP_ShowVal_Long
;                 moveq	#0,d0
;                 move.l	(RAM_Joypads+4),d0
;                 move.l	#Plane_FG+(vdp_Xpos*8),d1
;                 move.w	#$8560+"0"+$6000,d2
;                 bsr	VDP_ShowVal_Long
                
;  		btst	#bitJoyStart,(RAM_Joypads+OnPress)
;  		beq.s	@keep
;  		move.b	#1,(RAM_GameMode)
; 		rts	
; @keep:
		bra	Title_Loop
		
; =================================================================
; ------------------------------------------------
; Subs
; ------------------------------------------------
		
MegaVid_Load:
		lea	(RAM_FullMotVid),a6
		move.w 	d0,vid_rate(a6)
		move.w	d1,vid_vram(a6)
		move.w	d2,vid_vram+2(a6)
		
		movea.l	(a0)+,a1
 		move.l	(a0)+,d0
 		move.l	d0,vid_artstart(a6)
 		move.l	d0,vid_artnext(a6)
 		move.l	(a0)+,d0
 		move.l	d0,vid_mapstart(a6)
 		move.l	d0,vid_mapnext(a6)
  		adda 	#4,a0			;later for dynpalette
  		
  		move.l	(a1),d0
  		move.w	6(a1),vid_xsize(a6)
  		move.w	8(a1),vid_ysize(a6)
  		adda 	#$10,a1
 		move.l	a1,vid_keystart(a6)
 		move.l	a1,vid_keynext(a6)
		
		moveq	#0,d2
    		move.l	8(a1),d2
    		lsl.w	#4,d2
  		move.w	vid_vram(a6),d0
  		bsr	VDP_VramAddr
 		move.l	vid_artnext(a6),d1
 		bsr	MegaVid_LoadDmaArt

    		movea.l	vid_keynext(a6),a1
    		move.l	$C(a1),d0
    		lsl.w	#1,d0
    		move.w	d0,vid_keepframe(a6)
 		movea.l	vid_mapnext(a6),a0
  		move.l	#vid_Plane_BG,d0
  		move.w	vid_xsize(a6),d1
  		move.w	vid_ysize(a6),d2
  		move.w	vid_vram(a6),d3
;   		add.w	#$8000,d3
  		moveq	#0,d4
  		bsr	VDP_LoadMaps
 		
		lea	(RAM_VdpRegs),a0
;   		move.b	#$38,2(a0)			;Layer A address
		move.b	#vdp_H32,vdpReg_HMode(a0)	;H32 mode
		move.b	#0,vdpReg_PlnSize(a0)		;Plane size: 32x32
		bsr	Vdp_Update
		
  		bsr	MegaVid_PlaySound
   		bra	MegaVid_Run
@Bad:
		rts
		
; ------------------------------------------------

MegaVid_Run:
		lea	(RAM_FullMotVid),a6
		sub.w	#1,vid_timer(a6)
 		bpl	@wait 
 		move.w	vid_rate(a6),vid_timer(a6)

   		tst.w	vid_keepframe(a6)
   		beq	@Valid
   		bpl	@CountFrame
@Valid:

 		movea.l	vid_keynext(a6),a1

 		moveq	#0,d2
     		move.l	8(a1),d2
     		lsl.w	#4,d2
    		move.w	vid_vram(a6),d0
      		tst.b	vid_frmswitch(a6)
      		bne.s	@Fine
      		move.w	vid_vram+2(a6),d0
@Fine:
  		bsr	VDP_VramAddr
  		move.l	vid_artnext(a6),d1
  		bsr	MegaVid_LoadDmaArt
 		
    		move.l	$C(a1),d0
    		lsl.w	#1,d0
    		move.w	d0,vid_keepframe(a6)
 	
		movea.l	vid_mapnext(a6),a0
 		move.l	#vid_Plane_BG,d0
;     		tst.b	vid_frmswitch(a6)
;     		bne.s	@Fine3
;  		move.l	#vid_Plane_BG+(vdp_Xpos*32),d0
; @Fine3:
 		move.w	vid_xsize(a6),d1
 		move.w	vid_ysize(a6),d2
  		move.w	vid_vram(a6),d3
    		tst.b	vid_frmswitch(a6)
    		bne.s	@Fine2
  		move.w	vid_vram+2(a6),d3
@Fine2:
;   		add.w	#$8000,d3
 		moveq	#0,d4
 		bsr	VDP_LoadMaps
 		bchg	#0,vid_frmswitch(a6)
 		
;  		moveq	#0,d0
;     		tst.b	vid_frmswitch(a6)
;     		beq.s	@Fine4
;  		move.w	#-$100,d0
; @Fine4:
; 		move.w	d0,(RAM_HorBuffer)
; 		move.w	d0,(RAM_HorBuffer+2)
		
		movea.l	vid_keynext(a6),a0
 		tst.l	(a0)
 		bpl.s 	@Keep_Play
 		
		move.l	vid_artstart(a6),vid_artnext(a6)
		move.l 	vid_mapstart(a6),vid_mapnext(a6)
		move.l 	vid_keystart(a6),vid_keynext(a6)
 		rts
;  		bra	MegaVid_PlaySound
 		
@Keep_Play:
   		move.l 	vid_artstart(a6),d0
    		move.l 	4(a0),d1
    		add.l	d1,d0 
    		move.l	d0,vid_artnext(a6)
   		
   		move.l 	vid_mapstart(a6),d0
   		move.l 	(a0),d1
   		add.l	d1,d0 
   		move.l	d0,vid_mapnext(a6)
 		
 		add.l	#$10,vid_keynext(a6)
	
@CountFrame:
   		sub.w	#1,vid_keepframe(a6)
@Wait:
		rts

; ------------------------------------------------

; MegaVid_LoadMaps:
		move.b	(RAM_VdpRegs+vdpReg_PlnSize),d4
 		and.w	#%00000011,d4
 		lsl.w	#2,d4
 		lea	VDP_LineAddr(pc),a5
 		move.l	(a5),d4
@Y_Loop:
		move.l	d0,($C00004).l		;Set VDP location from d0
		move.w	d1,d5	  		;Move X-pos value to d3
@X_Loop:
		move.w	(a0)+,d6
		cmp.w	#$7FF,d6
		beq.s 	@cont
                add.w	d3,d6  
@cont:
                move.w	d6,($C00000)		;Put data
		dbf	d5,@X_Loop		;X-pos loop (from d1 to d3)
		add.l	d4,d0                   ;Next line
		dbf	d2,@Y_Loop		;Y-pos loop
		rts

; -----------------------------------

MegaVid_LoadDmaArt:
		movem.l	a1-a2,-(sp)
		move.l	d1,a1
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
		
; ------------------------------------------------

MegaVid_PlaySound:
		move.l	#Sample_1,d0
		move.l	#Sample_1_End,d1
		move.l	#Sample_1+63036,d2
		moveq	#1,d3
;  		bsr	PlaySample
 		
PlaySample:
		move.w	#$100,($A11100).l
@WaitZ80:
		btst	#0,($A11100).l
		bne.s	@WaitZ80

		lea	($A001E0),a0
		;Start
		moveq	#0,d4
		tst.w	d0
		bpl.s	@plus_s
		move.w	#$81,d4
@plus_s:
		swap	d0
		swap	d4
		move.b	d0,d4
		swap	d4
		swap	d0
		move.b	d4,(a0)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a0)+		;		$xx0000
		swap	d4
		move.b	d0,(a0)+		;start Addr	$00xx
		lsr.w	#8,d0
		move.b	d0,(a0)+		;		$xx00
		
		;Loop
		moveq	#0,d4
		tst.w	d1
		bpl.s	@plus_e
		move.w	#$81,d4
@plus_e:
		swap	d1
		swap	d4
		move.b	d1,d4
		swap	d4
		swap	d1
		move.b	d4,(a0)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a0)+		;		$xx0000
		swap	d4
		move.b	d1,(a0)+		;start Addr	$00xx
		lsr.w	#8,d1
		move.b	d1,(a0)+		;		$xx00
		
		;End
		moveq	#0,d4
		tst.w	d2
		bpl.s	@plus_l
		move.w	#$81,d4
@plus_l:
		swap	d2
		swap	d4
		move.b	d2,d4
		swap	d4
		swap	d2
		move.b	d4,(a0)+		;start Bank	+$8000
		swap	d4
		move.b	d4,(a0)+		;		$xx0000
		swap	d4
		move.b	d2,(a0)+		;start Addr	$00xx
		lsr.w	#8,d2
		move.b	d2,(a0)+		;		$xx00
		
		moveq	#$3C+12,d0		; NOTE
  		sub.w	#12-1,d0
		move.w	d0,d1
		lsl.w	#6,d1
		add.w	#$200,d1
		move.b	d1,($A000F6)		; ld bc,(NEW ADDRESS)
		lsr.w	#8,d1			;
		move.b	d1,($A000F7)		;
		
		moveq	#1,d0			; TODO: Loop flag
		lsl.b	#1,d0
		bset	#0,d0
		move.b	d0,($A001E0+$D)
		
 		move.w  #$0,($A11100)
		rts
    		
; ================================================================
; Z80
; ================================================================

Z80_Init:
		move.w	#$100,($A11100).l
		move.w	#$100,($A11200).l
@WaitZ80:
		btst	#0,($A11100).l
		bne.s	@WaitZ80

		lea	($A00000).l,a0
		move.w	#$1FFF,d0
@cleanup:
		clr.b	(a0)+
		dbf	d0,@cleanup
		
		lea	Z80Driver(pc),a0
		lea	($A00000).l,a1
		move.w	#Z80DriverEnd-Z80Driver,d1
@ToZ80:
		move.b	(a0)+,(a1)+
		dbf	d1,@ToZ80

; -----------------------------------

		move.w	#0,($A11200).l
		nop
		nop
		nop
		nop
		move.w	#$100,($A11200).l
		move.w	#0,($A11100).l
		rts
		

; ---------------------------------------------------

Z80Driver:	incbin	"engine/sound/data/z80/main.bin"
Z80DriverEnd:
		even
		
; =================================================================
; ------------------------------------------------
; Hblank
; ------------------------------------------------
		
; =================================================================
; ------------------------------------------------
; VBlank
; ------------------------------------------------
	
Art_TempFont:	incbin	"engine/shared/data/art_dbgfont.bin",0,($20*96)
Art_TempFont_End:
		even
		
Pal_Title:	incbin	"engine/modes/Title/data/vidtest/pal.bin"
Pal_Title_End:
		even
		