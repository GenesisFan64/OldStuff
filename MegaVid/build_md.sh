echo "*** MD ***"

wine "tools/asm68k" /q /p /e SegaCD=0 /e MARS=0 "md/main.asm",rom_md.bin, ,"md/out.out"
#wine "tools/fixheadr" rom_md.bin