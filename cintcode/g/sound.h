// Header for the Sound module

// Implemented by Martin Richards (c) 29 Aug 2008

/*
This header file contains the interface for the sys(Sys_sound,...)
operations and also the library functions defined in g/sound.b which
allow reading and writing of .wav files. Functions to analyse and
generate sound data are also included.

01/12/11
Started major changes.

29/08/08
Original implementation.
*/

MANIFEST {
  // These are ops for res:=sys(Sys_sound, op, a1, a2, a3,...)
  snd_test =  0      // res = TRUE is sound is available
  snd_waveInOpen     // a1 is typically /dev/dsp or /dev/dsp1 or a small integer
                     // a2 is sample format, 16=S16_LE, 8=U8, etc
                     // a3 = channels, typically 1 or 2
                     // a4 = rate, eg 44100
                     // res = file (or device) descriptor,. or -1 if error
  snd_waveInPause    // Pause sound wave sampling,
                     // recently read samples can still be read
  snd_waveInRestart  // Restart sound wave sampling
  snd_waveInRead     // Read samples from sound wave input device,
                     // returning immediately
                     // a1 = file (or device) descriptor
                     // a2 = buffer address
                     // a3 = number of bytes to read
                     // res = number of bytes actually transferred into the buffer
  snd_waveInClose    // Close a sound wave input device
                     // a1 = the file (or device) descriptor
  snd_waveOutOpen    // a1 is typically /dev/dsp or /dev/dsp1 or a small integer
                     // a2 is sample format, 16=S16_LE, 8=U8, etc
                     // a3 = channels, typically 1 or 2
                     // a4 = rate, eg 44100
                     // res = file (or device) descriptor, or -1 if error
  snd_waveOutWrite   // Write samples to a sound wave output device,
                     // returning immediately
                     // a1 = file (or device) descriptor
                     // a2 = buffer address
                     // a3 = number of bytes to write
                     // res = number of bytes actually transferred from the buffer,
                     //       or -1 if error
  snd_waveOutClose   // Close a sound wave output device
                     // a1 = the file (or device) descriptor
  snd_midiInOpen
  snd_midiInRead
  snd_midiInClose
  snd_midiOutOpen
  snd_midiOutWrite1
  snd_midiOutWrite2
  snd_midiOutWrite3
  snd_midiOutWrite
  snd_midiOutClose
}
