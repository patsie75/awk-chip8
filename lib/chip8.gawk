@namespace "chip8"

@load "time"

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

  # low resolution pixels
  lores["00"] = " "
  lores["01"] = "▄"
  lores["10"] = "▀"
  lores["11"] = "█"

  # high resolution pixels
  hires["0000"] = " "
  hires["0001"] = "▗"
  hires["0010"] = "▖"
  hires["0011"] = "▄"
  hires["0100"] = "▝"
  hires["0101"] = "▐"
  hires["0110"] = "▞"
  hires["0111"] = "▟"
  hires["1000"] = "▘"
  hires["1001"] = "▚"
  hires["1010"] = "▌"
  hires["1011"] = "▙"
  hires["1100"] = "▀"
  hires["1101"] = "▜"
  hires["1110"] = "▛"
  hires["1111"] = "█"

}


function dump(self, val, xpos, ypos,    i, y) {
  switch(val) {
    case /^mem|all/:
      for (i=self["pc"]-2; i<self["pc"]+14; i+=2) {
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
      printf("\033[%d;%dHspeed: %.2fHz\n", ypos+10, xpos+31, self["cpu"]["cycles"] / (awk::gettimeofday() - self["start"]))
  }
}


function init(self) {
  # program counter
  self["pc"]      = 0x0200

  # set timing intervals
  self["cpuhz"]   = 1 / self["cfg"]["cpuhz"]
  self["timerhz"] = 1 / self["cfg"]["timerhz"]

  # put system font in memory
  for (i=0; i<0x50; i++)
    self["mem"][i] = awk::strtonum("0x" sysfont[i+1])

  # display data
  self["disp"]["width"] = self["cfg"]["width"]
  self["disp"]["height"] = self["cfg"]["height"]
  self["disp"]["refresh"] = 1

}


function load(self, fname, addr,    ext, _fs, x,   end, label, mnem, a, l, unknown, m, argv, opc) {
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

  # load assembly file
  if (ext == ".asm") {
    start = addr
    _fs = FS

    while ((getline <fname) > 0) {
      if ($1 ~ /^:/) {
        # catch labels and save their address
        label[$1] = sprintf("0x%04X", addr)
        continue
      }

      if (NF && ($1 !~ /^;/)) {
        # strip comments and reduce whitespace
        gsub(/;.*/, "")
        gsub(/\s\s*/, " ")
        gsub(/(^\s*|\s*$)/, "")

        # save leftover as mnemonic
        if (length($0)) {
          mnem[addr] = $0
          addr += 2
        }
      }
    }

    for (a=start; a<addr; a+=2) {
      # replace all labels with addresses
      for (l in label)
        gsub(l, label[l], mnem[a])

      unknown = 1
      for (m in cpu::opcode) {
        # put opcode in memory
        if (match(mnem[a], m, argv)) {
          #printf("0x%04X: %20s -> "cpu::opcode[m]"\n", a, mnem[a], argv[1], argv[2], argv[3])
          opc = sprintf(cpu::opcode[m], argv[1], argv[2], argv[3])
          self["mem"][a+0] = awk::strtonum("0x"substr(opc,1,2))
          self["mem"][a+1] = awk::strtonum("0x"substr(opc,3,2))
          unknown = 0
        }
      }

      # unknown mnemonic found (typo in code?)
      if (unknown) {
        printf("Cannot compile [%s] at address 0x%04X\n", mnem[a], a)
        getline
        return -1
      }
    }

  }

  close(fname)
  FS = _fs

  return addr
}

function save(self, fname, len, addr,    ext, i, opcode) {
  addr = length(addr) ? addr : 0x0200
  ext = substr(fname, length(fname)-3)

  if (ext == ".hex") {
    for (i=0; i<len; i+=2) {
      opcode = self["mem"][addr+i] * 256 + self["mem"][addr+i+1]
      printf("%04X	; [0x%04X] %s\n", opcode, addr+i, cpu::disasm(opcode)) >>fname
    }
  }
  if (ext == ".ch8") {
    for (i=0; i<len; i++)
      printf("%c", self["mem"][addr+i]) >>fname
  }
  close(fname)
}


function draw(self, xpos, ypos,    x,y, w,h, up1, up2, dn1, dn2, line, display) {
  if (self["disp"]["refresh"] == 1) {
    w = self["disp"]["width"]
    h = self["disp"]["height"]

    display = "\033[32;40m"
    for (y=0; y<h; y+=2) {
      line = sprintf("\033[%d;%dH", ypos + int(y/2), xpos)
      for (x=0; x<w; x+=(self["disp"]["hires"]+1)) {
        up1 = self["disp"][(y+0)*w + (x+0)] + 0
        up2 = self["disp"][(y+0)*w + (x+1)] + 0
        dn1 = self["disp"][(y+1)*w + (x+0)] + 0
        dn2 = self["disp"][(y+1)*w + (x+1)] + 0
        line = line "" (self["disp"]["hires"] ? hires[up1""up2""dn1""dn2] : lores[up1""dn1])
      }
      display = display "" line
    }
    printf("%s\033[0m", display)
    self["disp"]["refresh"] = 0
    self["disp"]["frames"]++
  }
}


function update_timers(self,    diff) {
  #getline <"/proc/uptime"
  #close("/proc/uptime")
  now = awk::gettimeofday()

  # since last update
  cpu   = now - self["timer"]["lastcpu"]
  timer = now - self["timer"]["lasttimer"]

  # update delay and sound timers
  if ( timer >= self["timerhz"] ) {
    if (self["timer"]["delay"] > 0) {
      self["timer"]["delay"] -= (timer / self["timerhz"])
      if (self["timer"]["delay"] < 0)
        self["timer"]["delay"] = 0
    }

    if (self["timer"]["sound"] > 0) {
      self["timer"]["sound"] -= (timer / self["timerhz"])
      if (self["timer"]["sound"] < 0)
        self["timer"]["sound"] = 0
    }

    self["timer"]["lasttimer"] = now - (timer % self["timerhz"])
  }

  # check CPU speed for a new cycle
  if (cpu >= self["cpuhz"]) {
    self["cpu"]["run"] = 1
    self["timer"]["lastcpu"] = now
  } else awk::sleep(0.00001)

}


function cycle(self) {
  # only run if CPU is not in 'halt' status
  if (!self["cpu"]["halt"]) {
    # update timers first
    update_timers(self)

    # only run if a cpu has a cycle waiting
    if (self["cpu"]["run"]) {
      cpu::fetch(self)
      cpu::execute(self)
      self["cpu"]["run"] = 0
      self["cpu"]["cycles"]++
    }
  }
}

