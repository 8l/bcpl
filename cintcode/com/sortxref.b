/*
This is a program to sort raw xref data into alpabetical order
removing duplicates.

Implemented by Martin Richards (c) 3 April 2009

*/

GET "libhdr"

GLOBAL {
  fromname: ug
  toname
  fromstream
  tostream
  stdin
  stdout
  blklist  // List of 4096 word block to hold the sorted binary
           // tree of xref lines.
  tree     // The root of the binary tree of nodes.
  optfns
}

MANIFEST {
  blkupb = 4095
}

LET start() = VALOF
{ LET format = "from/a,to/k,fns/s"
  LET argv = VEC 50
  LET linev = VEC 256/bytesperword

  blklist := 0
  tree := 0
  stdin, stdout := input(), output()
  fromstream, tostream := 0, 0
  fromname, toname := "**", "**"

  UNLESS rdargs(format, argv, 50) DO
  { writef("Bad argument for format: %s*n", format)
    RESULTIS 0
  }

  fromname := argv!0
  fromstream := findinput(fromname)
  UNLESS fromstream DO
  { writef("Unable to read file: %s*n", fromname)
    RESULTIS 0
  }

  IF argv!1 DO
  { toname := argv!1
    tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("Unable to output to file: %s*n", toname)
      RESULTIS 0
    }
  }

  optfns := argv!2

  writef("*nsorting xrefs from %s to %s*n", fromname, toname)
  selectinput(fromstream)

  WHILE rdline(linev) IF filter(linev) DO insertnode(linev)

  IF tostream DO selectoutput(tostream)
  prtree(tree)

fin:
//abort(1000)
  IF fromstream DO endstream(fromstream)
  IF tostream & tostream~=stdout DO endstream(tostream)

  WHILE blklist DO
  { LET blk = blklist
    blklist := !blk
    freevec(blk)
  }
  selectoutput(stdout)
  writef("done*n")
  RESULTIS 0
}

AND rdline(lnv) = VALOF
{ LET len = 0

  { LET ch = rdch()
    IF ch='*c' BREAK
    IF ch='*n' BREAK
    IF ch=endstreamch RESULTIS 0
    len := len+1
    IF len<=255 DO lnv%len := ch    
  } REPEAT

  IF len>255 DO len := 255
  lnv%0 := len
//writef("rdline: %s*n", lnv)
  RESULTIS TRUE // Successful return
}

AND filter(lnv) = VALOF
{ // Returns TRUE if lnv contains G:, M:, F: or S:
  LET len = lnv%0
  FOR i = 2 TO len IF lnv%i=':' DO
  { LET ch = lnv%(i-1)
    IF ch='G' | ch='M' | ch='F' | ch='S' DO
    { IF optfns DO
      { // OK if lnv contains " RT " or " FN "
        FOR i = 1 TO len-3 IF lnv%i=' ' & lnv%(i+3)='*s' DO
        { LET a, b = lnv%(i+1), lnv%(i+2)
          IF a='R' & b='T' RESULTIS TRUE
          IF a='F' & b='N' RESULTIS TRUE
        }
        RESULTIS FALSE
      }
      RESULTIS TRUE
    }
  }
  RESULTIS FALSE
}
AND insertnode(str) BE TEST tree
THEN { LET t = tree

       { // Find the position in the tree to insert the node
         LET rel = comp(str, @t!2)
         LET a = t
         UNLESS rel RETURN // str is a duplicate so don't insert
         IF rel>0 DO a := a+1
         t := !a
         UNLESS t DO { !a := mknode(str); RETURN }
       } REPEATWHILE t

     }
ELSE tree := mknode(str)

AND comp(s1, s2) = VALOF
{ LET len1, len2 = s1%0, s2%0
  LET minlen = len1<len2 -> len1, len2
  FOR i = 1 TO minlen DO
  { LET ch1, ch2 = s1%i, s2%i
    IF ch1<ch2 RESULTIS -1
    IF ch1>ch2 RESULTIS +1
  }
  IF len1<len2 RESULTIS -1
  IF len1>len2 RESULTIS +1
  RESULTIS 0                // The strings are equal
}

AND mknode(str) = VALOF
{ // Returns the pointer to the new node
  LET nodesize = 2 + str%0/bytesperword + 1 // [left, right, <bytes>]

//  writef("mknode: str=%s*n", str)

  IF blklist=0 DO
  { blklist := getvec(blkupb)
//writef("mknode: allocating blk %n upb=%n*n", blklist, blkupb)
//abort(1000)
    UNLESS blklist RESULTIS 0
    blklist!0, blklist!1 := 0, 1
  }

  IF blklist!1+nodesize > blkupb DO
  { // There is insufficient room for the new node so a new
    // block must be allocated.
    LET nb = getvec(blkupb)
    UNLESS nb RESULTIS 0
    nb!0, nb!1 := blklist, 1
    blklist := nb
//writef("mknode: allocating blk %n upb=%n*n", blklist, blkupb)
//abort(1001)
  }
  // The current block is large enough for the new node

  { LET pos = blklist!1         // Position of the new node
    LET node = @blklist!pos + 1 // Pointer to new node
    LET newstr = node+2         // Pointer to the node string bytes
    blklist!1 := pos + nodesize
//writef("mknode: making node=%n  str=%s*n", node, str)
    node!0, node!1 := 0, 0    // Null left and right children
    FOR i = 0 TO str%0/bytesperword DO newstr!i := str!i
    RESULTIS node
  }
}

AND prtree(t) BE IF t DO
{ // t = 0  or  t -> [left, right, <string>]
  LET x, y = t!0, t!1
  IF x DO prtree(x)
  writef("%s*n", @t!2)
  IF y DO prtree(y)
}
