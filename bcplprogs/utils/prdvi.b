SECTION "prdvi"

GET "libhdr"

GLOBAL $( 
f:       200
h:       201
v:       202
w:       203
x:       204
y:       205
z:       206
stk:     207
stkp:    208
stkt:    209
bytepos: 210
$)
         
LET start() = VALOF
$( LET argv = VEC 50
   LET v1 = VEC 600
   LET sysout, sysin = output(), input()
   LET infile, outfile = 0, 0
   
   IF rdargs("FROM/A,TO/K", argv, 50)=0 DO
   $( writes("Bad arguments for PRDVI*n")
      RESULTIS 20
   $)

   infile := findinput(argv!0)
   IF infile = 0 DO
   $( writef("Trouble with input file %s*n", argv!0)
      RESULTIS 20
   $)

   UNLESS argv!1=0 DO
   $( outfile := findoutput(argv!1)
      IF outfile = 0 DO
      $( writef("Trouble with output file %s*n", argv!1)
         RESULTIS 20
      $)
   $)

   selectinput(infile)
   UNLESS outfile=0 DO selectoutput(outfile)

   stk, stkp, stkt := v1, v1, v1+600
   h, v            := 0, 0
   w, x, y, z      := 0, 0, 0, 0
   bytepos         := 0

   prdvimain()

   endread()
   UNLESS outfile=0 DO endwrite()
   selectoutput(sysout)
   writes("*nPRDVI done*n")
   RESULTIS 0
$)

