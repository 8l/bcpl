/*
This program is a translation from C to BCPL of conn.c which connects
stdin and stdout to a full duplex TCP/IP connection to another
machine.

Implemented by Martin Richards (c) May 2008


Usage:

conn [-h host] [-p port]

If port is omitted, port 9000 is used.  If host is omitted the program
waits for a TCP/IP connection by another machine using the specified
port on the local machine. If host is specified, the program attempts
to make a connection to the specified host and port.

Once a connection is established, it copies all input from stdin to
the host and all data received from the host goes to stdout.  This
program can be killed by typing ctrl-c, or by the host breaking the
connection.

The program is based on examples in Jon Snader's book: "Effective
TCP/IP Programming".  
*/

GET "libhdr"
GET "tcp.h"

// For compatibility with non Cintcode BCPL.
LET callc(fno, a1, a2, a3, a4, a5, a6) =
  sys(Sys_callc, fno, a1, a2, a3, a4, a5, a6)

LET name2ipaddr(hname) = VALOF // name => ipaddr (host format)
$( IF hname=0 RESULTIS 0
  //writef("calling callc c_name2ipaddr %s*n", hname)
  RESULTIS callc(c_name2ipaddr, hname)
$)

AND name2port(pname) = VALOF  // name => port (host format)
$(
  //writef("calling callc c_name2port %s*n", pname)
  RESULTIS callc(c_name2port, pname)
$)

AND newsocket() = VALOF   // Allocate a new socket
$(
  //writef("calling callc c_newsocket*n")
  RESULTIS callc(c_newsocket)
$)

AND reuseaddr(s, n) = VALOF
$(
  //writef("calling callc c_reuseaddr %n %n*n", s, n)
  RESULTIS callc(c_reuseaddr, s, n)
$)

AND setsndbufsz(s, sz) = VALOF
$(
  //writef("calling callc c_setsndbufsz %n %n*n", s, sz)
  RESULTIS callc(c_setsndbufsz, s, sz)
$)

AND setrcvbufsz(s, sz) = VALOF
$(
  //writef("calling callc c_setrcvbufsz %n %n*n", s, sz)
  RESULTIS callc(c_setrcvbufsz, s, sz)
$)

AND tcpbind(s, ipaddr, port) = VALOF
$(
  //sawritef("calling callc c_bind %n %x8 %n*n", s, ipaddr, port)
  RESULTIS callc(c_tcpbind, s, ipaddr, port)
$)

AND tcpconnect(s, ipaddr, port) = VALOF
$(
  //writef("calling callc c_connect %x8 %n*n", ipaddr, port)
  RESULTIS callc(c_tcpconnect, s, ipaddr, port)
$)

AND tcplisten(s, n) = VALOF
$(
  //writef("calling callc c_tcplisten %n %n*n", s, n)
  RESULTIS callc(c_tcplisten, s, n)
$)

AND tcpaccept(s) = VALOF
$(
  //writef("calling callc c_tcpaccept %s*n", s)
  RESULTIS callc(c_tcpaccept, s)
$)

AND tcpclose(s) = VALOF
$(
  //writef("calling callc c_tcpclose %n*n", s)
  RESULTIS callc(c_tcpclose, s)
$)

AND FD_ZERO(bits) = callc(c_fd_zero, bits)

AND FD_SET(bit, bits) = callc(c_fd_set, bit, bits)

AND FD_ISSET(bit, bits) = callc(c_fd_isset, bit, bits)

AND select(s, rdset, wrset, errset, timeval) = VALOF
$( //writef("select: calling callc(c_select, %n,%n,%n,%n,%n)*n",
  //       s, rdset, wrset, errset, timeval)
  RESULTIS callc(c_select, s, rdset, wrset, errset, timeval)
$)

AND recv(s, buf, n, flags) = VALOF
$( // Receive n bytes into buf from socket s
  //writef("calling sys(callc, c_recv, s=%n, buf=%n n=%n, flags=%n*n",
  //        s, buf, n, flags)
  RESULTIS callc(c_recv, s, buf, n, flags)
$)

