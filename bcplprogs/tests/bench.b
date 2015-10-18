// header file for the bench mark test

MANIFEST $( // Comment out one of the following lines
  Count=10000;      Qpktcountval=23246;   Holdcountval=9297
//Count=10000*100;  Qpktcountval=2326410; Holdcountval=930563
$)

GET "libhdr"
 
MANIFEST $(
i_idle       = 1
i_work       = 2
i_handlera   = 3
i_handlerb   = 4
i_deva       = 5
i_devb       = 6
tasktab_upb  = 10
 
p_link = 0
p_id   = 1
p_kind = 2
p_a1   = 3
p_a2   = 4
pkt_upb= 8
 
t_link = 0
t_id   = 1
t_pri  = 2
t_wkq  = 3
t_state= 4
t_fn   = 5
t_v1   = 6
t_v2   = 7
tcb_upb= 7
 
bufsize = 3
 
pktbit         = 1
waitbit        = 2
holdbit        = 4
 
notpktbit      = NOT pktbit
notwaitbit     = NOT waitbit
notholdbit     = NOT holdbit
 
s_run          = 0
s_runpkt       = pktbit
s_wait         = waitbit
s_waitpkt      = waitbit + pktbit
s_hold         = holdbit
s_holdpkt      = holdbit + pktbit
s_holdwait     = holdbit + waitbit
s_holdwaitpkt  = holdbit + waitbit + pktbit
 
k_dev   = 1000
k_work  = 1001
$)
 
GLOBAL $(
tasktab  : 250
tasklist : 251
tcb      : 252
taskid   : 253
v1       : 254
v2       : 255
 
trace    : 259
schedule : 260
qpkt     : 261
wait     : 262
holdself : 263
release  : 264
 
idlefn   : 270
workfn   : 271
handlerfn: 272
devfn    : 273
 
qpktcount: 280
holdcount: 281
tracing  : 282
layout   : 283
$)
 
//.
 
//SECTION "main"
 
//GET "HDR"

LET start() = VALOF
$( LET wkq = 0

   writef("*Nbench mark starting, Count=%n*N", Count)
 
   tasktab := getvec(tasktab_upb)
   tasktab!0 := tasktab_upb
   FOR taskno = 1 TO tasktab_upb DO tasktab!taskno := 0
 
   tasklist := 0
 
   createtask(i_idle, 0, wkq, s_run, idlefn, 1, Count)
 
   wkq := pkt(0,   0, k_work)
   wkq := pkt(wkq, 0, k_work)
   createtask(i_work, 1000, wkq, s_waitpkt, workfn, i_handlera, 0)
 
   wkq := pkt(0,   i_deva, k_dev)
   wkq := pkt(wkq, i_deva, k_dev)
   wkq := pkt(wkq, i_deva, k_dev)
   createtask(i_handlera, 2000, wkq, s_waitpkt, handlerfn, 0, 0)
 
   wkq := pkt(0,   i_devb, k_dev)
   wkq := pkt(wkq, i_devb, k_dev)
   wkq := pkt(wkq, i_devb, k_dev)
   createtask(i_handlerb, 3000, wkq, s_waitpkt, handlerfn, 0, 0)
 
   wkq := 0
   createtask(i_deva, 4000, wkq, s_wait, devfn, 0, 0)
   createtask(i_devb, 5000, wkq, s_wait, devfn, 0, 0)
 
   tcb := tasklist
 
   qpktcount, holdcount := 0, 0
 
   writes("*Nstarting*N")
// writef("starting time = %n*N", time())
   tracing, layout := FALSE, 0
   schedule()
   writes("*Nfinished*N")
// writef("*Nfinishing time = %n*N", time())
 
   writef("qpkt count = %n  holdcount = %n*N",
           qpktcount,       holdcount)
 
   writes("these results are ")
   TEST qpktcount=Qpktcountval & holdcount=Holdcountval
   THEN writes("correct")
   ELSE writes("incorrect")
 
   writes("*Nend of run*N")
   RESULTIS 0
$)
 
AND createtask(id, pri, wkq, state, fn, v1, v2) BE
$( LET t = getvec(tcb_upb)
   tasktab!id := t  // insert in the task table
   t_link!t := tasklist
   t_id!t   := id
   t_pri!t  := pri
   t_wkq!t  := wkq
   t_state!t:= state
   t_fn!t   := fn
   t_v1!t   := v1
   t_v2!t   := v2
   tasklist := t
$)
 
AND pkt(link, id, kind) = VALOF
$( LET p = getvec(pkt_upb)
   FOR i = 0 TO pkt_upb DO p!i := 0
   p_link!p    := link
   p_id!p      := id
   p_kind!p    := kind
   RESULTIS p
$)
 
 
AND trace(ch) BE
$( layout := layout - 1
   IF layout<=0 DO
   $( newline()
      layout := 50
   $)
   wrch(ch)
   ch := 7
$)
 
//.
 
//SECTION "bench"
 
//GET "HDR"
 
