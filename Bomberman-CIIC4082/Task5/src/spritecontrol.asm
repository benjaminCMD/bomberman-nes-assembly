.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1 ; $00
player_y: .res 1 ; $01
player_dir: .res 1 ; $02
frame_position: .res 1 ; $03
frame_buffer: .res 1 ; $04
dpad: .res 1 ; $05
metaIndexX: .res 1 ; $06 - Mxb 
metaIndexY: .res 1 ; $07 - Myb
highBit: .res 1 ; $08 - hight-bit address for the tiles loaded per level
lowBit: .res 1 ; $09 - low-bit address for the tiles loaded per level
level: .res 1 ; $0a - indicates current position of the map
NTB_offset: .res 1 ; $0b - offset added to the high-bit since  hight-bit calculates from 00 to 08
mapIndex: .res 1 ; $0c - a copy of current level number 
worldFlag: .res 1 ; $0d - indicates the current world number
scroll: .res 1 ; $0e - used to scroll increment scroll horizontally
scrollLimit: .res 1 ; $0f -indicates when the scroll has reached its limit
absX: .res 1; $10 - the true position of the sprite
BlockX: .res 1 ; $11
currentMxb: .res 1 ; $12
currentMyb: .res 1 ; $13
currentlvl: .res 1 ; $14
colX: .res 1 ; $15
colY: .res 1 ; $16
overflowFlag: .res 1 ; $17
TileWalkable: .res 1 ; $18