AND send(s, buf, n) = VALOF
$( // Write n bytes from buf to socket s
  RESULTIS callc(c_write, s, buf, n)
$)

AND read(s, buf, n) = VALOF
$( // Read n bytes into buf from socket s
  LET rc = 0

//writef("read: Calling c_read: s=%n buf=%n n=%n*n", s, buf, n)
  rc := callc(c_read, s, buf, n)
//writef("read:  => rc= %n*n", rc)
  RESULTIS rc
$)

AND write(s, buf, n) = VALOF
$( // Write n bytes from buf to socket s
  RESULTIS callc(c_write, s, buf, n)
$)

AND copydata(s) = VALOF
$( LET allreads = VEC 128/bytesperword // fd_set allreads
  LET readmask = VEC 128/bytesperword // fd_set readmask
  LET rc = 0
  LET buf = VEC 128/bytesperword
  LET timeval = VEC 1   // timeval!0 = secs, timeval!1 = usecs
  timeval!0 := 10       // 10 second
  timeval!1 := 500_000  // plus 1/2 a second


FOR i = 1 TO 0 DO
$(
s := 0 // Try reading from the keyboard
//writef("copydata: calling read(%n,%n,%n)*n", s, buf, 127)
      rc := read(s, buf, 127)
//writef("read => rc = %n*n", rc)
      FOR i = 0 TO rc-1 DO $( wrch(buf%i); deplete(cos) $)
      newline()
$)
//RESULTIS 0
//abort(1001)


  $( // Start of main loop
    //readmask := allreads;
    FD_ZERO(  readmask);
    FD_SET(s, readmask);  // the TCP/IP socket
    FD_SET(0, readmask);  // stdin

//writef("copydata: readmask=%n readmask!0=%20b*n", readmask, readmask!0)
//FOR i = 0 TO 9 DO
//  writef("copydata: readmask bit %n = %n*n", i, FD_ISSET(i, readmask))
//abort(1000)
//writef("*ncopydata: calling select(%n,%n,0,0,%n) with readmask above*n",
//        s+1, readmask, timeval)

    timeval!0 := 10       // 10 second
    timeval!1 := 500_000  // plus 1/2 a second

    rc := select(s+1,
                 readmask,  // read mask
                 //0,  // read mask
                 0,         // write mask
                 0,         // error mask
                 0//timeval    // timeout structure
                )

//writef("*ncopydata: select returned rc=%n*n", rc)
//abort(1111)
    IF rc<0 DO
    $( writef("*nerror: select returned %n*n", rc)
      BREAK
    $)

//FOR i = 0 TO 9 DO
//  writef("copydata: readmask bit %n = %n*n", i, FD_ISSET(i, readmask))

    IF FD_ISSET(0, readmask) DO
    $( //writef("copydata: readmask bit 0 = %n*n", FD_ISSET(0, readmask))
      //writef("copydata: calling read(0,...*n")

      rc := read(0, buf, 127)

      IF rc=0 DO
      $( writef("*nuser disconnected -- EOF*n")
        BREAK
      $)

      IF rc<0 DO
      $( writef("*nerror: read returned rc=%n*n", rc)
//abort(1000)
        BREAK
      $)

      //writef("copydata: rc=%n from fd 0*n", rc)
//abort(1000)
      FOR i = 0 TO rc-1 DO
      $( LET ch = buf%i
        IF ch=127 DO ch := 8 /* replace RUBOUT from the keyboard by BS */
        IF ch>=0 DO wrch(ch);
        IF ch=13 DO $( ch := 10; wrch(10) $)
      $)
      deplete(cos)

      IF rc>0 & buf%0='.' BREAK
//writef("copydata calling send: buf%0=%c*n", buf%0)
      IF send(s, buf, rc, 0) < 0 DO
      $( writef("*nerror: send failure*n")
        BREAK
      $)
    $)

    IF FD_ISSET(s, readmask) DO
    $( rc := recv(s, buf, 127, 0)
      // It read rc chars from socket s into buf

      IF rc=0 DO
      $( writef("*nremote host disconnected*n")
        BREAK
      $)

      IF rc<0 DO
      $( writef("*nerror: read returned %n*n", rc)
        BREAK
      $)

      //writef("copydata: rc=%n from fd %n*n", rc, s)

      FOR i = 0 TO rc-1 DO wrch(buf%i)
      deplete(cos)
//abort(2222)
    $)
//writef("copydata: go round the loop again*n")
//abort(1001)
  $) REPEAT

  RESULTIS 0
$)

