/**
 * This is a low-level module for creating mulitthreaded tcp server system.
 *
 * Synopsis:
 * ---
 *
 * import threadedtcpserver;
 *
 * import std.stdio;
 *
 *
 * void main()
 * {
 *   auto server = new ThreadedTcpServer(4000);
 *   server.listen;
 *   server.run((sock) {
 *       ubyte[1024] buffer;
 *       scope (exit) sock.close;
 *
 *       sock.receive(buffer);
 *       writeln(cast(string) buffer);
 *       sock.send(buffer);
 *     });
 *}
 *---
 */

module threadedtcpserver;


debug(printlog) import std.stdio;
import std.socket;
import std.concurrency;
import core.time;


/**
 * TcpListener listens on a Tcp socket.
 */
class TcpListener
{
  shared TcpSocket listener;

  /**
   * Constructs a Tcp listener.
   */
  this(ushort port)
  {
    TcpSocket tmp = new TcpSocket;
    assert(tmp.isAlive);
    tmp.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
    tmp.bind(new InternetAddress(port));
    listener = cast(shared) tmp;
  }

  /**
   * Listen for an incoming connection.
   */
  void listen(int backlog)
  {
    (cast()listener).listen(backlog);
  }

  /**
   * Accept an incoming connection.
   */
  Socket accept() shared
  {
    Socket sock = (cast()listener).accept;
    scope (failure) {
      if (sock !is null) {
        sock.close;
      }
    }
    return sock;
  }
}


/**
 * A server handles client sockets in worker threads.
 */
class ThreadedTcpServer
{
  TcpListener listener;

  /**
   * Constructs a threaded tcp server.
   */
  this(ushort port)
  {
    listener = new TcpListener(port);
  }

  /**
   * Listen for an incoming connection.
   */
  void listen(int backlog = 1024)
  {
    listener.listen(backlog);
  }

  /**
   * Runs a server and start handling incoming connection.
   */
  void run(void function(Socket) handler, uint nthreads = 2)
  {
    uint counter = nthreads;
    Tid ownerTid = thisTid;

    for (int i; i< nthreads; ++i) {
      spawn(cast(void delegate() shared) () {
          scope(exit) ownerTid.send(thisTid);
          for (;;) {
            Socket sock = (cast(shared)listener).accept;
            debug(printlog) writeln("Accepted: ", thisTid);
            handler(sock);
          }
        });
    }

    for (;;) {
      receiveTimeout(dur!"msecs"(10), (Tid tid) {
          counter--;
        });

      if (counter == 0) {
        break;
      }
    }
  }
}
