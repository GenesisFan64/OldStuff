; ====================================================================
; -------------------------------------------------
; DATA | Title Screen
; -------------------------------------------------

art_title:
		incbin "modes/title/data/art.bin"
art_title_end	equ *-art_title

pal_title:	incbin "modes/title/data/pal.bin"
		incbin "modes/title/data/cat/pal.bin"
		
map_title:	incbin "modes/title/data/map.bin"