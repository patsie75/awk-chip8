       :init
0x0200  LD V0,0x00	; image counter
0x0202  LD VE,0x08	; number of images
0x0204  LD V3,0x0F	; height of sprite
0x0206	LV V4,0x78	; delay between pictures (0x78 == 120 == 2 secs)

0x0208  LD I,:img1	; first image position
       :draw0
0x020a  CLS
0x020c  LD V2,0x00	; ypos (0)
       :draw1
0x020e  LD V1,0x10	; xpos (16)
       :draw2
0x0210  DRAW V1,V2,0xF	; draw 15 bytes
0x0212  ADD I,V3	; move data pointer
0x0214  ADD V1,0x08	; xpos += 8
0x0216  SE  V1,0x30	; columns finished?
0x0218  JMP :draw2
0x021a  ADD V2,V3	; ypos += 15
0x021c  SE  V2,0x1E	; rows finished?
0x021e  JMP :draw1

0x0220	LD  DT,V4	; set delay timer
       :delay
0x0222	LD  V5,DT	; read delay timer
0x0224	SE  V5,0x00	; timer 0?
0x0226	JP  :delay	; loop until 0

0x0228  ADD V0, 1	; next image
0x022a  SE  V0,VE	; last image?
0x022c  JMP :draw0
        :end
0x022e  JMP :end
       :img1
0x0230  <DATA>


0x0200  LD V0,0x00	; 6000
0x0202  LD VE,0x08	; 6E08
0x0204  LD V3,0x0F	; 630F
0x0206	LD V4,0x78	; 6478
0x0208  LD I,0x230	; A230
0x020a  CLS		; 00E0
0x020c  LD V2,0x00	; 6200
0x020e  LD V1,0x10	; 6110
0x0210  DRAW V1,V2,0xF	; D12F
0x0212  ADD I,V3	; F31E
0x0214  ADD V1,0x08	; 7108
0x0216  SE  V1,0x30	; 3130
0x0218  JP  0x210	; 1210
0x021a  ADD V2,V3	; 8234
0x021c  SE  V2,0x1E	; 321E
0x021e  JP  0x20E	; 120E
0x0220	LD  DT,V4	; F415
0x0222	LD  V5,DT	; F507
0x0224	SE  V5,0x00	; 3500
0x0226	JP  0x222	; 1222
0x0228  ADD V0,0x01	; 7001
0x022a  SE  V0,VE	; 50E0
0x022c  JP  0x20A	; 120A
0x022e  JP  0x22E	; 122E
0x0230  <DATA>
