// A Discrete event simulation benchmark 
// Designed and implemented by Martin Richards (c) June 2004 

// This is a benchmark test for a discrete event simulator using
// BCPL style coroutines. It simulates a network of n nodes which
// each receive, queue, process and transmit messages to other nodes.
// The nodes are uniformly spaced on a straight line and the network
// delay is assumed to be proportional to the linear distance between
// the source and the destination. On arrival, if the receiving node is
// busy the message is queued, otherwise it is processed immediately.
// After processing the message for random time it is sent to another
// random node. If the node has a non empty queue it dequeues its first
// message and starts to process it, otherwise it becomes suspended.
// Initially every node is processing a message and every queue is
// empty. There are n coroutines to simulate the  progress of each
// message and the discrete event priority queue is implemented using
// the heapsort heap structure. The simulation stops at a specified
// simulated time. The result is the number of messages that have been
// processed. A machine independent random number generator is used
// so the resulting value should be independent of implementation
// language and machine being used.

// Special comment lines have been included, eg:

//        IF j<priqn & min>priq!(j+1)!0 DO j := j+1
//      //   ^7499862  ^7463825            ^3477178

// These give counts of how many times the statements above
// the ^s were executed when cosim was run. These counts
// were obtained using the stats command.

SECTION "cosim"

GET "libhdr"

GLOBAL {
  priq:ug    // The vector holding the priority queue
  priqupb    // The upper bound
  priqn      // Number of items in the priority queue
  wkqv       // The vector of work queues
  count      // count of messages processed
  nodes      // The number of nodes
  ptmax      // The maximum processing time
  stopco     // The stop coroutine
  cov        // Vector of message coroutines
  ranv       // A vector used by the random number generator
  rani; ranj // subscripts of ranv
  simtime    // Simulated time
  stoptime   // Time to stop the simulation
  tracing

// Functions
  rnd
  initrnd
  closernd
  prq
  insertevent
  upheap
  downheap
  getevent
  waitfor
  prwaitq
  qitem
  dqitem
  stopcofn
  messcofn
}

// ################### Random number generator #######################

// The following random number generator is based on one give
// in Knuth: The art of programming, vol 2, p 26.
LET rnd(n) = VALOF
{ LET val = (ranv!rani + ranv!ranj) & #x_FFF_FFFF
//^1004310
  ranv!rani := val
  rani := (rani + 1) MOD 55
  ranj := (ranj + 1) MOD 55
  RESULTIS val MOD n
}

AND initrnd(seed) = VALOF
{ LET a, b = #x_234_5678+seed, #x_536_2781
//^1
  ranv := getvec(54)
  UNLESS ranv RESULTIS FALSE
  FOR i = 0 TO 54 DO
  { LET t = (a+b) & #x_FFF_FFFF
//  ^55
    a := b
    b := t
    ranv!i := t
  }
  rani, ranj := 55-55, 55-24  // ie: 0, 31
//^1
  RESULTIS TRUE
//^1
}

AND closernd() BE IF ranv DO freevec(ranv)
//                ^1         ^1

// ################### Priority Queue functions ######################

AND prq() BE
{ FOR i = 1 TO priqn DO writef(" %i4", priq!i!0)
//^0
  newline()
}

AND insertevent(event) BE
{ priqn := priqn+1        // Increment number of events
//^1004063
  //writef("insertevent: at time: %n  co=%n*n", event!0, event!1)
  upheap(event, priqn)
}

AND upheap(event, i) BE
{ LET eventtime = event!0
//^2007777
//writef("upheap: eventtime=%n i=%n*n", eventtime, i)

  { LET p = i/2          // Parent of i
//  ^3066788
    UNLESS p & eventtime < priq!p!0 DO
//             ^3064920
    { priq!i := event
//    ^2007777
//prq()
      RETURN
    }
    priq!i := priq!p     // Demote the parent
//  ^1059011
//prq()
    i := p
  } REPEAT
}

AND downheap(event, i) BE
{ LET j, min = 2*i, ? // j is left child, if present
//^8503576
//writef("downheap: eventtime=%n i=%n*n", event!0, i)
//prq()
  IF j > priqn DO
  { upheap(event, i)
//  ^1003714
    RETURN
  }
  min := priq!j!0
//^7499862
  // Look at other child, if it exists
  IF j<priqn & min>priq!(j+1)!0 DO j := j+1
//   ^7499862  ^7463825            ^3477178
  // promote earlier child
  priq!i := priq!j
//^7499862
  i := j
} REPEAT

