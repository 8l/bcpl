SECTION "QUIT"

// This command terminated the execution of a command-command

GET "libhdr"

LET start() = VALOF
{ LET rc = 0
  LET argv = VEC 50

  UNLESS rdargs("RC/N,REASON/N", argv, 50) DO
  { writes("Bad arguments for Quit*n")
    RESULTIS 10
  }

  IF (cli_status & clibit_comcom) ~= 0 DO
    // Force the currentinput to be exhausted
    cli_currentinput!scb_end := -1

  result2 := 0  // the default reason

  IF argv!0 DO rc      := !(argv!0)    // RC
  IF argv!1 DO result2 := !(argv!1)    // REASON

  RESULTIS rc
}

