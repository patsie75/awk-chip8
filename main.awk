#!/usr/bin/gawk -f

@include "lib/chip8.gawk"

BEGIN {
  printf("\033[?25l")
  srand()

  chip["cfg"]["width"] = 64
  chip["cfg"]["height"] = 32
  chip["cfg"]["debug"] = 1
  chip["cfg"]["step"] = 1

  chip8::init(chip)
  #chip8::load(chip, "prgs/maze.hex", 0x0200)
  chip8::load(chip, "prgs/chip8pic.hex", 0x0200)

  #chip["pc"] = 0x0002
  #chip8::dump(chip, "all", 1, 1)
  #exit 0

  while ("awk" != "difficult") {
    chip8::cycle(chip)
    chip8::draw(chip, 1,1)

    # show memory and register information
    if (chip["cfg"]["debug"])
      chip8::dump(chip, "all", chip["cfg"]["width"]+2, 1)

    # wait for enter to step to the next cycle
    if (chip["cfg"]["step"])
      getline
  }

}

END {
  printf("\033[16;1H\033[?25h\n")
}
