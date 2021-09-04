; ====================================================================
; -------------------------------------------------
; Level
; -------------------------------------------------

; -------------------------------------------------
; Include
; -------------------------------------------------

		include	"modes/level/subs/object.asm"
		include	"modes/level/subs/level.asm"

; -------------------------------------------------
; Vars
; -------------------------------------------------

; -------------------------------------------------
; RAM
; -------------------------------------------------

			rsset ram_modebuffer
RAM_LevelBuffer		rb max_lvlprz
RAM_LevelPrizes		rb 100h 
RAM_ObjBuffer		rb sizeof_obj*max_objects
RAM_ObjJmpTo		rb 3			;0C3 + co + de
;    			inform 0,"%h",ram_levelbuffer
 			
; -------------------------------------------------
; Init
; -------------------------------------------------

Level:
  		ld	b,ID_FadeOut
  		ld	de,1F00h
  		call	PalFade_Set
    		call	PalFade_Wait
 		
 		di
		call	VDP_ClearLayer
		
  		ld	a,(ram_vdpregs)
		set	bit_HscrlBar,a
		res 	4,a
		ld	(ram_vdpregs),a
		call	Vdp_Update
		
; -----------------------------------

		bankdata BANK_LvlMd_Init
		
		ld      hl,pal_level_test
  		ld	ix,ram_palfadebuff
		ld	bc,0010h
 		call	PalFade_Load
		ld      hl,pal_player
  		ld	ix,ram_palfadebuff
		ld	bc,1010h
 		call	PalFade_Load
		ld	hl,art_level_test
		ld	bc,1620h
		ld	de,0
		call	WriteVRAM
		
; -----------------------------------

		bankdata BANK_LvlMd_Loop
		
		call	level_init
		ld	hl,test_level
		ld	bc,0
		ld	de,0
		call	level_load
		call	level_draw
		call	objects_init
		
		ld	bc,VBlank_Default
		ld	(ram_vintaddr),bc
		ld	bc,HBlank_Level
		ld	(ram_hintaddr),bc
		
 		ld	bc,obj_test
 		ld	(ram_objbuffer),bc
 		
; -----------------------------------

		ei
		call	level_run
		call	objects_run
		
  		ld	b,ID_FadeIn
  		ld	de,1F00h
  		call	PalFade_Set
   		call	PalFade_Wait
   		
; -------------------------------------------------
; Loop
; -------------------------------------------------

level_loop:
  		call	Sprites_Reset		
		call    vsync
		
   		call	level_run
   		
; --------------------

		ld	hl,ram_tilestovdp+200h
		xor	a
  		out 	(Vcom),a
  		ld	a,22h|WriteMask
    		out 	(Vcom),a
		ld	c,Vdata
		ld	b,80h
		otir

; --------------------

		call	objects_run
	
		jp      level_loop		; loop

; -------------------------------------------------
; HBlank
; -------------------------------------------------

HBlank_Level:
		ret
		
; -------------------------------------------------
; Subs
; -------------------------------------------------


		