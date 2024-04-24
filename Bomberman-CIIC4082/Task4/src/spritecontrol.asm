.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
;player_dir: .res 1
frame_position: .res 1
frame_buffer: .res 1
dpad: .res 1

.exportzp player_x, player_y, frame_position, frame_buffer

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00

  ; update tiles *after* DMA transfer
	;JSR update_player
	JSR draw_player_idle
	JSR read_controller1
	JSR update_player
	JSR update_frame
	;JSR draw_player_idle

	; JSR draw_player_down
	; JSR draw_player_up
	; JSR draw_player_left
	; JSR draw_player_right
	STA $2005
	STA $2005
  RTI
.endproc

.import reset_handler

.export main
.proc main
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


.proc update_frame
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	INC frame_buffer
	LDA frame_buffer
	CMP #$0a 
	BEQ next_frame_tile
	JMP exit_subroutine

next_frame_tile:

	LDA frame_position
	CLC 
	ADC #$02
	STA frame_position

	LDA frame_position
	CMP #$06
	BEQ reset_frame
	LDA #$00
	STA frame_buffer
	JMP exit_subroutine

reset_frame:
	LDA #$00
	STA frame_position
	STA frame_buffer


exit_subroutine:
   ; all done, clean up and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS

.endproc



.proc update_player
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
  check_left:
	LDA dpad
	AND #BTN_LEFT
	BEQ check_right
	DEC player_x
	JSR draw_player_left
  check_right:
	LDA dpad
	AND #BTN_RIGHT
	BEQ check_up
	INC player_x
	JSR draw_player_right
  check_up:
	LDA dpad
	AND #BTN_UP
	BEQ check_down
	DEC player_y
	JSR draw_player_up
  check_down:
	LDA dpad
	AND #BTN_DOWN
	BEQ done_checking
	INC player_y
	JSR draw_player_down

   done_checking:
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

.proc draw_player_up
	; save registers
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; write player ship tile numbers

	LDA frame_position
	CLC 
	ADC #$06
	STA $0201


	LDA frame_position
	CLC 
	ADC #$07
	STA $0205

	LDA frame_position
	CLC 
	ADC #$16
	STA $0209

	LDA frame_position
	CLC 
	ADC #$17
	STA $020d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	; store tile locations
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

.proc draw_player_down

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; write player ship tile numbers

	LDA frame_position
	CLC 
	ADC #$00
	STA $0201


	LDA frame_position
	CLC 
	ADC #$01
	STA $0205

	LDA frame_position
	CLC 
	ADC #$10
	STA $0209

	LDA frame_position
	CLC 
	ADC #$11
	STA $020d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	; store tile locations
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


.proc draw_player_left


	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; write player ship tile numbers

	LDA frame_position
	CLC 
	ADC #$20
	STA $0201


	LDA frame_position
	CLC 
	ADC #$21
	STA $0205

	LDA frame_position
	CLC 
	ADC #$30
	STA $0209

	LDA frame_position
	CLC 
	ADC #$31
	STA $020d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	; store tile locations
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

.proc draw_player_right

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; write player ship tile numbers

	LDA frame_position
	CLC 
	ADC #$26
	STA $0201


	LDA frame_position
	CLC 
	ADC #$27
	STA $0205

	LDA frame_position
	CLC 
	ADC #$36
	STA $0209

	LDA frame_position
	CLC 
	ADC #$37
	STA $020d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0202
	STA $0206
	STA $020a
	STA $020e

	; store tile locations
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

.proc draw_player_idle

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA
	
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

	; store tile locations
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

.proc read_controller1
 PHA
 TXA
 PHA
 PHP


 LDA #01
 STA CONTROLLER1 ; controller's shift register set in data collection mode
 LDA #00
 STA CONTROLLER1; sets controller into output mode

 LDA #%00000001

 STA dpad

get_buttons:
  LDA CONTROLLER1 ; loads the leftmost bit into the accumalator
  LSR A ; shifts bit0 -> carry
  ROL dpad ; dpad value <- carry
  BCC get_buttons
  PLP
  PLA
  TAX
  PLA
  RTS
.endproc




.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
palettes:
.byte $0f, $12, $23, $27
.byte $0f, $2b, $3c, $39
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $0f, $02, $38
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

.segment "CHR"
.incbin "starfield6.chr"

.segment "CHARS"
.segment "STARTUP"


nametable1_lvl1:
.byte %01010101, %01010101, %01010101, %01010101
.byte %01000000, %00000011, %11111111, %00000001
.byte %01001010, %10100010, %10101010, %00101001
.byte %01001010, %10100010, %00000000, %00101001
.byte %01000011, %11100010, %10001010, %10101001
.byte %01101010, %11101111, %10001000, %00000000
.byte %01101010, %11101111, %10001000, %00001001
.byte %01001000, %00000010, %00000010, %00001001
.byte %01001000, %00101010, %00100010, %00001001
.byte %01001000, %00100010, %00100010, %00001001
.byte %01111010, %10100010, %00101110, %10001001
.byte %01111010, %00000010, %00101111, %00001001
.byte %01111010, %00101010, %00101110, %10001001
.byte %01000000, %00000010, %00100010, %10001001

nametable2_lvl1:
.byte %01010101, %01010101, %01010101, %01010101
.byte %01001000, %00000000, %00000000, %00000001
.byte %01111011, %10101010, %10101110, %11101001
.byte %11111111, %11000010, %10101110, %11100001
.byte %01101010, %10100000, %00101110, %11100001
.byte %00000000, %00100010, %10100010, %00100001
.byte %01100010, %00100000, %00100010, %00000001
.byte %01100010, %00101010, %00100010, %10100001
.byte %01100010, %00111111, %11100000, %00100001
.byte %01100010, %00101110, %11101010, %00100001
.byte %01100010, %00100010, %00100010, %00100001
.byte %01100010, %00100010, %00100010, %00100001
.byte %01101110, %10100010, %10100010, %00100000
.byte %01101111, %11100000, %00000010, %00100001

nametable1_lvl2:
.byte %01010101, %01010101, %01010101, %01010101
.byte %01000000, %00001010, %10110000, %00000001
.byte %01001010, %10000011, %11111010, %10101001
.byte %01001011, %10101011, %10101000, %00000001
.byte %01001111, %11001011, %11101111, %00000000
.byte %01101010, %10001010, %11101110, %10101001
.byte %01000000, %10000010, %00101110, %00000001
.byte %01001010, %10100010, %00100010, %00000001
.byte %01001000, %00000010, %00100010, %00101001
.byte %01001000, %10101010, %00100010, %00100001
.byte %01001000, %10100000, %00101110, %00100001
.byte %01001011, %11100000, %00111111, %00000001
.byte %01001010, %11101010, %10101110, %00100001
.byte %01000011, %11110000, %00100010, %00100001

nametable2_lvl2:
.byte %01010101, %01010101, %01010101, %01010101
.byte %01100000, %10000000, %00110000, %00000001
.byte %01100010, %10001010, %10111010, %10111001
.byte %01101110, %10001000, %10101000, %10111001
.byte %00111111, %11001000, %10101000, %10111001
.byte %01111011, %10001000, %00000000, %10000001
.byte %01001000, %10001010, %10100000, %10000001
.byte %01001000, %10001010, %11100010, %10100001
.byte %01001000, %10001010, %11100000, %00100001
.byte %01001000, %10000011, %11100010, %10100001
.byte %01001000, %10101010, %10100010, %10111101
.byte %01001000, %00000000, %00000010, %10111101
.byte %01001010, %10101010, %10101010, %10100001
.byte %01000011, %11111100, %00000000, %00100000
