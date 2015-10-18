/* This is a version of the Tripos why command
   modified by Alistair Scott
   16/09/05 Modified by MR
*/

SECTION "WHY"

GET "libhdr"

LET start() BE
{ LET v = VEC 1
  rdargs("Type <cr> to know ...", v, 1)

  UNLESS cli_returncode DO
  { writef("The last command completed successfully*n")
    result2 := 10000
    stop(1)  // Start the joke off!
  }

  writef("The last command had return code: %n for reason: %n*n*n",
          cli_returncode, cli_result2)
  
  SWITCHON cli_result2 INTO
  { DEFAULT:
    CASE 0:
         writes(cli_result2 -> "Unknown reason*n",
                               "No reason given*n")
         result2 := 10000
         stop(1)  // Start the joke off!

    CASE 10000:
         writes("I have just told you*n")
         result2 := 10001
         stop(1)

    CASE 10001:
         writes("Don't you listen ? ... I HAVE JUST TOLD YOU*n")
         result2 := 10002
         stop(1)

    CASE 10002:
         writes("Look here you silly toad-faced little twerp..*n")
         writes("I do not intend to keep answering these silly questions,*n")
         writes("so pack it in or I will pull the plug on you!!!*n")
         result2 := 10003
         stop(1)

    CASE 10003:
         writes("Because I have better things to do than answering your*
                 * silly questions..*n")
         writes("I don't know - Brain the size of a planet and all I am *
                 *asked to do*n")
         writes("is answer stupid questions from some immature little *
                *cretin who*n")
         writes("sees fit too waste my time with such trivia....*n")
         result2 := 10004
         stop(1)
         ENDCASE

    CASE 10004:
         writes("WHY ??? .. Don't talk to me about 'WHY'.*n")
         writes("I can't think WHY or even WHAT, WHEN, WHERE or WHO.*n")
         writes("In fact I think, therefore I am ... or I certainly was ...*n")
         writes(".. but then again, I might still be ......*n")
         writes("Oh shit.....*n")
         deplete(cos)
         abort(9999, 0)
         writes("Oh Hell .. Here we go again*n")
         result2 := 10000
         stop(1)
  }
}

