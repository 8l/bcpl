// (C) Copyright 1992 Martin Richards

// Command to map the store allocation under the Cintpos system.
// It counts the store used for its own code, stack
// and workspace as free.
//
// It is based on the map command from the Tripos Operating System
//
// MAP [BLOCKS] [CODE] [NAMES] [MAPSTORE] [TO file]
//     [PIC]
//
//     BLOCKS gives size and address of every block
//     CODE   gives layout of loaded code sections
//     NAMES  gives space used for routine names,
//            section names, and global initialisation info.
//     TO     specifies an output file
//     PIC    gives the allocation map in picture form

SECTION "MAP"

GET "libhdr"

MANIFEST $(
         maxpri    = maxint

         sectnamesize 	= (11 + bytesperword)/bytesperword
         routnamesize 	= (11 + bytesperword)/bytesperword
         nameoffset 	= -routnamesize
         vecupb 	= 5000
         $)

LET start() = VALOF
$(  LET blocklist 	= 0 //rootnode ! rtn_blklist
    LET a 		= blocklist
    LET topofstore 	= rootnodeaddr ! rtn_memsize // * 1024
    LET free, used, n 	= 0, 0, 0
    LET blocks 		= getvec(vecupb)
    LET argv 		= VEC 50
    LET largest_free 	= 0
    LET joinfree 	= 0
    LET blocksopt 	= FALSE
    LET namesopt 	= FALSE
    LET codeopt 	= FALSE
    LET mapstore 	= FALSE
    LET picopt 		= FALSE
    LET mapstack 	= currco - 1  // stackbase - 1
    LET mapcode  	= cli_module-1  // Section vector
    LET sectnames, routnames, globinit = 0, 0, 0
    LET constr 		= output()
    LET outstr 		= 0
    LET rdargs_string	= "BLOCKS/S,NAMES/S,CODE/S,MAPSTORE/S,TO/K,PIC/S"

    IF rdargs(rdargs_string, argv, 50) = 0 DO
    $( writef("MAP: Bad args for key string *"%S*"*N", rdargs_string)
       freevec(blocks)
       RESULTIS 20
    $)

    IF blocks = 0 DO
    $( writes("MAP: Not enough store for workspace*N")
       RESULTIS 20
    $)

    blocksopt := argv!0
    namesopt := argv!1
    codeopt := argv!2
    IF argv!3 DO mapstore, codeopt, namesopt := TRUE, TRUE, TRUE
    IF argv!4 DO
    $( outstr := findoutput(argv!4)
       IF outstr = 0 DO
       $( writef("Can't open %S*N", argv!4)
          freevec(blocks)
          RESULTIS 20
       $)
       selectoutput(outstr)
    $)

    picopt := argv!5

    // Take highest task priority for critical section
    // (Should always be available if we are running)
    //changepri(taskid, maxpri)

    UNTIL !a = 0 DO
    $( LET size = !a
       LET next = ?
       IF a = mapstack | a = mapcode | a = blocks-1 DO
          size := size + 1 // Make it look free

       blocks!n := size; n := n + 1
       TEST (size & 1) = 0
       THEN $( // Used block
               used := used + size
               IF joinfree > largest_free
               THEN largest_free := joinfree
               joinfree := 0
            $)
       ELSE $( size := size-1
               free := free + size
               joinfree := joinfree + size
            $)

       next := a + size
       UNLESS size>=0 & next<=topofstore DO
       $( //changepri(taskid, oldpri)
          writef("******Store chain corrupt!!*N*
                 *Noticed at %n*n", a)
          BREAK
       $)
       a := next
       IF n > vecupb DO
       $( writef("*N****** Too many blocks for MAP's workspace*N*
                 ******* Only the first %N mapped*N", vecupb+1)
          BREAK
       $)
    $)

    IF joinfree > largest_free DO largest_free := joinfree

    //changepri(taskid, oldpri)

    // Now print what we've found
    newline()

    IF blocksopt DO
    $( writes("Map of free and allocated store*N*N")

       a := blocklist

       FOR i = 0 TO n-1 DO
       $(   LET s = blocks!i
            LET free = (s&1)=1

            //IF testflags(1) GOTO exit

            writef("%i8: ", a)
            TEST free
            THEN $( writes("free ") ; s := s - 1 $)
            ELSE    writes("alloc")

            writef("%i8 words", s)
            IF a = mapstack     DO writes(" MAP's stack")
            IF a = mapcode      DO writes(" MAP's code")
            IF a = (blocks-1)   DO writes(" MAP's workspace")
            IF a = (rootnode-1) DO writes(" Rootnode")
            IF a!3 = sectword  & (a+4)%0 = 11  DO
                                writef(" Section %s", a+4)
            newline()
            a := a + s
       $)

       writef("Top of block list = %n*n", a)
       topofstore := a
    $)

    writef("Largest contiguous free area: ")
    writeu(largest_free, 0); writes(" words*n")
    writes("Totals: "); writeu(used+free, 0)
    writes(" words available, "); writeu(used, 0)
    writes(" used, "); writeu(free, 0)
    writes(" free*n*n")

    IF picopt DO
    $( // Print as a picture
       LET alloc = TRUE
       LET next_block = blocklist
       LET num=0
       LET col = 0
       LET grainsize = topofstore/(20*64) + 1
       LET addr = 0

       WHILE addr < topofstore DO
       $( LET some_alloc = alloc
          LET some_free  = NOT alloc

          UNTIL addr <= next_block | num > n DO
          $( // Move to next block
             alloc := ((blocks!num) & 1) = 0
             TEST alloc THEN some_alloc := TRUE
                        ELSE $( some_free := TRUE
                                next_block := next_block - 1
                             $)
             next_block := next_block + blocks!num
             num := num+1
          $)

          IF col REM 64 = 0 DO writef("*n%i8  ", addr)
          wrch (num > n -> '?',  // No info
                some_alloc   -> (some_free -> 'a', '@'), '.')
          col, addr := col+1, addr+grainsize
       $)
       newline()
    $)

   // Print the layout of the code sections, assuming
   // that they will not change under our feet!
   // Also, add up space used for section names, routine
   // names, and global initialisation information.

   a := blocklist

   IF codeopt | namesopt DO
   $(   IF codeopt THEN writes("Layout of loaded code*N*N")

        FOR i = 0 TO n-1 DO
        $( LET s = blocks!i
           //IF testflags(1) THEN BREAK
           IF (s&1)=1
           THEN $( a := a+s-1; LOOP $) // Free block

           IF a!3=sectword & (a+4)%0=11 DO
           $( // We've found a BCPL section
              LET goffset = ?

              IF codeopt DO
                writef("*n%i8: Section %S - length %i5 words*n",
                          a+2,        a+4,         a!2)

              sectnames := sectnames + sectnamesize + 1

              // Count space for global initialisation
              // table
              goffset := a+2 + a!2 // Word after highest
                                   // referenced global
              $( globinit := globinit+2
                 goffset  := goffset-2
              $) REPEATUNTIL !goffset=0 // End of list

              IF namesopt FOR j=5 /* skip some junk! */ TO a!2 DO
              $( LET addr = a+j // Avoid comparing signed addresses

                 IF addr!(nameoffset-1) = entryword &
                    good_routine_name(addr + nameoffset) DO
                 $( // BCPL entry sequence
                    routnames := routnames + routnamesize + 1
                    IF mapstore DO
                      writef("%i8: %S*N", addr, addr+nameoffset)
                 $)
              $)
           $)
           a := a+s // Point to next block
        $)

        IF namesopt DO writef("*NRoutine names: %I5 words*N*
                              *Section names: %I5 words*N*
                              *Global initialisation info: %N words*N",
                               routnames, sectnames, globinit)
   $)

exit:
   freevec(blocks)
   UNLESS outstr = 0 THEN endwrite()
   selectoutput(constr)
  RESULTIS 0
$)


AND good_routine_name(string) = VALOF
$( UNLESS string%0 = 11 RESULTIS FALSE

   FOR i = 1 TO 11 DO
   $( LET ch = string%i

      UNLESS 'A'<=ch<='Z' | 'a'<=ch<='z' | '0'<=ch<='9' |
             ch='.' | ch='_' | ch=' ' | ch='*'' RESULTIS FALSE
   $)

   RESULTIS TRUE
$)
