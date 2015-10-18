// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

/*      REPEAT COMMAND

        Repeat a command line

        The stream character pointer is backspaced to
        the beginning of the line
*/


SECTION "repeat"

GET "libhdr"

LET start() BE
{ UNLESS input()!scb_type<=0 DO
  { writes("REPEAT not allowed in C command*n")
    stop(return_severe)
  }
  //UNLESS testflags(flag_d) DO
    WHILE unrdch() LOOP
}
