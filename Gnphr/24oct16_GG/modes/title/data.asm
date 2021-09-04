; ====================================================================
; -------------------------------------------------
; DATA | Title Screen
; -------------------------------------------------

art_title:	incbin "modes/title/data/art.bin"
art_title_end	equ *-art_title
pal_title:	incbin "modes/title/data/pal.bin"
map_title:	incbin "modes/title/data/map.bin"

; art_plhold_spr:	incbin	"modes/level/data/sprhold.bin"
; art_plhold_spr_end: