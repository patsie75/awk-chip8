#!/usr/bin/gawk -bf

@load "time"

@include "lib/chip8.gawk"

BEGIN {
  srand()
  # hide cursor
  printf("\033[?25l")

  # config (to be loaded from file in future)
  chip["cfg"]["width"]   = 64
  chip["cfg"]["height"]  = 32
  chip["cfg"]["cpuhz"]   = 500
  chip["cfg"]["timerhz"] = 60
  chip["cfg"]["debug"]   = 0
  chip["cfg"]["step"]    = 0

  # initialize chip-8 computer and load program
  chip8::init(chip)

  #chip8::load(chip, ARGV[1], 0x0200)
  #chip8::load(chip, "prgs/idisplay.ch8")
  chip8::load(chip, "prgs/test_opcode.ch8")

  if (chip["cfg"]["debug"]) {
    chip8::draw(chip, 1,1)
    chip8::dump(chip, "all", chip["cfg"]["width"]+2, 1)

    if (chip["cfg"]["step"])
      getline
  }

  start = gettimeofday()

  # run the chip-8 machine
  while ("awk" != "difficult") {
    # run one cpu-cycle and display output
    chip8::cycle(chip)
    chip8::draw(chip, 1,1)

    # show memory and register information
    if (chip["cfg"]["debug"])
      chip8::dump(chip, "all", chip["cfg"]["width"]+2, 1)

    # wait for enter key to step to the next cycle
    if (chip["cfg"]["step"])
      getline
  }

  exit 0
}

END {
  # show cursor, put at sane location and print some final statistics
  printf("\033[%d;1H\033[?25h", chip["disp"]["height"]/2+1)
  printf("cycles: %d (%.2fHz)\n", chip["cpu"]["cycles"], chip["cpu"]["cycles"] / (gettimeofday() - start) )
  printf("frames: %d (%.2ffps)\n", chip["disp"]["frames"], chip["disp"]["frames"] / (gettimeofday() - start) )
}
