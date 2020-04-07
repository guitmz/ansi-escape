# ansi-escape
Simple program to demonstrate how to control a terminals with x64 Assembly. It works by fetching information about the terminal window size using Linux syscalls and crafting [ANSI escape](https://en.wikipedia.org/wiki/ANSI_escape_code) codes to control the inputs. 

Another small auxiliar tool is included that can be used display the terminal dimensions (rows and columns) and there are comments in the code to make it easier to follow and understand.

# Usage
You'll need [Flat Assembler](https://flatassembler.net/) and Linux 64-bit (the code can be ported to 32-bit and other assemblers without much effort since it's pretty generic).

For the main program:
```
$ fasm ansi.asm
$ ./ansi
```

For the auxiliar program:
```
$ gcc winsz.c -o winsz
$ ./winsz 
lines 67
columns 274
```

# Demo
[![asciicast](https://asciinema.org/a/mPFXstXi8MisAgoZ9IhC2T32B.svg)](https://asciinema.org/a/mPFXstXi8MisAgoZ9IhC2T32B)
