SECTION "crdemo"

GET "libhdr"
 
GLOBAL { locked: 200;  buf: 201
         ptr.in: 202; ptr.out: 203
         curr.id: 204; ticks:205
}
 
MANIFEST { bufupb=3; f.put=101; f.get=102  }
 
LET start() = VALOF
{ LET slicer = createco(slicer.fn, 500)
  LET v = VEC 4
 
  writes("Monitor simulator entered*n")
 
  buf := getvec(bufupb)
  //writes("Returned from getvec*n")
  ptr.in, ptr.out := 0, 0
  locked := FALSE
  ticks := 0
 
  //writes("Creating server coroutine*n")
  v!0 := createco(server.fn, 500)
  //writes("Creating client coroutines*n")
 
  FOR id = 1 TO 4 DO v!id := createco(client.fn, 500)
  //writes("Calling callco*n")
 
  callco(slicer, v)
 
  writes("end of test*n")
  RESULTIS 0
}
 
AND tick() BE cowait()
 
AND server.fn() BE
{ LET val = monitor(f.get)
  FOR i = 1 TO 3 DO tick()
  writef("T= %i3 %n: Server >>>>>>>%i3*n", ticks, curr.id, val)
  tick()
} REPEAT
 
AND client.fn() BE
{ LET val = curr.id
 
  { FOR i = 1 TO 20 + 10*curr.id DO tick()  // delay depending on the id
    val := val + 100
    writef("T= %i3 %n: Client putting  %i3*n", ticks, curr.id, val)
//abort(1000/(val-val))
    monitor(f.put, val)
    tick()
  } REPEAT
}
 
AND slicer.fn(cptrv) BE UNTIL ticks>200 DO
{ //writef("slicer.fn: ticks=%n*n", ticks)
  FOR id = 0 TO 4 DO { curr.id := id
                       //writef("slicer.fn: id=%n*n", id)
                       //writef("slicer.fn: calling callco(%n)*n", cptrv!id)
                       callco(cptrv!id)
                      }
  ticks := ticks + 1
}
 
 
 
 
 
 
 
 
AND monitor(fno, arg) = VALOF
{ LET res = ?
 
  tick() REPEATWHILE locked
  // tick()  NOT allowed here
  locked := TRUE
//   writef("T= %i3 %n: locked*n", ticks, curr.id)
 
  tick()
  SWITCHON fno INTO
  { DEFAULT: writef("Unknown monitor function %n*n", fno)
             ENDCASE
 
    CASE f.put:  // put arg into the buffer if there is room
                 tick()
                 IF ptr.in>=ptr.out+bufupb DO
                 { tick()
                   locked := FALSE
//                   writef("T= %i3 %n: unlocked*n", ticks, curr.id)
                   LOOP
                 }
                 tick()
                 buf ! (ptr.in REM bufupb) := arg
                 tick()
                 ptr.in := ptr.in + 1
                 writef("T= %i3 %n: ++++++ put %i3  buf now: ",
                         ticks, curr.id, arg)
                 wrbuf()
                 ENDCASE
 
    CASE f.get:  // get two values from the buffer if possible
                 tick()
                 IF ptr.out>=ptr.in DO
                 { tick()
                   locked := FALSE
//                   writef("T= %i3 %n: unlocked*n", ticks, curr.id)
                   LOOP
                 }
                 tick()
                 res := buf ! (ptr.out REM bufupb)
                 tick()
                 ptr.out := ptr.out + 1
                 writef("T= %i3 %n: ------ get %i3  buf now: ",
                         ticks, curr.id, res)
                 wrbuf()
                 ENDCASE
  }
  locked := FALSE
//  writef("T= %i3 %n: unlocked*n", ticks, curr.id)
  tick()
  RESULTIS res
} REPEAT
 
AND wrbuf() BE
{ FOR i = ptr.out TO ptr.in-1 DO writef(" %i3", buf!(i REM bufupb))
  newline()
}
