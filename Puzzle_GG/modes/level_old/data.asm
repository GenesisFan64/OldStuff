; ====================================================================
; -------------------------------------------------
; DATA | Level
; -------------------------------------------------

art_level_test:	incbin "modes/level/data/levels/test/lvl_art.bin",0,(100h*20h)
pal_level_test:	incbin "modes/level/data/levels/test/lvl_pal.bin",0,(32*2)

test_level:	dw @blocks,@collision,@prizes,@objpos
		incbin "modes/level/data/levels/test/lvl_lay.bin"
@blocks:	incbin "modes/level/data/levels/test/lvl_blk.bin"
@collision:	incbin "modes/level/data/levels/test/lvl_col.bin"
@prizes:	dw -1
@objpos:	dw -1