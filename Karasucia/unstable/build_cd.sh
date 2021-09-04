# CD Programs
wine tools/asm68k /q /p /e MCD=1 /e MARS=0 "engine/modes/title/mcd.asm","system/hardware/mcd/fs/PRG_TITL.BIN", ,"engine/modes/title/out_mcd.txt"
wine tools/asm68k /q /p /e MCD=1 /e MARS=0 "engine/modes/level/mcd.asm","system/hardware/mcd/fs/PRG_LEVL.BIN", ,"engine/modes/level/out_mcd.txt"

# Make ISO Filesystem
mkisofs -quiet -iso-level 1 -o "system/hardware/mcd/fs.bin" \
                          -pad "system/hardware/mcd/fs"
                          
# Main ISO
wine tools/asm68k /q /p /e MCD=1 /e MARS=0 system/mcd.asm,out/rom_cd.bin, ,out/out_mcd.txt


rm "system/hardware/mcd/fs.bin"
