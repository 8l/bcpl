GET"libhdr"

LET start() BE FOR k = 1 TO 31 DO
$( LET num = (1<<k) - 1
   writef("*NFactors of %N  k = %N*N", num, k)

   FOR i = 2 TO num<#XFFFF->num/2, #XFFFF IF num REM i = 0 DO
       writef("%N ", i)

$)


