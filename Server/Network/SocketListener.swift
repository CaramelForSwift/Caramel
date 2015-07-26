public protocol SocketListener {
	func listen(port: Port, accept: (Connection<SocketData, SocketData>) -> Void) throws
}