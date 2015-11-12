import Caramel

let server = IRCServer(host: "localhost", port: 8081)
server.messageOfTheDay = [
    "Check out my cool IRC server. This was written",
    "entirely in pure Swift using Caramel. Find out",
    "more at CaramelForSwift.org."
]
try! server.start()

EventLoop.defaultLoop.run()