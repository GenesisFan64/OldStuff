@mappings:
		dc.w @frame_0-@mappings
		dc.w @frame_1-@mappings
		dc.w @frame_2-@mappings
		dc.w @frame_3-@mappings
		dc.w @frame_4-@mappings
@frame_0:
		dc.b $4

		dc.b $F0,$9,$0,$0,$F0
		dc.b $E8,$4,$0,$6,$F8
		dc.b $0,$9,$0,$8,$F8
		dc.b $F8,$0,$0,$E,$8
		even
@frame_1:
		dc.b $4

		dc.b $F0,$9,$0,$F,$F0
		dc.b $E8,$4,$0,$15,$F8
		dc.b $0,$9,$0,$17,$F8
		dc.b $F8,$0,$0,$1D,$8
		even
@frame_2:
		dc.b $4

		dc.b $F0,$9,$0,$1E,$F0
		dc.b $E8,$4,$0,$24,$F8
		dc.b $0,$9,$0,$26,$F8
		dc.b $F8,$0,$0,$2C,$8
		even
@frame_3:
		dc.b $1

		dc.b $F0,$B,$0,$2D,$F8
		even
@frame_4:
		dc.b $1

		dc.b $F0,$B,$0,$39,$F8
		even
