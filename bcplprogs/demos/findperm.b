GET "libhdr"

GLOBAL $(
name:200; namep:201
perm:202; used:203; hashtab:204
probword:205
$)

LET dsw(str) BE
$( namep := namep + 1
   IF namep<256 DO name!namep := str
$)

LET initnames() BE
$( namep := 0

   dsw("a")
   dsw("b")
   dsw("c")
   dsw("d")
   dsw("e")
   dsw("f")
   dsw("g")
   dsw("h")
   dsw("i")
   dsw("j")
   dsw("k")
   dsw("l")
   dsw("m")
   dsw("n")
   dsw("o")
   dsw("p")
   dsw("q")
   dsw("r")
   dsw("s")
   dsw("t")
   dsw("u")
   dsw("v")
   dsw("w")
   dsw("x")
   dsw("y")
   dsw("z")

   dsw("AND")
   dsw("ABS")
   dsw("BE")
   dsw("BREAK")
   dsw("BY")
   dsw("CASE")
   dsw("DO")
   dsw("DEFAULT")
   dsw("EQ")
   dsw("EQV")
   dsw("ELSE")
   dsw("ENDCASE")
   dsw("FALSE")
   dsw("FOR")
   dsw("FINISH")
   dsw("GOTO")
   dsw("GE")
   dsw("GR")
   dsw("GLOBAL")
   dsw("GET")
   dsw("IF")
   dsw("INTO")
   dsw("LET")
   dsw("LV")
   dsw("LE")
   dsw("LS")
   dsw("LOGOR")
   dsw("LOGAND")
   dsw("LOOP")
   dsw("LSHIFT")
   dsw("MANIFEST")
   dsw("NE")
   dsw("NOT")
   dsw("NEQV")
   dsw("NEEDS")
   dsw("OR")
   dsw("RESULTIS")
   dsw("RETURN")
   dsw("REM")
   dsw("RSHIFT")
   dsw("RV")
   dsw("REPEAT")
   dsw("REPEATWHILE")
   dsw("REPEATUNTIL")
   dsw("SWITCHON")
   dsw("STATIC")
   dsw("SECTION")
   dsw("TO")
   dsw("TEST")
   dsw("TRUE")
   dsw("THEN")
   dsw("TABLE")
   dsw("UNTIL")
   dsw("UNLESS")
   dsw("VEC")
   dsw("VALOF")
   dsw("WHILE")
   dsw("$")


   dsw("globsize")
   dsw("start")
   dsw("stop")
   dsw("sys")
   dsw("clihook")
   dsw("changeco")
   dsw("currco")
   dsw("colist")
   dsw("rootnode")
   dsw("result2")
   dsw("intflag")
   dsw("sardch")
   dsw("sawrch")
   dsw("level")
   dsw("longjump")
   dsw("muldiv")
   dsw("aptovec")
   dsw("createco")
   dsw("deleteco")
   dsw("callco")
   dsw("cowait")
   dsw("resumeco")
   dsw("initco")
   dsw("globin")
   dsw("getvec")
   dsw("freevec")
   dsw("abort")
   dsw("packstring")
   dsw("unpackstring")
   dsw("cis")
   dsw("cos")
   dsw("rdch")
   dsw("unrdch")
   dsw("wrch")
   dsw("findinput")
   dsw("findoutput")
   dsw("selectinput")
   dsw("selectoutput")
   dsw("endread")
   dsw("endwrite")
   dsw("input")
   dsw("output")
   dsw("readn")
   dsw("newline")
   dsw("newpage")
   dsw("writed")
   dsw("writeu")
   dsw("writen")
   dsw("writeoct")
   dsw("writehex")
   dsw("writes")
   dsw("writet")
   dsw("writef")
   dsw("capitalch")
   dsw("compch")
   dsw("compstring")
   dsw("rdargs")
   dsw("rditem")
   dsw("findarg")
   dsw("loadseg")
   dsw("unloadseg")
   dsw("callseg")
   dsw("deletefile")
   dsw("renamefile")
   dsw("randno")
   dsw("str2numb")

   dsw("endstreamch")
   dsw("bytesperword")
   dsw("bitsperword")
   dsw("bitsperbyte")
   dsw("maxint")
   dsw("minint")
   dsw("mcaddrinc")
   dsw("ug")

   dsw("t_hunk")
   dsw("t_end")

   dsw("co_pptr")
   dsw("co_parent")
   dsw("co_list")
   dsw("co_fn")
   dsw("co_size")

   dsw("rtn_membase")
   dsw("rtn_memsize")
   dsw("rtn_blklist")
   dsw("rtn_tallyv")
   dsw("rtn_syslib")
   dsw("rtn_blib")
   dsw("rtn_boot")
   dsw("rtn_cli")
   dsw("rtn_keyboard")
   dsw("rtn_screen")
   dsw("rtn_upb")
$)

