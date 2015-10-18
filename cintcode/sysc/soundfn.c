/*
This contains the implemetation of the sys(Sys_sound, fno, ...) facility.
It was first aimed at alsa sound under Linux, but is now being extend
to run under Win32.

Implemented by Martin Richards (c) August 2008

Specification of res := sys(Sys_sound, fno, a1, a2, a3, a4,...)

Note that this calls soundfn(args, g)
where args[0] = fno, args[1]=a1,... etc
and   g points to the base of the global vector.

fno=0  Test for sound
       res is TRUE if the sound feature is implemented.

fno=1  Open sound wave device for input
       a1 = typically "/dev/dsp", "/dev/dsp1" or a small integer
       a2 = sample format, eg 16 for S16_LE, 8 for U8
       a3 = channels, typically 1 or 2
       a4 = rate ie samples per second, eg 44100
       res is the file (or device) descriptor of the opened device
           or -1 if error.

fno=2  Pause sound wave sampling
       Recently read samples can still be read (to flush the buffered data)

fno=3  Restart sound wave sampling

fno=4  Read samples from a sound wave input device, returning immediately
       a1 = the file (or device) descriptor
       a2 = the buffer
       a3 = the number of bytes to read
       res = the number of bytes transferred into the buffer

fno=5  Close a sound wave input device
       a1 = the file descriptor

fno=6  Open a sound wave device for output
       a1 = typically "/dev/dsp", "/dev/dsp1" or a small integer
       a2 = sample format, eg 16 for S16_LE, 8 for U8
       a3 = channels, typically 1 or 2
       a4 = rate ie samples per second, eg 44100
       res is the file descriptor (an integer) of the opened device
           or -1 if error.

fno=7  Write bytes to a sound wave device
       a1 = the file descriptor
       a2 = the buffer
       a3 = the number of bytes to write
       res = the number of bytes actually transferred, -1 if error

fno=8  Close a sound wave output device
       a1 = the file (or device) descriptor

fno=9  Open a MIDI device for input
       a1 = typically "/dev/midi", "/dev/dmmidi1" or a small integer
       res is the file (or device) descriptor of the opened device
           or -1 if error.

fno=10 Read bytes from a MIDI input device
       a1 = the file (or device) descriptor
       a2 = the buffer
       a3 = the number of MIDI bytes to write
       res = the number of bytes actually transferred
             or -1 if error

fno=11 Close a MIDI input device
       a1 = the file (or device) descriptor

fno=12 Open a MIDI device for output
       a1 = typically "/dev/midi", "/dev/dmmidi1" or a small integer
       res is the file (or device) descriptor of the opened device
           or -1 if error.

fno=13 Write a one byte MIDI message
       a1 = the file descriptor
       a2 = the status byte

fno=14 Write a two byte MIDI message
       a1 = the file descriptor
       a2 = the status byte
       a3 = the second byte

fno=15  Write a three byte MIDI message
       a1 = the file descriptor
       a2 = the status byte
       a3 = the second byte
       a4 = the third byte

fno=16 Write MIDI bytes to a MIDI output device
       a1 = the file descriptor
       a2 = the buffer
       a3 = the number of MIDI bytes to write
       res = the number of bytes actuallty transferred

fno=17 Close a MIDI output device
       a1 = the file (or device) descriptor


Note that it may be necessary to run alsamixer to enable the sound
device and adjust its volume setting.
*/

#if defined(forLinux) || defined(forARM)
/******************** LINUX Version *********************************/
BCPLWORD soundfn(BCPLWORD *args, BCPLWORD *g) {
   
  //printf("soundfn: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
  //        args[0], args[1], args[2], args[3], args[4]);

  switch(args[0]) {
  default:
    return -1;

  case 0:   // Test for sound
    //printf("The Linux sound functions are available\n");
    return -1;

  case 1:  // Open sound wave device for input
    { char *micname = b2c_str(args[1], chbuf1); // Name of microphone device
      int format    = args[2];  // Typically 16 for S16_LE
                                // ie 16-bit signed little ender samples
      int channels  = args[3];  // 1=mono or 2=stereo
      int speed     = args[4];  // Typically 44100 samples per second
      int audio_fd  = -1;
      audio_fd = open(osfname(micname, chbuf2), O_RDONLY, 0); // Returns fd or -1

      if (ioctl(audio_fd, SNDCTL_DSP_SETFMT, &format) == -1) {
        goto rderr;
      }

      if (format != args[2]) {
	//printf("device does not accept this format\n");
        goto rderr;
      }

      if (ioctl(audio_fd, SNDCTL_DSP_CHANNELS, &channels) == -1) {
	//printf("Trouble with SNDCTL_DSP_CHANNELS\n");
	goto rderr;
      }

      if (channels != args[3]) {
	//printf("device does not support %d channels\n", args[3]);
	goto rderr;
      }

      if (ioctl(audio_fd, SNDCTL_DSP_SPEED, &speed) == -1) {
	//printf("Trouble with SNDCTL_DSP_SPEED\n");
	goto rderr;
      }

      return audio_fd;

    rderr:
      close(audio_fd);
      return -1;
    }

  case 2:  // Pause wave input sampling
  case 3:  // Restart wave input sampling
      return -1;

  case 4:  // Read samples from a sound wave input device
    { int audio_fd = args[1];
      char *buf = (char*)(&W[args[2]]);
      int n = args[3];  /* Number of bytes to read */
      int len = read(audio_fd, buf, n);
      return len;  /* Number of bytes actually read or -1 */
    }

  case 5:  // Close sound wave input device
    return close(args[1]);

  case 6: // Open sound wave device for output
    { char *outdevname = b2c_str(args[1], chbuf1);
      int format   = args[2];
      int channels = args[3];
      int speed    = args[4];
      int audio_fd = -1;
      audio_fd = open(osfname(outdevname, chbuf2), O_WRONLY, 0); // Returns fd or -1


      if (ioctl(audio_fd, SNDCTL_DSP_SETFMT, &format) == -1) {
        goto rderr;
      }

      if (format != args[2]) {
	//printf("device does not accept this format\n");
        goto rderr;
      }

      if (ioctl(audio_fd, SNDCTL_DSP_CHANNELS, &channels) == -1) {
	//printf("Trouble with SNDCTL_DSP_CHANNELS\n");
	goto rderr;
      }

      if (channels != args[3]) {
	//printf("device does not support %d channels\n", args[3]);
	goto rderr;
      }

      if (ioctl(audio_fd, SNDCTL_DSP_SPEED, &speed) == -1) {
	//printf("Trouble with SNDCTL_DSP_SPEED\n");
	goto rderr;
      }

      return audio_fd;

    wrerr:
      close(audio_fd);
      return -1;
    }

  case 7:  // Write n bytes of sound samples
    { int audio_fd = args[1];
      char *buf = (char*)(&W[args[2]]);
      int n = args[3];  /* Number of bytes to write */
      int len = write(audio_fd, buf, n);
      return len;  /* Number of bytes written or -1 */
    }

  case 8:  // Close a sound wave output device
    return close(args[1]);


  case 9: // Open MIDI device for input
    { char *mididevname = b2c_str(args[1], chbuf1);
      int audio_fd = -1;

      audio_fd = open(osfname(mididevname, chbuf2), O_RDONLY, 0); // Returns fd or -1

      return audio_fd;
    }

  case 10: // Read n MIDI bytes from a MIDI input device
           // Returns the number of bytes actually read or -1
    { int midi_fd = args[1];
      char *buf = (char*)(&W[args[2]]);
      int n = args[3];  /* Number of bytes to read */
      int len = read(midi_fd, buf, n);
      return len;  /* Number of bytes actually or -1 */
    }

  case 11: // Close a MIDI input device
    return close(args[1]);

  case 12: // Open MIDI device for output
    { char *mididevname = b2c_str(args[1], chbuf1);
      int audio_fd = -1;

      audio_fd = open(osfname(mididevname, chbuf2), O_WRONLY, 0); // Returns fd or -1

      return audio_fd;
    }

  case 13: // Write a one byte MIDI message
    { int midi_fd = args[1];
      char buf[4];
      buf[0] = args[2];
      int len = write(midi_fd, buf, 1);
      return len;  /* Number of bytes written or -1 */
    }

  case 14: // Write a two byte MIDI message
    { int midi_fd = args[1];
      char buf[4];
      buf[0] = args[2];
      buf[1] = args[3];
      int len = write(midi_fd, buf, 2);
      return len;  /* Number of bytes written or -1 */
    }

  case 15: // Write a three byte MIDI message
    { int midi_fd = args[1];
      char buf[4];
      buf[0] = args[2];
      buf[1] = args[3];
      buf[2] = args[4];
      int len = write(midi_fd, buf, 3);
      return len;  /* Number of bytes written or -1 */
    }

  case 16: // Write bytes to a MIDI device
           // Returns the number of bytes actually written or -1
    { int midi_fd = args[1];
      char *buf = (char*)(&W[args[2]]);
      int n = args[3];  /* Number of bytes to write */
      int len = write(midi_fd, buf, n);
      return len;  /* Number of bytes written or -1 */
    }

  case 17:  // Close a MIDI output device
    return close(args[1]);
  }
}
#endif