LET schedule() BE UNTIL tcb=0 DO
//                      *106605
$( LET pkt, newtcb = 0, ?
// *106604

   SWITCHON t_state!tcb INTO
   $( CASE s_waitpkt:    pkt := t_wkq!tcb
//                       *23250
                         t_wkq!tcb := p_link!pkt
                         t_state!tcb := t_wkq!tcb=0 -> s_run, s_runpkt
//                       *23250                        *14760 *8490
      CASE s_run:
      CASE s_runpkt:     taskid, v1, v2 := t_id!tcb, t_v1!tcb, t_v2!tcb
//                       *65790
                         IF tracing DO trace(taskid+'0')
//                                     *0
                         newtcb := (t_fn!tcb)(pkt)
//                       *65790
                         t_v1!tcb, t_v2!tcb := v1, v2
                         tcb := newtcb
                         LOOP
 
      CASE s_wait:
      CASE s_hold:
      CASE s_holdpkt:
      CASE s_holdwait:
      CASE s_holdwaitpkt:tcb := t_link!tcb
//                       *40814
                         LOOP
 
      DEFAULT:           RETURN
//                       *0
   $)
$)
 
AND qpkt(pkt) = VALOF
$( LET t = findtcb(p_id!pkt)
// *23246
   IF t=0 RESULTIS 0
//        *0
   qpktcount := qpktcount + 1
// *23246
 
   p_link!pkt, p_id!pkt := 0, taskid
// *23246
   TEST t_wkq!t=0
   THEN $( t_wkq!t := pkt
//         *14759
           t_state!t := t_state!t | pktbit
           IF t_pri!t > t_pri!tcb RESULTIS t
//                                *3140
        $)
   ELSE append(pkt, @ t_wkq!t)
//      *11619
   RESULTIS tcb
// *23246
$)
 
AND wait() = VALOF
$( t_state!tcb := t_state!tcb | waitbit
// *23248
   RESULTIS tcb
$)
 
AND holdself() = VALOF
$( holdcount := holdcount + 1
// *9297
   t_state!tcb := t_state!tcb | holdbit
   RESULTIS t_link!tcb
$)
 
AND release(id) = VALOF
$( LET t = findtcb(id)
// *9999
   IF t=0 RESULTIS 0
//        *0
 
   t_state!t := t_state!t & notholdbit
// *9999
   IF t_pri!t > t_pri!tcb RESULTIS t
//                        *9999
   RESULTIS tcb
// *0
$)
 
AND findtcb(id) = VALOF
$( LET t = 0
// *33245
   IF 1 <= id <= tasktab!0 DO t := tasktab!id
//                            *33245
   IF t=0 DO writes("*Nbad task id*N")
//           *0
   RESULTIS t
// *33245
$)
 
AND idlefn(pkt) = VALOF
$( v2 := v2 - 1
// *10000
   IF v2=0 RESULTIS holdself()
//         *1
   TEST (v1&1)=0
// *9999
   THEN $( v1 := v1>>1
//         *5007
           RESULTIS release(i_deva)
        $)
   ELSE $( v1 := v1>>1 NEQV #XD008
//         *4992
           RESULTIS release(i_devb)
        $)
$)
 
AND workfn(pkt) = VALOF TEST pkt=0
//                      *4654
   THEN RESULTIS wait()
//      *2327
   ELSE $( LET buf = @ p_a2!pkt
//         *2327
           v1 := i_handlera + i_handlerb - v1
           // v1 is alternately i>handlera AND i_handlerb
 
           p_id!pkt := v1   // set the destination task id
           p_a1!pkt := 0    // set the buffer subscript
           FOR i = 0 TO bufsize DO
           $( v2 := v2 + 1
//            *9308
              IF v2>26 DO v2 := 1
//                        *358
              buf%i := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"%v2
           $)
           RESULTIS qpkt(pkt)
//         *2327
        $)
 
AND handlerfn(pkt) = VALOF
$( UNLESS pkt=0 DO append(pkt, p_kind!pkt=k_work -> @v1,  @v2)
// *23252          *11627                           *2327 *9300
   UNLESS v1=0 DO
// *23252
   $( LET workpkt = v1
//    *20310
      LET count, buf = p_a1!workpkt, @ p_a2!workpkt
      IF count>bufsize DO
      $( v1 := p_link!v1
//       *2325
         RESULTIS qpkt(workpkt)  // send back the exhausted a work packet
      $)
      UNLESS v2=0 DO
//    *17985
      $( LET devpkt = v2
         v2 := p_link!v2
         p_a1!devpkt := buf%count  // copy character into it
         p_a1!workpkt := count+1   // incrementing the character count
         RESULTIS qpkt(devpkt)     // send the packet to the device task
      $)
   $)
 
   // cannot proceed for lack of a packet so wait for one
   RESULTIS wait()
// *11627
$)
 
AND devfn(pkt) = VALOF TEST pkt=0
//               *27884
    THEN $( IF v1=0 RESULTIS wait()
//          *18588  *9294
            pkt := v1
//          *9294
            v1 := 0
            RESULTIS qpkt(pkt)
         $)
    ELSE $( v1 := pkt
//          *9296
            IF tracing DO trace(p_a1!pkt)
            RESULTIS holdself()
         $)
 
AND append(pkt, ptr) BE
$( p_link!pkt := 0
// *20114
   UNTIL !ptr=0 DO ptr := !ptr
//       *39877    *10467
   !ptr := pkt
// *20114
$)
