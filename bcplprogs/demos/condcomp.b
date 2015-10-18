/* This is a demonstration of the conditional
   compilation features of BCPL
*/

GET "libhdr"

LET start() = VALOF
{ writef("Conditional compilation demonstration*n*n")

// All conditional compilation tags are initially false

$<XYZ
  writef("1: Tag XYZ should be false here*n")
$>XYZ

$$XYZ   // Set the XYZ tag to true

$<XYZ
  writef("2: Tag XYZ should be true here*n")
$>XYZ

$$XYZ   // Complement the XYZ tag 

$<XYZ
  writef("3: Tag XYZ should be false here*n")
$>XYZ

$$Linux     // Set the Linux conditional compilation tag
$$WinNT

$<Linux
  // The following lines are skipped if the Linux tag is unset
  $<WinNT $$WinNT $>WinNT  // Unset the WinNT tag if set
  writef("This was compiled for Linux*n")
$>Linux
$<WinNT
  // Include only if the WinNT tag is set
  writef("This was compiled for Windows NT*n")
$>WinNT
FINISH
  RESULTIS 0
}

$<WinNT
// This material should be skipped until EOF
// without complaining about the missing $>WinNT
