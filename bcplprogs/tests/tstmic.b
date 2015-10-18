GET "libhdr"

MANIFEST {
  bufsize = 1024
  bufbytes = bufsize * bytesperword
}

LET start() = VALOF
{ LET audio_fd = 0
  LET micname = "/dev/dsp1"
  LET format = 16  // S16_LE
  LET channels = 1 // Mono
  LET rate = 44100 // Samples per second
  LET buf = VEC bufsize-1

  writef("tstmic entered*n")

  writef("sys(Sys_sound, 0,...) => %n*n", sys(Sys_sound, 0, 11, 22, 33, 44))

  UNLESS sys(Sys_sound, 0, 11, 22, 33, 44) DO
  { writef("Sound not available*n")
    RESULTIS 0
  }

  writef("Trying to open device %s*n", micname)

  audio_fd := sys(Sys_sound, 1, micname, format, channels, rate)

  writef("audio_fd = %n*n", audio_fd)

  UNLESS audio_fd<0 FOR i = 1 TO 8/8 DO
  { LET len = sys(Sys_sound, 2, audio_fd, buf, bufbytes, 0)
    writef("len=%n*n", len)
    FOR i = 0 TO bufsize-1 DO
    { LET w = buf!i
      LET a = (w << 16) / #x1_0000
      LET b = w / #x1_0000
      IF i MOD 8 = 0 DO newline()
      writef(" %i6 %i6", a, b)
    }
    newline()
  }

  writef("Closing audio_fd*n")

  audio_fd := sys(Sys_sound, 3, audio_fd, 0, 0, 0)

  writef("return code = %n*n", audio_fd)

  RESULTIS 0
}