.exportzp player_x, player_y, frame_position, frame_buffer, scroll


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
	JSR startscroll
	JSR FindColPixel
	JSR FindCurrentLevel
	JSR checkTileCollision

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
	

	LDA worldFlag
	CMP #$00
	BEQ world1
	CMP #$01
	BEQ world2
	JMP vblankwait

	world1:
		LDA PPUSTATUS ; initialize the nameatable world tile addresss
		LDA #$20
		STA PPUADDR
		LDA #$00
		STA PPUADDR


		LDA #$00 ; when rendering new background, recommended to turn off PPUCTRL and PPUMASK
		STA PPUCTRL
		STA PPUMASK

		JSR loadWorld1 ; renders the background for world 1
		JSR load_world1_attributes ; renders the backgrounds colors for world 2
		JMP vblankwait ; once the rendering is done, ignore world 2 and turn rendering back on



	world2:
		LDA PPUSTATUS ; initialize the nameatable world tile addresss
		LDA #$20
		STA PPUADDR
		LDA #$00
		STA PPUADDR

		LDA #$00 ; turn off the rendering
		STA PPUCTRL
		STA PPUMASK

		JSR loadWorld2 ; renders the background for world 2
		JSR load_world2_attributes ; renders the backgrounds colors for world 2
		


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
		STA player_dir
		JSR draw_player_left
		LDA TileWalkable
		AND #$01 
		BEQ check_right


		LDA scrollLimit ; flag which checks if the sprite has reached the other nametable
		CMP #$00
		BEQ ScrollModeLeft ; uses scroll to move the sprite left
		CMP #$01
		BEQ UnScrollModeLeft ; uses player_x to move the sprite left
		

		ScrollModeLeft:

		LDA scroll 
		CMP #$00 ; checks if the scroll is initially 0
		BEQ check_right ; if so, then stay on that nametable if its hits the edge of the screen
		JMP scrollLeft ; if the scroll value is higher, then the sprite can move left

		updateScreen_checkerRTL: ; Checks if the sprite is in the left edge of the second screen
			LDX scrollLimit 
			CPX #$01
			BEQ MoveToLeftScreen ; if it is, then actually update the screen
			JMP check_right


		MoveToLeftScreen: ; updates the screen from right to left
			LDA #$ff ; since we are switching screens, I want the sprite to be on the right edge of screen 1
			STA scroll
			; LDA $0f
			; STA player_x
			LDA #$00 ; when modifying the background, always turn off render with PPUCTRL
			STA PPUCTRL
			LDA #%10010000 ; then we turn on the rendering
			STA PPUCTRL
			DEC scrollLimit ; once it renders, we set the flag to 0 indicating we are on the first screen
			DEC overflowFlag
			JMP check_right 


		scrollLeft: 
			DEC scroll
			JMP check_right
	
	
	UnScrollModeLeft: ; once the sprite is on the second screen, we disable scroll
		DEC player_x ; use the sprite's x coordinate to make it move left
		LDA player_x 
		CMP #$00 ; checks if the sprite is on the left edge of the second screen
		BEQ updateScreen_checkerRTL ; if it is, then go update the screen





	check_right:
		LDA dpad
		AND #BTN_RIGHT
		BEQ check_up
		STA player_dir
		JSR draw_player_right
		LDA TileWalkable
		AND #$01
		BEQ check_up


		LDA scrollLimit ; flag which checks if the sprite has reached the other nametable
		CMP #$00
		BEQ ScrollModeRight ; uses scroll to move the sprite right
		CMP #$01
		BEQ UnScrollModeRight ; uses player to move the sprite right


	ScrollModeRight: 
		LDA absX ; 
		CMP #$ff ; checks if the sprite is on the right edge of the first screen using scroll value
		BEQ updateScreen_checkerLTR ; if it is, then go update the screen
		JMP scrollRight ; if not, then moving the sprite right

	updateScreen_checkerLTR:
		LDX scrollLimit
		CPX #$00 ; checks if the sprite is on the first screen
		BEQ MoveToRightScreen ; if it is, then move towards the right screen
		JMP check_up 


	MoveToRightScreen:
		LDA #$00 ; turn off the rendering
		STA PPUCTRL
		LDA #%10010001 ; turn it back on
		STA PPUCTRL
		INC scrollLimit ; then increase the flag to indicate if the sprite is on the second screen
		INC overflowFlag
		LDA #$00
		STA scroll

	scrollRight:
		INC scroll
		JMP check_up

	UnScrollModeRight: ; when unscroll mode, then player_x is incremented so it can move right
		INC player_x

	check_up:
		LDA dpad
		AND #BTN_UP
		BEQ check_down
		STA player_dir
		JSR draw_player_up
		LDA TileWalkable
		AND #$01
		BEQ check_down
		DEC player_y
		
	check_down:
		LDA dpad
		AND #BTN_DOWN
		BEQ check_A
		STA player_dir
		JSR draw_player_down
		LDA TileWalkable
		AND #$01
		BEQ check_A
		INC player_y
	check_A:
		LDA dpad
		AND #BTN_A ; checks if the button A is pressed
		BEQ done_checking ; if not pressed, then skip over it and  


		; if A is pressed, then it will execute the code below
		LDA worldFlag ; a flag which background stages are being loaded currently
		CMP #$00 ; if world 1 is being loaded, then load in world 2
		BEQ jump_main 
		CMP #$01 ;  if world 2 is being loaded, then load in world 3 (sadly this world was never properly implemented)
		BEQ jump_main 
		JMP done_checking

	jump_main: ; increments the world flag and jump backs to main to load new in the new background
		INC worldFlag 
		JMP main
	


   done_checking:
	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc


.proc startscroll
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA scroll
	STA PPUSCROLL ; a register which allows to move the screen along with the player
	LDA #$00 ;  scroll has a x & y coordinates: 0 is added to make the screen move horizontally, not diagonally
	STA PPUSCROLL 

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

.proc DecodeMetatile
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	decode:
		LDA level ; megatile index represented as a btyw
		LSR A ; Shift that index right: level/2 to calculaye Myb
		LSR A 
		STA metaIndexY ; Store Myb into the memeory

		LDA level
		AND #%00000011 ; level mod 4 
		STA metaIndexX ; store value into Mxb

		LDA metaIndexY ; Stores in Myb into the accumalator 
		LSR A ; Myb/4 again 
		LSR A
		AND #%00000011; then do bitmask comparions: Myb mod 4
		STA highBit ; the final result is gonna be our hight bit for PPUADRR

		LDA metaIndexX ; loads Mxb into the accumalator
		ASL A ; Shift left three times: metaIndex * 8
		ASL A 
		ASL A 
		STA metaIndexX ; then stores the updated value
		
		LDA metaIndexY ; laod Myb into A 
		ASL A ; Shift left six times: Myb*64
		ASL A
		ASL A
		ASL A
		ASL A
		ASL A ; the updated Myb is in A
		CLC 
		ADC metaIndexX ; then add the current Mxb value into A
		STA lowBit ; the final result gives the low-bit for PPUADRR

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

