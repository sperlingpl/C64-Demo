/* 
	Simple and first demo.
	
	Author: Pawel "sperling" Wroblewski
	Date: 29-07-2015          		
*/

:BasicUpstart2(main)			 		// Basic caller for the main program.

.const CHROUT    = $ffd2		 		// Kernal routine: 
								 		// prints char in ACCU to output device (screen as default).
.const ASC_CLSCR = 147			 		// ASCII for "clear screen".
.const ASC_CR	 = 13			 		// ASCII for line break code.
.const NULL		 = 0 			 		// NULL code to express the end of strings.

.const ANIMATION_STATE = $cd00			// States of whole demo.
										// #$00 - Initial state after running a program.
										// #$01 - Move "Ready." text to the center of the screen.
										// #$02 - Wait and change border color to black.
										// #$03 - Wait some time.
										// #$04 - Change background color to black and clear screen, only "Ready." visible.
										// #$05 - Wait.
										// #$06 - Clear screen and show text.
										// #$07 - Wait
										// #$08 - Show rasterbar.

.const RASTER_SHOW = $cfd
.const RASTER_MOVE_DIRECTION = $cfe
.const RASTER_START = $cff

.const RASTERBEAM_IRQ_COUNTER = $cf00	// Just a counter used in IRQ.

.const music_address = $1000
.const sprite_address = $3000

//.pc = music_address "Music"

//.import binary "ode to 64.bin"

.var music = LoadSid("jeff_donald.sid")

.pc = music.location "Music"
.fill music.size, music.getData(i)

.pc = sprite_address "Sprite"
//.include binary "main.asm"

.pc = $810 "Data"

// Data

//string: 	.byte ASC_CLSCR .text "HELLO AGAIN, COMMODORE 64!" .byte ASC_CR .byte NULL

line1:		.text "       sperling in 2015 presents..."
line2:		.text "            demo of the year!              "

color:       
			.byte $09,$09,$02,$02,$08 
         	.byte $08,$0a,$0a,$0f,$0f 
         	.byte $07,$07,$01,$01,$01 
         	.byte $01,$01,$01,$01,$01 
			.byte $01,$01,$01,$01,$01 
			.byte $01,$01,$01,$07,$07 
			.byte $0f,$0f,$0a,$0a,$08 
			.byte $08,$02,$02,$09,$09 

color2:       
			.byte $09,$09,$02,$02,$08 
			.byte $08,$0a,$0a,$0f,$0f 
			.byte $07,$07,$01,$01,$01 
			.byte $01,$01,$01,$01,$01 
			.byte $01,$01,$01,$01,$01 
			.byte $01,$01,$01,$07,$07 
			.byte $0f,$0f,$0a,$0a,$08 
			.byte $08,$02,$02,$09,$09 
				
colors:
			.byte $06,$06,$06,$0e,$06,$0e
			.byte $0e,$06,$0e,$0e,$0e,$03
			.byte $0e,$03,$03,$0e,$03,$03
			.byte $03,$01,$03,$01,$01,$03
			.byte $01,$01,$01,$03,$01,$01
			.byte $03,$01,$03,$03,$03,$0e
			.byte $03,$03,$0e,$03,$0e,$0e
			.byte $0e,$06,$0e,$0e,$06,$0e
			.byte $06,$06,$06,$00,$00,$00
			
			.byte $ff


.pc = * "Code"

// Entry point to the program:

