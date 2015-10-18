SECTION "COINS"
 
GET "libhdr"
 
LET coins(sum) = c(sum, (TABLE 200, 100, 50, 20, 10, 5, 2, 1))
 
AND c(sum, t) = sum<0 -> 0,
                sum=0 | !t=1 -> 1,
                c(sum, t+1) + c(sum-!t, t)
 
LET start() = VALOF
{ writes("Coins problem*n")
 
  t(0)
  t(1)
  t(2)
  t(5)
  t(21)
  t(100)
  t(200)
  RESULTIS 0
}
 
AND t(n) BE writef("Sum = %i3  number of ways = %i6*n", n, coins(n))
