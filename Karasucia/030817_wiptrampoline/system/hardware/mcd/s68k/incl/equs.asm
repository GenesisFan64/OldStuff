; =================================================================
; ----------------------------------------
; Shared vars
; ----------------------------------------

; -------------
; bits
; -------------

bitWRamMode	equ	2		;2M | 1M

; -------------
; Registers
; -------------

MemoryMode	equ	$02		;WORD
CommMain	equ	$0E		;BYTE
CommSub		equ	$0F		;BYTE
CommDataM	equ	$10		;Array (size: $E)
CommDataS	equ	$20		;Array (size: $E)

; =================================================================
; ----------------------------------------
; SUB CPU ONLY
; ----------------------------------------

; -------------
; PCM
; -------------

PCM		equ	$FF0000
ENV		equ	$01		; Envelope
PAN		equ	$03		; Panning (%RRRRLLLL, and negative)
FDL		equ	$05		; Sample rate $00xx
FDH		equ	$07		; Sample rate $xx00
LSL		equ	$09		; Loop address $xx00
LSH		equ	$0B		; Loop address $00xx
ST		equ	$0D		; Start address (only $x0, $x000)
Ctrl		equ	$0F		; Control register ($80 - Bank select, $C0 - Channel select)
OnOff		equ	$11		; Channel On/Off (BITS: 1 - off, 0 - on)

; =================================================================
