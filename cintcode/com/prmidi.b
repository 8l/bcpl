/*

This is a test program trying to read a midi stream and output it in a
readable form. It should work with any MIDI file and also hopefully
with data received from my Roland HP107e Digital Piano, typically
using input device /dev/dmmidi1 under Linux or the default midi device
under Windows.

The MIDI input part is influenced by midiread.c used in pmidi
implemented by Steve Ratcliffe.

Implemented by Martin Richards (c) 21 May 2008

Updated 27/09/08
*/

GET "libhdr"

MANIFEST {
Note_off           = #x80
Note_on            = #x90
Key_aftertouch     = #xa0
Controller         = #xb0
Patch              = #xc0
Channel_aftertouch = #xd0
Pitch_wheel        = #xe0
Sysex              = #xf0
Meta               = #xff

// Meta event defines
Meta_sequence   = 0

// The text type meta events
Meta_text       = 1
Meta_copyright  = 2
Meta_trackname  = 3
Meta_instrument = 4
Meta_lyric      = 5
Meta_marker     = 6
Meta_cue        = 7

// More meta events
Meta_channel      = #x20
Meta_port         = #x21
Meta_eot          = #x2f
Meta_tempo        = #x51
Meta_smpte_offset = #x54
Meta_time         = #x58
Meta_key          = #x59
Meta_prop         = #x7f

// The maximum of the midi defined text types
Max_text_type     = 7

Head_magic        = #x4D546864  // MHdr
Track_magic       = #x4D54726B  // MTrk
}

GLOBAL {
  midiname:ug
  midistream
  outname
  outstream
  stdin
  stdout
  midiformat
  miditracks
  miditimebase
  midiport
  current_time
  rdvar
  status
  laststatus
  chunk_size
  chunk_count
}

LET start() = VALOF
{ LET argv = VEC 50
  stdout := output()
  stdin := input()

  UNLESS rdargs("from,to/k", argv, 50) DO
  { writef("Bad arguments for prmidi*n")
    RESULTIS 0
  }

  //writef("prmidi: entered*n")

  midiname := "test.mid"
  //midiname := "/dev/dmmidi1"
  midistream := 0
  outname    := 0
  outstream  := 0

  IF argv!0 DO midiname := argv!0
  IF argv!1 DO outname  := argv!1

  midistream := findinput(midiname)
  UNLESS midistream DO
  { writef("Trouble with file: %s*n*n", midiname)
    GOTO fin
  }

  IF outname DO
  { outstream := findoutput(outname)
    UNLESS outstream DO
    { writef("Trouble with file: %s*n*n", outname)
      RESULTIS fin
    }
  }

  writef("Reading MIDI file: %s*n", midiname)
  IF outname DO writef("Sending the result to file: %s*n", outname)

  IF midistream DO selectinput(midistream)
  IF outstream  DO selectoutput(outstream)

  rdhead()

//writef("format=%n tracks=%n timebase=%n*n",
//          midiformat, miditracks, miditimebase)

  FOR i = 1 TO miditracks DO
  { newline()
    rdtrack()
  }

fin:
  IF midistream DO endstream(midistream)
  IF outstream DO endstream(outstream)

  selectoutput(stdout)
  //writef("*nEnd of output*n")

  RESULTIS 0
}

AND rdhead() = VALOF
{ LET magic = rdint4()
  LET length = 0

  UNLESS magic = Head_magic DO
  { writef("Bad MIDI header: %x8*n", magic)
    RESULTIS 0
  }

  length := rdint4() // Header length
  UNLESS length>=6 DO
  { writef("Bad MIDI header length: %n*n", length)
    RESULTIS 0
  }

  midiformat   := rdint2()
  miditracks   := rdint2()
  miditimebase := rdint2()

  FOR i = 7 TO length DO rdint1()

//writef("midiformat=%n tracks=%n timebase=%n*n",
//        midiformat, miditracks, miditimebase)

  RESULTIS 1
}

