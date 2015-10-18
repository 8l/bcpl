GET "libhdr"

LET clihook(a1) = VALOF
{ LET mess = "Hello*n"
  selectinput(findinput("**"))
  selectoutput(findoutput("**"))

  RESULTIS start(a1)
}