main:
{		
			lda #$00
			sta ANIMATION_STATE

			sei							// Disable interrupts.
			
			//jsr init_screen
			//jsr init_text	
			//jsr $1000					// Init music.
			lda #music.startSong - 1
			jsr music.init
						
			ldy #$7f
			sty $dc0d   				// Turn off CIAs Timer interrupts.
           	sty $dd0d   				// Turn off CIAs Timer interrupts.
           	lda $dc0d   				// Cancel all CIA-IRQs in queue/unprocessed.
           	lda $dd0d   				// Cancel all CIA-IRQs in queue/unprocessed.
           	
           	lda #$01					// Set interrupt request mask.
           	sta $d01a					// IRQ by rasterbeam.
           	
           	lda #<irq
           	ldx #>irq
           	sta $314
           	stx $315
           	
           	lda #$00					// Trigger first interrupt at row zero.
           	sta $d012
           	
           	lda $d011
           	and #$7f
           	sta $d011
           	
           	cli                      	
			
           	lda #$7a
           	sta RASTER_START
           	
           	lda #$0						// First raster bars go down.
           	sta RASTER_MOVE_DIRECTION	// Store direction.
           	
           	lda #$00					// In the first seconds we don't want to show rasterbar.
           	sta RASTER_SHOW
           	
main_loop:
			lda RASTER_SHOW				// Check if we should show rasterbar.
			cmp #$01					// If flag is set to 1 then show rasterbar.
			bne main_loop
           	
raster_start:           	
           	ldy RASTER_START 			// Load $7a into Y. this is the line where our rasterbar will start.
           	ldx #$00 					// Load $00 into X.
           	
           	cpy #$bf					// Check if this is the line where rasterbar should stop.
           	beq raster_reverse
           	
           	cpy #$3a					// If it is the start line
           	beq raster_forward			// then we move forward (down).
           	
           	ldy RASTER_MOVE_DIRECTION	// Check for direction and move bars.
           	cpy #$01
           	beq raster_move_backward
           	
raster_move_forward:
			ldy RASTER_START			// Move bars down.
			iny
			sty RASTER_START
			jmp raster_bar
			
raster_move_backward:
			ldy RASTER_START			// Move bars up.
			dey
			sty RASTER_START
			jmp raster_bar           	
           	
raster_reverse:
			lda #$01					// Change move direction to reverse
			sta RASTER_MOVE_DIRECTION
           	jmp raster_move_backward
			
raster_forward:
			lda #$00
			sta RASTER_MOVE_DIRECTION
			jmp raster_move_forward
						
raster_bar:
		   	lda colors, x 				// Load value at label 'colors' plus x into a. if we don't add x, only the first 
		   				  				// value from our color-table will be read.
           	cpy $d012 					// ComPare current value in Y with the current rasterposition.
           	bne *-3 					// Is the value of Y not equal to current rasterposition? then jump back.
           	sta $d020 					// If it IS equal, store the current value of A (a color of our rasterbar)
           								// into the bordercolour
           	//sta $d021					// and into the screen.
           						
           	cpx #51 					// Compare X to #51 (decimal). have we had all lines of our bar yet?
           	beq main_loop 				// Branch if EQual. if yes, jump to main.

           	inx 						// Increase X. so now we're gonna read the next color out of the table.
           	iny 						// Increase Y. go to the next rasterline.
		   	
			jmp raster_bar
						
!end:	
			rts							// Returns to BASIC.
			
			
col_wash:
			lda color + $00				// Loads current first color from table.
			sta color + $28				// Store in last position of table to reset.
			ldx #$00
			sta $d9df					// Put current color into Color RAM position.
			
cycle1:
			lda color + 1, x			// Gets next color in table.
			sta color, x				// Store it in current active position.
			sta $d990, x				// Put into Color RAM.
			inx
			cpx #$28
			bne cycle1
			
col_wash2:
			lda color2 + $28
			sta color2 + $00
			ldx #$28

cycle2:
			lda color2 - 1, x
			sta color2, x
			sta $d9df, x
			dex
			bne cycle2
			
			rts
			
init_screen:
			ldx #$00 					// Black color.
			stx $d020 					// Set border color.
			stx $d021 					// Set background color.

clear_screen:			
			lda #$20 					// Spacebar screen code.
			sta $0400, x				// Fill screen with spacebars.
			sta $0500, x
			sta $0600, x
			sta $06e8, x
			lda #$00					// Set foreground color to black.
			sta $d800, x
			sta $d900, x
			sta $da00, x
			sta $dae8, x
			inx
			bne clear_screen
			rts
			
init_text:
			ldx #$00
			
loop_text:
			lda line1, x
			sta $0590, x
			lda line2, x
			sta $05e0, x
			
			inx
			cpx #$28
			bne loop_text
			rts
			
irq:
			dec $d019

			//jsr music.play				// Play music (always)

			ldx ANIMATION_STATE				// Check actual animation state.
			cpx #$00
			beq border_state				// Change border color state.
			cpx #$01
			beq clear_chars_state
			cpx #$03
			beq rasterbar_state				// Rasterbar show state.
			
irq_main:			
			inc	RASTERBEAM_IRQ_COUNTER	
			
			jsr col_wash
			//jsr $1003					// Play music.
			
exit_irq:
			jmp $ea81					// Return to kernel interrupt routine.
			
			
rasterbar_state:
			ldx RASTERBEAM_IRQ_COUNTER	// Wait 2 seconds.
			cpx #100
			beq rasterbar_show
			jmp irq_main
			
rasterbar_show:
			lda #$01					// Show rasterbar
			sta RASTER_SHOW
			
			jsr reset_rasterbar_counter
			
			inc ANIMATION_STATE
			jmp irq_main
			
border_state:
			ldx RASTERBEAM_IRQ_COUNTER
			cpx #100
			beq border_state_change
			jmp irq_main

border_state_change:			
			ldx #$00 					// Black color.
			stx $d020 					// Set border color.
			
			jsr reset_rasterbar_counter
			
			inc ANIMATION_STATE
			jmp irq_main
			
reset_rasterbar_counter:
			lda #00						// Reset rasterbar irq counter.
			sta RASTERBEAM_IRQ_COUNTER
			rts
			
clear_chars_state:
			ldx RASTERBEAM_IRQ_COUNTER
			cpx #10
			beq clear_chars_clear_one
			
			inc RASTERBEAM_IRQ_COUNTER

			jmp irq_main
			
clear_chars_clear_one:
			lda #00
			sta RASTERBEAM_IRQ_COUNTER
			jmp irq_main
}

.print ""
.print "SID Data"
.print "--------"
.print "location=$"+toHexString(music.location)
.print "init=$"+toHexString(music.init)
.print "play=$"+toHexString(music.play)
.print "songs="+music.songs
.print "startSong="+music.startSong
.print "size=$"+toHexString(music.size)
.print "name="+music.name
.print "author="+music.author
.print "copyright="+music.copyright

.print ""
.print "Additional tech data"
.print "--------------------"
.print "header="+music.header
.print "header version="+music.version
.print "flags="+toBinaryString(music.flags)
.print "speed="+toBinaryString(music.speed)
.print "startpage="+music.startpage
.print "pagelength="+music.pagelength
