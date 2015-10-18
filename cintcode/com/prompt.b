// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "PROMPT"

GET "libhdr"

LET start() = VALOF
{ LET prompt = "%5.3d> "
  LET v = VEC 15

  UNLESS rdargs("PROMPT,P0/S,P1/S,P2/S,P3/S,P4/S,NO/S",v,15) DO
  { writes("Parameters no good for PROMPT*N")
    RETURN
  }

  IF v!0 DO prompt := v!0                         // PROMPT
  IF v!1 DO prompt := "> "                        // P0/S
  IF v!2 DO prompt := "%+%+%n:%2z:%2z> "          // P1/S
  IF v!3 DO prompt := "%+%+%n:%2z:%2z.%3z> "      // P2/S
  IF v!4 DO prompt := "%5.3d %+%n:%2z:%2z> "      // P3/S
  IF v!5 DO prompt := "%5.3d %+%n:%2z:%2z.%3z> "  // P3/S

  IF prompt FOR i = 0 TO prompt%0 DO cli_prompt%i := prompt%i

  TEST v!6                                        // NO/S
  THEN cli_status := cli_status |  clibit_noprompt
  ELSE cli_status := cli_status & ~clibit_noprompt
}
