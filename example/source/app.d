import threadedtcpserver;
import std.stdio;

void main()
{
    stderr.writeln("Listening localhost:4000.");
    auto server = new ThreadedTcpServer("localhost", 4000);
    server.listen(1024);
    server.run((sock) {
            ubyte[1024] buffer;

            sock.receive(buffer);
            writeln(cast(string) buffer);
            sock.send(buffer);
        });
}
