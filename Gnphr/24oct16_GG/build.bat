@ECHO OFF
ECHO *** GAME GEAR ***
ASMZ80.EXE /q /p /e MERCURY=1 main.asm,main.gg, ,out_gg.out
ECHO *** MASTER SYSTEM ***
ASMZ80.EXE /q /p /e MERCURY=0 main.asm,main.sms, ,out_ms.out
pause
