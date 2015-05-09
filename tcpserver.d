import std.stdio;
import std.socket;
import std.concurrency;


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

  this(ushort port, int backlog = 1024)
  {
    listener = new TcpListener(port);
    listener.listen(backlog);
  }

  void run(void function(Socket) handler, uint nthreads = 2)
  {
    for (int i; i< nthreads; ++i) {
      spawn(&spawnedFunc, thisTid, cast(shared)listener, handler);
    }
    for (;;) { /* sleep */ };
  }
}


void spawnedFunc(Tid ownerTid, shared(TcpListener) listener,
                 void function(Socket) handler)
{
  for (;;) {
    Socket sock = listener.accept;
    writeln("Accepted: ", thisTid);
    handler(sock);
  }
}


void main()
{
  auto server = new ThreadedTcpServer(4000);
  server.run((sock) {
      ubyte[1024] buffer;
      scope (exit) sock.close;

      sock.receive(buffer);
      writeln(cast(string) buffer);
      sock.send(buffer);
    });
}

