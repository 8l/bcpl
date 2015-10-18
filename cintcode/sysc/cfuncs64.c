/*
This is a file contains the definition of the C function cfuncs
which is callable from BCPL.

Implemented by Martin Richards (c) May 2008

Under Cintcode and Cintpos, the following

res := sys(Sys_callc, fno, a1, a2,...)

calls cfuncs(args, g) where cfuncs is a C function, args is a
pointer to the arguments fno, a1, a2,..., and g is a pointer
to the base of the global vector. The result of cfuncs is assigned
to res.

*/

#include <stdio.h>
#include "cintsys64.h"

#include <stdlib.h>
#include <signal.h>
#include <errno.h>

#include <fcntl.h>
#include <sys/wait.h>
//#include <sys/time.h>
#include <sys/timeb.h>
//#include <sys/select.h>
//#include <linux/time.h>
#include <unistd.h>
#include <sys/signal.h>

/* include for the TCP/IP code */

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define  c_name2ipaddr 101
#define  c_name2port   102
#define  c_newsocket   103
#define  c_reuseaddr   104
#define  c_setsndbufsz 105
#define  c_setrcvbufsz 106
#define  c_tcpbind     107
#define  c_tcpconnect  108
#define  c_tcplisten   109
#define  c_tcpaccept   110
#define  c_tcpclose    111
#define  c_fd_zero     112
#define  c_fd_set      113
#define  c_fd_isset    114
#define  c_select      115
#define  c_recv        116
#define  c_send        117
#define  c_read        118
#define  c_write       119

extern BCPLWORD *W;

char namebuf[ 256];

BCPLWORD result2  = 0;

char *b2cstr(BCPLWORD bstr, char *cstr) {
  char *p = (char*)&W[bstr];
  char *q = cstr;
  int len = *p++;
  int i = 0;
  //printf("b2cstr: len=%d\n", len);
  for(i=1; i<=len; i++) *q++ = *p++;
  *q = 0;
  //printf("b2cstr: => \"%s\"\n", cstr);
  return cstr;
}

int name2ipaddr(char *hname) { // name => ipaddr (host format)
  struct hostent *hp;
  int ipaddr = -1;

  if (hname==0) return INADDR_ANY;

  //printf("name2ipaddr: \"%s\"\n", hname);

  if(inet_aton(hname, &ipaddr)) return ntohl(ipaddr);

  hp = gethostbyname(hname);
  if(hp==NULL) return -1; // Unknown host

  return ntohl(((struct in_addr *)hp->h_addr)->s_addr);
}

int name2port(char *pname) { // name => port (host format)
  struct servent *sp;
  char *endptr;
  short port;

  if(pname==0) return -1;

  port = strtol(pname, &endptr, 0);
  if(*endptr == '\0') return port;

  sp = getservbyname(pname, "tcp");
  if(sp==NULL) return -1;
  return ntohs(sp->s_port);
}

int newsocket() {
  // Create an internet socket to provide a reliable, full duplex
  // connection-oriented (TCP) byte stream.
  return socket( AF_INET, SOCK_STREAM, 0 );
}

int reuseaddr(int s, int n) {
  return setsockopt( s, SOL_SOCKET, SO_REUSEADDR,
                     ( char * )&n, sizeof( n ) );
}

int setsndbufsz(int s, int sz) {
  return setsockopt( s, SOL_SOCKET, SO_SNDBUF,
                     ( char * )&sz, sizeof( sz ) );
}

int setrcvbufsz(int s, int sz) {
  return setsockopt( s, SOL_SOCKET, SO_RCVBUF,
                     ( char * )&sz, sizeof( sz ) );
}

int tcpbind(int s, int ipaddr, int port) {
  int rc;
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = htonl(ipaddr);
  rc = bind( s, ( struct sockaddr * )&addr, sizeof( addr ) );
  if(rc==-1) perror("bind error");
  return rc;
}

