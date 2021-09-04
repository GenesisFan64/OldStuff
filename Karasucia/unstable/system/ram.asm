; ====================================================================
; -------------------------------------------------
; RAM
; -------------------------------------------------

; ---------------------------
; Setup
; ---------------------------

                rsset	$FFFFBC00
RAM_ModeBuffer	rs.b	$2000
RAM_Engine      rs.b	$200
RAM_System      rs.b	$80
RAM_Input	rs.b	$80
RAM_Video       rs.b	$1000
RAM_Audio       rs.b	$400
endof_ram	rs.l	0
;      		inform  0,"RAM ends at: %h",endof_ram
