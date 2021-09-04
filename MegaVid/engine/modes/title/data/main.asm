; =================================================================
; ------------------------------------------------
; Data
; ------------------------------------------------

Vid_Data:
		dc.l @Frames
		dc.l @GFX
		dc.l @Maps
		dc.l 0
@Frames:
		incbin	"engine/modes/Title/data/vidtest/frames.bin"
		even
@Maps:
		incbin	"engine/modes/Title/data/vidtest/map.bin"
		even

		cnop 0,$8000
@GFX:
		incbin	"engine/modes/Title/data/vidtest/art.bin"
		even
		
vidSound:
 		incbin	"engine/modes/Title/data/vidtest/video/sound.wav",$3A
vidSound_End:
		even

