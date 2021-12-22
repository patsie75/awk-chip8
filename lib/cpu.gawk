@namespace "cpu"

BEGIN {
  mnem["0000"]       = "NOP"
  mnem["00E0"]       = "CLS"
  mnem["00EE"]       = "RET"
  mnem["0([^0][^0E][^0])"] = "SYS  0x%s"
  mnem["1(...)"]     = "JP   0x%s"
  mnem["2(...)"]     = "CALL 0x%s"
  mnem["3(.)(..)"]   = "SE   V%s,0x%s"
  mnem["4(.)(..)"]   = "SNE  V%s,0x%s"
  mnem["5(.)(.)0"]   = "SE   V%s,V%s"
  mnem["6(.)(..)"]   = "LD   V%s,0x%s"
  mnem["7(.)(..)"]   = "ADD  V%s,0x%s"
  mnem["8(.)(.)0"]   = "LD   V%s,V%s"
  mnem["8(.)(.)1"]   = "OR   V%s,V%s"
  mnem["8(.)(.)2"]   = "AND  V%s,V%s"
  mnem["8(.)(.)3"]   = "XOR  V%s,V%s"
  mnem["8(.)(.)4"]   = "ADD  V%s,V%s"
  mnem["8(.)(.)5"]   = "SUB  V%s,V%s"
  mnem["8(.)(.)6"]   = "SHR  V%s,V%s"
  mnem["8(.)(.)7"]   = "SUBN V%s,V%s"
  mnem["8(.)(.)E"]   = "SHL  V%s,V%s"
  mnem["9(.)(.)0"]   = "SNE  V%s,V%s"
  mnem["A(...)"]     = "LD   I,0x%s"
  mnem["B(...)"]     = "JP   V0,0x%s"
  mnem["C(.)(..)"]   = "RND  V%s,0x%s"
  mnem["D(.)(.)(.)"] = "DRW  V%s,V%s,0x%s"
  mnem["E(.)9E"]     = "SKP  V%s"
  mnem["E(.)A1"]     = "SKNP V%s"
  mnem["F(.)07"]     = "LD   V%s,DT"
  mnem["F(.)0A"]     = "LD   V%s,K"
  mnem["F(.)15"]     = "LD   DT,V%s"
  mnem["F(.)18"]     = "LD   ST,V%s"
  mnem["F(.)1E"]     = "ADD  I,V%s"
  mnem["F(.)29"]     = "LD   F,V%s"
  mnem["F(.)33"]     = "LD   B,V%s"
  mnem["F(.)55"]     = "LD   [I],V%s"
  mnem["F(.)65"]     = "LD   V%s,[I]"
}


function disasm(opcode,    hex, op, argv) {
  hex = sprintf("%04X", opcode)

  for (op in mnem)
    if (match(hex, op, argv))
      # there are at most 3 arguments for an opcode
      return sprintf(mnem[op], argv[1], argv[2], argv[3])

  return "<UNKNOWN>"
}


function fetch(self,    pc) {
  pc = self["pc"]
  self["opcode"] = self["mem"][pc] * 256 + self["mem"][pc+1]
}


