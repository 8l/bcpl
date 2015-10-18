GET "libhdr"

LET start() = VALOF
{ FOR i = -10 TO +10 DO
  { try(i)
    try (i-1_000_000)
    try (i-2_000_000)
    try (i+1_000_000)
    try (i+2_000_000)
    try (i+minint)
    try (i+maxint)
    try (i+3_000_000)
    try (i+4_000_000)
    try (i+5_000_000)
    try (i+6_000_000)
    try (i+7_000_000)
    try (i+7_000_100)
    try (i+7_000_200)
    try (i+7_000_300)
    try (i+7_000_400)
    try (i+7_000_500)
    try (i+7_000_600)
    try (i+7_000_700)
    try (i+7_000_800)
    try (i+7_000_900)

  }
  writef("end of test*n")
}

AND try(x) BE UNLESS sw(x)=answer(x) DO
  writef("sw(%n)=%i3  it should be %i3*n", x, sw(x), answer(x))

AND sw(n) = VALOF SWITCHON n INTO
{ DEFAULT: RESULTIS 123

  CASE -3:           RESULTIS 1
  CASE -2:           RESULTIS 2
  CASE -1:           RESULTIS 3
  CASE  0:           RESULTIS 4
  CASE  1:           RESULTIS 5
  CASE  2:           RESULTIS 6
  CASE  3:           RESULTIS 7

  CASE -1_000_000:   RESULTIS 8

  CASE -2_000_000:   RESULTIS 9
  CASE -2_000_001:   RESULTIS 10

  CASE  1_000_000:   RESULTIS 11
  CASE  1_000_001:   RESULTIS 12
  CASE  1_000_002:   RESULTIS 13

  CASE  2_000_000:   RESULTIS 14
  CASE  2_000_001:   RESULTIS 15
  CASE  2_000_002:   RESULTIS 16
  CASE  2_000_003:   RESULTIS 17


  CASE minint+0:     RESULTIS 18
  CASE minint+1:     RESULTIS 19
  CASE minint+2:     RESULTIS 20
  CASE minint+3:     RESULTIS 21
  CASE minint+4:     RESULTIS 22

  CASE maxint-0:     RESULTIS 23
  CASE maxint-1:     RESULTIS 24
  CASE maxint-2:     RESULTIS 25
  CASE maxint-3:     RESULTIS 26
  CASE maxint-4:     RESULTIS 27

  CASE  3_000_000:   RESULTIS 28
  CASE  4_000_000:   RESULTIS 29
  CASE  5_000_000:   RESULTIS 30
  CASE  6_000_000:   RESULTIS 31

  CASE  7_000_000:   RESULTIS 32
  CASE  7_000_100:   RESULTIS 33
  CASE  7_000_200:   RESULTIS 34
  CASE  7_000_300:   RESULTIS 35
  CASE  7_000_400:   RESULTIS 36
  CASE  7_000_500:   RESULTIS 37
  CASE  7_000_600:   RESULTIS 38
  CASE  7_000_700:   RESULTIS 39
  CASE  7_000_800:   RESULTIS 40
  CASE  7_000_900:   RESULTIS 41
}

AND answer(n) = VALOF
{ IF n = -3           RESULTIS 1
  IF n = -2           RESULTIS 2
  IF n = -1           RESULTIS 3
  IF n =  0           RESULTIS 4
  IF n =  1           RESULTIS 5
  IF n =  2           RESULTIS 6
  IF n =  3           RESULTIS 7

  IF n = -1_000_000   RESULTIS 8

  IF n = -2_000_000   RESULTIS 9
  IF n = -2_000_001   RESULTIS 10

  IF n =  1_000_000   RESULTIS 11
  IF n =  1_000_001   RESULTIS 12
  IF n =  1_000_002   RESULTIS 13

  IF n =  2_000_000   RESULTIS 14
  IF n =  2_000_001   RESULTIS 15
  IF n =  2_000_002   RESULTIS 16
  IF n =  2_000_003   RESULTIS 17


  IF n = minint+0     RESULTIS 18
  IF n = minint+1     RESULTIS 19
  IF n = minint+2     RESULTIS 20
  IF n = minint+3     RESULTIS 21
  IF n = minint+4     RESULTIS 22

  IF n = maxint-0     RESULTIS 23
  IF n = maxint-1     RESULTIS 24
  IF n = maxint-2     RESULTIS 25
  IF n = maxint-3     RESULTIS 26
  IF n = maxint-4     RESULTIS 27

  IF n =  3_000_000   RESULTIS 28
  IF n =  4_000_000   RESULTIS 29
  IF n =  5_000_000   RESULTIS 30
  IF n =  6_000_000   RESULTIS 31

  IF n =  7_000_000   RESULTIS 32
  IF n =  7_000_100   RESULTIS 33
  IF n =  7_000_200   RESULTIS 34
  IF n =  7_000_300   RESULTIS 35
  IF n =  7_000_400   RESULTIS 36
  IF n =  7_000_500   RESULTIS 37
  IF n =  7_000_600   RESULTIS 38
  IF n =  7_000_700   RESULTIS 39
  IF n =  7_000_800   RESULTIS 40
  IF n =  7_000_900   RESULTIS 41

  RESULTIS 123
}
