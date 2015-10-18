
GLOBAL { start:1 }

LET start(x) = VALOF
{ LET v = VEC 10
  FOR i = 7 TO 10 DO v!i := 0
  SWITCHON v!4 INTO
  { CASE 23: v!1 := 10
    CASE 56: v!2 := 20
    CASE 33: v!3 := 30
    DEFAULT: v!4 := 40
  }
  RESULTIS 0
}