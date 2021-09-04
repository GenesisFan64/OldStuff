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
		
		cnop 0,$4000
Sample_1:	incbin	"engine/sound/data/z80/out.wav",$2C,0x1F0000
Sample_1_End:
		even