LET start() BE
$( perm := TABLE
      1, 14,110, 25, 97,174,132,119,138,170,125,118, 27,233,140, 51,
     87,197,177,107,234,169, 56, 68, 30,  7,173, 73,188, 40, 36, 65,
     49,213,104,190, 57,211,148,223, 48,115, 15,  2, 67,186,210, 28,
     12,181,103, 70, 22, 58, 75, 78,183,167,238,157,124,147,172,144,
    176,161,141, 86, 60, 66,128, 83,156,241, 79, 46,168,198, 41,254,
    178, 85,253,237,250,154,133, 88, 35,206, 95,116,252,192, 54,221,
    102,218,255,240, 82,106,158,201, 61,  3, 89,  9, 42,155,159, 93,
    166, 80, 50, 34,175,195,100, 99, 26,150, 16,145,  4, 33,  8,189,
    121, 64, 77, 72,208,245,130,122,143, 55,105,134, 29,164,185,194,
    193,239,101,242,  5,171,126, 11, 74, 59,137,228,108,191,232,139,
      6, 24, 81, 20,127, 17, 91, 92,251,151,225,207, 21, 98,113,112,
     84,226, 18,214,199,187, 13, 32, 94,220,224,212,247,204,196, 43,
    249,236, 45,244,111,182,153,136,129, 90,217,202, 19,165,231, 71,
    230,142, 96,227, 62,179,246,114,162, 53,160,215,205,180, 47,109,
     44, 38, 31,149,135,  0,216, 52, 63, 23, 37, 69, 39,117,146,184,
    163,200,222,235,248,243,219, 10,152,131,123,229,203, 76,120,209

   writes("Find perm entered*n")
   name    := getvec(255)
   hashtab := getvec(255)
   used    := getvec(255)
   FOR i = 0 TO 255 DO name!i, hashtab!i, used!i := 0, 0, 0

   initnames()

   writef("Number of names is %n*n", namep)

   try(1, 1, 0)

   freevec(name)
   freevec(hashtab)
   freevec(used)
   writes("End of test*n")
$)

AND try(i, p, h) BE
$( LET word = name!i
   writef("%i3  %n %i3  %s*n", i, p, h, word)
   TEST p>word%0
   THEN TEST hashtab!h=0
        THEN $( hashtab!h := i
                IF i=namep DO abort(9999)
                writef("hashval = %n*n", h)
                try(i+1, 1, 0)
                hashtab!h := 0
             $)
        ELSE $( probword := word
                FOR i = 0 TO 255 DO
                $( IF i REM 64 = 0 DO newline()
                   IF i REM 8 = 0 DO wrch(' ')
                   wrch('0'+used!i)
                $)
                abort(1001)
                newline()
             $)
   ELSE $( LET q = h NEQV word%p
           used!q := used!q + 1
           try(i, p+1, perm!q)
           IF used!q=1 FOR j = 0 TO 255 IF used!j=0 DO
           $( LET w = perm!j
              //writef("Swapping %n:%n and %n:%n*n", q, perm!q, j, perm!j)
              perm!j := perm!q
              perm!q := w
              IF ok(probword) DO try(i, p+1, perm!q)
              perm!q := perm!j
              perm!j := w
           $)
           used!q := used!q - 1
        $)
   writef("Backtracking %i3  %n %i3  %s  probword: %s*n",
           i, p, h, word, probword)
//   abort(1000)
$)

AND ok(word) = VALOF
$( LET hashval = 0
   FOR i = 1 TO word%0 DO hashval := perm!(hashval NEQV word%i)
//   UNLESS hashtab!hashval=0 DO writef("still colliding: %s*n", word)
   RESULTIS hashtab!hashval=0
$)