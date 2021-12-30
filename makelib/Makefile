CC = cl
CFLAGS = /EHsc /O2 /std:c++20
RM = del
EXTENSION = .exe

all: makelib

makelib: makelib.cpp
	$(CC) $(CFLAGS) makelib.cpp /link /out:makelib$(EXTENSION)

clean:
	$(RM) *.obj
