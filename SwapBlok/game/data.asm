; ================================================================
; ------------------------------------------------------------
; DATA SECTION
; ------------------------------------------------------------

Map_Backgrd00:	binclude "game/graphics/ingame/backg00_map.bin"
		align 2

; ----------------------------------------------------
; Main game data
; ----------------------------------------------------

		align $1000
Art_PlyrCursor:
		binclude "game/graphics/ingame/cursor_art.bin"
Art_PlyrCursor_e:
		align 2
Art_BlockPzes:	binclude "game/graphics/ingame/blocks_art.bin"
Art_BlockPzes_e:
		align 2
Art_PlyrBorders:
		binclude "game/graphics/ingame/borders_art.bin"
Art_PlyrBorders_e:
		align 2
Art_Backgrd00:	binclude "game/graphics/ingame/backg00_art.bin"
Art_Backgrd00_e:
		align 2
		
Art_Title_FG:
		binclude "game/graphics/title/title_art.bin"
Art_Title_FG_e:
		align 2
Art_Title_BG:
		binclude "game/graphics/title/bg_art.bin"
Art_Title_BG_e:
		align 2
Art_MenuFont:
		binclude "game/graphics/title/menu_art.bin"
Art_MenuFont_e:
		align 2
		
; ----------------------------------------------------
; Sound data
; ----------------------------------------------------

		include "game/sound/data.asm"
