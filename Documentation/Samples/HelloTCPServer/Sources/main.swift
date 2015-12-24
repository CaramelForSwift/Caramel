import Caramel

try! TCPServer(port: 8080).listen { 
     connection in
         connection.outgoing.write("Hello World\n".utf8.data)
     connection.outgoing.end()
}

EventLoop.defaultLoop.run ()