.proc load_brick
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA PPUSTATUS ; sequence to load in the top-left tile
	LDA highBit 
	CLC
	ADC NTB_offset ; manages the offset for the high-bit
	STA PPUADDR
	LDA lowBit
	STA PPUADDR
	LDX blocks 
	STX PPUDATA


	LDA PPUSTATUS ; sequence to load in the top-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$01 ; Add 1 to lowBit so the tile can be printed on the top right
	STA PPUADDR
	LDX blocks+1
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-left tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$20 ; Add 32 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+2
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$21 ; Add 33 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+3
	STX PPUDATA


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

.proc load_broken_brick
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA PPUSTATUS ; sequence to load in the top-left tile
	LDA highBit
	CLC
	ADC NTB_offset ; manages the offset for the high-bit
	STA PPUADDR
	LDA lowBit
	STA PPUADDR
	LDX blocks+4
	STX PPUDATA


	LDA PPUSTATUS ; sequence to load in the top-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$01 ; Add 1 to lowBit so the tile can be printed on the top right
	STA PPUADDR
	LDX blocks+5
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-left tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$20 ; Add 32 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+6
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$21 ; Add 33 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+7
	STX PPUDATA


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc


.proc load_grass
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA PPUSTATUS ; sequence to load in the top-left tile
	LDA highBit
	CLC
	ADC NTB_offset ; manages the offset for the high-bit
	STA PPUADDR
	LDA lowBit
	STA PPUADDR
	LDX blocks+8
	STX PPUDATA


	LDA PPUSTATUS ; sequence to load in the top-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$01 ; Add 1 to lowBit so the tile can be printed on the top right
	STA PPUADDR
	LDX blocks+9
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-left tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$20 ; Add 32 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+10
	STX PPUDATA

	LDA PPUSTATUS
	LDA highBit
	CLC
	ADC NTB_offset ; sequence to load in the bottom-right tile
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$21 ; Add 33 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+11
	STX PPUDATA


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc


.proc load_floor
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA PPUSTATUS ; sequence to load in the top-left tile
	LDA highBit
	CLC
	ADC NTB_offset ; manages the offset for the high-bit
	STA PPUADDR
	LDA lowBit
	STA PPUADDR
	LDX blocks+12
	STX PPUDATA


	LDA PPUSTATUS ; sequence to load in the top-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$01 ; Add 1 to lowBit so the tile can be printed on the top right
	STA PPUADDR
	LDX blocks+12
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-left tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$20 ; Add 32 to lowBit so the tile can be printed on the bottom-left
	STA PPUADDR
	LDX blocks+12
	STX PPUDATA

	LDA PPUSTATUS ; sequence to load in the bottom-right tile
	LDA highBit
	CLC
	ADC NTB_offset
	STA PPUADDR
	LDA lowBit
	CLC 
	ADC #$21 ; Add 32 to lowBit so the tile can be printed on the bottom-right
	STA PPUADDR
	LDX blocks+12
	STX PPUDATA


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc


.proc loadLevel
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX #$00

	start:
	LDA mapIndex ; stores in the byte sequence of a specific nametable
	AND #%11000000 
	CMP #%00000000 ; checking if the block is a floor
	BEQ floor
	
	AND #%11000000 
	CMP #%01000000 ; checking if the block is a brick
	BEQ brick

	AND #%11000000 
	CMP #%10000000 ; checking if the block is a broken brick
	BEQ broken_brick

	AND #%11000000 
	CMP #%11000000 ; checking if the block is a grass
	BEQ grass




	


	floor: 
		JSR load_floor ; 00
		JMP blockLoop

	brick: 
		JSR load_brick ; 01
		JMP blockLoop

	broken_brick: 
		JSR load_broken_brick ; 10
		JMP blockLoop

	grass: 
		JSR load_grass ; 11
		JMP blockLoop
	



	blockLoop:
		ASL mapIndex
		ASL mapIndex

		INX ; the iterator counter 

		INC lowBit ;  updating the base low-bit index so it can print the other tiles
		INC lowBit

		CPX #$04 ;  if x <= 4, break out of the loop
		BNE start


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS
.endproc