AND rdtrack() = VALOF
{ LET magic = rdint4()
  LET length, pos = 0, 0

  UNLESS magic = Track_magic DO
  { writef("Bad track header: %x8*n", magic)
    RESULTIS 0
  }

  length := rdint4()
  chunk_size := length
  chunk_count := 0 // Nothing read yet

  current_time := 0

  WHILE chunk_count<length DO
  { LET delta_time = rdvar()
    current_time := current_time + delta_time
    writef("%i7 %i5: ", current_time, delta_time)
    status := rdint1()

    TEST (status & #x80) = 0
    THEN { // This is not a status byte so running status is being used.
           unrdch()
           status := laststatus
         }
    ELSE laststatus := status

//IF delta_time DO {
//  writef("delta=%n status=%x2*n", delta_time, status)
//  abort(1003)
//}
    handle_status(status)
  }
}

AND handle_status(status) BE
{ LET ch   = status & #x0F
  LET chno = ch + 1  // channel 1 .. 16
  LET type = status & #xF0
  LET device = 0
  // Do not set the device if the type is F0 as these commands are
  // not channel specific.
  UNLESS type=#xF0 DO device := midiport<<4 | ch

  //writef("handle_status: %x2*n", status)

  SWITCHON type INTO
  { CASE Note_off:              // #x80
         // Format: 8n note velocity            Note On
         // n = 0 to 15 for channels 1 to 16
         // note = 0 to 127 for Midi note number (60 = middle C)
         // velocity = 0 to 127 -- decay time?
       { LET note = rdint1()
         LET vel  = rdint1()

         //finish_note(msp, note, vel);
         writef("Note_off:    %i2 %i3 %i3*n", chno, note, vel);
         ENDCASE
       }

    CASE Note_on:               // #x90
         // Format: 9n note velocity            Note On
         // n = 0 to 15 for channels 1 to 16
         // note = 0 to 127 for Midi note number (60 = middle C)
         // velocity = 0 to 127 -- volume?
       { LET note = rdint1();
         LET vel  = rdint1();
         writef("Note_on:     %i2 %i3 %i3*n", chno, note, vel)

         TEST vel=0
         THEN { // This is really a note off
                //finish_note(msp, note, vel);
              }
         ELSE { // Save the start, so it can be matched with the note off
                //el = save_note(msp, note, vel);
              }
         ENDCASE
       }

    CASE Key_aftertouch:        // #xA0
         // Format: An note velocity            After Touch
         // n = 0 to 15 for channels 1 to 16
         // note = 0 to 127 for Midi note number (60 = middle C)
         // velocity = 0 to 127 -- volume?
       { LET note = rdint1();
         LET vel = rdint1();
         writef("Aftertouch:  %i2 %i3 %i3*n", chno, note, vel);

         // new aftertouchElement
         // el = MD_ELEMENT(md_keytouch_new(note, vel));
         ENDCASE
       }

    CASE Controller:            // #xB0
         // Format: Bn controller_no val            Set controller value
         // n = 0 to 15 for channels 1 to 16
         // controller_no = 0 to 127 for Midi note number (60 = middle C)
         // val = 0 to 127 -- value
         // Controller numbers are as follows
         // 00  20     MS and LS 7 bits of Bank Select
         // 01  21     MS and LS 7 bits of Modulation Wheel
         // 02  22     MS and LS 7 bits of Breath Control
         // 03  23     MS and LS 7 bits of Undefined
         // 04  24     MS and LS 7 bits of Foot Controller
         // 05  25     MS and LS 7 bits of Portamento Time
         // 06  26     MS and LS 7 bits of Data Entry Slider
         // 07  27     MS and LS 7 bits of Main Volume
         // 08  28     MS and LS 7 bits of Balance
         // 09  29     MS and LS 7 bits of Undefined
         // 0A  2A     MS and LS 7 bits of Pan
         // 0B  2B     MS and LS 7 bits of Expression Controller
         // 0C  2C     MS and LS 7 bits of Effect Control 1
         // 0D  2D     MS and LS 7 bits of Effect Control 2
         // 0E  2E     MS and LS 7 bits of Undefined
         // 0F  2F     MS and LS 7 bits of Undefined
         // 10  30     MS and LS 7 bits of General Purpose Controller 1
         // 11  31     MS and LS 7 bits of General Purpose Controller 2
         // 12  32     MS and LS 7 bits of General Purpose Controller 3
         // 13  33     MS and LS 7 bits of General Purpose Controller 4
         // 14  34     MS and LS 7 bits of Undefined
         // ......
         // 1F  3F     MS and LS 7 bits of Undefined
         // 40         7 bits of Sustain Pedal
         // 41         7 bits of Portamento on/off
         // 42         7 bits of Sostenuto on/off
         // 43         7 bits of Soft Pedal
         // 44         7 bits of Legato Foot Switch
         // 45         7 bits of Hold 2
         // 46         7 bits of Sound Variation
         // 47         7 bits of Timbre/Harmonic Content
         // 48         7 bits of Release Time
         // 49         7 bits of Attack Time
         // 4A         7 bits of Brightness
         // 4B - 4F    7 bits of Sound controllers (no default)
         // 50 - 53    7 bits of General Purpose Controller 5 - 8
         // 54         7 bits of Portamento Control - note to slide from
         //                      (normally transmitted between 2 notes)
         // 55 - 5A    Unedefined
         // 5B         7 bits of External Effects Depth
         // 5C         7 bits of Tremulo Depth
         // 5D         7 bits of Chorus Depth
         // 5E         7 bits of Celestre(Detune) Depth
         // 5F         7 bits of Phaser Depth
         // 60         7 bits of Data Increment
         // 61         7 bits of Data Decrement
         // 62  63     LS and MS 7 bits of NRPC Control
         // 64  65     LS and MS 7 bits of RPC Control
         // 66  77     Undefined
         // 78         All sounds off
         // 79         Reset all controllers
         // 7A         Local on/off
         // 7B         All notes off
         // 7C         Omni receive mode off
         // 7D         Omni receive mode on
         // 7E         Mono receive mode
         // 7F         Poly receive mode
       { LET control = rdint1();
         LET val = rdint1();
         writef("Control:     %i2 %i3 %i3*n", chno, control, val);
         //el = MD_ELEMENT(md_control_new(control, val));
         ENDCASE
       }

    CASE Patch:                 // #xC0
         // Format: Cn number                     Patch
         // n = 0 to 15 for channels 1 to 16
         // nunmber = 0 to 127 for patch number 1 to 128
       { LET val = rdint1();
         writef("Patch:       %i2 %i3*n", chno, val);
         //el = MD_ELEMENT(md_program_new(val));
         ENDCASE
       }

   CASE Channel_aftertouch:     // #xD0
         // Format: Dn pressure                   After Touch
         // n = 0 to 15 for channels 1 to 16
         // pressure = 0 to 127 for the after touch pressure - voluime?
      { LET val = rdint1();
        writef("Chan_atouch:  %i2 %i3*n", chno, val);
        //el = MD_ELEMENT(md_pressure_new(val));
        ENDCASE
      }

    CASE Pitch_wheel:           // #xE0
         // Format: En lsb msn                   Pitch Bend Wheel
         // n = 0 to 15 for channels 1 to 16
         // lsb msb are the LS and MS 7 bits of the pitch bend value
       { LET val = rdint1();
         val := val | rdint1()<<7;
         val := val - #x2000;	// Centre it around zero
         writef("Pitch_wheel: %i2 %4x*n", chno, val);
         //el = MD_ELEMENT(md_pitch_new(val));
         ENDCASE
       }

         // Now for all the non-channel specific ones
    CASE Sysex:                 // #xF0
       { LET length = 0
         LET data = VEC 50

         // Deal with the end of track event first
         IF ch = #x0F DO
         { type := rdint1();
           IF type = #x2F DO
           { writef("End of track:*n");
             // End of track - skip to end of real track
             skip_chunk()
             RETURN
           }
         }

         // Get the length of the following data
         length := rdvar();
         data%0 := length
         FOR i = 1 TO length DO data%i := rdint1()

         TEST ch = #x0F
         THEN handle_meta(type, data, length)
         ELSE handle_sysex(status, data, length)
         ENDCASE
       }

     DEFAULT:
           writef("Bad status type %x2*n", type)
  }
}

AND skip_chunk() BE WHILE chunk_count < chunk_size DO rdint1()

AND handle_meta(type, data, length) BE
{ // Data is in data%1 ... data%length
  // data%0 = length & 255   -- useful for string data
  SWITCHON type INTO
  { CASE Meta_sequence:
         writef("Meta_sequence:*n");
         ENDCASE

    // Text based events
    CASE Meta_text:       writef("Meta_text: %s*n",       data); ENDCASE
    CASE Meta_copyright:  writef("Meta_copyright: %s*n",  data); ENDCASE
    CASE Meta_trackname:  writef("Meta_trackname: %s*n",  data); ENDCASE
    CASE Meta_instrument: writef("Meta_instrument: %s*n", data); ENDCASE
    CASE Meta_lyric:      writef("Meta_lyric: %s*n",      data); ENDCASE
    CASE Meta_marker:     writef("Meta_marker: %s*n",     data); ENDCASE
    CASE Meta_cue:        writef("Meta_cue:*n",           data); ENDCASE

    CASE Meta_channel:    writef("Meta_channel:*n");  ENDCASE

    CASE Meta_port:
         //msp->port = data[0];
         writef("Meta_port: %d*n", data%1);
         //g_free(data);
         ENDCASE

    CASE Meta_eot:
         writef("Meta_EOT:*n");
         ENDCASE

    CASE Meta_tempo:
       { LET micro_tempo = ((data%1<<16) & #xff0000) +
                           ((data%2<<8) & #xff00) + (data%3 & #xff)
         writef("Meta_tempo: %n*n", micro_tempo)
         ENDCASE
       }

    CASE Meta_smpte_offset:
         writef("Meta_SMPTE_OFFSET: %2x %2x %2x %2x %2x*n",
		 data%1, data%2, data%3, data%4, data%5);

         ENDCASE

    CASE Meta_time:
         writef("Meta_time: %n/%n %n %n*n",
                   data%1, data%2, data%3, data%4)
         ENDCASE

    CASE Meta_key:
         writef("Meta_key: %n %n*n", data%1, data%2)
         ENDCASE

    CASE Meta_prop:
         // Proprietry sequencer specific event
         // Just throw it out
	 writef("Meta_prop:*n")
         ENDCASE

    DEFAULT:
         writef("Bad meta event type=%x2*n", type);
         ENDCASE
  }
}

AND handle_sysex(status, data, length) BE
{
sw:
  SWITCHON status INTO
  { DEFAULT:
         writef("handle_sysex: bad status %x2*n", status)
         RETURN

    CASE #xF0:
         { LET byte = binrdch()
           IF byte=#xF7 DO
           { writef("*nEox:*n")
             BREAK
           }
           IF byte>=#x80 DO
           { newline()
             BREAK
           }
           writef("F0 %x2", byte)
           UNLESS byte=#xF7 BREAK
         } REPEAT
         LOOP

    CASE #xF1:
         writef("MIDI Time Code: %i4*n", rdint2())
         LOOP
    CASE #xF2:
         writef("Song Position Pointer: %i4*n", rdint2())
         LOOP
    CASE #xF3:
         writef("Song Select:%i3*n", rdint1())
         LOOP
    CASE #xF4:
         writef("Undef:*n")
         LOOP
    CASE #xF5:
         writef("Undef:*n")
         LOOP
    CASE #xF6:
         writef("Tune Request:*n")
         LOOP
    CASE #xF7:
         writef("Eox:*n")
         LOOP
    CASE #xF8:
         writef("Timing clock:*n")
         LOOP
    CASE #xF9:
         writef("Undef:*n")
         LOOP
    CASE #xFA:
         writef("Start:*n")
         LOOP
    CASE #xFB:
         writef("Continue:*n")
         LOOP
    CASE #xFC:
         writef("Stop:*n")
         LOOP
    CASE #xFD:
         writef("Undef:*n")
         LOOP
    CASE #xFE:
         writef("Active Sensing:*n")
         LOOP
    CASE #xFF:
         writef("System Reset:*n")
         LOOP
  }
} REPEAT

AND rdvar() = VALOF
{ LET val, c = 0, 0
  { c := rdint1()
    IF c=endstreamch DO
    { writef("Unexpected EOF*n")
      RESULTIS val
    }
    val := val<<7 | (c & #x7F)
  } REPEATWHILE (c&#x80) = #x80

  RESULTIS val
}

AND rdint1() = VALOF
{ LET a = binrdch()
  chunk_count := chunk_count+1
  IF a<0 DO
  { writef("Unexpected EOF*n")
    abort(999)
  }

  RESULTIS a
}

AND rdint2() = VALOF
{ LET a = rdint1()
  LET b = rdint1()

  RESULTIS a<<8 | b
}

AND rdint4() = VALOF
{ LET a = rdint1()
  LET b = rdint1()
  LET c = rdint1()
  LET d = rdint1()

//writef("rdint4: %x2 %x2 %x2 %x2*n", a, b, c, d)
  RESULTIS ((a<<8 | b)<<8 | c)<<8 | d
}

AND mk3(a, b, c) = VALOF
{ RESULTIS 0
}

AND namename(n) = VALOF SWITCHON n INTO
{ DEFAULT:  RESULTIS "Bad "

  CASE   0: RESULTIS "C-1 "
  CASE   1: RESULTIS "C#-1"
  CASE   2: RESULTIS "D-1 "
  CASE   3: RESULTIS "D#-1"
  CASE   4: RESULTIS "E-1 "
  CASE   5: RESULTIS "F-1 "
  CASE   6: RESULTIS "F#-1"
  CASE   7: RESULTIS "G-1 "
  CASE   8: RESULTIS "G#-1"
  CASE   9: RESULTIS "A-1 "
  CASE  10: RESULTIS "A#-1"
  CASE  11: RESULTIS "b-1 "

  CASE  12: RESULTIS "C0  "
  CASE  13: RESULTIS "C#0 "
  CASE  14: RESULTIS "D0  "
  CASE  15: RESULTIS "D#0 "
  CASE  16: RESULTIS "E0  "
  CASE  17: RESULTIS "F0  "
  CASE  18: RESULTIS "F#0 "
  CASE  19: RESULTIS "G0  "
  CASE  20: RESULTIS "G#0 "
  CASE  21: RESULTIS "A0  "
  CASE  22: RESULTIS "A#0 "
  CASE  23: RESULTIS "b0  "

  CASE  24: RESULTIS "C1  "
  CASE  25: RESULTIS "C#1 "
  CASE  26: RESULTIS "D1  "
  CASE  27: RESULTIS "D#1 "
  CASE  28: RESULTIS "E1  "
  CASE  29: RESULTIS "F1  "
  CASE  30: RESULTIS "F#1 "
  CASE  31: RESULTIS "G1  "
  CASE  32: RESULTIS "G#1 "
  CASE  33: RESULTIS "A1  "
  CASE  34: RESULTIS "A#1 "
  CASE  35: RESULTIS "b1  "

  CASE  36: RESULTIS "C2  "
  CASE  37: RESULTIS "C#2 "
  CASE  38: RESULTIS "D2  "
  CASE  39: RESULTIS "D#2 "
  CASE  40: RESULTIS "E2  "
  CASE  41: RESULTIS "F2  "
  CASE  42: RESULTIS "F#2 "
  CASE  43: RESULTIS "G2  "
  CASE  44: RESULTIS "G#2 "
  CASE  45: RESULTIS "A2  "
  CASE  46: RESULTIS "A#2 "
  CASE  47: RESULTIS "b2  "

  CASE  48: RESULTIS "C3  "
  CASE  49: RESULTIS "C#3 "
  CASE  50: RESULTIS "D3  "
  CASE  51: RESULTIS "D#3 "
  CASE  52: RESULTIS "E3  "
  CASE  53: RESULTIS "F3  "
  CASE  54: RESULTIS "F#3 "
  CASE  55: RESULTIS "G3  "
  CASE  56: RESULTIS "G#3 "
  CASE  57: RESULTIS "A3  "
  CASE  58: RESULTIS "A#3 "
  CASE  59: RESULTIS "b3  "

  CASE  60: RESULTIS "C4  "
  CASE  61: RESULTIS "C#4 "
  CASE  62: RESULTIS "D4  "
  CASE  63: RESULTIS "D#4 "
  CASE  64: RESULTIS "E4  "
  CASE  65: RESULTIS "F4  "
  CASE  66: RESULTIS "F#4 "
  CASE  67: RESULTIS "G4  "
  CASE  68: RESULTIS "G#4 "
  CASE  69: RESULTIS "A4  "
  CASE  70: RESULTIS "A#4 "
  CASE  71: RESULTIS "b4  "

  CASE  72: RESULTIS "C5  "
  CASE  73: RESULTIS "C#5 "
  CASE  74: RESULTIS "D5  "
  CASE  75: RESULTIS "D#5 "
  CASE  76: RESULTIS "E5  "
  CASE  77: RESULTIS "F5  "
  CASE  78: RESULTIS "F#5 "
  CASE  79: RESULTIS "G5  "
  CASE  80: RESULTIS "G#5 "
  CASE  81: RESULTIS "A5  "
  CASE  82: RESULTIS "A#5 "
  CASE  83: RESULTIS "b5  "

  CASE  84: RESULTIS "C6  "
  CASE  85: RESULTIS "C#6 "
  CASE  86: RESULTIS "D6  "
  CASE  87: RESULTIS "D#6 "
  CASE  88: RESULTIS "E6  "
  CASE  89: RESULTIS "F6  "
  CASE  90: RESULTIS "F#6 "
  CASE  91: RESULTIS "G6  "
  CASE  92: RESULTIS "G#6 "
  CASE  93: RESULTIS "A6  "
  CASE  94: RESULTIS "A#6 "
  CASE  95: RESULTIS "b6  "

  CASE  96: RESULTIS "C7  "
  CASE  97: RESULTIS "C#7 "
  CASE  98: RESULTIS "D7  "
  CASE  99: RESULTIS "D#7 "
  CASE 100: RESULTIS "E7  "
  CASE 101: RESULTIS "F7  "
  CASE 102: RESULTIS "F#7 "
  CASE 103: RESULTIS "G7  "
  CASE 104: RESULTIS "G#7 "
  CASE 105: RESULTIS "A7  "
  CASE 106: RESULTIS "A#7 "
  CASE 107: RESULTIS "b7  "

  CASE 108: RESULTIS "C8  "
  CASE 109: RESULTIS "C#8 "
  CASE 110: RESULTIS "D8  "
  CASE 111: RESULTIS "D#8 "
  CASE 112: RESULTIS "E8  "
  CASE 113: RESULTIS "F8  "
  CASE 114: RESULTIS "F#8 "
  CASE 115: RESULTIS "G8  "
  CASE 116: RESULTIS "G#8 "
  CASE 117: RESULTIS "A8  "
  CASE 118: RESULTIS "A#8 "
  CASE 119: RESULTIS "b8  "

  CASE 120: RESULTIS "C9  "
  CASE 121: RESULTIS "C#9 "
  CASE 122: RESULTIS "D9  "
  CASE 123: RESULTIS "D#9 "
  CASE 124: RESULTIS "E9  "
  CASE 125: RESULTIS "F9  "
  CASE 126: RESULTIS "F#9 "
  CASE 127: RESULTIS "G9  "
}

