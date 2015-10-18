// This is a MIDI output test program designed to write to the
// currently selected MIDI output device. It runs on the BCPL Cintcode
// system under Windows.

// Implemented by Martin Richards (c) 15 May 2008 

GET "libhdr"
GET "sound.h"

GLOBAL {
  stdin:ug
  stdout
  midiname
  midifd
  prog
  tempo
  instr
  volumelevel
  legatoval
  msecsperbeat
  channelno
}

LET start() = VALOF
{ LET argv = VEC 50

  stdout := output()
  stdin  := input()

  midifd := 0
  instr  := 1
  tempo  := 180
  volumelevel := 100
  legatoval := 80  

  UNLESS rdargs("INSTR/n,TEMPO/n,VOL/n,LEGATO/n", argv, 50) DO
  { writef("Bad arguments for tstmidi*n")
    RESULTIS 0
  }

  IF argv!0 DO instr       := !(argv!0)   // INSTR
  IF argv!1 DO tempo       := !(argv!1)   // TEMPO
  IF argv!2 DO volumelevel := !(argv!2)   // VOL
  IF argv!3 DO legatoval   := !(argv!3)   // LEGATO

  msecsperbeat := 60_000 / tempo

  midifd := sys(Sys_sound, snd_midiOutOpen, midiname)

  UNLESS midifd DO
  { writef("Trouble with %s*n", midiname)
    RESULTIS 0
  }

  writef("*nSending MIDI data instr=%n tempo=%n vol=%n legato=%n*n*n*n",
          instr, tempo, volumelevel, legatoval)
  channel(1)  // select the MIDI channel (1..16)

  { LET patch = instr-1
    writef("*nPatch %n*n", patch+1)

    wrmid3(#xB0+channelno, 123, 0) // Allnotes off
    delay(1000)
    
    bankselect((93<<8) + (7 + patch/128))
    writef("Selecting patch %n*n", patch & 127)
    wrmid2(#xC0+channelno, patch & 127)       // Set Program number

    volume(volumelevel) // Select the volume
    legato(legatoval)   // Select the percentage on time


    FOR i = 0 TO 24 DO
    { TEST i MOD 12 = 0
      THEN n1(60-12+i)
      ELSE n4(60-12+i) // Play a crochet
    }

    n4(60)
    n4(60+4)
    n4(60+7)
    n4(72)
    n4(72+4)
    n4(72+7)
    n4(84)
    n4(72+7)
    n4(72+4)
    n4(72)
    n4(60+7)
    n4(60+4)
    n1(60)
  }

  delay(msecsperbeat)

  sys(Sys_sound, snd_midiOutClose, midifd) // Close the midi output device
  selectoutput(stdout)
  writef("End of test*n")

  RESULTIS 0
}

AND playnote(duration, n) BE
{ LET ontime  = duration*legatoval/100
  LET offtime = duration - ontime

  wrmid3(#x90+channelno, n, volumelevel)
  delay(ontime)
  wrmid3(#x80+channelno, n, 0)
  delay(offtime)
}

AND n1(n)  BE playnote(msecsperbeat*4,  n)
AND n2(n)  BE playnote(msecsperbeat*2,  n)
AND n4(n)  BE playnote(msecsperbeat,    n)
AND n8(n)  BE playnote(msecsperbeat/2,  n)
AND n16(n) BE playnote(msecsperbeat/4,  n)
AND n32(n) BE playnote(msecsperbeat/8,  n)
AND n64(n) BE playnote(msecsperbeat/16, n)

AND volume(vol) BE volumelevel := vol
AND legato(p) BE legatoval := p
AND channel(n) BE channelno := (n-1) & 15

AND bankselect(bank) BE
{ LET mm = bank>>8 & 255
  LET ll = bank    & 255
  writef("Selecting Bank %n %n*n", mm, ll)
  wrmid3(#xB0+channelno, #x00, mm)
  wrmid3(#xB0+channelno, #x20, ll)
}
AND delay(msecs) BE
{ LET ticks = tickspersecond * msecs / 1000
  deplete(cos)
  sys(Sys_delay, ticks)
}

AND wrmid1(a) BE
{
  sawritef(" %x2*n", a)
  sys(Sys_sound, snd_midiOutWrite1, midifd, a)
}

AND wrmid2(a, b) BE
{
  sawritef(" %x2 %x2*n", a, b)
  sys(Sys_sound, snd_midiOutWrite2, midifd, a, b)
}

AND wrmid3(a, b, c) BE
{
  sawritef(" %x2 %x2 %x2*n", a, b, c)
  sys(Sys_sound, snd_midiOutWrite3, midifd, a, b, c)
}