int tcpconnect(int s, int ipaddr, int port) {
  struct sockaddr_in peer;
  peer.sin_family = AF_INET;
  peer.sin_port = htons(port);
  peer.sin_addr.s_addr = htonl(ipaddr);
  return connect( s, ( struct sockaddr * )&peer, sizeof( peer ) );
}

int tcplisten(int s, int n) {
  return listen(s, n);
}

int tcpaccept(int s) {
  struct sockaddr_in peer;
  int peerlen = sizeof(peer);
  int res = accept(s, (struct sockaddr *)&peer, &peerlen);
  result2 = ntohl(peer.sin_addr.s_addr);
  return res;
}

/*
int copydata(int s) {
  fd_set allreads;
  fd_set readmask;
  int rc;
  char buf[128];

  FD_ZERO(  &allreads);
  FD_SET(s, &allreads);  // the TCP/IP socket
  FD_SET(0, &allreads);  // stdin

  while(1) {
    readmask = allreads;

    rc = select(s+1, &readmask, NULL, NULL, NULL);
    if(rc<0) {
      printf("\nerror: select returned %d\n", rc);
      break;
    }

    if(FD_ISSET(0, &readmask)) {
      //printf("copydata: calling read\n");

      rc = read(0, buf, sizeof(buf)-1);
      if(rc==0) {
        //printf("\nserver disconnected -- EOF\n");
        break;
      }
      if(rc<0) {
        printf("\nerror: read returned %d\n", rc);
        break;
      }

      //if(rc>0 && buf[0]=='.') break;

      if(send(s, buf, rc, 0) < 0) {
        printf("\nerror: send failure\n");
        break;
      }
    }

    if(FD_ISSET(s, &readmask)) {
      rc = recv(s, buf, sizeof(buf)-1, 0);
      // It read rc chars into buf
      if(rc==0) {
        printf("\nserver disconnected\n");
        break;
      }
      if(rc<0) {
        printf("\nerror: read returned %d\n", rc);
        break;
      }

      buf[rc] = 0;
      printf("%s", buf);
      fflush(stdout);
    }
  }

  return 0;
}
*/

