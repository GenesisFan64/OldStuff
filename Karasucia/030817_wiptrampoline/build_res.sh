# ----------------------------------------------
# Title screen
# ----------------------------------------------

# python tools/tga2md.py "engine/modes/title/data/tga/title.tga" \
# 			"engine/modes/title/data/art.bin" \
# 			"engine/modes/title/data/pal.bin" \
# 			"engine/modes/title/data/map.bin"
                       
# python tools/tga2md.py "engine/modes/title/data/tga/chabuelo.tga" \
# 			"engine/modes/title/data/art_2.bin" \
# 			"engine/modes/title/data/pal_2.bin" \
# 			"engine/modes/title/data/map_2.bin"

# ----------------------------------------------
# Levels
# ----------------------------------------------

# -----------
# DEFAULT
# -----------

python tools/tga2md.py "engine/modes/level/data/layouts/main/bg.tga" \
			"engine/modes/level/data/layouts/main/bg_art.bin" \
			"engine/modes/level/data/layouts/main/bg_pal.bin" \
			"engine/modes/level/data/layouts/main/bg_map.bin"
			
python tools/tga2blkmd.py "engine/modes/level/data/layouts/prizemap.tga" \
			  "engine/modes/level/data/layouts/prizes_art.bin" \
			  "engine/modes/level/data/layouts/prizes_map.bin" \
			  "False" \
			  0x340

python tools/tga2blkmd.py "engine/modes/level/data/layouts/coin.tga" \
			  "engine/modes/level/data/layouts/coin_art.bin" \
			  "False" \
			  "engine/modes/level/data/layouts/lvlitems_pal.bin" \
			  0x340

# -----------
# LAYOUTS
# -----------

python tools/tiled_folder.py "engine/modes/level/data/layouts/main/level_1.tmx" \
			"engine/modes/level/data/layouts/main/1/"  \
			"engine/modes/level/data/layouts/main/map16.tga" \
			"engine/modes/level/data/layouts/main/"
			
# python tools/tiled_folder.py "engine/modes/level/data/layouts/main/level_2.tmx" \
# 			"engine/modes/level/data/layouts/main/2/"  \
# 			False \
# 			False
# 
# python tools/tiled_folder.py "engine/modes/level/data/layouts/main/level_3.tmx" \
# 			"engine/modes/level/data/layouts/main/3/"  \
# 			False \
# 			False
# 			
# python tools/tiled_folder.py "engine/modes/level/data/layouts/main/level_4.tmx" \
# 			"engine/modes/level/data/layouts/main/4/"  \
# 			False \
# 			False