AND getevent() = VALOF
{ LET event = priq!1      // Get the earliest event
//^1003714
  LET last  = priq!priqn  // Get the event at the end of the heap
//writef("getevent: priq:")
//prq()
  UNLESS priqn>0 RESULTIS 0 // No events in the priority queue
//               ^0
  priqn := priqn-1        // Decrement the heap size
//^1003714
  downheap(last, 1)       // Re-insert last event
  RESULTIS event
}

AND waitfor(ticks) BE
{ // Make an event item into the priority queue
  LET eventtime, co = simtime+ticks, currco
//^1004063
//writef("waitfor: simtime=%n ticks=%n*n", simtime, ticks)
  insertevent(@eventtime) // Insert into the priority queue
  cowait()                // Wait for the specified number of ticks
}

// ###################### Queueing functions #########################

AND prwaitq(node) BE
{ LET p = wkqv!node
//^0
//abort(997)
  IF -1 <= p <= 0 DO { writef("wkq for node %n: %n*n", node, p); RETURN }
  writef("wkq for node %n:", node)
  WHILE p DO
  { writef(" %n", p!1)
    p := !p
  }
  newline()
}

AND qitem(node) BE
// The message has reached this node
// It currently not busy, mark it as busy and return to process
// the message, other append it to the end of the work queue
// for this node.
{ // Make a queue item
  LET link, co = 0, currco
//^502305
  LET p = wkqv!node
//writef("qitem: entered*n")
//prwaitq(node)
  UNLESS p DO
  { // The node was not busy
    wkqv!node := -1  // Mark node as busy
//  ^251611
    IF tracing DO
      writef("%i8: node %i4: node not busy*n", simtime, node)
//    ^0
//writef("qitem: wkqv!%n=%n*n", node, wkqv!node)
    //prwaitq(node)
//abort(998)
    RETURN
//  ^251611
  }
  // Append item to the end of this queue
//abort(1000)
  IF tracing DO
// ^250694
    writef("%i8: node %i4: busy so appending message to end of work queue*n",
            simtime, node)
//  ^0
//abort(1000)
  TEST p=-1
//^250694
  THEN wkqv!node := @link     // Form a unit list
//     ^146286
  ELSE { WHILE !p DO p := !p  // Find the end of the wkq
//       ^104408     ^61303
         !p := @link          // Append to end of wkq
//       ^104408
       }
  //prwaitq(node)
  cowait() // Wait to be activated (by dqitem)
//^250694
}

AND dqitem(node) BE
// A message has just been processed by this node and is ready to process
// the next, if any.
{ LET item = wkqv!node // Current item (~=0)
//^501907
//writef("dqitem(%n): entered, item=%n*n", node, item)
  UNLESS item DO abort(999)
//               ^0
//prwaitq(node)
  TEST item=-1
//^501907
  THEN wkqv!node := 0                  // The node is no longer busy
//     ^251363
  ELSE { LET next = item!0
//       ^250544
         AND co   = item!1
         wkqv!node := next -> next, -1 // De-queue the item
//                            ^104356^146188
//prwaitq(node)
         callco(co)                    // Process the next message
//       ^250544
       }
}

// ######################## Coroutine Bodies ##########################

AND stopcofn(arg) = VALOF
{ waitfor(stoptime)
//^1
  IF tracing DO
    writef("%i8: Stop time reached*n", simtime)
//  ^0
  RESULTIS 0
//^1
}
 
AND messcofn(node) = VALOF
{ qitem(node)   // Put the message on the work queue for this node
//^500

  { // Start processing the first message
    LET prtime   = rnd(ptmax)     // a random processing time
//  ^502155
    LET dest     = rnd(nodes) + 1 // a random destination node
    LET netdelay = ABS(node-dest) // the network delay

//writef("prtime=%i3 dest=%i3*n", prtime, dest)
//abort(1001)
    IF tracing DO
      writef("%i8: node %i4: processing message until %n*n",
              simtime, node, simtime+prtime)
//    ^0
    waitfor(prtime)
//  ^502155
    count := count + 1 // One more message processed
//  ^501907
    IF tracing DO
      writef("%i8: node %i4: message processed*n",
              simtime, node, dest, simtime+netdelay)
//    ^0

//prwaitq(node)
    dqitem(node) // De-queue current item and activate the next, if any
//  ^501907
//prwaitq(node)
    IF tracing DO
      writef("%i8: node %i4: sending message to node %n to arrive at %n*n",
              simtime, node, dest, simtime+netdelay)
//    ^0

    waitfor(netdelay)
//  ^501907
    node := dest      // The message has arrived at the destination node
//  ^501805
    IF tracing DO
      writef("%i8: node %i4: message reached this node*n",
              simtime, node)
//    ^0
    qitem(node)   // Queue the message if necessary
//  ^500636
    // The node can now process the first message on its work queue
  } REPEAT
//  ^500469
}
// ######################### Main Program ############################

