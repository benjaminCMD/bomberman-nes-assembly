.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1

player_xb: .res 1
player_yb: .res 1

player_xr: .res 1
player_yr: .res 1

player_xl: .res 1
player_yl: .res 1
.exportzp player_x, player_y

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  JSR draw_player_front
  JSR draw_player_back
  JSR draw_player_right
  JSR draw_player_left

  LDA #$00
  STA $2005
  STA $2005
  RTI
.endproc

.proc draw_player_back
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player ship tile numbers
  LDA #$06
  STA $0201
  LDA #$07
  STA $0205
  LDA #$16
  STA $0209
  LDA #$17
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; top left tile:
  LDA player_yb
  STA $0200
  LDA player_xb
  STA $0203

  ; top right tile (x + 8):
  LDA player_yb
  STA $0204
  LDA player_xb
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_yb
  CLC
  ADC #$08
  STA $0208
  LDA player_xb
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_yb
  CLC
  ADC #$08
  STA $020c
  LDA player_xb
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


.proc draw_player_left
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player ship tile numbers
  LDA #$22
  STA $0201
  LDA #$23
  STA $0205
  LDA #$32
  STA $0209
  LDA #$33
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; top left tile:
  LDA player_yl
  STA $0200
  LDA player_xl
  STA $0203

  ; top right tile (x + 8):
  LDA player_yl
  STA $0204
  LDA player_xl
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_yl
  CLC
  ADC #$08
  STA $0208
  LDA player_xl
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_yl
  CLC
  ADC #$08
  STA $020c
  LDA player_xl
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc draw_player_right
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player ship tile numbers
  LDA #$0c
  STA $0201
  LDA #$0d
  STA $0205
  LDA #$1c
  STA $0209
  LDA #$1d
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; top left tile:
  LDA player_yr
  STA $0200
  LDA player_xr
  STA $0203

  ; top right tile (x + 8):
  LDA player_yr
  STA $0204
  LDA player_xr
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_yr
  CLC
  ADC #$08
  STA $0208
  LDA player_xr
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_yr
  CLC
  ADC #$08
  STA $020c
  LDA player_xr
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc


.proc draw_player_front
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write player ship tile numbers
  LDA #$00
  STA $0201
  LDA #$01
  STA $0205
  LDA #$10
  STA $0209
  LDA #$11
  STA $020d

  ; write player ship tile attributes
  ; use palette 0
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e

  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.import reset_handler

.export main
.proc main

 ; initialize zero-page values
  LDA #$90
  STA player_x
  LDA #$a0
  STA player_y

  LDA #$70
  STA player_xb
  LDA #$a0
  STA player_yb


  LDA #$90
  STA player_xr
  LDA #$a8
  STA player_yr

  LDA #$70
  STA player_xl
  LDA #$a8
  STA player_yl


  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR

load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes
  ; write sprite data
  LDX #$00

; load_sprites:
;   LDA forward,X
;   STA $0200,X
;   INX
;   CPX #$c0
;   BNE load_sprites

	; write nametables
	; loading in top-left tile from texture 1
	LDA PPUSTATUS 
	LDA #$20 
	STA PPUADDR
	LDA #$4a
	STA PPUADDR
	LDX #$30
	STX PPUDATA

	; loading in top-right tile from texture 1
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$4b
	STA PPUADDR
	LDX #$31
	STX PPUDATA

	; loading in bottom-left tile from texture 1
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$6a
	STA PPUADDR
	LDX #$40
	STX PPUDATA

	; loading in bottom-right tile from texture 1
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$6b
	STA PPUADDR
	LDX #$41
	STX PPUDATA

	; loading in top-left tile from texture 2
	LDA PPUSTATUS 
	LDA #$20 
	STA PPUADDR
	LDA #$0a
	STA PPUADDR
	LDX #$32
	STX PPUDATA

	; loading in top-right tile from texture 2
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$0b
	STA PPUADDR
	LDX #$33
	STX PPUDATA

	; loading in bottom-left tile from texture 2
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$2a
	STA PPUADDR
	LDX #$42
	STX PPUDATA

	; loading in bottom-right tile from texture 2
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$2b
	STA PPUADDR
	LDX #$43
	STX PPUDATA

	; loading in top-left tile from texture 3
	LDA PPUSTATUS 
	LDA #$20 
	STA PPUADDR
	LDA #$08
	STA PPUADDR
	LDX #$34
	STX PPUDATA

	; loading in top-right tile from texture 3
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$09
	STA PPUADDR
	LDX #$35
	STX PPUDATA

	; loading in bottom-left tile from texture 3
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$28
	STA PPUADDR
	LDX #$44
	STX PPUDATA

	; loading in bottom-right tile from texture 3
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$29
	STA PPUADDR
	LDX #$45
	STX PPUDATA


; loading in top-left tile from texture 4
	LDA PPUSTATUS 
	LDA #$20 
	STA PPUADDR
	LDA #$48
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in top-right tile from texture 4
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$49
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in bottom-left tile from texture 4
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$68
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in bottom-right tile from texture 4
	LDA PPUSTATUS
	LDA #$20 
	STA PPUADDR
	LDA #$69
	STA PPUADDR
	LDX #$36
	STX PPUDATA


	
	; setting up the attribute tables
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%00000000
	STA PPUDATA




