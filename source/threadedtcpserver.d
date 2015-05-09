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

    for (int i; i< nthreads; ++i) {
      spawn(&spawnedFunc, thisTid, cast(shared)listener, handler);
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


private void spawnedFunc(Tid ownerTid, shared(TcpListener) listener,
                         void function(Socket) handler)
{
  scope(exit) ownerTid.send(thisTid);
  for (;;) {
    Socket sock = listener.accept;
    debug(printlog) writeln("Accepted: ", thisTid);
    handler(sock);
  }
}
