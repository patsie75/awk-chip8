@namespace "chip8"

@include "lib/cpu.gawk"

BEGIN {
  # bytes for characters 0-9 and A-F
  fontstr = "F0 90 90 90 F0 \
             20 60 20 20 70 \
             F0 10 F0 80 F0 \
             F0 10 F0 10 F0 \
             90 90 F0 10 10 \
             F0 80 F0 10 F0 \
             F0 80 F0 90 F0 \
             F0 10 20 40 40 \
             F0 90 F0 90 F0 \
             F0 90 F0 10 F0 \
             F0 90 F0 90 90 \
             E0 90 E0 90 E0 \
             F0 80 80 80 F0 \
             E0 90 90 90 E0 \
             F0 80 F0 80 F0 \
             F0 80 F0 80 80"
  split(fontstr, sysfont)

  # set ord table
  for (i=0; i<256; i++)
    ORD[sprintf("%c",i)] = i;
}


function dump(self, val, xpos, ypos,    i, y) {
  switch(val) {
    case /^mem|all/:
      for (i=self["pc"]-2; i<self["pc"]+30; i+=2) {
        opcode = self["mem"][i] * 256 + self["mem"][i+1]
        printf("\033[%d;%dH%s%04X: %02X %02X [%-14s]%c\033[0m\n", ypos+y++, xpos, (i==self["pc"]) ? "\033[97;101m>" : " ", i, self["mem"][i], self["mem"][i+1], cpu::disasm(opcode), (i==self["pc"]) ? "<" : " " )
      }

    case /^reg|all/:
      printf("\033[%d;%dHPC: 0x%04X, val: 0x%02X\n", ypos+0, xpos+31, self["pc"], self["mem"][ self["pc"] ])
      printf("\033[%d;%dH I: 0x%04X, val: 0x%02X\n", ypos+1, xpos+31, self["I"],  self["mem"][ self["I"] ])
      printf("\033[%d;%dHSP: 0x%04X, val: 0x%02X\n", ypos+2, xpos+31, self["sp"], self["stack"][ self["sp"] ])

      printf("\033[%d;%dHV0-V3: %02X %02X %02X %02X\n", ypos+4, xpos+31, self["V"][0x0], self["V"][0x1], self["V"][0x2], self["V"][0x3])
      printf("\033[%d;%dHV4-V7: %02X %02X %02X %02X\n", ypos+5, xpos+31, self["V"][0x4], self["V"][0x5], self["V"][0x6], self["V"][0x7])
      printf("\033[%d;%dHV8-VB: %02X %02X %02X %02X\n", ypos+6, xpos+31, self["V"][0x8], self["V"][0x9], self["V"][0xA], self["V"][0xB])
      printf("\033[%d;%dHVC-VF: %02X %02X %02X %02X\n", ypos+7, xpos+31, self["V"][0xC], self["V"][0xD], self["V"][0xE], self["V"][0xF])

      printf("\033[%d;%dHdelay: %02X, sound %02X\n", ypos+9, xpos+31, self["timer"]["delay"], self["timer"]["sound"])
  }
}


function init(self) {
  # program counter
  self["pc"]     = 0x0200

  # put system font in memory
  for (i=0; i<0x50; i++)
    self["mem"][i] = awk::strtonum("0x" sysfont[i+1])

  # display data
  self["disp"]["refresh"] = 1
}


function load(self, fname, addr,    ext, _fs, x) {
  addr = length(addr) ? addr : 0x0200
  ext = substr(fname, length(fname)-3)

  # load ascii based hex file. big-endian word per line
  if (ext == ".hex") {
    _fs = FS; FS = ","
    while ((getline <fname) > 0) {
      self["mem"][addr++] = awk::strtonum("0x"substr($0,1,2)) % 256
      self["mem"][addr++] = awk::strtonum("0x"substr($0,3,2)) % 256
    }
  }

  # load binary ch8 file
  if (ext == ".ch8") {
    _fs = FS; FS = ""
    while ((getline <fname) > 0) {
      for (x=1; x<=NF; x++)
        self["mem"][addr++] = ORD[$x]
      if (RT)
        self["mem"][addr++] = ORD[RT]
    }
  }

  close(fname)
  FS = _fs
}


function draw(self, xpos, ypos,    x,y, w,h, up,dn, line) {
  if (self["disp"]["refresh"] == 1) {
    w = self["cfg"]["width"]
    h = self["cfg"]["height"]

    for (y=0; y<h; y+=2) {
      line = sprintf("\033[%d;%dH\033[32;40m", ypos+(y/2), xpos)
      for (x=0; x<w; x++) {
        up = self["disp"][(y+0)*w + x]
        dn = self["disp"][(y+1)*w + x]
        line = sprintf("%s%s", line, up ? (dn ? "█" : "▀") : (dn ? "▄" : " "))
      }
      printf("%s\033[0m", line)
    }
    self["disp"]["refresh"] = 0
  }
}


function update_timers(self) {
  if (self["timer"]["delay"] > 0)
    self["timer"]["delay"]--

  if (self["timer"]["sound"] > 0)
    self["timer"]["sound"]--
}


function cycle(self) {
  cpu::fetch(self)
  cpu::execute(self)
  update_timers(self)
}

