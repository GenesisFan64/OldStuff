@echo off
asm68k /p /o ae-  "main.asm", game.bin, , out.dat
fixheadr.exe game.bin
pause