// Test line numbers in error messages
LET start() = VALOF
{
  ENDCASE // Should be line 4


  BREAK   // Should be line 7
  a := b  // Should be line 8
}
