/*
This basically flies Jumbo with a fixed setting of
initial speed, Thrust, Elevator and Aileron
It genrates a sequence of 3D coordinates of the path taken by the aircraft.

This implementation is based on the jumbo flight simulator that ran interactively on a PDP 11
generating the pilots view on a Vector General Display.

Implemented by Martin Richards (c) July 2012
*/

SECTION "Flight"

GET "libhdr"

//LET muldiv(a, b, c) = sys(26, a, b, c)

MANIFEST { One = 1000000; Sps = 10; k.g = 9810000; k.drag = k.g/400 }

GLOBAL { c.thrust:ug; c.aileron; c.elevator }

LET inprod(a, b) =
   muldiv(a!0, b!0, One) + muldiv(a!1, b!1, One) + muldiv(a!2, b!2, One)

AND adjustlength(v) BE
{ LET corr = One - (inprod(v, v) - One)/2
  FOR i = 0 TO 2 DO v!i := muldiv(corr, v!i, One)
}

AND adjustortho(a, b) BE
{ LET corr = inprod(a, b)
  FOR i = 0 TO 2 DO b!i := b!i - muldiv(corr, a!i, One)
}

LET step(vp, vq, vr, cg, speed) = VALOF
{ LET a = muldiv(k.g, vq!2, speed)               /Sps // Turn right rate
  LET b = (muldiv(k.g, vr!2, speed) - c.elevator)/Sps // Pitch down rate
  LET c = muldiv(c.aileron, speed, One)          /Sps // Roll left rate

//writef("a=%i7 b=%i7 c=%i7*n", a, b, c)
  FOR i = 0 TO 2 DO
  { LET pi, qi, ri = vp!i, vq!i, vr!i
    vp!i := pi - muldiv(a, qi, One) - muldiv(b, ri, One)
    vq!i := qi + muldiv(a, pi, One) - muldiv(c, ri, One)
    vr!i := ri + muldiv(b, pi, One) + muldiv(c, qi, One)
  }      

   adjustlength(vp); adjustlength(vq); adjustlength(vr); 
   adjustortho(vp, vq); adjustortho(vp, vr); adjustortho(vq, vr)
//   writef("lengths       %i7 %i7 %i7*n",
//           inprod(vp, vp), inprod(vq, vq), inprod(vr, vr))
//   writef("orthogonality %i7 %i7 %i7*n",
//           inprod(vp, vq), inprod(vp, vr), inprod(vq, vr))

   speed := speed +
         (c.thrust - muldiv(k.drag,speed,One) - muldiv(k.g,vp!2,One))/Sps
   FOR i = 0 TO 2 DO  cg!i := cg!i + muldiv(vp!i, speed, One)/(Sps*1000)
//   FOR i = 0 TO 2 DO writef("%i5 %i5 %i5*n",
//                             vp!i/1000, vq!i/1000, vr!i/1000)
   RESULTIS speed
}

LET start() = VALOF
{ LET vp = VEC 2
  AND vq = VEC 2
  AND vr = VEC 2 AND cg = VEC 2
  AND speed = ?
  AND sysout = output()
  LET outfile = sysout

  LET argv = VEC 50

  IF rdargs("s=speed,t=thrust,e=elevator,a=airleron,to/k",
             argv, 50)=0 DO
  { writes("Bad arguments fo Jumbo*n")
    RESULTIS 20
  }
      
  cg!0, cg!1, cg!2 :=     0,   0, 1*One
   
  vp!0, vp!1, vp!2 :=     0, One,   0
  vq!0, vq!1, vq!2 :=  -One,   0,   0
  vr!0, vr!1, vr!2 :=     0,   0, One

  speed := 45 * One
  c.thrust, c.elevator, c.aileron := 5250000, 160000, 50
  UNLESS argv!0=0 DO speed      := One * str2numb(argv!0)   
  UNLESS argv!1=0 DO c.thrust   := str2numb(argv!1)   
  UNLESS argv!2=0 DO c.elevator := str2numb(argv!2)   
  UNLESS argv!3=0 DO c.aileron  := str2numb(argv!3)   

  IF argv!4=0 DO argv!4 := "FLIGHT"
  outfile := findoutput(argv!4)

  IF outfile=0 DO
  { writef("Unable to open file %s*n", argv!4)
    RESULTIS 20
  }

  selectoutput(outfile)
  writef("%i7 %i7 %i7*n", cg!0/1000,   cg!1/1000, cg!2/1000)
  selectoutput(sysout)
   
  FOR i = 1 TO 1000 DO
  { FOR j = 1 TO Sps DO speed := step(vp, vq, vr, cg, speed)
    writef("%i4: Speed=%i5  Height=%i7   x=%i7 y=%i7",
           i,   speed/One, cg!2/1000,   cg!0/1000, cg!1/1000)
    FOR i = 0 TO 2 DO writef("  %i4", muldiv(speed, vp!i, One)/One)
    newline()
      
    selectoutput(outfile)
    writef("%i7 %i7 %i7*n", cg!0/1000,   cg!1/1000, cg!2/1000)
    selectoutput(sysout)

    IF cg!2<0 | speed<0 BREAK
  }
  UNLESS outfile=sysout DO
  { selectoutput(outfile)
    endwrite()
  }
  selectoutput(sysout)
  RESULTIS 0
}
