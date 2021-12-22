# Makelib
Makelib is a simple tool for combining multiple files into one big file (libfile).

Combining files into one libfile has some advantages, especially for disk based games:
- Overcome the maximum number of files (eg 112 files on MSX DOS1 formatted disks)
- Reduce required space (eg files on MSX DOS1 formatted disk use a multiple of two sectors of 512 bytes)
- Improve loading speeds (eg when opening a file the system may read the whole FAT first)

# Contents
- makelib: Tool for creating libfiles
- readlib: Code for reading libfiles (for MSX)
- example: A simple example demonstrating how to use readlib (for MSX)


# Notes
- The code in readlib and sample can be assembled using sjasmplus ( https://github.com/z00m128/sjasmplus )
- I used the "MSX constants (EQUs) for assembly development by FRS" ( http://frs.badcoffee.info/tools.html ). These are public domain
