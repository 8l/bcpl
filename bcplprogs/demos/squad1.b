/*
This is a simple implementation of the firing squad problem
by Martin Richards  (c) September 2004
*/

GET "libhdr"

MANIFEST { upb = 1000 }
 
GLOBAL { rulev: ug }

LET start() = VALOF
{ LET v = VEC upb
  AND n = 50
  LET argv = VEC 20

  UNLESS rdargs("N", argv, 20) DO
  { writes("Bad arguments for SQUAD*n")
    RESULTIS 20
  }
  UNLESS argv!0=0 DO n := str2numb(argv!0)

  UNLESS 2<=n<=upb DO
  { writef("The number of soldiers must be between 2 and %n*n", upb)
    RESULTIS 0
  }

  writef("*nFiring squad solution for %i2 soldier%-%ps*n*n", n)
  squad(v, n)
  RESULTIS 0
}
 
AND squad(v, n) BE
{ LET count = 0
  initrules()
  FOR i = 0 TO n+1 DO v!i := 0                // 1=-
  v!1, v!n := 1, 4                            // 1=S 4=|

  { LET p, a, b, c = 0, ?, v!0, v!1
    LET error = FALSE
    LET t = TABLE '-', 'S', '.', '+', '|', '>', '<', ')',
                  ']', '\', '(', '[', '/', 'F', '#', '?'
    //LET t = TABLE '0', '1', '2', '3', '4', '5', '6', '7',
    //              '8', '9', 'A', 'B', 'C', 'D', 'E', '?'
    writef("%i3: ", count)
    count := count+1
    FOR i = 1 TO n DO
    { LET val = v!i
      writef("%c", t!val)
      IF val=#xF DO error := TRUE
    }
    newline()
    IF v!2=#xD | error BREAK
    UNTIL p=n DO
    { p := p+1
      a := b
      b := c
      c := v!(p+1)
      v!p := func(a, b, c)
    }
  } REPEAT
 
  newline()
  closerules()
}

AND setrule(abc, val) BE
{ UNLESS rulev!abc = #xF DO
    writef("Error: rule #x%x3 => %x1 and %x1*n", abc, rulev!abc, val)
  rulev!abc := val
}

AND initrules() BE
{ MANIFEST { A=10; B; C; D; E; F }
  rulev := getvec(#xFFF)
  FOR i = 0 TO #xFFF DO rulev!i := #xF

  setrule(#x010, 3)
  setrule(#x100, 5)
  setrule(#x000, 0)
  setrule(#x004, 0)
  setrule(#x040, 4)
  setrule(#x500, 5)
  setrule(#x035, 4)
  setrule(#x350, 7)
  setrule(#x047, 4)
  setrule(#x475, 8)
  setrule(#x750, 0)
  setrule(#x048, 4)
  setrule(#x480, 9)
  setrule(#x805, 0)
  setrule(#x050, 0)
  setrule(#x049, 4)
  setrule(#x490, 0)
  setrule(#x900, 7)
  setrule(#x005, 0)
  setrule(#x407, 0)
  setrule(#x070, 8)
  setrule(#x700, 0)
  setrule(#x408, 0)
  setrule(#x080, 9)
  setrule(#x800, 0)
  setrule(#x409, 0)
  setrule(#x090, 0)
  setrule(#x400, 0)
  setrule(#x007, 0)
  setrule(#x008, 0)
  setrule(#x009, 0)
  setrule(#x504, 6)
  setrule(#x006, 6)
  setrule(#x064, 0)
  setrule(#x640, 4)
  setrule(#x060, 0)
  setrule(#x604, 0)
  setrule(#x600, 0)
  setrule(#x076, 1)
  setrule(#x760, 1)
  setrule(#x001, 6)
  setrule(#x011, 3)
  setrule(#x110, 3)
  setrule(#x063, A)
  setrule(#x633, 4)
  setrule(#x335, 4)
  setrule(#x06A, 0)
  setrule(#x6A4, B)
  setrule(#xA44, 4)
  setrule(#x447, 4)
  setrule(#x60B, 0)
  setrule(#x0B4, C)
  setrule(#xB44, 4)
  setrule(#x448, 4)
  setrule(#x00C, A)
  setrule(#x0C4, 0)
  setrule(#xC44, 4)
  setrule(#x449, 4)
  setrule(#x00A, 0)
  setrule(#x0A0, B)
  setrule(#xA04, 0)
  setrule(#x044, 4)
  setrule(#x440, 4)
  setrule(#x00B, 0)
  setrule(#x0B0, C)
  setrule(#xB04, 0)
  setrule(#x0C0, 0)
  setrule(#xC04, 0)
  setrule(#x406, 5)
  setrule(#xA00, 0)
  setrule(#x045, 4)
  setrule(#x450, 0)
  setrule(#xB00, 0)
  setrule(#x405, 0)
  setrule(#xC00, 0)
  setrule(#x50B, 1)
  setrule(#x806, 1)
  setrule(#x01C, 3)
  setrule(#x1C0, 5)
  setrule(#x091, 6)
  setrule(#x910, 3)
  setrule(#x635, 4)
  setrule(#xA47, 4)
  setrule(#xB48, 4)
  setrule(#xC49, 4)
  setrule(#x644, 4)
  setrule(#x445, 4)
  setrule(#x05A, 1)
  setrule(#x5A0, 1)
  setrule(#x401, 1)
  setrule(#x104, 1)
  setrule(#x041, D)
  setrule(#x413, D)
  setrule(#x133, D)
  setrule(#x331, D)
  setrule(#x314, D)
  setrule(#x141, D)
  setrule(#x144, D)
  setrule(#x441, D)
  setrule(#x140, D)
  setrule(#x645, 4)
  setrule(#x45A, 1)
  setrule(#x5A4, 1)
  setrule(#x476, 1)
  setrule(#x764, 1)
  setrule(#x411, D)
  setrule(#x114, D)
  setrule(#x1C4, 1)
  setrule(#x491, 1)
  setrule(#x131, D)
  setrule(#x031, D)
  setrule(#x030, D)
  setrule(#x014, D)


/*
  0=-
  1=S
  2=.    not used
  3=+
  4=|
  5=>
  6=<
  7=)
  8=]
  9=\
 10=(
 11=[
 12=/
 13=F
*/
}

AND closerules() BE IF rulev DO freevec(rulev)

AND func(a, b, c) = rulev!((a<<8) + (b<<4) + c)

/*
0> squad1 27

Firing squad solution for 27 soldiers

  0: S-------------------------|
  1: +>------------------------|
  2: |)>-----------------------|
  3: |]->----------------------|
  4: |\-->---------------------|
  5: |-)-->--------------------|
  6: |-]--->-------------------|
  7: |-\---->------------------|
  8: |--)---->-----------------|
  9: |--]----->----------------|
 10: |--\------>---------------|
 11: |---)------>--------------|
 12: |---]------->-------------|
 13: |---\-------->------------|
 14: |----)-------->-----------|
 15: |----]--------->----------|
 16: |----\---------->---------|
 17: |-----)---------->--------|
 18: |-----]----------->-------|
 19: |-----\------------>------|
 20: |------)------------>-----|
 21: |------]------------->----|
 22: |------\-------------->---|
 23: |-------)-------------->--|
 24: |-------]--------------->-|
 25: |-------\----------------<|
 26: |--------)--------------<-|
 27: |--------]-------------<--|
 28: |--------\------------<---|
 29: |---------)----------<----|
 30: |---------]---------<-----|
 31: |---------\--------<------|
 32: |----------)------<-------|
 33: |----------]-----<--------|
 34: |----------\----<---------|
 35: |-----------)--<----------|
 36: |-----------]-<-----------|
 37: |-----------\S------------|
 38: |-----------<+>-----------|
 39: |----------<(|)>----------|
 40: |---------<-[|]->---------|
 41: |--------<--/|\-->--------|
 42: |-------<--(-|-)-->-------|
 43: |------<---[-|-]--->------|
 44: |-----<----/-|-\---->-----|
 45: |----<----(--|--)---->----|
 46: |---<-----[--|--]----->---|
 47: |--<------/--|--\------>--|
 48: |-<------(---|---)------>-|
 49: |>-------[---|---]-------<|
 50: |->------/---|---\------<-|
 51: |-->----(----|----)----<--|
 52: |--->---[----|----]---<---|
 53: |---->--/----|----\--<----|
 54: |----->(-----|-----)<-----|
 55: |-----SS-----|-----SS-----|
 56: |----<++>----|----<++>----|
 57: |---<(||)>---|---<(||)>---|
 58: |--<-[||]->--|--<-[||]->--|
 59: |-<--/||\-->-|-<--/||\-->-|
 60: |>--(-||-)--<|>--(-||-)--<|
 61: |->-[-||-]-<-|->-[-||-]-<-|
 62: |--S/-||-\S--|--S/-||-\S--|
 63: |-<+>-||-<+>-|-<+>-||-<+>-|
 64: |>(|)<||>(|)<|>(|)<||>(|)<|
 65: |SS|SS||SS|SS|SS|SS||SS|SS|
 66: FFFFFFFFFFFFFFFFFFFFFFFFFFF

10> 
*/
 
