; ====================================================================
; -------------------------------------------------
; GAME
; -------------------------------------------------

		include	"system/macros.asm"
		include	"system/ram.asm"
		include	"system/hardware/map.asm"
		
; ====================================================================
; -------------------------------------------------
; Header / Init
; -------------------------------------------------

		if MARS
		include	"system/hardware/mars/68k/head.asm"	
		else
		include	"system/hardware/md/head.asm"
		endif
		
; ====================================================================
; -------------------------------------------------
; Subs
; -------------------------------------------------

		include	"system/video.asm"
		include	"system/misc.asm"
		include	"system/input/code.asm"
		include	"system/sound/68k/main.asm"
		
; ====================================================================
; -------------------------------------------------
; Main
; -------------------------------------------------

		include	"engine/md.asm"

; ====================================================================
; -------------------------------------------------
; 68k DATA
; -------------------------------------------------

; ====================================================================
; -------------------------------------------------
; MARS ONLY: sh2-ready DATA
; -------------------------------------------------

		if MARS
		obj *+$22000000
		
; --------------------------------------------
	
mdldata_cube:	dc.l @faces,@points,mdldata_material
@faces:		incbin "ideas/models/cube_fce.bin"
		align 4
@points: 	incbin "ideas/models/cube_vrt.bin"
		align 4
		
mdldata_sphere:	dc.l @faces,@points,mdldata_material
@faces:		incbin "ideas/models/sphere_fce.bin"
		align 4
@points: 	incbin "ideas/models/sphere_vrt.bin"
		align 4

mdldata_field:	dc.l @faces,@points,mdldata_material
@faces:		incbin "ideas/models/field_fce.bin"
		align 4
@points: 	incbin "ideas/models/field_vrt.bin"
		align 4

mdldata_world:	dc.l @faces,@points,mdldata_material
@faces:		incbin "ideas/models/world_fce.bin"
		align 4
@points: 	incbin "ideas/models/world_vrt.bin"
		align 4
	
mdldata_monkey:	dc.l @faces,@points,mdldata_material
@faces:		incbin "ideas/models/monkey_fce.bin"
		align 4
@points: 	incbin "ideas/models/monkey_vrt.bin"
		align 4
		
; --------------------------------------------

mdldata_material:

		;BETTY
       		dc.l $80000000|0		; ID
  		dc.l texturepack+$312		; Texture address     | (-1) Solid color mode
  		dc.l (320<<16)			; Texture Width+Entry | Solid color
  		dc.l 320,  0
  		dc.l   0,  0
  		dc.l   0,223
       		dc.l 320,223
       		
       		;ZACATE
;		tex_01
       		dc.l $80000000|1		; ID
  		dc.l texturepack+$312		; Texture address     | (-1) Solid color mode
  		dc.l (320<<16)			; Texture Width+Entry | Solid color
  		dc.l  63,224
  		dc.l   0,224
  		dc.l   0,287
       		dc.l  63,287

       		;CASAS
       		dc.l $80000000|2		; ID
  		dc.l texturepack+$312		; Texture address     | (-1) Solid color mode
  		dc.l (320<<16)			; Texture Width+Entry | Solid color
  		dc.l 127,288
  		dc.l   0,288
  		dc.l   0,365
       		dc.l 127,365
       		
       		;CAMINO,left
       		dc.l $80000000|3		; ID
  		dc.l texturepack+$312		; Texture address     | (-1) Solid color mode
  		dc.l (320<<16)			; Texture Width+Entry | Solid color
  		dc.l 127,224
  		dc.l  64,224
  		dc.l  64,287
       		dc.l 127,287
       		
       		;CAMINO, right
       		dc.l $80000000|4		; ID
  		dc.l texturepack+$312		; Texture address     | (-1) Solid color mode
  		dc.l (320<<16)			; Texture Width+Entry | Solid color
  		dc.l 191,224
  		dc.l 128,224
  		dc.l 128,287
       		dc.l 191,287
       		
		dc.l -1
		align 4

		cnop 0,$10000
		dc.b "AQUI"
texturepack:
		incbin "ideas/textures.tga"
		align 4
		
; --------------------------------------------
; SOUND
; --------------------------------------------

; 		dc.b "LEFT"
; 		incbin "ideas/L.wav",$2C,$1C8000
; 
; 		dc.b "RGHT"
; 		incbin "ideas/R.wav",$2C,$1C8000

; --------------------------------------------

		objend
		endif
		
; ====================================================================
; -------------------------------------------------
; END
; -------------------------------------------------
		
ROM_END:
		inform 0,"ROM Size: %h",ROM_END
		cnop 0,$80000
