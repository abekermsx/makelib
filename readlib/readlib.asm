
        MODULE libfile

; Load directory
; In:  HL: pointer to filename of libfile to load
;      DE: destination address directory
; Out: A: 0 if directory has been loaded
;         <>0 if directory hasn't been loaded
; Destroys: all
load_directory:
        ld (current_directory),de

        ld de,fcb.FNAME
        ld bc,11
        ldir                    ; Copy the filename to the FCB
        
		call clear_fcb

        ld de,fcb
        ld c,_FOPEN
        call BDOSBAS
        or a
		ret nz                  ; Exit if file not found

        call initialize_fcb

        ld de,(current_directory)
        ld c,_SETDTA
        call BDOSBAS
		
        ld hl,2
        call load_data          ; Read number of files in library
        
        ld hl,(current_directory)
        ld c,(hl)
        inc hl
        ld b,(hl)

		push bc                 ; Push number of entries
		
		dec hl
		ex de,hl
        ld c,_SETDTA
        call BDOSBAS		

        pop hl                  ; Pop number of entries

; Calculate size of directory (6 bytes per file: offset = 3 bytes, size = 3 bytes)
        add hl,hl ; *2
        ld b,h
        ld c,l
        add hl,hl ; *4
        add hl,bc ; *6

        call load_data          ; Load directory
		ret


; Load a file
; In: HL: file number to load
;     DE: destination address
; Out: A: 0 if no error occurred while reading data
;         <>0 if an error occurred
;      HL: number of bytes read
; Destroys: all
load_file:
        push de
		call seek_file
		pop de   
		
		push hl
		ld c,_SETDTA
        call BDOSBAS
        pop hl
        call load_data
		ret


; Set pointer in library file to file we want to read and get file length
; In:  HL: file number to load
; Out: CHL: length of file
; Destroys: flags, B, DE
seek_file:
        ex de,hl

; Calculate address of file entry
        ld hl,(current_directory)
		add hl,de
		add hl,de
		add hl,de
		add hl,de
		add hl,de
		add hl,de

; Set offset of file in fcb
		ld de,fcb.RN
		ld bc,3
		ldir               

; Get file length
		ld e,(hl)
		inc hl
		ld d,(hl)          
		inc hl
		ld c,(hl)
		ex de,hl
		ret


; Load data
; In: HL: number of bytes to read
; Out: A: 0 if no error occurred while reading data
;         <>0 if an error occurred
;      HL: number of bytes actually read
; Destroys: all
load_data:
        ld de,fcb
        ld c,_RDBLK
        call BDOSBAS
        ret


; Initialize FCB
; In: -
; Out: -
; Destroys: flags, BC, DE, HL
clear_fcb:
        ld hl,fcb.EX
        ld de,fcb.EX + 1
        ld bc,24
        ld (hl),b
        ldir
        ret


; Initialize FCB
; In: -
; Out: -
; Destroys: HL
initialize_fcb:
        ld hl,0
        ld (fcb.EX),hl     ; Reset block number

        ld (fcb.RN+0),hl   ; Reset random block
        ld (fcb.RN+2),hl

        ld (fcb.CR),hl     ; Reset current record

        inc hl
        ld (fcb.S2),hl     ; Set block length to 1
        ret


; File control block
; Variable names / descriptions from: https://www.msx.org/wiki/FCB
fcb:
.DR:     db 0           ; Drive
.FNAME:  db "        "  ; File name
.FEXT:   db "   "       ; File extension
.EX:     db 0           ; Least significant byte of the current record block number for sequential accesses, or "Extent number LO" depending of function called.
.S1:     db 0           ; Most significant byte of the current record block number for sequential accesses, or File attributes (DOS2). It depends of the called function.
.S2:     db 0           ; Least significant byte of the record size (128 bytes by default to be CP/M compatible), or Most significant byte of the extent number. This depends on called function. NOTE: Because of Extent number the record size must be manually defined after opening a file! 
.RC:     db 0           ; Most significant byte of the record size, or record count. This depends on function called. (Always 0 under CP/M) 
.FILSIZ: db 0,0,0,0     ; File size in bytes
.DATE:   db 0,0         ; Date (DOS1) / Volume ID (DOS2)
.TIME:   db 0,0         ; Time (DOS1) / Volume ID (DOS2)
.DEVID:  db 0           ; Device ID. (DOS1) 
.DIRLOC: db 0           ; Directory location. (DOS1) 
.STRCLS: db 0,0         ; Top cluster number of the file (DOS1) (indicated in inverted bits). 
.CLRCLS: db 0,0         ; Last cluster number accessed. (DOS1) (indicated in inverted bits) 
.CLSOFF: db 0,0         ; Relative location from top cluster of the file number of clusters from top of the file to the last cluster accessed. (DOS1) (indicated in inverted bits). 
.CR:     db 0           ; Current record within extent for sequential accesses. (0~127) 
.RN:     db 0,0,0,0     ; Record number for random accesses. If record size <64 then all 4 bytes will be used. 

current_directory: dw 0

        ENDMODULE
