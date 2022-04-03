
        OUTPUT "EXAMPLE.ROM"

		include "../../system/MSXBIOS.equ.z80"
		include "../../system/MSXvars.equ.z80"

		include "example.txt"
		

mapper_bank0: equ $5000
mapper_bank1: equ $7000
mapper_bank2: equ $9000
mapper_bank3: equ $B000

data_segment: equ 4


		org $4000
		
		db "AB"
		dw init
		dw 0		; statement
		dw 0		; device
		dw 0		; text
		dw 0,0,0	; reserved
		
init:

; The ROM is selected in page 1, but we also need it in page 2
		call enable_rom_in_page2

; Map the file hello.txt into the address space
		ld de,hello.txt
		call map_file
		
; Print the text
		call print_text

; Print a space
		ld a,' '
		call CHPUT

; Map the file world.txt into the address space
		ld de,world.txt
		call map_file

; Print some more text
		call print_text

; Wait forever
		di
		halt


; Enable the ROM that's selected in page 1 in page 2
enable_rom_in_page2:
		call RSLREG		; Read the primary slots register
		rrca
		rrca
		and	3
		ld c,a
		ld b,0
		ld hl,EXPTBL	; HL = Address of the secondary slot flags table
		add hl,bc
		ld a,(hl)
		and $80			; Keep the bit 7 (secondary slot flag)
		or c
		ld c,a
		inc hl
		inc hl
		inc hl
		inc hl			; HL =  Address of the secondary slot register in the secondary slot register table
		ld a,(hl)
		and $0c
		or c
		ld h,$80
		call ENASLT		; Select the ROM on page 8000h-BFFFh
		ret
		
		
; Print some text
; In: HL: text address
;     BC: length:
print_text:
		ld a,(hl)
		call CHPUT
		
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,print_text
		ret
		

; Map file from library into memory area $8000-$bfff
; In: DE: file number
; Out: HL: address
;      EBC: length
; Destroys: AF, AF', D
map_file:
		call get_file_info
		
		ld a,h
		and %11100000		; get lower 3 bits of page number
		rlca
		rlca
		rlca
		
		sla d				; 64KB is 8 pages of 8KB
		rl d
		rl d
		
		add a,d
		
		add a,data_segment	; the first segment with data
		
		ld (mapper_bank2),a
		inc a
		ld (mapper_bank3),a
		
		ld a,h
		and %00011111
		add a,$80			; the starting address in the selected page in $8000-9FFF
		ld h,a
		ret


; Get file offset / length
; In: HL: pointer to library
;     DE: file number
; Out: DHL: offset
;      EBC: length
; Destroys: AF, AF'
get_file_info:
		ld a,data_segment	; select page containing file info into $8000-$9FFF
		ld (mapper_bank2),a	; assuming ROM is still selected here...
		
		ld hl,$8002	; lib starts at $8000, first two bytes indicate number of files in the lib

		add hl,de	; *6 to get to file offset/length info
		add hl,de
		add hl,de
		add hl,de
		add hl,de
		add hl,de
		
		ld e,(hl)	; put offset in lib in ADE
		inc hl
		ld d,(hl)
		inc hl
		ld a,(hl)
		inc hl
		
		ld c,(hl)	; put length in ABC
		inc hl
		ld b,(hl)
		inc hl
		ex af,af'
		ld a,(hl)
		
		ex de,hl	; put offset in lib in DHL
		ex af,af'
		ld d,a
		
		ex af,af'	; put length in EBC
		ld e,a
		ret


		ds $8000 - ($ - $4000)	; fill up the first four 8KB segments

example.lib:
		INCBIN "EXAMPLE.LIB"
		
		
		ds $20000 - ($ - $4000)	; pad the rom to 128KB
		