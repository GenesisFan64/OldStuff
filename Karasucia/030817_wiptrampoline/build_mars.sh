# SH2
echo "---- sh2 side ----"
wine tools/asmsh /q /p /o i+ /o psh2 /o w- "system/hardware/mars/sh2/main.asm","system/hardware/mars/sh2/code.bin", ,"system/hardware/mars/sh2/out.out"

# 68K
echo "---- 68k side ----"
wine tools/asm68k /q /p /e MCD=0 /e MARS=1 "system/md.asm",out/rom_mars.bin, ,out/out_mars.txt

rm "system/hardware/mars/sh2/code.bin"
