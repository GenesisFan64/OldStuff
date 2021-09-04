; ====================================================================
; MARS Shared Data
; ====================================================================

; ------------------------------------------------
	
test_model:
		dc.l @faces
		dc.l @points
		dc.l @material
@faces:
		incbin "engine/misc/3dtest/signal/face.bin"
		cnop 0,4
@points:
		incbin "engine/misc/3dtest/signal/vert.bin"
		cnop 0,4
@material:
       		dc.l 0
  		dc.l tex_trfc_stop,32,$30
  		dc.w 32, 0
  		dc.w  0, 0
  		dc.w  0,31
       		dc.w 32,31
		dc.l -1
		cnop 0,4
		
; ------------------------------------------------

test_model_2:
		dc.l @faces
		dc.l @points
		dc.l @material
@faces:
		incbin "engine/misc/3dtest/lightsign/face.bin"
		cnop 0,4
@points:
		incbin "engine/misc/3dtest/lightsign/vert.bin"
		cnop 0,4
@material:
       		dc.l 0
  		dc.l texture+(32*32)*1,32,0		;red
  		dc.w 32, 0
  		dc.w  0, 0
  		dc.w  0,31
       		dc.w 32,31
       		dc.l 1
   		dc.l texture+(32*32)*2,32,0		;yellow
   		dc.w 32, 0
   		dc.w  0, 0
   		dc.w  0,31
       		dc.w 32,31
       		dc.l 2
   		dc.l texture+(32*32)*3,32,0		;green
   		dc.w 32, 0
   		dc.w  0, 0
   		dc.w  0,31
       		dc.w 32,31
		dc.l -1
		cnop 0,4
		
; ----------------------------------------------

texture:
		incbin "engine/misc/3dtest/lightsign/trfc_lights.data"
		cnop 0,4
tex_trfc_stop:
		incbin "engine/misc/3dtest/signal/trfc_stop.data"
		cnop 0,4
		