function execute(self,     opcode, i, vx, vy,    x,y,n,byte,bit,offset,pre) {
  opcode = self["opcode"]

  # CLS (Clear Screen)
  if ( 0x00E0 == opcode ) {
    n = self["cfg"]["width"] * self["cfg"]["height"]
    for (i=0; i<=n; i++)
      self["disp"][i] = 0x00
    self["disp"]["refresh"] = 1
    return self["pc"] += 2
  }

  # RET (Return from subroutine)
  if ( 0x00EE == opcode ) {
    return self["pc"] = self["stack"][self["sp"]--] + 2
  }

  # JP addr (Jump to address)
  if ( 0x1000 == awk::and(opcode, 0xF000) ) {
    if (self["pc"] == awk::and(opcode, 0x0FFF)) exit 0
    self["pc"] = awk::and(opcode, 0x0FFF)
    return self["pc"]
  }

  # CALL addr (jump to subroutine at address)
  if ( 0x2000 == awk::and(opcode, 0xF000) ) {
    self["stack"][++self["sp"]] = self["pc"]
    self["pc"] = awk::and(opcode, 0x0FFF)
    return self["pc"]
  }

  # SE Vx (Vx == byte)
  if ( 0x3000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    if (self["V"][vx] == awk::and(opcode, 0x00FF))
      self["pc"] += 2
    return self["pc"] += 2
  }

  # SNE Vx (Vx != byte)
  if ( 0x4000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    if (self["V"][vx] != awk::and(opcode, 0x00FF))
      self["pc"] += 2
    return self["pc"] += 2
  }

  # SE Vx,Vy (Vx == Vy)
  if ( 0x5000 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    if (self["V"][vx] == self["V"][vy])
      self["pc"] += 2
    return self["pc"] += 2
  }

  # LD Vx, byte (Vx := byte)
  if ( 0x6000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["V"][vx] = awk::and(opcode, 0x00FF)
    return self["pc"] += 2
  }

  # ADD Vx, byte (Vx += byte)
  if ( 0x7000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["V"][vx] += awk::and(opcode, 0x00FF)
    return self["pc"] += 2
  }

  # LD Vx, Vy (Vx := Vy)
  if ( 0x8000 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    self["V"][vx] = self["V"][vy]
    return self["pc"] += 2
  }

  # OR Vx, Vy (Vx |= Vy)
  if ( 0x8001 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    self["V"][vx] = or(self["V"][vx], self["V"][vy])
    return self["pc"] += 2
  }

  # AND Vx, Vy (Vx &= Vy)
  if ( 0x8002 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    self["V"][vx] = awk::and(self["V"][vx], self["V"][vy])
    return self["pc"] += 2
  }

  # XOR Vx, Vy (Vx ^= Vy)
  if ( 0x8003 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    self["V"][vx] = awk::xor(self["V"][vx], self["V"][vy])
    return self["pc"] += 2
  }

  # ADD Vx, Vy (Vx += Vy)
  if ( 0x8004 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    i = self["V"][vx] + self["V"][vy]
    self["V"][0xF] = (i > 0xFF) ? 1 : 0
    self["V"][vx] = awk::and(i, 0xFF)
    return self["pc"] += 2
  }

  # DEC Vx, Vy (Vx -= Vy)
  if ( 0x8005 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    i = self["V"][vx] - self["V"][vy]
    self["V"][0xF] = (i > 0) ? 1 : 0
    self["V"][vx] = awk::and(i, 0xFF)
    return self["pc"] += 2
  }

  # SHR Vx, 1 (Vx >> 1)
  if ( 0x8006 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["V"][0xF] = self["V"][vx] % 2
    self["V"][vx] = rshift(self["V"][vx], 1)
    return self["pc"] += 2
  }

  # SUBN Vx, Vy (Vx -= Vy)
  if ( 0x8007 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)

    self["V"][0xF] = (self["V"][vy] >= self["V"][vx])
    self["V"][vx] = self["V"][vy] - self["V"][vx]

    return self["pc"] += 2
  }

  # SHL Vx, 1 (Vx << 1)
  if ( 0x800E == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["V"][0xF] = rshift(self["V"][vx], 7)
    self["V"][vx] = lshift(self["V"][vx], 1)
    return self["pc"] += 2
  }

  # SNE Vx, Vy (Vx != Vy)
  if ( 0x9000 == awk::and(opcode, 0xF00F) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    if (self["V"][vx] != self["V"][vy])
      self["pc"] += 2
    return self["pc"] += 2
  }

  # LD I, addr (I := addr)
  if ( 0xA000 == awk::and(opcode, 0xF000) ) {
    self["I"] = awk::and(opcode, 0x0FFF)
    return self["pc"] += 2
  }

  # JP V0, addr (jump to address V0 + addr)
  if ( 0xB000 == awk::and(opcode, 0xF000) ) {
    self["pc"] = self["V"][0] + awk::and(opcode, 0x0FFF)
    return self["pc"] += 2
  }

  # RND Vx, byte (random number & byte)
  if ( 0xC000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    i = int(rand() * 255)
    self["V"][vx] = awk::and(i, awk::and(opcode, 0x00FF))
    return self["pc"] += 2
  }

  # DRAW V1, V2, N (draw byte at [I] at Vx,Vy, N times high)
  if ( 0xD000 == awk::and(opcode, 0xF000) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    vy = awk::rshift(awk::and(opcode, 0x00F0), 4)
    n  = awk::and(opcode, 0x000F)

    w = self["cfg"]["width"]

    for (y=0; y<n; y++) {
      offset = (self["V"][vy] + y) * w + self["V"][vx]
      byte = self["mem"][(self["I"] + y)]
      for (x=0; x<8; x++) {
        bit = awk::and(awk::rshift(byte, (7-x)), 0x01)
        pre = self["disp"][offset + x]
        self["disp"][offset + x] = awk::xor(pre, bit)
        if (bit && pre)
          self["V"][0xF] = 1
      }
    }
    self["disp"]["refresh"] = 1
    return self["pc"] += 2
  }

  # SKP Vx (Check keypress with Vx)
  if ( 0xE09E == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    ## TODO check keymap/keypress
    if (self["V"][vx])
      self["pc"] += 2
    return self["pc"] += 2
  }

  # SKNP Vx (Check not-keypressed with Vx)
  if ( 0xE0A1 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    ## TODO check keymap/keypress
    if (self["V"][vx])
      self["pc"] += 2
    return self["pc"] += 2
  }

  # LD Vx,DT (Vx := delay timer)
  if ( 0xF007 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["V"][vx] = self["timer"]["delay"]
    return self["pc"] += 2
  }

  # LD Vx, K (Vx := key press)
  if ( 0xF00A == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    # TODO check checkmap/keypress
    self["V"][vx] = 0x00
    return self["pc"] += 2
  }

  # LD DT, Vx (Delay timer := Vx)
  if ( 0xF015 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["timer"]["delay"] = self["V"][vx]
    return self["pc"] += 2
  }

  # LD ST, Vx (Sound timer := Vx)
  if ( 0xF018 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["timer"]["sound"] = self["V"][vx]
    return self["pc"] += 2
  }

  # ADD I, Vx (I += Vx)
  if ( 0xF01E == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["I"] += self["V"][vx]
    return self["pc"] += 2
  }

  # LD F, Vx (I := sprite location at Vx)
  if ( 0xF029 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    self["I"] = awk::and(self["V"][vx], 0x0F) * 5
    return self["pc"] += 2
  }

  # LD B, Vx ([I] := BCD of Vx)
  if ( 0xF033 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    i = self["I"]
    self["mem"][i+0] = 0
    self["mem"][i+1] = 0
    self["mem"][i+2] = 0
    return self["pc"] += 2
  }

  # LD [I], Vx (save V0-Vx starting at [I])
  if ( 0xF055 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    i = self["I"]
    for (n=0; n<=vx; n++)
      self["mem"][i+n] = self["V"][n]
    return self["pc"] += 2
  }

  # LD Vx, [I] (load V0-Vx from [I] onwards)
  if ( 0xF065 == awk::and(opcode, 0xF0FF) ) {
    vx = awk::rshift(awk::and(opcode, 0x0F00), 8)
    i = self["I"]
    for (n=0; n<=vx; n++)
      self["V"][n] = self["mem"][i+n]
    return self["pc"] += 2
  }


  # no opcode found
  return 0
}

