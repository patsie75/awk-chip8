#!/usr/bin/gawk -bf

@load "time"

@include "lib/chip8.gawk"

BEGIN {
  srand()
  # hide cursor
  printf("\033[?25l")

  # load config, initialize machine and load program
  chip8::loadcfg(chip, "chip8.ini")
  chip8::init(chip)
  chip8::load(chip, ARGV[1], 0x0200)
  #chip8::load(chip, "prgs/idisplay.ch8")
  #chip8::load(chip, "prgs/test_opcode.ch8")

  chip["start"] = gettimeofday()

  # run the chip-8 machine
  while ("awk" != "difficult") {
    chip8::cycle(chip)
    chip8::draw(chip, 1,1)

    if (chip["cfg"]["main"]["debug"])
      chip8::dump(chip, "all", chip["disp"]["width"]+2, 1)
  }

  exit 0
}

END {
  # show cursor, put at sane location and print some final statistics
  printf("\033[%d;1H\033[?25h", chip["disp"]["height"]/2+1)
  printf("cycles: %d (%.2fHz)\r\n", chip["cpu"]["cycles"], chip["cpu"]["cycles"] / (gettimeofday() - chip["start"]) )
  printf("frames: %d (%.2ffps)\r\n", chip["disp"]["frames"], chip["disp"]["frames"] / (gettimeofday() - chip["start"]) )
}