BCPLWORD callc(BCPLWORD *args, BCPLWORD *g) {
  int rc = 0;
  BCPLWORD fno = args[0];
  //printf("\nCallc: fno = %d\n", fno);

  switch(fno) {
  default:
    return -1;

  case c_name2ipaddr: // name => ipaddr (host format)
    b2cstr(args[1], namebuf);
    //printf("Callc c_name2ipaddr: args[1]=%d %s\n",
    //       args[1], namebuf);
    return name2ipaddr(namebuf);

  case c_name2port: // name => port (host format)
    b2cstr(args[1], namebuf);
    //printf("callc c_name2port: %s\n", namebuf);
    return name2port(namebuf);

  case c_newsocket: // Allocate a new socket
    return newsocket();

  case c_reuseaddr: // Reuse address
    return reuseaddr((int)args[1], (int)args[2]);

  case c_setsndbufsz: // Set the send buffer size
    return setsndbufsz((int)args[1], (int)args[2]);

  case c_setrcvbufsz: // Set the recv buffer size
    return setrcvbufsz((int)args[1], (int)args[2]);

  case c_tcpbind:     // Bind a socket to a given ipaddr/port
    //printf("c_tcpbind: %d %08x %d\n", args[1], args[2], args[3]);
    return tcpbind((int)args[1], (int)args[2], (int)args[3]);

  case c_tcpconnect: //  Connect a socket to a given ipaddr/port
    //printf("tcpconnect %d %08x %d\n", args[1], args[2], args[3]);
    return tcpconnect((int)args[1], (int)args[2], (int)args[3]);

  case c_tcplisten: //  Cause a socket to listen
    return tcplisten((int)args[1], (int)args[2]);

  case c_tcpaccept: // Cause a socket to accept a connection
    return tcpaccept((int)args[1]);

  case c_tcpclose: // Close a connection
    //printf("tcpclose %d\n", args[1]);
    return close((int)args[1]);

  case c_fd_zero: // Clear all bits in an fd_set
    { //fd_set *bits = (fd_set*)&W[args[2]];
      FD_ZERO((fd_set*)&W[args[1]]);
      return 0;
    }

  case c_fd_set: // Set a bit in an fd_set
    //printf("c_fd_set: args[1]=%d args[2]=%d\n", args[1], args[2]);
    FD_SET((int)args[1], (fd_set*)&W[args[2]]);
    return 0;

  case c_fd_isset: // Test a bit in an fd_set
    return FD_ISSET((int)args[1], (fd_set*)&W[args[2]]);

  case c_select: // Call the select function
    { int i, rc;
      int      s       = (int)          args[1];
      fd_set  *rd_set  = (fd_set *)  &W[args[2]];
      fd_set  *wr_set  = (fd_set *)  &W[args[3]];
      fd_set  *er_set  = (fd_set *)  &W[args[4]];
      struct timeval *timeval = (struct timeval *)
	                        ((args[5]==0) ? NULL : &W[args[5]]);
      /*
      //for(i=0; i<10;i++)
      //  printf("callc: rdset bit %d = %d\n",
	       i, FD_ISSET(i, (fd_set*)&W[args[2]]));
      */
      //printf("callc: calling select(%d,%d,%d,%d,%d)\n",
      //        args[1],args[2],args[3],args[4],args[5]);
      //if(timeval) {
      //printf("c_select: tv_sec  = %d\n", timeval->tv_sec);
      //printf("c_select: tv_usec = %d\n", timeval->tv_usec);
      //}
      rc = select(s, rd_set, wr_set, er_set, timeval);

      if(rc==-1) perror("select returned error");
      //printf("\ncallc: select => rc = %d\n", rc);
      //for(i=0; i<10;i++)
      //   printf("callc: rdset bit %d = %d\n",
      //           i, FD_ISSET(i, rd_set));
      return rc;
    }

  case c_recv:    // Call the recv(s, buf, len, flags)
    { int   s     = (int)args[1];
      char *buf   = (char*)&W[args[2]];
      int   len   = (int)args[3];
      int   flags = (int)args[4];
      int rc = 0;
      //printf("cfuncs: Calling recv(%d, %d, %d, %d)\n",
      //     args[1], args[2], args[3], args[4]);
      rc = recv(s, buf, len, flags);
      if(rc==-1)perror("recv returned error");
      //printf("cfuncs: recv returned rc=%d\n", rc);
      return rc;
    }

  case c_send:    // Call the send(s, buf, len, flags)
    { int   s     = (int)args[1];
      char *buf   = (char*)&W[args[2]];
      int   len   = (int)args[3];
      int   flags = (int)args[4];
      int rc = 0;
      //printf("cfuncs: Calling send(%d, %d, %d, %d)\n",
      //       args[1], args[2], args[3], args[4]);
      rc = send(s, buf, len, flags);
      if(rc==-1)perror("send returned error");
      //printf("cfuncs: send returned rc=%d\n", rc);
      return rc;
    }

  case c_read:    // Call the read(s, buf, len)
    { int   s   = (int)args[1];
      char *buf = (char*)&W[args[2]];
      int   len = (int)args[3];
      int rc = 0;
      //printf("cfuncs: Calling read(%d, %d, %d)\n", args[1], args[2], args[3]);
      rc = read(s, buf, len);
      //if(rc==-1)perror("read returned error");
      //printf("cfuncs: read returned rc=%d\n", rc);
      return rc;
    }

  case c_write:   // Call the write(s, buf, len)
    { int   s   = (int)   args[1];
      char *buf = (char*) &W[args[2]];
      int   len = (int)   args[3];
      int   rc  = 0;
      //printf("cfuncs: Calling write(%d, %d, %d)\n", args[1], args[2], args[3]);
      rc = write(s, buf, len);
      if(rc==-1)perror("read returned error");
      //printf("cfuncs: read returned rc=%d\n", rc);
      return rc;
    }
  }
}