; loading in top-left tile from texture 5
	LDA PPUSTATUS 
	LDA #$21 
	STA PPUADDR
	LDA #$4a
	STA PPUADDR
	LDX #$30
	STX PPUDATA

	; loading in top-right tile from texture 5
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$4b
	STA PPUADDR
	LDX #$31
	STX PPUDATA

	; loading in bottom-left tile from texture 5
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$6a
	STA PPUADDR
	LDX #$40
	STX PPUDATA

	; loading in bottom-right tile from texture 5
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$6b
	STA PPUADDR
	LDX #$41
	STX PPUDATA
	

; loading in top-left tile from texture 6
	LDA PPUSTATUS 
	LDA #$21 
	STA PPUADDR
	LDA #$0a
	STA PPUADDR
	LDX #$32
	STX PPUDATA

	; loading in top-right tile from texture 6
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$0b
	STA PPUADDR
	LDX #$33
	STX PPUDATA

	; loading in bottom-left tile from texture 6
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$2a
	STA PPUADDR
	LDX #$42
	STX PPUDATA



	; loading in bottom-right tile from texture 6
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$2b
	STA PPUADDR
	LDX #$43
	STX PPUDATA


	; loading in top-left tile from texture 7
	LDA PPUSTATUS 
	LDA #$21 
	STA PPUADDR
	LDA #$48
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in top-right tile from texture 7
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$49
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in bottom-left tile from texture 7
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$68
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in bottom-right tile from texture 7
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$69
	STA PPUADDR
	LDX #$36
	STX PPUDATA

	; loading in top-left tile from texture 8
	LDA PPUSTATUS 
	LDA #$21 
	STA PPUADDR
	LDA #$08
	STA PPUADDR
	LDX #$34
	STX PPUDATA

	; loading in top-right tile from texture 8
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$09
	STA PPUADDR
	LDX #$35
	STX PPUDATA

	; loading in bottom-left tile from texture 8
	LDA PPUSTATUS
	LDA #$21 
	STA PPUADDR
	LDA #$28
	STA PPUADDR
	LDX #$44
	STX PPUDATA

	; loading in bottom-right tile from texture 8
	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$29
	STA PPUADDR
	LDX #$45
	STX PPUDATA


	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$d2
	STA PPUADDR
	LDA #%01010101
	STA PPUDATA


vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $05, $16, $27
.byte $0f, $12, $23, $34
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $0f, $02, $38
.byte $0f, $0c, $23, $14
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29


sprites:
;      y   tile palette  x		; static front

.byte $70, $01, $00, $78  ;right side of face
.byte $70, $00, $00, $70  ;left side of face
.byte $78, $10, $00, $70  ;left side of body
.byte $78, $11, $00, $78  ;right side of body

; one of the bomberman's sprite 
; .byte $70, $41, $01, $78  ;right side of face
; .byte $70, $40, $01, $70  ;left side of face
; .byte $78, $50, $01, $70  ;left side of body
; .byte $78, $51, $01, $78  ;right side of body

.byte $70, $02, $00, $80
.byte $70, $03, $00, $88   ; moving front (left hand)
.byte $78, $12, $00, $80
.byte $78, $13, $00, $88

.byte $70, $04, $00, $90
.byte $70, $05, $00, $98   ; moving front (right hand)
.byte $78, $14, $00, $90
.byte $78, $15, $00, $98

.byte $80, $06, $00, $70   ; back static
.byte $80, $07, $00, $78   
.byte $88, $16, $00, $70
.byte $88, $17, $00, $78

.byte $80, $08, $00, $80   ; moving back (left hand)
.byte $80, $09, $00, $88   
.byte $88, $18, $00, $80
.byte $88, $19, $00, $88

.byte $80, $0a, $00, $90   ; moving back (right hand)
.byte $80, $0b, $00, $98   
.byte $88, $1a, $00, $90
.byte $88, $1b, $00, $98

.byte $90, $0c, $00, $70   ; right static
.byte $90, $0d, $00, $78   
.byte $98, $1c, $00, $70
.byte $98, $1d, $00, $78

.byte $90, $0e, $00, $80   ; moving right (left hand)
.byte $90, $0f, $00, $88   
.byte $98, $1e, $00, $80
.byte $98, $1f, $00, $88

.byte $90, $20, $00, $90   ; moving right (right hand)
.byte $90, $21, $00, $98   
.byte $98, $30, $00, $90
.byte $98, $31, $00, $98

.byte $a0, $22, $00, $70   ; left static
.byte $a0, $23, $00, $78   
.byte $a8, $32, $00, $70
.byte $a8, $33, $00, $78


.byte $a0, $24, $00, $80   ; moving left (left hand)
.byte $a0, $25, $00, $88   
.byte $a8, $34, $00, $80
.byte $a8, $35, $00, $88

.byte $a0, $26, $00, $90   ; moving left (right hand)
.byte $a0, $27, $00, $98   
.byte $a8, $36, $00, $90
.byte $a8, $37, $00, $98



; attr $03 = %0000 0011
; .byte $70, $05, $00, $80
; .byte $70, $06, $00, $88
; .byte $78, $07, $00, $80
; .byte $78, $08, $00, $88

.segment "CHR"
.incbin "starfield5.chr"
.segment "CHARS"
.segment "STARTUP"