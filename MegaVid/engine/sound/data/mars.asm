; ---------------------------------------------
; PWM Samples for SMEG
; 
; MARS Samples MUST be here
; ---------------------------------------------

; pcm_warm_pad:	dc.l @End
;   		incbin "engine/sound/data/instruments/samples/pcm/chor.wav",$3A
; @End:

pcm_piano:	dc.l @End
  		incbin "engine/sound/data/instruments/samples/pcm/PIANRAVE.bin"
@End:
 		cnop 0,4
 		
pcm_brass_1:	dc.l @End
  		incbin "engine/sound/data/instruments/samples/pcm/CHOR.bin"
@End:
 		cnop 0,4
; 
; 
; 		cnop 0,4
; smp_testsong_02:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/2.wav",$2C,29036
; @End:
; 
; 		cnop 0,4
; smp_testsong_03:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/3.wav",$2C,28500
; @End:
; 
; 		cnop 0,4
; smp_testsong_09:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/9.wav",$2C,19798
; @End:
; 
; 		cnop 0,4
; smp_testsong_10:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/10.wav",$2C,28988
; @End:
; 
; 		cnop 0,4
; smp_testsong_11:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/11.wav",$2C,20362
; @End:
; 
; 		cnop 0,4
; smp_testsong_12:
; 		dc.l @End
;   		incbin 	"engine/sound/data/instruments/samples/pcm/new/12.wav",$2C,19100
; @End:

; ---------------------------------------------