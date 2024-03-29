        
		DEVICE NOSLOT64K
        OUTPUT "EXAMPLE.BIN"

		
		include "../system/MSX-DOS.equ.z80"
		
		include "example.txt"
		
        org $9000 - 7

header: db $fe
        dw start, end, entry

start:
entry:

; Open the libfile  directory
		ld hl,libfile
		ld de,directory
		call libfile.load_directory
		
; Load the file hello.txt
		ld hl,hello.txt
		ld de,$a000
		call libfile.load_file
		
; Add " $" after file contents
		ld de,$a000
		add hl,de
		ld (hl)," "
		inc hl
		ld (hl),"$"
		
; Output text
		ld c,_STROUT
		ld de,$a000
		call BDOSBAS
		
; Load the file world.txt
		ld hl,1
		ld de,$a000
		call libfile.load_file
		
; Add "$" after file contents
		ld de,$a000
		add hl,de
		ld (hl),"$"
		
; Output more text
		ld c,_STROUT
		ld de,$a000
		call BDOSBAS
		
; Return to BASIC
		ret
		
		
		include "../readlib/readlib.asm"
		

libfile: db "EXAMPLE LIB"	; the libfile containing contents from files "hello.txt" and "world.txt"
directory:

end:
