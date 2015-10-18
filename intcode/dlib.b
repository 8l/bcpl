// This is DLIB (system dependent library) for single threaded
// Cintcode BCPL

// It contains functions that have different definitions in Cintpos

/*
Change log

9/11/06
Change treatment of RUBOUT (#x7F)

*/

SECTION "DLIB"

GET "libhdr"

MANIFEST {
  char_bs = 8
  buflen  = 4096 // Must equal the block size
}

LET findstream(name, id, path) = VALOF // MR 8/5/03
{ LET console = compstring("**", name)=0
  LET scb = ?
  LET res = 0
  LET prefix = VEC 31

//TEST path
//THEN sawritef("DLIB: findstream(%s, %n, %s)*n", name, id, path)
//ELSE sawritef("DLIB: findstream(%s, %n, 0)*n", name, id)
//sawritef("DLIB: currentdir=%n*n", currentdir)

  IF console DO
  { IF id=id_inscb & rootnode!rtn_keyboard RESULTIS rootnode!rtn_keyboard
    IF id=id_outscb & rootnode!rtn_screen  RESULTIS rootnode!rtn_screen
  } 

  scb := getvec(scb_upb)
  UNLESS scb RESULTIS 0

  FOR i = 0 TO scb_upb DO scb!i := 0

  scb!scb_id := id  // id_inscb, id_outscb, id_inoutscb or id_appendscb

  // Copy (truncated) stream name into the scb
  { LET len = name%0
    LET scbname = @scb!scb_name
    LET maxlen = scb_maxnamelen
    IF len>scb_maxnamelen DO len := scb_maxnamelen
    FOR i = 1 TO len DO scbname%i := name%i
    scbname%0 := len
  }

  IF console DO
  { // Console stream being opened for the first time
    LET buf = getvec(4095/bytesperword) // Room for 4096 bytes
    UNLESS buf DO { freevec(scb); RESULTIS 0 }
    scb!scb_type    := scbt_console
    scb!scb_buf     := buf
    scb!scb_bufend  := 4096

    IF id=id_inscb DO
    { scb!scb_rdfn   := cnslrdfn // fn to replenish current buffer
      rootnode!rtn_keyboard := scb
      RESULTIS scb
    }
    IF id=id_outscb DO
    { scb!scb_wrfn   := cnslwrfn // fn to output current buffer
      rootnode!rtn_screen := scb
      RESULTIS scb
    }
    // Bad stream id
    freevec(scb)
    RESULTIS 0
  }

  splitname(prefix, ':', name, 1)
  IF compstring(prefix, "NIL")=0 DO
  { // On reading always gives endstreamch
    // On writing always throws away the data
    scb!scb_wrfn    := nilrdfn
    scb!scb_endfn   := nilwrfn
//sawritef("DLIB: Opening stream to/from NIL:*n")
    RESULTIS scb 
  }

  IF compstring(prefix, "TCP")=0 | compstring(prefix, "NET")=0 DO
  { sawritef("TCP connections not yet available*n")
    freevec(scb)
    RESULTIS 0
  }

  // Open a file stream
//sawritef("DLIB: %s must be a file*n", name)

  IF id=id_inscb     & fh0findinput   (scb, name, path) RESULTIS scb
  IF (id=id_outscb | id=id_appendscb) &
                       fh0findoutput  (scb, name)       RESULTIS scb
  IF id=id_inoutscb  & fh0findinoutput(scb, name)       RESULTIS scb

  freevec(scb)
  RESULTIS 0
}

AND nilrdfn(scb) = FALSE

AND nilwrfn(scb) = VALOF
{ scb!scb_pos := 0 // Throw away the buffer contents (if any)
  RESULTIS TRUE
}

AND cnslrdfn(scb) = VALOF
{ LET buf, p = scb!scb_buf, 0

//sawritef("DLIB: cnslrdfn: scb=%n*n", scb)
  { LET ch = sys(Sys_sardch)
    SWITCHON ch INTO
    { DEFAULT:          buf%p := ch
                        p := p+1
                        IF p<4096 LOOP
                        BREAK

      CASE endstreamch: IF p BREAK
                        // No characters in the buffer
                        result2 := endstreamch // =-1
                        RESULTIS FALSE

      CASE '*n':        buf%p := ch
                        p := p+1
                        BREAK

      CASE #x7F:        // Rubout
                        sys(Sys_sawrch, char_bs)
      CASE char_bs:     // Backspace -- already echoed
                        sys(Sys_sawrch, ' ')     // MR 9/11/06
                        sys(Sys_sawrch, char_bs)
                        IF p>0 DO p := p-1
                        LOOP
    }
  } REPEAT
//sawritef("DLIB: cnslrdfn: line read*n")
//FOR i = 0 TO p-1 DO sawrch(buf%i)
  scb!scb_pos, scb!scb_end := 0, p
  RESULTIS TRUE
}

AND cnslwrfn(scb) = VALOF
{ LET buf = scb!scb_buf
//sawritef("DLIB: cnslwrfn(%n) called*n", scb)
//sawritef("DLIB: cnslwrfn: buf=%n pos=%n end=%n*n",
//          scb!scb_buf, scb!scb_pos, scb!scb_end)

  FOR i = 0 TO scb!scb_pos-1 DO sys(Sys_sawrch, buf%i)
  scb!scb_pos := 0
  scb!scb_end := 0  // No valid data
  RESULTIS TRUE
}

AND flush() = VALOF
{ IF cos=0 | cos!scb_id~=id_outscb DO abort(187)
  RESULTIS fh0wrfn(cos)
}  

AND getremipaddr(scb) = VALOF
{
sawritef("DLIB: getremipaddr not yet available*n")
RESULTIS 0
   UNLESS scb!scb_type=scbt_tcp | scb!scb_type=scbt_net DO
  { result2 := 0
    RESULTIS 0
  }
  RESULTIS 0 //sendpkt(-1, scb!scb_task, Action_getremipaddr, 0,0, scb)
}

AND relfilename(name) = VALOF
{ // Absolute file names are (eg):
  //  "/abc"    "\xyz"   "pqr:vuw"
  LET len = name%0
  UNLESS len RESULTIS TRUE
  IF name%1='/' | name%1='\' RESULTIS FALSE
  FOR i = 1 TO len IF name%i=':' RESULTIS FALSE
  RESULTIS TRUE
}

AND trfilename(name, filename) BE
{ LET p = 0

//IF currentdir DO
//   sawritef("DLIB: trfilename: name=%s currentdir=%n*n", name, currentdir)

  IF currentdir & relfilename(name) DO
  { LET len = currentdir%0
    LET lastch = currentdir%len
    IF lastch='/' | lastch=':' DO len := len-1
    IF len DO
    { FOR i = 1 TO len DO { p :=  p+1; filename%p := currentdir%i }
      p := p+1
      filename%p := '/'
    }
  }
  FOR i = 1 TO name%0 DO { p :=  p+1; filename%p := name%i }
  filename%0 := p
  //FOR i = 1 TO p IF filename%i=':' DO filename%i := '/'
//TEST currentdir
//THEN sawritef("DLIB: trfilename %s %s => %s*n", currentdir, name, filename)
//ELSE sawritef("DLIB: trfilename %s => %s*n", name, filename)
}

AND fh0findinput(scb, name, path) = VALOF
// Returns TRUE   if successful
// Returns FALSE, result2=100  Can't open file
//                result2=101  Can't allocate buffer
{ LET fp, buf = 0, 0
  LET filesize = 0
  LET filename = VEC 50
  trfilename(name, filename)

//sawritef("DLIB: fh0findinput calling sys_openread %s %s*n",
//          filename, path->path,"null")
  // Open the file for input
  fp := sys(Sys_openread, filename, path)  // MR 8/5/03
  UNLESS fp DO
  {
//sawritef("DLIB: fh0findinput sys_openread %s failed*n", filename)
    result2 := 100
    RESULTIS FALSE
  }

//sawritef("DLIB: %s opened*n", filename)
  filesize :=sys(Sys_filesize, fp)
//sawritef("DLIB: filesize=%n*n", filesize)

  // allocate a buffer
  buf := getvec(buflen/bytesperword)
  UNLESS buf DO
  { sys(Sys_close, fp) // First close the file
    result2 := 101
    RESULTIS 0
  }
//sawritef("DLIB: fh0findinput scb %n fp %n buf %n*n", scb, fp, buf)
    
  scb!scb_type    := scbt_file
  scb!scb_task    := 0
  scb!scb_buf     := buf
  scb!scb_rdfn    := fh0rdfn
  scb!scb_wrfn    := 0       // An input stream cannot be depleted
  scb!scb_endfn   := fh0endfn
  scb!scb_fd      := fp
  scb!scb_bufend  := buflen
  scb!scb_write   := FALSE   // No data waiting to be written
  scb!scb_blength := buflen  // MR 15/3/02
  scb!scb_block   := 0       // MR 29/7/02
  scb!scb_lblock  := filesize/buflen //+ 1  // MR 16/4/02 MR 29/7/02
  scb!scb_ldata   := filesize REM buflen  // MR 16/4/02
//sawritef("fh0findinput: lblock=%n*n", scb!scb_lblock)

  // Initialise the buffer by reading the first block
  fh0getbuf(scb)
  RESULTIS scb
}

AND fh0findoutput(scb, name) = VALOF
// Returns TRUE   if successful
// Returns FALSE, result2=100  Can't open file
//                result2=101  Can't allocate buffer
{ LET fp, buf = 0, 0
  LET sysop = scb!scb_id=id_appendscb -> Sys_openappend, Sys_openwrite
  LET filename = VEC 50
  trfilename(name, filename)

  // Open the file for output
  fp := sys(sysop, filename)
  UNLESS fp DO
  { result2 := 100
    RESULTIS FALSE
  }

  // allocate a buffer
  buf := getvec(buflen/bytesperword)
  UNLESS buf DO
  { sys(Sys_close, fp) // First close the file
    result2 := 101
    RESULTIS FALSE
  }

//sawritef("DLIB: fh0findoutput scb %n  %n  buf %n*n", scb, fp, buf)

  scb!scb_type    := scbt_file
  scb!scb_task    := 0
  scb!scb_buf     := buf
  scb!scb_rdfn    := 0       // Can't replenish output streams
  scb!scb_wrfn    := fh0wrfn
  scb!scb_endfn   := fh0endfn
  scb!scb_fd      := fp
  scb!scb_bufend  := buflen
  scb!scb_write   := FALSE   // No data waiting to be written
  scb!scb_blength := buflen
  scb!scb_block   := 0       // MR 29/7/02
  scb!scb_lblock  := 0       // This is an empty file currently, MR 29/7/02
  scb!scb_ldata   := 0
//sawritef("fh0findoutput: lblock=%n*n", scb!scb_lblock)

  scb!scb_pos     := 0       // The buffer has no valid data initially
  scb!scb_end     := 0

  result2 := 0
  RESULTIS TRUE
}

AND fh0findinoutput(scb, name) = VALOF
// Returns TRUE   if successful
// Returns FALSE, result2=100  Can't open file
//                result2=101  Can't allocate buffer
{ LET fp, buf, res1, res2 = 0, 0, 1, 0
  LET filesize = 0
  LET filename = VEC 50
  trfilename(name, filename)

  // open the file for input and output
  fp := sys(Sys_openreadwrite, filename)
//sawritef("DLIB: open %s in inout mode => %n*n", filename, fp)
  UNLESS fp DO
  { result2 := 100
    RESULTIS FALSE
  }

  filesize :=sys(Sys_filesize, fp)
//sawritef("BLIB: filesize=%n*n", filesize)

  // allocate a buffer
  buf := getvec(buflen/bytesperword)
  UNLESS buf DO
  { sys(Sys_close, fp) // First close the file
    result2 := 101
    RESULTIS FALSE
  }
//sawritef("DLIB: buflen = %n*n", buflen)
//sawritef("DLIB: fh0findinoutput scb %n  %n  buf %n*n", scb, fp, buf)

  scb!scb_type    := scbt_file
  scb!scb_buf     := buf
  scb!scb_rdfn    := fh0rdfn
  scb!scb_wrfn    := fh0wrfn
  scb!scb_endfn   := fh0endfn
  scb!scb_fd      := fp
  scb!scb_bufend  := buflen
  scb!scb_write   := FALSE   // No data waiting to be written
  scb!scb_blength := buflen  // MR 15/3/02
  scb!scb_block   := 0 //1 MR 29/7/02
  scb!scb_lblock  := filesize/buflen //+ 1  // MR 16/4/02 MR 29/7/02
  scb!scb_ldata   := filesize REM buflen  // MR 16/4/02
//sawritef("fh0findinoutput: lblock=%n*n", scb!scb_lblock)

  // Initialise the buffer by reading the first block
  UNLESS fh0getbuf(scb) DO
  { // Failed to fill the buffer with data
    sawritef("DLIB: fh0getbuf(%n) failed*n", scb)
    RESULTIS FALSE
  }
  res2 := result2
  RESULTIS TRUE
}

AND fh0falsefn(scb)  = FALSE


AND fh0rdfn(scb)  = VALOF
// This is only used for disc files. The field end will equal
// buflen for all blocks except possibly the last one.
// If the buffer contains data from the last block and pos=end,
// then EOF has been reached. If pos=end data from the next block
// must be read. But the current block will first have to be
// written to disc, if the write field is TRUE.
// Returns TRUE,  if successful. There will be valid data between
//                pos and end in the buffer.
// Returns FALSE, result2=-1 on EOF
//         FALSE, result2=errorcode, otherwise.
{ LET block, lblock = scb!scb_block, scb!scb_lblock
  LET pos,   end    = scb!scb_pos,   scb!scb_end
//sawritef("DLIB: fh0readfn scb %n pos %n end %n*n", scb, pos, end)
//sawritef("DLIB: fh0readfn block %n lblock %n*n", block, lblock)
  IF pos<end      RESULTIS TRUE  // Data still available in current buffer
  IF block=lblock DO { result2 := -1; RESULTIS FALSE } // End-of-file

  IF scb!scb_write DO fh0putbuf(scb)  // Write block if necessary

  IF end>=buflen DO block := block+1  // Advance block if necessary
  scb!scb_block, scb!scb_pos := block, 0
//sawritef("DLIB: fh0rdfn block %n pos %n end %n*n", scb!scb_block, pos, end)

  UNLESS fh0getbuf(scb) DO
  { sawritef("DLIB: fh0getbuf(%n) failed*n", scb)
    RESULTIS FALSE  // Read data into the buffer
  }

  // Safety check
  end := scb!scb_end
  UNLESS end=buflen | lblock = scb!scb_block DO
  { sawritef("DLIB: fh0rdfn block=%n lblock=%n pos=%n end=%n*n",
              scb!scb_block, lblock, scb!scb_pos, end)
    abort(9999)
  }
  
  RESULTIS TRUE              // The buffer is not empty
}  
   
AND fh0wrfn(scb) = VALOF
// Write the current buffer to file, if the write flag is set
// Return TRUE, if successful
// Return FALSE otherwise.
{ LET block, lblock = scb!scb_block, scb!scb_lblock
  LET pos, end = scb!scb_pos, scb!scb_end
  LET len = ?
//sawritef("DLIB: fh0wrfn scb %n pos %n end %n*n", scb, pos, end)
//sawritef("DLIB: fh0wrfn block %n lblock %n*n", block, lblock)
  IF scb!scb_write DO // Write current block if necessary
    UNLESS fh0putbuf(scb) RESULTIS FALSE

//  IF pos<scb!scb_bufend DO
//sawritef("DLIB: return0 from fh0wrfn block=%n lblock=%n pos=%n end=%n*n",
//          scb!scb_block, scb!scb_lblock, pos, end)

  IF pos < scb!scb_bufend RESULTIS TRUE  // Still room in the buffer
  // Move to next block
  block := block+1
  scb!scb_block, scb!scb_pos, scb!scb_end := block, 0, 0
  IF block>lblock DO
  { scb!scb_lblock := block    // Last block is empty
//sawritef("DLIB: return1 from fh0wrfn block=%n lblock=%n pos=%n end=%n*n",
//          scb!scb_block, scb!scb_lblock, pos, end)
    RESULTIS TRUE
  }

  IF scb!scb_id=id_inoutscb UNLESS fh0getbuf(scb) DO
  { sawritef("DLIB: fh0wrfn getbuf failed block=%n lblock=%n pos=%n end=%n*n",
              scb!scb_block, scb!scb_lblock, pos, end)
    abort(1102)
  }

//sawritef("DLIB: return2 from fh0wrfn block=%n lblock=%n pos=%n end=%n*n",
//          scb!scb_block, scb!scb_lblock, pos, end)

  RESULTIS TRUE
}  

   
AND fh0endfn(scb) = VALOF
// Write the buffer, if necessary, and free it.
// Close the file.
// Return TRUE, if successful
// Return FALSE otherwise.
{
//sawritef("DLIB: fh0endfn scb %n, write flag=%n*n", scb, scb!scb_write)
//sawritef("DLIB: fh0endfn pos=%n end=%n*n", scb!scb_pos, scb!scb_end)
  IF scb!scb_write UNLESS fh0putbuf(scb) RESULTIS FALSE
//sawritef("DLIB: fh0endfn freeing buf=%n*n", scb!scb_buf)
  freevec(scb!scb_buf)
  RESULTIS sys(Sys_close, scb!scb_fd)
}

// Result TRUE: posv contains the stream block and pos
//       FALSE: scb was not a file or RAM stream
AND note(scb, posv) = VALOF
{ LET type = scb!scb_type
  UNLESS type=scbt_file | type=scbt_ram RESULTIS FALSE
  posv!0 := scb!scb_block
  posv!1 := scb!scb_pos
//sawritef("DLIB: note => %n %n*n", posv!0, posv!1)
  RESULTIS TRUE
}

// Set the stream position to that specified in posv.  If the
// new position is in a different block the buffer may have to
// be written out and new data read in.
// It returns TRUE if successful, even if positioned just after the
// last block of the file, ie block=lblock+1 and pos=end=0.
// It returns FALSE, otherwise. Possibly because the stream is not
// pointable or the posv is out of range.
AND point(scb, posv) = VALOF
{ LET blkno  = posv!0
  LET pos    = posv!1
  LET id     = scb!scb_id
  LET block  = scb!scb_block   // Current block number
  LET lblock = scb!scb_lblock  // Last block number of the stream
  LET end    = scb!scb_end
  LET type   = scb!scb_type
//sawritef("DLIB: point posv!0=%n posv!1=%n*n", posv!0, posv!1)

//sawritef("DLIB: point block=%n lblock=%n blkno=%n pos=%n end=%n*n",
//               block, lblock,  blkno, pos, end)

   // The stream must be a readable disc or RAM file
  UNLESS (type=scbt_file | type=scbt_ram) &
         (id=id_inscb | id=id_inoutscb) RESULTIS FALSE

  IF pos=0 & blkno=lblock+1 DO blkno, pos := lblock, buflen
 
//sawritef("DLIB: point block=%n lblock=%n blkno=%n pos=%n end=%n*n",
//               block, lblock,  blkno, pos, end)

//  IF blkno<=0 DO blkno, pos := 0, 0 // Cannot position before start of file

  // Safety check
  // Make sure the position is within the file
  IF blkno<0 | 
     blkno>lblock |
     blkno=lblock & pos > (block=lblock -> end, scb!scb_ldata)  DO
  { sawritef("DLIB: point beyond end of file, blkno=%n pos=%n*n", blkno, pos)
    sawritef("block=%n end=%n lblock=%n posv=(%n,%n)*n",
              block, end, lblock, posv!0, posv!1)
    abort(999)
    RESULTIS FALSE
  }

  IF blkno=block DO
  { // The new position is in the current block
    scb!scb_block := blkno
    scb!scb_pos   := pos
//sawritef("DLIB: point setting scb block=%n pos=%n*n", blkno, pos)
    RESULTIS TRUE // Success
  }

  // The move is to a different block, so must read a block
  // but first check if the current block must be written
  IF scb!scb_write DO
  { //sawritef("DLIB: point write block %n*n", scb!scb_block) 
    UNLESS fh0putbuf(scb) DO abort(5003)
  }

  scb!scb_block := blkno  // Set the new position
 
//sawritef("DLIB: point read block %n*n", blkno)

  UNLESS fh0getbuf(scb) DO
  { sawritef("DLIB: point fh0getbuf failed block %n => %n*n", blkno, end)
    abort(5004)
    RESULTIS FALSE
  }

  // Safety check
  UNLESS scb!scb_end=buflen |
         blkno=lblock & end>=scb!scb_ldata DO
  { sawritef("DLIB point: safety check failed*n")
    sawritef("DLIB point: blkno %n pos %n*n", blkno, pos)
    sawritef("DLIB point: end %n buflen %n*n", scb!scb_end, buflen)
    sawritef("DLIB point: block %n lblock %n*n", blkno, lblock)
    sawritef("DLIB point: end %n ldata %n*n", end, scb!scb_ldata)
    abort(5005)
  }

  scb!scb_pos   := pos  // Set the desired offset

//sawritef("DLIB: point(..) => TRUE, blkno %n pos %n*n", blkno, pos)
  RESULTIS TRUE
}

AND fh0putbuf(scb) = VALOF
// This is only used on disc file streams and is only called when
// the write field is TRUE. It writes the buffer to file.
// The file is positioned before the write. If the last block
// is being written ldata is set to end and this number of bytes written
// to disc. (For all other blocks end=buflen.)
// Returns TRUE, if successful, having set the write field to FALSE.
// Returns FALSE, otherwise.
{ LET end    = scb!scb_end    // Number of bytes of valid data in buf
  LET block  = scb!scb_block
  LET fd     = scb!scb_fd
  LET offset = buflen*block   // File offset of buffer's first byte MR 29/7/02

  IF end<=0 DO
  { // Nothing in the buffer to write, probably a mistake.
    //sawritef("DLIB: fh0putbuf, end=%n*n", end)
    scb!scb_write := FALSE
    RESULTIS TRUE
  }

  // The size of a file can only change when writing its last block
  // so ldata only needs correcting when this happens
  IF block = scb!scb_lblock DO scb!scb_ldata := end

//sawritef("DLIB: putbuf seeking offset %n (block %n)*n", offset, block)
  UNLESS sys(Sys_seek, fd, offset) RESULTIS FALSE

//sawritef("DLIB: putbuf write %n bytes at offset %n*n", end, offset)
  IF sys(Sys_write, fd, scb!scb_buf, end) < 0
    RESULTIS FALSE
  scb!scb_write := FALSE // The buffer has been written successfully
  RESULTIS TRUE
}

// fh0getbuf reads a block into the scb's buffer.
// Returns TRUE if successful
//      having set pos=0 and end to the end of valid data
// Returns FALSE, otherwise.

AND fh0getbuf(scb) = VALOF
{ LET fd      = scb!scb_fd
  LET block   = scb!scb_block   // Block number (>=0)
  LET offset  = buflen*block    // MR 29/7/02
  LET end     = ? 

//sawritef("DLIB: fh0getbuf seeking start of block %n (offset %n)*n",
//            block, offset)
  UNLESS sys(Sys_seek, fd, offset) RESULTIS FALSE
//sawritef("DLIB: fh0getbuf file position now %n*n", sys(Sys_tell, fd))

//sawritef("DLIB: fh0getbuf reading block %n offset=%n*n", block, offset)
  end := sys(Sys_read, fd, scb!scb_buf, buflen)
//sawritef("DLIB: fh0getbuf read => %n*n", end)
//sawritef("DLIB: fh0getbuf block=%n lblock=%n ldata=%n*n",
//               block, scb!scb_lblock, scb!scb_ldata)
  IF end<0 RESULTIS FALSE // Unable to read
  scb!scb_pos, scb!scb_end := 0, end 
  RESULTIS TRUE
}

AND delay(ms) = sys(Sys_delay, ms)

/*
AND delay(ms) = VALOF
{ LET days, msecs = ?, ?
  MANIFEST { msperday = 24*60*60*1000 }
  datstamp(@days)
//sawritef("delay: time now       days=%i5 msecs=%n*n", days, msecs)
  msecs := msecs+ms
  IF ms>msperday DO days, msecs := days+1, msecs-msperday
//sawritef("delay: delaying until days=%i5 msecs=%n*n", days, msecs)
  RESULTIS delayuntil(days, msecs)
}
*/

AND delayuntil(days, msecs) BE
{ LET ds, ms = 0, 0
  datstamp(@ds)
  IF ds<days RETURN
  IF ds=days & ms<=msecs RETURN
  sys(Sys_delay, 1) // Sleep for 1 msec
} REPEAT



