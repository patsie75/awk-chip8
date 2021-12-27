#!/usr/bin/gawk -f

BEGIN {
  addr = 0x0200

  opcode["NOP"]			= "0000"
  opcode["SCD 0x(.)"]		= "00C%s"
  opcode["CLS"]			= "00E0"
  opcode["RET"]			= "00EE"
  opcode["SCR"]			= "00FB"
  opcode["SCL"]			= "00FC"
  opcode["EXIT"]		= "00FD"
  opcode["LOW"]			= "00FE"
  opcode["HIGH"]		= "00FF"
  opcode["JP 0x0?(...)"]	= "1%s"
  opcode["CALL 0x0?(...)"]	= "2%s"
  opcode["SE V(.), ?0x(..)"]	= "3%s%s"
  opcode["SNE V(.), ?0x(..)"]	= "4%s%s"
  opcode["SE V(.), ?V(.)"]	= "5%s%s0"
  opcode["LD V(.), ?0x(..)"]	= "6%s%s"
  opcode["ADD V(.), ?0x(..)"]	= "7%s%s"
  opcode["LD V(.), ?V(.)"]	= "8%s%s0"
  opcode["OR V(.), ?V(.)"]	= "8%s%s1"
  opcode["AND V(.), ?V(.)"]	= "8%s%s2"
  opcode["XOR V(.), ?V(.)"]	= "8%s%s3"
  opcode["ADD V(.), ?V(.)"]	= "8%s%s4"
  opcode["SUB V(.), ?V(.)"]	= "8%s%s5"
  opcode["SHR V(.), ?V(.)"]	= "8%s%s6"
  opcode["SUBN V(.), ?V(.)"]	= "8%s%s7"
  opcode["SHL V(.), ?V(.)"]	= "8%s%sE"
  opcode["SNE V(.), ?V(.)"]	= "9%s%s0"
  opcode["LD I, ?0x0?(...)"]	= "A%s"
  opcode["JP V0, ?0x0(...)"]	= "B%s"
  opcode["RND V(.), ?0x(..)"]	= "C%s%s"
  opcode["DRW V(.), ?V(.), ?0x(.)"] = "D%s%s%s"
  opcode["SKP V(.)"]		= "E%s9E"
  opcode["SKNP V(.)"]		= "E%sA1"
  opcode["LD V(.), ?DT"]	= "F%s07"
  opcode["LD V(.), ?K"]		= "F%s0A"
  opcode["LD DT, ?V(.)"]	= "F%s15"
  opcode["LD ST, ?V(.)"]	= "F%s18"
  opcode["ADD I, ?V(.)"]	= "F%s1E"
  opcode["LD F, ?V(.)"]		= "F%s29"
  opcode["LD B, ?V(.)"]		= "F%s33"
  opcode["LD \\[I\\], ?V(.)"]	= "F%s55"
  opcode["LD V(.), ?\\[I\\]"]	= "F%s65"
}

($1 ~ /^:/) { label[$1] = sprintf("0x%04X", addr); next }

NF {
  gsub(/;.*/, "")
  gsub(/  */, " ")
  gsub(/(^ *| *$)/, "")

  if (length($0)) {
    mnem[addr] = $0
    addr += 2
  }
}

END {
  #for (l in label)
  #  printf("%s\t[%s]\n", label[l], l)

  # loop over all mnemonics
  for (a=0x0200; a<addr; a+=2) {
    # replace all labels with addresses
    for (l in label)
      gsub(l, label[l], mnem[a])

    unknown = 1
    for (m in opcode) {
      # print out opcode
      if (match(mnem[a], m, argv)) {
        #printf("0x%04X\t%20s ; "opcode[m]"\n", a, mnem[a], argv[1], argv[2], argv[3])
        printf(opcode[m]"\n", argv[1], argv[2], argv[3])
        unknown = 0
      }
    }
    # unknown mnemonic found (typo in code?)
    if (unknwon) {
      printf("Unknown mnemonic [%s] at address 0x%04X\n", mnem[a], a)
      exit 0
    }
  }

}