.proc loadWorld1
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX #$00

	load_background1:
		LDY #$20 ; nametable 1
		STY NTB_offset ; placing the initial offset into the highBit
		STX level ; current index section within the map 
		LDA nametable1_lvl1, x
		STA mapIndex ; the byte used to print the tiles

		JSR DecodeMetatile ; decode to get the highBit and lowBit value
		JSR loadLevel ; prints the entire level sequence from left to right
		INX ; iterator counter
		CPX #$3c ; total amount of bytes within our nametable labels 
		BNE load_background1

	LDX #$00
	STX level
	load_background2:
		LDY #$24 ; nametable2
		STY NTB_offset ; placing the initial offset into the highBit
		STX level ; current index section within the map 
		LDA nametable2_lvl1, x
		STA mapIndex ; the byte used to print the tiles

		JSR DecodeMetatile ; decode to get the highBit and lowBit value
		JSR loadLevel  ; prints the entire level sequence from left to right
		INX ; iterator counter
		CPX #$3c ; total amount of bytes within our nametable labels 
		BNE load_background2 ; total amount of bytes within our nametable labels 

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc loadWorld2
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX #$00

	load_background3:
		LDY #$20 ; nametable 1
		STY NTB_offset ; placing the initial offset into the highBit
		STX level ; current index section within the map 
		LDA nametable1_lvl2, x
		STA mapIndex ; the byte used to print the tiles

		JSR DecodeMetatile ; decode to get the highBit and lowBit value
		JSR loadLevel ; prints the entire level sequence from left to right
		INX ; iterator counter
		CPX #$3c ; total amount of bytes within our nametable labels 
		BNE load_background3

	LDX #$00
	STX level
	load_background4:
		LDY #$24 ; nametable 2
		STY NTB_offset ; placing the initial offset into the highBit
		STX level ; current index section within the map 
		LDA nametable2_lvl2, x
		STA mapIndex ; the byte used to print the tiles

		JSR DecodeMetatile ; decode to get the highBit and lowBit value
		JSR loadLevel ; prints the entire level sequence from left to right
		INX ; iterator counter
		CPX #$3c ; total amount of bytes within our nametable labels 
		BNE load_background4

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc load_world1_attributes
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX #$00 
    LDA PPUSTATUS ; sequence to initialize the base for the first attribute table
    LDA #$23
    STA PPUADDR
    LDA #$c0 
    STA PPUADDR
  	loadattribute:
		LDY #%00000000 ; one world uses only one palette
		STY PPUDATA ; once written in the PPUDATA, the address will update by 1 automically
		INX
		CPX #$40 ; 64 bytes 
		BNE loadattribute


    LDX #$00 ; reset the counter 
    LDA PPUSTATUS ; sequence to initialize the base for the second attribute table
    LDA #$27
    STA PPUADDR
    LDA #$c0 
    STA PPUADDR
	loadattribute1:
		LDY #%00000000 ; one world uses only one palette
		STY PPUDATA ; once written in the PPUDATA, the address will update by 1 automically
		INX
		CPX #$40 ; 64 bytes 
		BNE loadattribute1

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc load_world2_attributes
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA PPUSTATUS ; sequence to initialize the base for the first attribute table
    LDA #$23
    STA PPUADDR
    LDA #$c0
    STA PPUADDR
	LDX #$00   
	loadattribute2:
		LDY #%01010101 ; one world uses only one palette
		STY PPUDATA ; once written in the PPUDATA, the address will update by 1 automically
		INX
		CPX #$40 ; 64 bytes 
		BNE loadattribute2



    LDA PPUSTATUS ; sequence to initialize the base for the second attribute table
    LDA #$27
    STA PPUADDR
    LDA #$c0
    STA PPUADDR   
	LDX #$00 ; reset the counter 
	loadattribute3:
		LDY #%01010101 ; one world uses only one palette
		STY PPUDATA ; once written in the PPUDATA, the address will update by 1 automically
		INX
		CPX #$40 ; 64 bytes 
		BNE loadattribute3

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc FindCurrentLevel
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDA scroll
	CLC 
	ADC colX ; at this moment, A = absoluteX
	STA absX

	LSR A ; shift right A/4 = absX/16
	LSR A
	LSR A
	LSR A
	STA BlockX ; the byte range for x between 0-15

	LSR A  ; shift right A/2 = absX/4
	LSR A  
	STA currentMxb



	LDY colY
	TYA 
	LSR A ; shift right A/4 = player_y/16
	LSR A ;
	LSR A ;
	LSR A ;

	ASL A ; shift left A*2 = player_y * 4
	ASL A 
	CLC 
	ADC currentMxb ; then add player_y into currentMxb
	STA currentlvl ; the final result is the current player's level



	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc 


