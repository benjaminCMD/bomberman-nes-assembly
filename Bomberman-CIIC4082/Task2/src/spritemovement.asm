.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
;player_dir: .res 1
frame_position: .res 1
frame_buffer: .res 1
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
	JSR update_frame
	JSR draw_player_down
	JSR draw_player_up
	JSR draw_player_left
	JSR draw_player_right
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



; .proc update_player
;   
; .endproc

.proc draw_player_up
	; save registers
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	; write player ship tile numbers

	; Loads in top-left tile del sprite up
	LDA frame_position
	CLC 
	ADC #$00
	STA $0201


	; Loads in top-right tile del sprite up
	LDA frame_position
	CLC 
	ADC #$01
	STA $0205

	; Loads in bottom-left del sprite up
	LDA frame_position
	CLC 
	ADC #$10
	STA $0209

	
	; Loads in bottom-right del sprite up
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
	ADC #$06
	STA $0211


	LDA frame_position
	CLC 
	ADC #$07
	STA $0215

	LDA frame_position
	CLC 
	ADC #$16
	STA $0219

	LDA frame_position
	CLC 
	ADC #$17
	STA $021d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0212
	STA $0216
	STA $021a
	STA $021e

	; store tile locations
	; top left tile:
	LDA player_y
	CLC
	SBC #$18
	STA $0210
	LDA player_x
	STA $0213

	; top right tile (x + 8):
	LDA player_y
	CLC
	SBC #$18
	STA $0214
	LDA player_x
	CLC
	ADC #$08
	STA $0217

	; bottom left tile (y + 8):
	LDA player_y
	CLC
	SBC #$10
	STA $0218
	LDA player_x
	STA $021b

	; bottom right tile (x + 8, y + 8)
	LDA player_y
	CLC
	SBC #$10
	STA $021c
	LDA player_x
	CLC
	ADC #$08
	STA $021f

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
	STA $0221


	LDA frame_position
	CLC 
	ADC #$21
	STA $0225

	LDA frame_position
	CLC 
	ADC #$30
	STA $0229

	LDA frame_position
	CLC 
	ADC #$31
	STA $022d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0222
	STA $0226
	STA $022a
	STA $022e

	; store tile locations
	; top left tile:
	LDA player_y
	STA $0220
	LDA player_x
	CLC 
	SBC #$18
	STA $0223

	; top right tile (x + 8):
	LDA player_y
	STA $0224
	LDA player_x
	CLC
	SBC #$10
	STA $0227

	; bottom left tile (y + 8):
	LDA player_y
	CLC 
	ADC #$08
	STA $0228
	LDA player_x
	CLC
	SBC #$18
	STA $022b

	; bottom right tile (x + 8, y + 8)
	LDA player_y
	CLC 
	ADC #$08
	STA $022c
	LDA player_x
	CLC
	SBC #$10
	STA $022f

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
	STA $0231


	LDA frame_position
	CLC 
	ADC #$27
	STA $0235

	LDA frame_position
	CLC 
	ADC #$36
	STA $0239

	LDA frame_position
	CLC 
	ADC #$37
	STA $023d

	; write player ship tile attributes
	; use palette 0
	LDA #$00
	STA $0232
	STA $0236
	STA $023a
	STA $023e

	; store tile locations
	; top left tile:
	LDA player_y
	STA $0230
	LDA player_x
	CLC 
	ADC #$18
	STA $0233

	; top right tile (x + 8):
	LDA player_y
	STA $0234
	LDA player_x
	CLC
	ADC #$20
	STA $0237

	; bottom left tile (y + 8):
	LDA player_y
	CLC
	ADC #$08
	STA $0238
	LDA player_x
	CLC
	ADC #$18
	STA $023b

	; bottom right tile (x + 8, y + 8)
	LDA player_y
	CLC
	ADC #$08
	STA $023c
	LDA player_x
	CLC
	ADC #$20
	STA $023f

	; restore registers and return
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
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
