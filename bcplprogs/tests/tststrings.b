GET "libhdr"

LET start() = VALOF
{ LET s = "hello* // This is a comment
                  // so is this
          * world*n"
  writef(s)
  RESULTIS 0
}
