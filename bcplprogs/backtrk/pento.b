SECTION "pento"

GET "libhdr"

GLOBAL { pv:200
         count:201
         space:202
         pos:203
         bv:204
}

LET setup() BE
{ // initialise the data structure representing
  // rotations, reflections and translations of the pieces.
  LET sp = getvec(5000)
  space := sp
  pv := getvec(11)
  pos := getvec(11)
  bv  := getvec(11)
  FOR i = 0 TO 11 DO pv!i, pos!i, bv!i := 0, 0, 0

  init(0, #0000000037,  //  * * * * *   *
          #0101010101,  //              *
       0)               //              *
                        //              *
                        //              *

  init(1,     #020702,  //    *
       0)               //  * * *
                        //    *

  init(2,   #03010101,  //    *    *    * *    * *
            #03020202,  //    *    *      *    *
            #01010103,  //    *    *      *    *
            #02020203,  //  * *    * *    *    *

                #1701,  //           *    *
                #1710,  //     * * * *    * * * *

                #0117,  //     * * * *    * * * *
                #1017,  //           *    *
       0)

  init(3,     #010701,  //      *   *       * * *     *
              #040704,  //  * * *   * * *     *       *
              #020207,  //      *   *         *     * * *
              #070202,
       0)

  init(4,       #0703,  //    * *   * *    * * *   * * *
                #0706,  //  * * *   * * *    * *   * *
                #0307,
                #0607,
              #030301,  //    *   *     * *   * *
              #030302,  //  * *   * *   * *   * *
              #010303,  //  * *   * *     *   *
              #020303,
       0)

  init(5,       #0316,  //  * * *       * * *
                #1407,  //      * *   * *

                #1603,  //      * *   * *
                #0714,  //  * * *       * * *

            #01030202,  //  *       *     *   *
            #02030101,  //  *       *   * *   * *
            #02020301,  //  * *   * *   *       *
            #01010302,  //    *   *     *       *
       0)

  init(6,     #070101,  //     *   *       * * *   * * *
              #070404,  //     *   *           *   *
              #010107,  // * * *   * * *       *   *
              #040407,
       0)

  init(7,    #030604,  //  *           *     * *   * *
             #060301,  //  * *       * *   * *       * *
             #040603,  //    * *   * *     *           *
             #010306,
       0)

  init(8,    #030103,  //  * *   * *   * * *   *   *
             #030203,  //    *   *     *   *   * * *
               #0507,  //  * *   * *
               #0705,
       0)

  init(9,    #010704,  //  *           *   * *      * *
             #040701,  //  * * *   * * *     *      *
             #030206,  //      *   *         * *  * *
             #060203,
       0)

  init(10,     #1702,  //      *       *       * * * *   * * * *
               #1704,  //  * * * *   * * * *       *       *
               #0217,
               #0417,
           #01030101,  //    *   *       *   *
           #02030202,  //    *   *     * *   * *
           #01010301,  //  * *   * *     *   *
           #02020302,  //    *   *       *   *
       0)

// The comments eliminate reflectively similar solutions

  init(11,   #010702,  //    *       *         *   *
//           #040702,  //  * * *   * * *   * * *   * * *
//           #020701,  //      *   *         *       *
//           #020704,
             #030602,  //    *       *       * *   * *
//           #060302,  //  * *       * *   * *       * *
//           #020603,  //    * *   * *       *       *
//           #020306,
       0)
  writef("*nSpace used = %n*n", space-sp)
}

AND list2(x, y) = VALOF
{ LET s = space
  space := space + 2
  s!0, s!1 := x, y
  RESULTIS s
}

AND init(piece, a, b, c, d, e, f, g, h, i) BE
{ LET t = @a
  LET v = getvec(59)

  FOR i = 0 TO 59 DO v!i := 0

  pv!piece := v

  { LET bits = !t
    t := t+1
    IF bits=0 RETURN

    { LET org = VALOF FOR i = 0 TO 4 UNLESS (bits>>i & 1)=0 RESULTIS i
      LET ysize = VALOF FOR i = 6 TO 30 BY 6 DO
                        IF (bits>>i & #77) = 0 RESULTIS i
      FOR p = 0 TO 60-ysize BY 6 DO
      { LET w = bits
        LET q = p+org

        { v!q := list2(v!q, bits>>org)
//          writef("piece %I2  p %I2  bits %Oa*n", piece, q, bits>>org)
          UNLESS (w&#4040404040) = 0 BREAK
          q, w := q+1, w<<1
        } REPEAT
      }

    }
  } REPEAT
}


AND try(n, p, board) BE TEST n<0
THEN { count := count + 1
       writef("%I5 ", count)
       pr(0)
     }
ELSE { UNTIL (board&1)=0 DO p, board := p+1, board>>1
       FOR i = 0 TO n DO
       { LET v = pv!i

         UNLESS v!p=0 DO
         { LET l = v!p
           pv!i := pv!n
           { IF (l!1 & board)=0 DO
             { pos!n, bv!n := p, l!1
               try(n-1, p, l!1+board)
             }
             l := !l
           } REPEATUNTIL l=0
           pv!i := v
         }
       }
     }

AND start() = VALOF
{ writes("*nPENTO started*n")
  setup()
  count := 0
  try(11, 0, 0)
  writef("*nNumber of solutions is %n*n", count)
  RESULTIS 0
}

AND pr(n) BE
{ LET v = VEC 59
  FOR i = 0 TO 59 DO v!i := '-'
  FOR i = n TO 11 DO
  { LET id  = "ABCDEFGHIJKL"%(12-i)
    LET p = pos!i
    LET bits = bv!i
    UNTIL bits=0 DO
    { UNLESS (bits&1)=0 DO v!p := id
      p, bits := p+1, bits>>1
    }
  }
  FOR i = 0 TO 59 DO
  { IF i REM 6 = 0 DO wrch(' ')
    wrch(v!i)
  }
  newline()
}