.proc FindColPixel
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	check_collision_left:
		LDA player_dir
		AND #BTN_LEFT
		BEQ check_collision_right
		LDA player_x
		CLC 
		SBC #$01
		STA colX
		LDY player_y
		STY colY

	check_collision_right:
		LDA player_dir
		AND #BTN_RIGHT
		BEQ check_collision_down
		LDA player_x
		CLC 
		ADC #$10
		STA colX

		LDY player_y
		STY colY

		

	check_collision_down: 
		LDA player_dir
		AND #BTN_DOWN
		BEQ check_collision_up
		LDA player_x
		STA colX
		LDA player_y
		CLC 
		ADC #$10
		STA colY



	check_collision_up:
		LDA player_dir
		AND #BTN_UP
		BEQ check_end
		LDA player_x
		STA colX
		LDA player_y
		CLC 
		SBC #$01
		STA colY


	check_end:

	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc 


.proc checkTileCollision
	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDX colX
	LDY colY

	; TXA 
	; CLC 
	; ADC scroll
	; BCS FoundOverflow
	; LDA #$00
	; STA overflowFlag

	
	; CMP #$ff
	; BEQ checkfornt1
	; LDA #$00
	; STA overflowFlag
	; JMP Worldchekcer

	
	; checkfornt1:
	; 	LDA absX
	; 	CMP #$00
	; 	BEQ resetoverflow
	; 	LDA #$01
	; 	STA overflowFlag
	; 	JMP Worldchekcer
	; LDA absX
	; CMP #$ff
	; BEQ FoundOverflow
	; LDA scrollLimit
	; CMP #$00
	; BEQ resetoverflow

	; resetoverflow:
	; 	LDA #$00
	; 	STA overflowFlag

	; JMP Worldchekcer



	; FoundOverflow:
	; 	LDA #$01
	; 	; STA overflowFlag
	; 	; CLC 
	; 	; ADC #$01
	; 	STA overflowFlag


	Worldchekcer: 
		LDA worldFlag
		CMP #$01
		BEQ checkWorld2

		LDA overflowFlag
		CMP #$01
		BEQ ntb2_lvl1

		JSR NTB1_colmaplvl1
		JMP final

	ntb2_lvl1:
		JSR NTB2_colmaplvl1
		JMP final

	checkWorld2: 
		LDA overflowFlag
		CMP #$01
		BEQ ntb2_lv2
		JSR NTB1_colmaplvl2
		JMP final

	ntb2_lv2:
		JSR NTB2_colmaplvl2 
		JMP final
	final: 



	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS


.endproc 

