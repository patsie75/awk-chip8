#!/usr/bin/gawk -f 

## Let 'od' decode our binary file
## Process 'od' output with disassembled mnemonics

@include "opcode.gawk"

BEGIN {
  if (ARGC != 2) {
    printf("Usage: %s <file>.ch8\n", ARGV[0])
    exit 1
  }

  addr = 0x0200
  cmd = sprintf("od --endian=big -v -w2 -t x1 \"%s\"", ARGV[1])

  while ((cmd | getline) > 0) {
    opcode = strtonum("0x"$2$3)
    printf("%04X\t; [0x%04X] %s\n", opcode, addr, opcode::disasm(opcode) )
    addr += 2
  }

  close(cmd)
}

