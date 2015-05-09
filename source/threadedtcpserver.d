module threadedtcpserver;


debug(printlog) import std.stdio;
import std.socket;
import std.concurrency;
import core.time;


class TcpListener
{
  shared TcpSocket listener;

  this(ushort port)
  {
    TcpSocket tmp = new TcpSocket;
    assert(tmp.isAlive);
    tmp.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
    tmp.bind(new InternetAddress(port));
    listener = cast(shared) tmp;
  }

  void listen(int backlog)
  {
    (cast()listener).listen(backlog);
  }

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


class ThreadedTcpServer
{
  TcpListener listener;

  this(ushort port)
  {
    listener = new TcpListener(port);
  }

  void listen(int backlog = 1024)
  {
    listener.listen(backlog);
  }

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
