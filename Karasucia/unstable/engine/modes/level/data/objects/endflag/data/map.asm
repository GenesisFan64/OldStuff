@mappings:
		dc.w @frame_0-@mappings
		dc.w @frame_1-@mappings
		dc.w @frame_2-@mappings
@frame_0:
		dc.b $7

		dc.b $10,$C,$0,$0,$E0
		dc.b $E0,$B,$0,$4,$E8
		dc.b $0,$5,$0,$10,$E8
		dc.b $0,$C,$0,$14,$F8
		dc.b $E8,$E,$0,$18,$0
		dc.b $E0,$4,$0,$24,$8
		dc.b $0,$0,$0,$26,$18
		even
@frame_1:
		dc.b $7

		dc.b $10,$C,$0,$0,$E0
		dc.b $E0,$F,$0,$4,$E8
		dc.b $0,$5,$0,$14,$E8
		dc.b $0,$C,$0,$18,$F8
		dc.b $E8,$A,$0,$1C,$8
		dc.b $E0,$0,$0,$25,$10
		dc.b $0,$0,$0,$26,$18
		even
@frame_2:
		dc.b $7

		dc.b $10,$C,$0,$0,$E0
		dc.b $E0,$F,$0,$4,$E8
		dc.b $0,$5,$0,$14,$E8
		dc.b $0,$C,$0,$18,$F8
		dc.b $E0,$7,$0,$1C,$8
		dc.b $E0,$1,$0,$24,$18
		dc.b $F8,$1,$0,$26,$18
		even