LET start() = VALOF
{ LET seed = 0
//^1
  LET argv = VEC 50
//abort(1002)

  UNLESS rdargs("-n/n,-s/n,-p/n,-r/n,-t/S", argv, 50) DO
//       ^1
  { writef("Bad arguments for cosim*n")
//  ^0
    RESULTIS 0
  }

  nodes, stoptime, ptmax := 500, 1_000_000, 1000
//^1
  IF argv!0  DO nodes    := !(argv!0) // -n/n
//   ^1       ^0                          ^0
  IF argv!1  DO stoptime := !(argv!1) // -s/n
//   ^1       ^0                          ^0
  IF argv!2  DO ptmax    := !(argv!2) // -p/n
//   ^1       ^0                          ^0
  IF argv!3  DO seed     := !(argv!3) // -r/n
//   ^1       ^0                          ^0
  tracing := argv!4                                           // -t
//^1
  writef("*nCosim entered*n*n")
  writef("Network nodes:       %n*n", nodes)
  writef("Stop time:           %n*n", stoptime)
  writef("Max processing time: %n*n", ptmax)
  writef("Random number seed:  %n*n", seed)
  newline()

  UNLESS initrnd(seed) DO
  { writef("Can't initialise the random number generator*n")
//  ^0
    RESULTIS 0
  }

IF FALSE DO
  FOR i = 1 TO 100 DO // Test the random number generator
  { writef(" %i4", rnd(10000))
    IF i MOD 10 = 0 DO newline()
  }

  stopco := 0
//^1
  wkqv, priq, cov := getvec(nodes), getvec(nodes+1), getvec(nodes)
  UNLESS wkqv & priq & cov DO  
  { writef("Can't allocate space for the node work queues*n")
//  ^0
    GOTO ret
  }

  FOR i = 1 TO nodes DO wkqv!i, cov!i := 0, 0
//^1                    ^500
  priqn := 0  // Number of events in the priority queue
//^1
  count := 0  // Count of message processed
  simtime := 0 // Simulated time

  IF tracing DO writef("%i8: Starting simulation*n", simtime)
//              ^0

//writef("rnd(10000)=%n*n", rnd(10000))
  // Create and start the stop coroutine
  stopco := createco(stopcofn, 200)
//^1
  IF stopco DO callco(stopco)
//             ^1
  // Create and start the message coroutines
  FOR i = 1 TO nodes DO
//^1
  { LET co = createco(messcofn, 200)
//  ^500
    IF co DO callco(co, i)
//           ^500
    cov!i := co
//  ^500
  }

  // Run the event loop

  { LET event = getevent()      // Get the earliest event
//  ^1003714
    UNLESS event BREAK
//               ^0
    simtime := event!0          // Set the simulated time
    //IF tracing DO writef("%i8: calling co=%n*n", simtime, event!1)
    IF simtime > stoptime BREAK
//                        ^1
    callco(event!1)
//  ^1003713
  } REPEAT

  IF tracing DO writef("*nSimulation stopped*n*n")
//^1            ^0
  writef("Messages processed: %n*n", count)
//^1

ret:
  FOR i = nodes TO 1 BY -1 IF cov!i DO deleteco(cov!i)
//^1                       ^500        ^500
  IF cov    DO freevec(cov)
//^1           ^1
  IF wkqv   DO freevec(wkqv)
//^1           ^1
  IF priq   DO freevec(priq)
//^1           ^1
  IF stopco DO deleteco(stopco)
//^1           ^1
  closernd()
//^1
  RESULTIS 0

fail:
  writef("Unable to initialise the simulator*n")
//^0
  GOTO ret
}

// Total number of Cintcode instructions executed: 435,363,350
// Number of coroutine changes:                      2,510,520
