import threadedtcpserver;

import std.stdio;


void main()
{
  auto server = new ThreadedTcpServer(4000);
  server.listen;
  server.run((sock) {
      ubyte[1024] buffer;
      scope (exit) sock.close;

      sock.receive(buffer);
      writeln(cast(string) buffer);
      sock.send(buffer);
    });
}
