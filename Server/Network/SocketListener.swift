public protocol SocketListener {
	func listen(port: Port, accept: (Connection<Data, Data>) -> Void) throws
}