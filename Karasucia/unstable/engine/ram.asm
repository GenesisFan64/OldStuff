; ====================================================================
; -------------------------------------------------
; RAM
; 
; Put your features here
; (players lives, keys, current level, map, etc.)
; -------------------------------------------------

                rsset	RAM_Engine
RAM_P1_Lives	rs.w	1
RAM_P1_Coins	rs.w	1
RAM_P1_Hits	rs.w	1
RAM_CurrLevel	rs.w	1
sizeof_engine	rs.l	0
; 		inform 0,"engine ram: %h",(sizeof_engine-RAM_Engine)