#ifdef forWIN32
/******************** WIN32 Version *********************************/

/* Declare the Win32 control block structure */

#define INP_BUFFER_SIZE (4096*2/4)
#define OUTP_BUFFER_SIZE (4096*2)

typedef struct waveInCB { /* The wave input control block structure */
  WAVEHDR *pWaveHdr1, *pWaveHdr2;
  PBYTE pBuf1, pBuf2;
  HWAVEIN hWaveIn;
  int currbufno; /* =1 or =2 */
  int pos; // Position of next sample in the current buffer
} waveInCB;

typedef struct waveOutCB { /* The wave output control block structure */
  WAVEHDR *pWaveHdr1, *pWaveHdr2;
  PBYTE pBuf1, pBuf2;
  HWAVEOUT hWaveOut;
  int currbufno; /* =1 or =2 */
  int pos; // Position of next sample to put in the current buffer
} waveOutCB;

struct midiInCB { /* The MIDI input control block structure */
  int n;
};

struct midiOutCB { /* The MIDI input control block structure */
  int n;
};

BCPLWORD soundfn(BCPLWORD *args, BCPLWORD *g) {
  //printf("soundfn: fno=%d a1=%d args[2]=%d args[3]=%d args[4]=%d\n",
  //        args[0], args[1], args[2], args[3], args[4]);

  switch(args[0]) {
  default:
    printf("soundfn: Unknown sound operation %d\n", args[0]);
    return 0;

  case 0:  // Test for sound
    //printf("The Win32 sound functions are available\n");
    return -1; /* Sound is available */

  case 1: // Open Win32 sound wave device for input
    { char *micname = 0;//b2c_str(args[1], chbuf1); // Wave input device
      int format   = args[2];  // Typically 16 for S16_LE
                               // ie 16-bit signed little ender samples
      int channels = args[3];  // 1=mono or 2=stereo
      int speed    = args[4];  // Typically 44100 samples per second

// Allocate control block
// 2 hdrs, 2 bufs waveIn handle
// call waveInOpen
// Set up headers and prepare them
// (The buffers will now begin to fill with samples)
// Return the control block (or -1).

      waveInCB *wicb = (waveInCB*)malloc(sizeof(waveInCB));
      WAVEFORMATEX waveform;

      if(wicb==NULL) {
	printf("Unable to allocate waveInCB\n");
        return -1;
      }

      wicb->pBuf1 = malloc(INP_BUFFER_SIZE);
      wicb->pBuf2 = malloc(INP_BUFFER_SIZE);
      wicb->pWaveHdr1 = malloc(sizeof(WAVEHDR));
      wicb->pWaveHdr2 = malloc(sizeof(WAVEHDR));
      wicb->currbufno = 1;
      wicb->pos = 0;

      // Assume 16 bit mono!!
      waveform.wFormatTag      = WAVE_FORMAT_PCM;
      waveform.nChannels       = channels; // eg 1
      waveform.nSamplesPerSec  = speed;    // eg 44100
      waveform.nAvgBytesPerSec = channels*2*speed;
      waveform.nBlockAlign     = 1;
      waveform.wBitsPerSample  = format; //16;
      waveform.cbSize          = 0;
   
      if(waveInOpen(&(wicb->hWaveIn), WAVE_MAPPER, &waveform, 0, 0, 0)) {
        // Failed to open wave in device
        free(wicb->pBuf1);
        free(wicb->pBuf2);
        free(wicb->pWaveHdr1);
        free(wicb->pWaveHdr2);
        free(wicb);
	printf("Failed to open wave in device\n");
        return -1;
      }

      //printf("Successfully opened waveIn device\n");

      // Setup both headers and prepare them

      wicb->pWaveHdr1->lpData          = wicb->pBuf1;
      wicb->pWaveHdr1->dwBufferLength  = INP_BUFFER_SIZE;
      wicb->pWaveHdr1->dwBytesRecorded = 0;
      wicb->pWaveHdr1->dwUser          = 0;
      wicb->pWaveHdr1->dwFlags         = 0;
      wicb->pWaveHdr1->dwLoops         = 1;
      wicb->pWaveHdr1->lpNext          = NULL;
      wicb->pWaveHdr1->reserved        = 0;

      waveInPrepareHeader(wicb->hWaveIn, wicb->pWaveHdr1, sizeof(WAVEHDR));

      wicb->pWaveHdr2->lpData          = wicb->pBuf2;
      wicb->pWaveHdr2->dwBufferLength  = INP_BUFFER_SIZE;
      wicb->pWaveHdr2->dwBytesRecorded = 0;
      wicb->pWaveHdr2->dwUser          = 0;
      wicb->pWaveHdr2->dwFlags         = 0;
      wicb->pWaveHdr2->dwLoops         = 1;
      wicb->pWaveHdr2->lpNext          = NULL;
      wicb->pWaveHdr2->reserved        = 0;

      waveInPrepareHeader(wicb->hWaveIn, wicb->pWaveHdr2, sizeof(WAVEHDR));

      // Add the buffers

      waveInAddBuffer(wicb->hWaveIn, wicb->pWaveHdr1, sizeof(WAVEHDR));
      waveInAddBuffer(wicb->hWaveIn, wicb->pWaveHdr2, sizeof(WAVEHDR));

      // Begin sampling
      waveInStart(wicb->hWaveIn);

      if(0)
      { int i, oldk1=0, oldf1=0, oldk2=0, oldf2=0;

        for(i=1; i<100000000; i++) {
          int k1 = wicb->pWaveHdr1->dwBytesRecorded;
          int f1 = wicb->pWaveHdr1->dwFlags;
          int k2 = wicb->pWaveHdr2->dwBytesRecorded;
          int f2 = wicb->pWaveHdr2->dwFlags;
          if(oldk1!=k1 || oldf1!=f1 || oldk2!=k2 || oldf2!=f2)
            printf("%10d:  %7d  %8x  %7d %8x\n", i, k1, f1, k2, f2);
          oldk1 = k1;
          oldf1 = f1;
          oldk2 = k2;
          oldf2 = f2;
	}
      }

      return (BCPLWORD)wicb;

      //    rderr:
      //if(wicb) close(wicb->hWaveIn);

      return -1;
    }

  case 2:  // Pause wave input sampling
  case 3:  // Restart wave input sampling
      return -1;

  case 4:  // Read 32-bit samples from a sound wave input device.
           // The 16-bit samples are sign extended.
    { waveInCB *wicb = (waveInCB*) args[1]; // The Wave In control block
      BCPLWORD *v = (BCPLWORD*)(&W[args[2]]); // vector for samples
      int n = args[3];  /* Number of samples to read */
      int len = 0;      // Number of samples tranferred to v so far

      int currbufno = wicb->currbufno;
      WAVEHDR *waveHdr = (WAVEHDR*)(currbufno==1    ?
                                    wicb->pWaveHdr1 :
                                    wicb->pWaveHdr2);

      while(waveHdr->dwFlags & WHDR_DONE) {
        short *buf = (short*)(currbufno==1 ? wicb->pBuf1 : wicb->pBuf2);
        int pos =  wicb->pos;
        int samplecount = (waveHdr->dwBytesRecorded)/2;
        // Copy samples

	//printf("case 4: pos=%d samplecount=%d len=%d n=%d\n",
        //      pos, samplecount, len, n);

        while(pos<samplecount && len<n) {
          v[len++] = buf[pos++];
          //printf("%7d: %6d\n", len, v[len-1]);
	}

        wicb->pos = pos;

        if(pos>=samplecount) {
          waveInAddBuffer(wicb->hWaveIn, waveHdr, sizeof(WAVEHDR));
          // Select the other buffer
          currbufno = 1+2-currbufno;
          wicb->currbufno = currbufno;
          wicb->pos = 0;
          waveHdr = (WAVEHDR*)(currbufno==1    ?
                               wicb->pWaveHdr1 :
                               wicb->pWaveHdr2);
	  //printf("waveInAddBuffer called -- now using buf%d\n", currbufno);
          continue;
        }

        if(len>=n) break;
      }

      return len;  /* Number of samples tranferred */
    }

  case 5:  // Close sound wave input device
    { waveInCB *wicb = (waveInCB*) args[1]; // The Wave In control block
      int currbufno = wicb->currbufno;
      WAVEHDR *waveHdr = (WAVEHDR*)(currbufno==1    ?
                                    wicb->pWaveHdr1 :
                                    wicb->pWaveHdr2);
      int rc;

      //printf("case 5: closing wave in device\n");
      waveInReset(wicb->hWaveIn);

      rc = waveInUnprepareHeader(wicb->hWaveIn,
                                 wicb->pWaveHdr1, sizeof(WAVEHDR));
      if(rc!=MMSYSERR_NOERROR)
        printf("soundfn.c: Unable to UnprepareHeader of Hdr1\n");
      rc = waveInUnprepareHeader(wicb->hWaveIn,
                                 wicb->pWaveHdr2, sizeof(WAVEHDR));
      if(rc!=MMSYSERR_NOERROR)
        printf("soundfn.c: Unable to UnprepareHeader of Hdr2\n");

      free(wicb->pBuf1);
      free(wicb->pBuf2);
      free(wicb->pWaveHdr1);
      free(wicb->pWaveHdr2);
      free(wicb);
      //printf("WAV in device closed\n");

      return -1;
    }

    // **************************  WAVE Output

  case 6: // Open Win32 sound wave device for output
          // rc := sys(Sys_sound, snd_waveOutOpen, dev, format, mode, rate)
    { char *devname = 0;//b2c_str(args[1], chbuf1); // Wave output device
      int format   = args[2];  /* Typically 16 or 8 */
      int channels = args[3];  // 1=mono or 2=stereo
      int speed    = args[4];  // Typically 44100 samples per second
      int bitsPerSample = 16;
      int rc=0;

// Allocate control block
// 2 hdrs, 2 bufs and the waveIn handle
// call waveOutOpen
// Set up the headers and prepare them
// Return the control block (or -1).

      waveOutCB *wocb = (waveOutCB*)malloc(sizeof(waveOutCB));
      WAVEFORMATEX waveform;

      if(wocb==NULL) {
	printf("Unable to allocate waveOutCB\n");
        return -1;
      }

      wocb->pBuf1 = malloc(OUTP_BUFFER_SIZE);
      wocb->pBuf2 = malloc(OUTP_BUFFER_SIZE);
      wocb->pWaveHdr1 = malloc(sizeof(WAVEHDR));
      wocb->pWaveHdr2 = malloc(sizeof(WAVEHDR));
      wocb->currbufno = 1; // Next buffer to used (1 or 2)
      wocb->pos = 0;       // Position of next sample to place in buf

      //printf("Calling waveOutOpen format=%d channels=%d rate=%d\n",
      //        format, channels, speed);
      // Assume 16 bit mono!!
      waveform.wFormatTag      = WAVE_FORMAT_PCM;
      waveform.nChannels       = channels; // eg 1
      waveform.nSamplesPerSec  = speed;    // eg 44100
      waveform.nAvgBytesPerSec = channels*2*speed;
      waveform.nBlockAlign     = 1;
      waveform.wBitsPerSample  = format; //16;
      waveform.cbSize          = 0;
   
      rc = waveOutOpen(&(wocb->hWaveOut), WAVE_MAPPER, &waveform, 0, 0, 0);
      if(rc != MMSYSERR_NOERROR) {
        // Failed to open wave out device
        char mess[256];
        waveOutGetErrorText(rc, mess, 256);
        printf("Error: %s\n", mess);
        free(wocb->pBuf1);
        free(wocb->pBuf2);
        free(wocb->pWaveHdr1);
        free(wocb->pWaveHdr2);
        free(wocb);
	printf("Failed to open wave out device\n");
        return -1;
      }

      //printf("Successfully opened waveOut device\n");

      // Setup both headers and prepare them

      wocb->pWaveHdr1->lpData          = wocb->pBuf1;
      wocb->pWaveHdr1->dwBufferLength  = OUTP_BUFFER_SIZE;
      wocb->pWaveHdr1->dwBytesRecorded = 0;
      wocb->pWaveHdr1->dwUser          = 0;
      wocb->pWaveHdr1->dwFlags         = 0;
      wocb->pWaveHdr1->dwLoops         = 1;
      wocb->pWaveHdr1->lpNext          = NULL;
      wocb->pWaveHdr1->reserved        = 0;

      waveOutPrepareHeader(wocb->hWaveOut, wocb->pWaveHdr1, sizeof(WAVEHDR));
      wocb->pWaveHdr1->dwFlags         |= WHDR_DONE;

      wocb->pWaveHdr2->lpData          = wocb->pBuf2;
      wocb->pWaveHdr2->dwBufferLength  = OUTP_BUFFER_SIZE;
      wocb->pWaveHdr2->dwBytesRecorded = 0;
      wocb->pWaveHdr2->dwUser          = 0;
      wocb->pWaveHdr2->dwFlags         = 0;
      wocb->pWaveHdr2->dwLoops         = 1;
      wocb->pWaveHdr2->lpNext          = NULL;
      wocb->pWaveHdr2->reserved        = 0;

      waveOutPrepareHeader(wocb->hWaveOut, wocb->pWaveHdr2, sizeof(WAVEHDR));
      wocb->pWaveHdr2->dwFlags         |= WHDR_DONE;

      return (BCPLWORD)wocb;

    wrerr:
      if(wocb) close(wocb->hWaveOut);

      return -1;
    }

  case 7:  // Write 32-bit samples to a sound wave output device
           // args[1] is the waveOut control block
           // args[2] is the buffer of 32-bit samples to write
           // args[3] is the number of 32-bit sample to write.
           // If the current buffer can take more samples,  copy data
           // into it.
           // When full call waveOutWrite and swap buffers and hdrs
           // and copy samples into the other buffer if possible, as above.
           // When no more samples can be written, return the number of 
           // samples actually written.
           // If the number of bytes written is less than the number in
           // the data buffer, the caller should delay a while and try again.

    { waveOutCB *wocb = (waveOutCB*) args[1]; // The Wave Out control block
      BCPLWORD *v = (BCPLWORD*)(&W[args[2]]); // vector of samples to write
      int n = args[3];  /* Number of samples to write */
      int len = 0;      // Number of samples tranferred from v so far

      int currbufno = wocb->currbufno;
      WAVEHDR *waveHdr = (WAVEHDR*)(currbufno==1    ?
                                    wocb->pWaveHdr1 :
                                    wocb->pWaveHdr2);

      //printf("Write 32-bit wave samples, currbufno=%d\n", currbufno);
      //printf("dwFlags=%8x\n\n", waveHdr->dwFlags);

      while(waveHdr->dwFlags & WHDR_DONE) {
        short *buf = (short*)(currbufno==1 ? wocb->pBuf1 : wocb->pBuf2);
        int pos =  wocb->pos;
        int samplecount = (waveHdr->dwBufferLength)/2; // Buffer size
        // Copy samples into a device buffer
        //printf("Writing samples\n");

        while(pos<samplecount && len<n) {
          //printf("%10d\n", v[len]);
          buf[pos++] = v[len++];
	}

        wocb->pos = pos;

        if(pos>=samplecount) {
          waveOutWrite(wocb->hWaveOut, waveHdr, sizeof(WAVEHDR));
	  //printf("waveOutWrite called using buf%d\n", currbufno);
          // Select the other buffer
          currbufno = 1+2-currbufno;
          wocb->currbufno = currbufno;
          wocb->pos = 0;
          waveHdr = (WAVEHDR*)(currbufno==1    ?
                               wocb->pWaveHdr1 :
                               wocb->pWaveHdr2);
          continue;
        }

        if(len>=n) break;
      }

      //printf("%d samples written\n", len);
      return len;  /* Number of samples tranferred */
    }

  case 8:  // Close sound wave output device
           // args[1] is zero or the opened wave out control block
           // If zero return TRUE for success
           // othewise
           // Unprepare both hdrs
           // and freevec both hdrs and buffers
           // Return TRUE for success.

    { waveOutCB *wocb = (waveOutCB*) args[1]; // The Wave Out control block
      int currbufno = wocb->currbufno;
      WAVEHDR *waveHdr = (WAVEHDR*)(currbufno==1    ?
                                    wocb->pWaveHdr1 :
                                    wocb->pWaveHdr2);
      int rc;

      //printf("Closing the wave output device\n");

      waveOutReset(wocb->hWaveOut);

      rc = waveOutUnprepareHeader(wocb->hWaveOut,
                                  wocb->pWaveHdr1, sizeof(WAVEHDR));
      if(rc!=MMSYSERR_NOERROR)
        printf("soundfn.c: Unable to UnprepareHeader of Hdr1\n");
      rc = waveOutUnprepareHeader(wocb->hWaveOut,
                                  wocb->pWaveHdr2, sizeof(WAVEHDR));
      if(rc!=MMSYSERR_NOERROR)
        printf("soundfn.c: Unable to UnprepareHeader of Hdr2\n");

      free(wocb->pBuf1);
      free(wocb->pBuf2);
      free(wocb->pWaveHdr1);
      free(wocb->pWaveHdr2);
      free(wocb);
      //printf("soundfn: Wave Out device closed\n");

      return -1;
    }

     // **************************  MIDI Input

  case 9:  // Open a MIDI device for input
    return -1;

  case 10: // Read bytes from a MIDI input device
    return -1;

  case 11: // Close a MIDI input device
    //return close(args[1]);
    return -1;


    // **************************  MIDI Output

  case 12: // Open MIDI device for output
    { HMIDIOUT hMidiOut;
      int rc = midiOutOpen(&hMidiOut, -1, 0, 0, 0); // Using MIDIMAPPER
      //if(rc==0) printf("Successfully opened MIDI output device\n");
      if(rc) { 
        //printf("Unable to open MIDI output device\n");
        return 0;
      }
      rc = midiOutSetVolume(hMidiOut, 0xFFFF); // Set max volume
      //if(rc) printf("Unable to set Midi volume, rd=%d\n", rc);
      //if(rc==MMSYSERR_INVALHANDLE) printf("INVALHANDLE\n");
      //if(rc==MMSYSERR_NOMEM) printf("NOMEM\n");
      //if(rc==MMSYSERR_NOTSUPPORTED) printf("NOTSUPPORTED\n");
      return (BCPLWORD)hMidiOut;
    }

  case 13: // Write a one byte MIDI message
    { HMIDIOUT handle = (HMIDIOUT)args[1];
      DWORD data=0;
      ((char*)&data)[0] = args[2];
      //printf("Writing data = '%8X'\n", data);
      return midiOutShortMsg(handle, data);
    }

  case 14: // Write a two byte MIDI message
    { HMIDIOUT handle = (HMIDIOUT)args[1];
      DWORD data=0;
      ((char*)&data)[0] = args[2];
      ((char*)&data)[1] = args[3];
      //printf("Writing data = '%8X'\n", data);
      return midiOutShortMsg(handle, data);
    }

  case 15: // Write a three byte MIDI message
    { HMIDIOUT handle = (HMIDIOUT)args[1];
      DWORD data=0;
      ((char*)&data)[0] = args[2];
      ((char*)&data)[1] = args[3];
      ((char*)&data)[2] = args[4];
      //printf("Writing data = '%8X'\n", data);
      return midiOutShortMsg(handle, data);
    }

  case 16: // Write (many) bytes to a MIDI output device
           // Typically used only for SysEx messages
           // Returns 0 if successful
    { HMIDIOUT handle = (HMIDIOUT)args[1];
      MIDIHDR midiHdr;
      UINT    err;
      int i;
      char *buf = (char*)(&W[args[2]]);
      int n = args[3];  /* Number of bytes to write */

      midiHdr.lpData = (LPBYTE)buf;
      midiHdr.dwBufferLength = n;
      midiHdr.dwFlags = 0;

      err = midiOutPrepareHeader(handle, &midiHdr, sizeof(MIDIHDR));
      if(!err) {
        // output the SysEx message
        err = midiOutLongMsg(handle, &midiHdr, sizeof(MIDIHDR));
        while(MIDIERR_STILLPLAYING ==
	      midiOutUnprepareHeader(handle, &midiHdr, sizeof(MIDIHDR))) {
          Sleep(10);
        }
      }
      return err;
    }

  case 17: // Close MIDI output device
      midiOutClose((HMIDIOUT)args[1]);
      return 0;
  }
}
#endif