AND prdvimain() BE
$( LET pos = bytepos
   LET op = rdbyte()

   SWITCHON op INTO
   $( DEFAULT: writef("*N%I5: BAD OP %N*n", pos, op)
               LOOP

      CASE endstreamch: 
               newline()
               RETURN

      CASE   0:CASE   1:CASE   2:CASE   3:CASE   4:CASE   5:CASE   6:CASE   7:
      CASE   8:CASE   9:CASE  10:CASE  11:CASE  12:CASE  13:CASE  14:CASE  15:
      CASE  16:CASE  17:CASE  18:CASE  19:CASE  20:CASE  21:CASE  22:CASE  23:
      CASE  24:CASE  25:CASE  26:CASE  27:CASE  28:CASE  29:CASE  30:CASE  31:
               writef("\%X2", op)
               LOOP

      CASE  32:CASE  33:CASE  34:CASE  35:CASE  36:CASE  37:CASE  38:CASE  39:
      CASE  40:CASE  41:CASE  42:CASE  43:CASE  44:CASE  45:CASE  46:CASE  47:
      CASE  48:CASE  49:CASE  50:CASE  51:CASE  52:CASE  53:CASE  54:CASE  55:
      CASE  56:CASE  57:CASE  58:CASE  59:CASE  60:CASE  61:CASE  62:CASE  63:
      CASE  64:CASE  65:CASE  66:CASE  67:CASE  68:CASE  69:CASE  70:CASE  71:
      CASE  72:CASE  73:CASE  74:CASE  75:CASE  76:CASE  77:CASE  78:CASE  79:
      CASE  80:CASE  81:CASE  82:CASE  83:CASE  84:CASE  85:CASE  86:CASE  87:
      CASE  88:CASE  89:CASE  90:CASE  91:CASE  92:CASE  93:CASE  94:CASE  95:
      CASE  96:CASE  97:CASE  98:CASE  99:CASE 100:CASE 101:CASE 102:CASE 103:
      CASE 104:CASE 105:CASE 106:CASE 107:CASE 108:CASE 109:CASE 110:CASE 111:
      CASE 112:CASE 113:CASE 114:CASE 115:CASE 116:CASE 117:CASE 118:CASE 119:
      CASE 120:CASE 121:CASE 122:CASE 123:CASE 124:CASE 125:CASE 126:CASE 127:
               wrch(op)
               LOOP

      CASE 128:writef("*Nset1 %N ", rd1u())
               LOOP
      CASE 129:writef("*Nset2 %N ", rd2u())
               LOOP
      CASE 130:writef("*Nset3 %N ", rd3u())
               LOOP
      CASE 131:writef("*Nset4 %N ", rd4())
               LOOP

      CASE 132:
            $( LET a = rd4()
               LET b = rd4()
               writef("*Nset_rule %N,%N ", a, b)
               LOOP
            $)

      CASE 133:writef("*Nput1 %N ", rd1u())
               LOOP
      CASE 134:writef("*Nput2 %N ", rd2u())
               LOOP
      CASE 135:writef("*Nput3 %N ", rd3u())
               LOOP
      CASE 136:writef("*Nput4 %N ", rd4())
               LOOP

      CASE 137:
            $( LET a = rd4()
               LET b = rd4()
               writef("*Nput_rule %N,%N ", a, b)
               LOOP
            $)

      CASE 138:writes("*nnop ")
               LOOP

      CASE 139:writef("*N*N%I6: bop %N", pos, rd4())
               FOR i = 1 TO 10 DO writef(",%N", rd4())
               newline()
               LOOP

      CASE 140:writes("*Neop*N")
               LOOP

      CASE 141:writes("*Npush ")
               LOOP

      CASE 142:writes("*Npop ")
               LOOP

      CASE 143:writef("*Nright1 %N ", rd1s())
               LOOP
      CASE 144:writef("*Nright2 %N ", rd2s())
               LOOP
      CASE 145:writef("*Nright3 %N ", rd3s())
               LOOP
      CASE 146:writef("*Nright4 %N ", rd4())
               LOOP

      CASE 147:writes("*Nw0 ")
               LOOP

      CASE 148:writef("*Nw1 %N ", rd1s())
               LOOP
      CASE 149:writef("*Nw2 %N ", rd2s())
               LOOP
      CASE 150:writef("*Nw3 %N ", rd3s())
               LOOP
      CASE 151:writef("*Nw4 %N ", rd4())
               LOOP

      CASE 152:writes("*Nx0 ")
               LOOP

      CASE 153:writef("*Nx1 %N ", rd1s())
               LOOP
      CASE 154:writef("*Nx2 %N ", rd2s())
               LOOP
      CASE 155:writef("*Nx3 %N ", rd3s())
               LOOP
      CASE 156:writef("*Nx4 %N ", rd4())
               LOOP

      CASE 157:writef("*Ndown1 %N ", rd1s())
               LOOP
      CASE 158:writef("*Ndown2 %N ", rd2s())
               LOOP
      CASE 159:writef("*Ndown3 %N ", rd3s())
               LOOP
      CASE 160:writef("*Ndown4 %N ", rd4())
               LOOP

      CASE 161:writes("*Ny0 ")
               LOOP

      CASE 162:writef("*Ny1 %N ", rd1s())
               LOOP
      CASE 163:writef("*Ny2 %N ", rd2s())
               LOOP
      CASE 164:writef("*Ny3 %N ", rd3s())
               LOOP
      CASE 165:writef("*Ny4 %N ", rd4())
               LOOP

      CASE 166:writes("*Nz0 ")
               LOOP

      CASE 167:writef("*Nz1 %N ", rd1s())
               LOOP
      CASE 168:writef("*Nz2 %N ", rd2s())
               LOOP
      CASE 169:writef("*Nz3 %N ", rd3s())
               LOOP
      CASE 170:writef("*Nz4 %N ", rd4())
               LOOP

      CASE 171:CASE 172:CASE 173:CASE 174:CASE 175:CASE 176:CASE 177:CASE 178:
      CASE 179:CASE 180:CASE 181:CASE 182:CASE 183:CASE 184:CASE 185:CASE 186:
      CASE 187:CASE 188:CASE 189:CASE 190:CASE 191:CASE 192:CASE 193:CASE 194:
      CASE 195:CASE 196:CASE 197:CASE 198:CASE 199:CASE 200:CASE 201:CASE 202:
      CASE 203:CASE 204:CASE 205:CASE 206:CASE 207:CASE 208:CASE 209:CASE 210:
      CASE 211:CASE 212:CASE 213:CASE 214:CASE 215:CASE 216:CASE 217:CASE 218:
      CASE 219:CASE 220:CASE 221:CASE 222:CASE 223:CASE 224:CASE 225:CASE 226:
      CASE 227:CASE 228:CASE 229:CASE 230:CASE 231:CASE 232:CASE 233:CASE 234:
               writef("*Nfnt_num_%N ", op-171)
               LOOP

      CASE 235:writef("*Nfnt1 %N ", rd1u())
               LOOP
      CASE 236:writef("*Nfnt2 %N ", rd2u())
               LOOP
      CASE 237:writef("*Nfnt3 %N ", rd3u())
               LOOP
      CASE 238:writef("*Nfnt4 %N ", rd4())
               LOOP

      CASE 239:writexxx("*Nxxx1 %N ", rd1u())
               LOOP
      CASE 240:writexxx("*Nxxx2 %N ", rd2u())
               LOOP
      CASE 241:writexxx("*Nxxx3 %N ", rd3u())
               LOOP
      CASE 242:writexxx("*Nxxx4 %N ", rd4())
               LOOP

      CASE 243:writefntdef("*Nfnt_def1 %N", rd1u())
               LOOP
      CASE 244:writefntdef("*Nfnt_def2 %N", rd2u())
               LOOP
      CASE 245:writefntdef("*Nfnt_def3 %N", rd3u())
               LOOP
      CASE 246:writefntdef("*Nfnt_def4 %N", rd4())
               LOOP

      CASE 247:
            $( LET i   = rd1u()
               LET num = rd4()
               LET den = rd4()
               LET mag = rd4()
               LET k   = rd1u()
               writef("*Npre %N, %N, %N, %N, %N*N",
                             i,  num,den,mag,k)
               FOR i = 1 TO k DO wrch(rdbyte())
               newline()
               LOOP
            $)

      CASE 248:
            $( LET p   = rd4()
               LET num = rd4()
               LET den = rd4()
               LET mag = rd4()
               LET l   = rd4()
               LET u   = rd4()
               LET s   = rd2u()
               LET t   = rd2u()
               writef("*N%I6: post %N, %N, %N, %N, %N, %N, %N, %N*N",
                         pos,      p,  num,den,mag,l,  u,  s,  t)
               LOOP
            $)

      CASE 249:
            $( LET q = rd4()
               LET i = rd1u()
               writef("*N%I6: post_post %N, %N*N", pos, q, i)
               RETURN
            $)
   $)
$) REPEAT