.proc NTB1_colmaplvl1

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDY currentlvl
	LDA BlockX
	AND #%00000011
	STA BlockX

	LDA nametable1_lvl1, Y
	LDX #$00
	LoopLevel: 
		CPX BlockX
		BEQ cheking_block
		ASL
		ASL 
		INX 
		JMP LoopLevel


	cheking_block: 
		AND #%11000000 
		CMP #%00000000
		BNE else 
		LDA #$01
		STA TileWalkable
		JMP colcheckdone

		else: 
			AND #%11000000
			CMP #%11000000
			BNE itsawall
			LDA #$01
			STA TileWalkable
			JMP colcheckdone
		
	itsawall:
	LDA #$00
	STA TileWalkable

	colcheckdone:


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc NTB2_colmaplvl1

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDY currentlvl
	LDA BlockX
	AND #%00000011
	STA BlockX

	LDA nametable2_lvl1, Y
	LDX #$00
	LoopLevel: 
		CPX BlockX
		BEQ cheking_block
		ASL
		ASL 
		INX 
		JMP LoopLevel


	cheking_block: 
		AND #%11000000 
		CMP #%00000000
		BNE else 
		LDA #$01
		STA TileWalkable
		JMP colcheckdone

		else: 
			AND #%11000000
			CMP #%11000000
			BNE itsawall
			LDA #$01
			STA TileWalkable
			JMP colcheckdone
		
	itsawall:
	LDA #$00
	STA TileWalkable

	colcheckdone:


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc NTB1_colmaplvl2

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDY currentlvl
	LDA BlockX
	AND #%00000011
	STA BlockX

	LDA nametable1_lvl2, Y
	LDX #$00
	LoopLevel: 
		CPX BlockX
		BEQ cheking_block
		ASL
		ASL 
		INX 
		JMP LoopLevel


	cheking_block: 
		AND #%11000000 
		CMP #%00000000
		BNE else 
		LDA #$01
		STA TileWalkable
		JMP colcheckdone

		else: 
			AND #%11000000
			CMP #%11000000
			BNE itsawall
			LDA #$01
			STA TileWalkable
			JMP colcheckdone
		
	itsawall:
	LDA #$00
	STA TileWalkable

	colcheckdone:


	PLA
	TAY
	PLA
	TAX
	PLA
	PLP
	RTS

.endproc

.proc NTB2_colmaplvl2

	PHP
	PHA
	TXA
	PHA
	TYA
	PHA

	LDY currentlvl
	LDA BlockX
	AND #%00000011
	STA BlockX

	LDA nametable2_lvl2, Y
	LDX #$00
	LoopLevel: 
		CPX BlockX
		BEQ cheking_block
		ASL
		ASL 
		INX 
		JMP LoopLevel


	cheking_block: 
		AND #%11000000 
		CMP #%00000000
		BNE else 
		LDA #$01
		STA TileWalkable
		JMP colcheckdone

		else: 
			AND #%11000000
			CMP #%11000000
			BNE itsawall
			LDA #$01
			STA TileWalkable
			JMP colcheckdone
		
	itsawall:
	LDA #$00
	STA TileWalkable

	colcheckdone:


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
.byte $0f, $05, $16, $27
.byte $0f, $12, $23, $34
.byte $0f, $0c, $07, $13
.byte $0f, $19, $09, $29

.byte $0f, $0f, $02, $38
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29
.byte $0f, $19, $09, $29

nametable1_lvl1:
	.byte %01010101, %01010101, %01010101, %01010101
	.byte %01000000, %00000011, %11111111, %00000001
	.byte %01001010, %10100010, %10101010, %00101001
	.byte %01001010, %10100010, %00000000, %00101001

	.byte %01000011, %11100010, %10001010, %10101001
	.byte %01101010, %11101111, %10001000, %00000000
	.byte %01000011, %11101010, %10001000, %00001001
	.byte %01001000, %00000010, %00000010, %00001001

	.byte %01001000, %00101010, %00100010, %00001001
	.byte %01001000, %00100010, %00100010, %00001001
	.byte %01111010, %10100010, %00101110, %10001001
	.byte %01111010, %00000010, %00101111, %00001001

	.byte %01111010, %00101010, %00101110, %10001001
	.byte %01000000, %00000010, %00100010, %10001001
	.byte %01010101, %01010101, %01010101, %01010101

nametable2_lvl1:
	.byte %01010101, %01010101, %01010101, %01010101
	.byte %01001000, %00000000, %00000000, %00000001
	.byte %01111011, %10101010, %10101110, %11101001
	.byte %01111111, %11000010, %10101110, %11100001

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
	.byte %01010101, %01010101, %01010101, %01010101

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

	.byte %00001010, %11101010, %10101110, %00100001
	.byte %01000011, %11110000, %00100010, %00100001
	.byte %01010101, %01010101, %01010101, %01010101

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
	.byte %01010101, %01010101, %01010101, %01010101


blocks:
	.byte $32, $33, $42, $43 ; regular brick block
	.byte $30, $31, $40, $41 ; broken brick block
	.byte $34, $35, $44, $45 ; grass block
	.byte $38, $39, $48, $49 ; floor block


.segment "CHR"
.incbin "starfield8.chr"

.segment "CHARS"
.segment "STARTUP"


