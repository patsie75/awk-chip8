#!/usr/bin/gawk -f

@include "lib/chip8.gawk"

BEGIN {
  srand()
  # hide cursor
  printf("\033[?25l")

  # config (to be loaded from file in future)
  chip["cfg"]["width"] = 64
  chip["cfg"]["height"] = 32
  chip["cfg"]["debug"] = 1
  chip["cfg"]["step"] = 1

  # initialize chip-8 computer and load program
  chip8::init(chip)
  chip8::load(chip, "prgs/maze.hex", 0x0200)
  #chip8::load(chip, "prgs/chip8pic.hex", 0x0200)
  #chip8::load(chip, "prgs/ibmlogo.hex", 0x0200)
  #chip8::load(chip, "prgs/chip8emu.hex", 0x0200)
  #chip8::load(chip, ARGV[1], 0x0200)

  # display first output
  chip8::draw(chip, 1,1)

  if (chip["cfg"]["debug"])
    chip8::dump(chip, "all", chip["cfg"]["width"]+2, 1)

  if (chip["cfg"]["step"])
    getline

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
}

END {
  # show cursor and put at sane location
  printf("\033[16;1H\033[?25h\n")
}