AND rdbyte() = VALOF
$( bytepos := bytepos + 1
   RESULTIS rdch()
$)

AND rd1u() = rdbyte()

AND rd2u() = VALOF
$( LET b1 = rdbyte()
   LET b2 = rdbyte()
   RESULTIS b1<<8 | b2
$)

AND rd3u() = VALOF
$( LET b1 = rdbyte()
   LET b2 = rdbyte()
   LET b3 = rdbyte()
   RESULTIS b1<<16 | b2<<8 | b3
$)

AND rd4() = VALOF
$( LET b1 = rdbyte()
   LET b2 = rdbyte()
   LET b3 = rdbyte()
   LET b4 = rdbyte()
   RESULTIS b1<<24 | b2<<16 | b3<<8 | b4
$)

AND rd1s() = VALOF
$( LET res = rd1u()
   RESULTIS res <= #X07F -> res,
            res -  #X100
$)

AND rd2s() = VALOF
$( LET res = rd2u()
   RESULTIS res <= #X07FFF -> res,
            res -  #X10000
$)

AND rd3s() = VALOF
$( LET res = rd3u()
   RESULTIS res <= #X07FFFFF -> res,
            res -  #X1000000
$)

AND writexxx(form, len) BE
$( writef(form, len)
   FOR i = 1 TO len DO
   $( IF i REM 8 = 1 DO newline()
      writef("%X2 ", rdbyte)
   $)
$)

AND writefntdef(form, k) BE
$( LET c = rd4()
   LET s = rd4()
   LET d = rd4()
   LET a = rd1u()
   LET l = rd1u()
   writef(form, k)
   writef(",%N,%N,%N,%N,%N ", c,s,d,a,l)
   
   FOR i = 1 TO a+l DO wrch(rdbyte())
   newline()
$)



