import Caramel

try! TCPServer(port: 8080).toStringUnicodeScalarsViewWithEncoding(.UTF8).stringsSplitByNewline.listen { connection in
    connection.incoming.wait({ (linesR: Result<[String]>) -> Void in
        do {
            let lines = try linesR.result()
            for line in lines {
                print("line: \(line)")
                connection.outgoing.write(line.utf8.data)
            }
        } catch let error {
            connection.outgoing.end()
        }
    })
}

EventLoop.defaultLoop.run()