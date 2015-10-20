import Caramel

try! TCPServer().listen(8080) { connection in
    connection.outgoing.write("Hello, goodbye".utf8.data)
    connection.outgoing.end()
}

EventLoop.defaultLoop.run()