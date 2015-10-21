import Caramel

let server = IRCServer(port: 8081)
try! server.start()

EventLoop.defaultLoop.run()