AND client(ipaddr, port) = VALOF
$( LET s, c = 0, 0;
  LET bufsz = 4096
  LET sndsz = 1440	// default ethernet mss

  //writef("client: entered*n")

  s := newsocket()
  IF s<0 DO
  $(  writef("*nsocket call failed" )
     RESULTIS 0
  $)

  //writef("client: socket %n created*n", s)

  IF reuseaddr(s, 1) < 0 DO
  $( writef("*nreuseaddr failed" )
    RESULTIS 0
  $)

  IF setsndbufsz( s, bufsz) DO
  $( writef("*nsetsockopt SO_SNDBUF failed" )
    RESULTIS 0
  $)

  IF tcpconnect( s, ipaddr, port) DO
  $( writef("*nconnect failed, s=%n ipaddr=%x8 port=%n*n",
            s, ipaddr, port )
    RESULTIS 0
  $)

  writef("connected established*n")
  //writef("calling copydata(%n)*n", s)

  copydata(s)
  //writef("returned from copydata*n")


  //writef("calling tcpclose(%n)*n", s)
  tcpclose(s)

  RESULTIS 0
$)

AND server(ipaddr, port) = VALOF
$(
  LET s, s1 = 0, 0
  LET c = 0
  LET bufsz = 4096
  LET sndsz = 1440	// default ethernet mss

again: // If the connection is closed by the client
       // start again here.

  s := newsocket()
  //sawritef("newsocket => s=%n*n", s)

  IF s<0 DO
  $( writef("socket call failed*n" )
    RESULTIS 0
  $)

  IF reuseaddr(s, 1) < 0 DO
  $( writef("reuseaddr failed*n" )
    RESULTIS 0
  $)

  //sawritef("calling bind, sock=%n ipaddr=%x8 port=%n*n", s, ipaddr, port )
  IF tcpbind(s, ipaddr, port) < 0 DO
  $( sawritef("bind failed, sock=%n ipaddr=%x8 port=%n*n", s, ipaddr, port )
    RESULTIS 0
  $)

  //IF reuseaddr(s, 1) < 0 DO
  //$( writef("reuseaddr failed*n" )
  //  RESULTIS 0
  //$)

  IF tcplisten( s, 5) < 0 DO
  $( writef("listen failed*n" )
    RESULTIS 0
  $)

  writef("Waiting for a connection request*n")

  s1 := tcpaccept(s)
  IF s1<0 DO
  $( writef("accept failed*n" )
    RESULTIS 0
  $)

  tcpclose(s) // Close the listening socket

  writef("connected established*n")

  copydata(s1)

  tcpclose(s1)

  writef("connection closed*n")
  GOTO again
$)

// main program
LET start() = VALOF
$( LET s, c = 0, 0
  LET hostname = 0
  LET portname = 0
  LET ipaddr, port = 0, 0
  LET argv = VEC 50

  UNLESS rdargs("-h,-p", argv, 50) DO
  $( writef("Bad args for CONN*n")
    RESULTIS 0
  $)

  IF argv!0 DO hostname := argv!0
  IF argv!1 DO portname := argv!1

  UNLESS portname DO portname := "9000"

  //IF hostname DO writef("hostname: %s*n", hostname)
  //writef("portname: %s*n", portname)

  ipaddr := name2ipaddr(hostname)
  port   := name2port(portname)
  //writef("ipaddr: %x8  port: %n*n", ipaddr, port)

  TEST hostname
  THEN client(ipaddr, port)
  ELSE server(ipaddr, port)

  writef("*nconnection closed*n")
  RESULTIS 0
$)












