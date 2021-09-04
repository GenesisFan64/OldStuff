; ====================================================================
; -------------------------------------------------
; DATA | ingame Screen
; -------------------------------------------------

art_ingame:	incbin "modes/level/data/art.bin"
art_ingame_end	equ *-art_ingame
pal_ingame:	incbin "modes/level/data/pal.bin"

art_ponbg:	incbin "modes/level/data/bg_art.bin"
; map_ingame:	incbin "modes/level/data/map.bin"