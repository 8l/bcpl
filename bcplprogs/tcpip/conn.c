/*
This program connects stdin and stdout to a full duplex TCP/IP connection with
with another machine.

Usage:

conn [-h host] [-p port]

If port is omitted, port 9000 is used by default.  If host is omitted the
program waits for a TCP/IP connection by another machine using the specified
port on the local machine. If host is specified, the program attempts to make a
connection to the specified host and port.

Once a connection is established, it copies all input from stdin to the host
and all data received from the host goes to stdout.  This program can be killed
by typing ctrl-c, or by the host breaking the connection. When running under
xterm, it essentially acts as a vt100 terminal.

The program is based on examples in Jon Snader's book: "Effective TCP/IP
Programming".

Implementation by Martin Richards (c) April 2002

*/


#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <errno.h>

#include <fcntl.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <unistd.h>
#include <sys/signal.h>

/* include for the TCP/IP code */

#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>


int   result2  = 0;

int name2ipaddr(char *hname) { // name => ipaddr (host format)
  struct hostent *hp;
  int ipaddr = -1;

  if (hname==0) return INADDR_ANY;

  //printf("name2ipaddr: %s\n", hname);

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
  struct sockaddr_in addr;
  addr.sin_family = AF_INET;
  addr.sin_port = htons(port);
  addr.sin_addr.s_addr = htonl(ipaddr);
  return bind( s, ( struct sockaddr * )&addr, sizeof( addr ) );
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

    printf("copydata: Calling select (%d,...)\n", s+1);
    { int i;
      /*
      for (i=0; i<10; i++)
        printf("copydata: readmask bit %d = %d\n",
	       i, FD_ISSET(i, &readmask));
      */
      rc = select(s+1, &readmask, NULL, NULL, NULL);
      if(rc==-1) perror("select returned error");
      printf("select => rc = %d\n", rc);
      for(i=0; i<10;i++)
        printf("callc: rdset bit %d = %d\n",
	       i, FD_ISSET(i, &readmask));
    }

    if(rc<0) {
      printf("\nerror: select returned %d\n", rc);
      break;
    }

    printf("copydata: select returned rc=%d\n", rc);

    { int i;
      for (i=0; i<10; i++)
        printf("copydata: readmask bit %d = %d\n",
	       i, FD_ISSET(i, &readmask));
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

      // Send some characters to the TCP destination
      if(send(s, buf, rc, 0) < 0) {
        printf("\nerror: send failure\n");
        break;
      }
    }

    if(FD_ISSET(s, &readmask)) {
      rc = recv(s, buf, sizeof(buf)-1, 0);
      // It read rc chars from socket s into buf
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

int client(int ipaddr, int port) {
  int s;
  int c;
  int bufsz = 4096;
  int sndsz = 1440;	/* default ethernet mss */

  s = newsocket();
  if ( s<0 ) {
    printf("\nsocket call failed" );
  }

  if ( reuseaddr(s, 1) < 0) {
    printf("\nreuseaddr failed" );
    return 0;
  }

  if ( setsndbufsz( s, bufsz)) {
    printf("\nsetsockopt SO_SNDBUF failed" );
    return 0;
  }

  if ( tcpconnect( s, ipaddr, port) ) {
    printf("\nconnect failed" );
    return 0;
  }

  printf("connected established\n");

  copydata(s);

  close(s);
  return 0;
}

int server(int ipaddr, int port) {
  int s, s1;
  int c;
  int bufsz = 4096;
  int sndsz = 1440;	/* default ethernet mss */

again: // If the connection is closed by the client
       // start again here.

  s = newsocket();
  if ( s<0 ) {
    printf("\nsocket call failed" );
  }

  if ( reuseaddr(s, 1) < 0) {
    printf("\nreuseaddr failed" );
    return 0;
  }

  if (tcpbind(s, ipaddr, port) < 0) {
    printf("\nbind failed, sock=%d ipaddr=%8x port=%d", s, ipaddr, port );
    return 0;
  }

  //if ( reuseaddr(s, 1) < 0) {
  //  printf("\nreuseaddr failed" );
  //  return 0;
  //}

  if ( tcplisten( s, 5) < 0 ) {
    printf("\nlisten failed" );
    return 0;
  }

  printf("Waiting for a connection request\n");

  s1 = tcpaccept(s);
  if(s1<0) {
    printf("\naccept failed" );
    return 0;
  }

  close(s); // Close the listening socket

  printf("connected established\n");

  copydata(s1);

  close(s1);

  printf("connection closed\n");
  goto again;
}


/* main program  */
int main( int argc, char **argv )
{ int s;
  int c;
  char *hostname=0;
  char *portname=0;
  int ipaddr=0, port=0;

  opterr = 0;
  while ( ( c = getopt( argc, argv, "h:p:" ) ) != EOF )
  { switch ( c )
    { case 'h' :
        hostname = optarg;
        break;

      case 'p' :
        portname = optarg;
        break;

      case '?' :
        printf("usage: conn [-h host] [-p port]\n", c );
        return 0;
    }
  }

  if(portname==0) portname = "9000";

  //  if (hostname) printf("hostname: %s\n", hostname);
  //  printf("portname: %s\n", portname);

  ipaddr = name2ipaddr(hostname);
  port   = name2port(portname);
  //printf("ipaddr: %8x  port: %d\n", ipaddr, port);

  if(hostname) client(ipaddr, port);
  else         server(ipaddr, port);

  printf("\nconnection closed\n");
}












