GET "libhdr"

LET start() = VALOF
{ //LET ch = 'B'
  //LET pos = 3
  //selectinput(findinput("**"))
  selectoutput(findoutput("**"))

  //sawrch('A')
  //sawrch('*n')
  wrch('A')
  wrch('B')
  wrch('*n')
  
  RESULTIS 111 //f(0)
}

AND f(n) = n=0 -> 1, n*f(n-1)
