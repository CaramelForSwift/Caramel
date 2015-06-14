public protocol SocketListener {
	func listen(port: Server.Port, accept: (Connection<Server.Data, Server.Data>) -> Void) throws
}