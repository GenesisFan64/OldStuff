; ====================================================================
; -------------------------------------------------
; DATA | DPLC art and Level data
; -------------------------------------------------

art_player:	dw @right
 		dw @left
@right:		incbin	"modes/level/data/object/player/data/art.bin"
@left:		incbin	"modes/level/data/object/player/data/art_l.bin"

map_player:	include	"modes/level/data/object/player/data/map.asm"
plc_player:	include	"modes/level/data/object/player/data/plc.asm"

; -------------------------------------------------

test_level:	dw @blocks,@collision,@prizes,@objpos
		incbin "modes/level/data/levels/test/lvl_lay.bin"
@blocks:	incbin "modes/level/data/levels/test/lvl_blk.bin"
@collision:	incbin "modes/level/data/levels/test/lvl_col.bin"
@prizes:	dw -1
@objpos:	dw -1

		
