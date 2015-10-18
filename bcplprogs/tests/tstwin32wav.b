/*
This is a test program for wave input and wave output devices.

Implemented by Martin Richards (c) September 2008

Usage: tstwin32wav "SECS/N,TO/K"

Record <secs> worth of samples into a buffer of signed integers.
If TO is specified output the samples as a .wav file.

The default for SECS is one
and the default .wav filename is res.wav


*/

GET "libhdr"
GET "sound.h"

GLOBAL {
  buf:ug
  bufsize // Number of samples in the buffer
  secs    // Number of seconds of recorded data
  tofilename // .wav file name
  tostream
  stdout
  play
}

LET start() = VALOF
{ LET waveInCB = 0
  LET devname = 0
  LET format = 16  // S16_LE
  LET channels = 1 // Mono
  LET rate = 44100 // Samples per second
  LET argv = VEC 50

  stdout := output()
  tostream := 0
  play := FALSE

  writef("tstwin32wav entered*n")

  UNLESS rdargs("SECS/N,TO/K,PLAY/S", argv, 50) DO
  { writef("Bad arguments for tstwin32wav*n")
    RESULTIS 0
  }

  secs := 5
  tofilename := "res.wav"
  IF argv!0 DO secs := !(argv!0)     // SECS/N
  IF argv!1 DO tofilename := argv!1  // TO/K
  play := argv!2                     // PLAY/S

  bufsize := rate * secs * channels

  TEST sys(Sys_sound, snd_test)=-1
  THEN writef("Sound is available*n")
  ELSE writef("Sound is not available*n")

  buf := getvec(bufsize-1)
  UNLESS buf DO
  { writef("Unable to allocate a buffer of size %n*n", bufsize)
    RESULTIS 0
  }

  //writef("Trying to open wave input device %n*n", devname)

  waveInCB := sys(Sys_sound, snd_waveInOpen, devname, format, channels, rate)

  //writef("waveInCB = %n*n", waveInCB)

  IF waveInCB=-1 DO
  { writef("Cannot open wave input device*n")
    GOTO fin
  }

  writef("*nRecording %n second%-%ps of samples*n", secs)

  { LET count = 0 // Count of samples read

    UNTIL count>=bufsize DO
    { LET len = sys(Sys_sound,
                    snd_waveInRead, waveInCB, buf+count, bufsize-count, 0)
      count := count+len
      //IF len DO writef("len = %i5 count = %i7 bufsize=%i7*n",
      //                 len, count, bufsize)
    }

IF FALSE DO
    FOR i = 0 TO bufsize-1 DO
    { IF i MOD 10 = 0 DO writef("*n%i8: ", i)
      writef(" %i6", buf!i)
    }
    newline()
  }

  //writef("Closing waveInCB*n")

  waveInCB := sys(Sys_sound, snd_waveInClose, waveInCB)

  // Output the .wav file
  tostream := findoutput(tofilename)
  UNLESS tostream DO
  { writef("Unable to open %s for output*n", tofilename)
    GOTO fin
  }
  
  selectoutput(tostream)

  riffhdr(1,         // mode = mono
          rate,      // typically 44100
          16,        // bits per sample
          bufsize*2) // number of bytes of data
  FOR i = 0 TO bufsize-1 DO
  { LET w = buf!i
    binwrch(w)
    binwrch(w>>8)
  }
  endwrite()
  tostream := 0

  selectoutput(stdout)

  IF play DO playvec(buf, bufsize, format, channels, rate)

fin:
  IF buf DO freevec(buf)
  IF tostream DO endstream(tostream)
  selectoutput(stdout)
  //writef("return code = %n*n", 0)

  RESULTIS 0
}

AND riffhdr(mode, rate, bits, databytes) BE
{ LET bytes_per_sample = bits/8 * mode
  LET byte_rate = bytes_per_sample * rate
  writes("RIFF")        //  0: R I F F
  wr4(36+0)             //  4: size of this file - 8
  writes("WAVE")        //  8: W A V E
  writes("fmt ")        // 12: f m t
  wr4(16)               // 16: fmt subchunk size is 16
  wr2(1)                // 20: 1 = linear quantisation
  wr2(mode)             // 22: 1 = mono, 2=stereo
  wr4(rate)             // 24: samples per second
  wr4(byte_rate)        // 28: bytes per second
  wr2(bytes_per_sample) // 32: bits/8 * mode  = 1, 2 or 4
  wr2(bits)             // 34: bits per sample  = 8 or 16
  writes("data")        // 36: d a t a
  //wr4(byte_rate * 1)    // 40: number of bytes of data or zero
  wr4(databytes)        // 40: number of bytes of data or -1
}

AND wr2(w) BE
{ LET s = @w
  binwrch(s%0)
  binwrch(s%1)
}

AND wr4(w) BE
{ LET s = @w
  binwrch(s%0)
  binwrch(s%1)
  binwrch(s%2)
  binwrch(s%3)
}

AND playvec(buf, bufsize, format, channels, rate) BE
{ LET waveOutCB = sys(Sys_sound,
                      snd_waveOutOpen, 0, format, channels, rate)

  //writef("waveOutCB = %n format=%n channels=%n rate=%n*n",
  //       waveOutCB, format, channels, rate)

  IF waveOutCB=-1 DO
  { writef("Cannot open wave output device*n")
    RETURN
  }

  //writef("*nPlaying %n samples*n", bufsize)

  { LET count = 0 // Count of samples sent and accepted

    UNTIL count>=bufsize DO
    { LET len = sys(Sys_sound,
                    snd_waveOutWrite, waveOutCB, buf+count, bufsize-count)
      count := count+len
      //IF len DO writef("len = %i5 count = %i7 bufsize=%i7*n",
      //                 len, count, bufsize)
      IF len<0 BREAK
//writef("Delaying 1 second*n")
      sys(Sys_delay, 1)
    }

  }

  sys(Sys_sound, snd_waveOutClose, waveOutCB)
}
