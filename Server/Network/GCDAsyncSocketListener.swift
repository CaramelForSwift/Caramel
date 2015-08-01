class GCDAsyncSocketListener: NSObject, SocketListener, GCDAsyncSocketDelegate {
	let dispatchQueue = dispatch_queue_create("GCDAsyncSocketListener", DISPATCH_QUEUE_CONCURRENT)
	let socket: GCDAsyncSocket
	
	override required init() {
		socket = GCDAsyncSocket(delegate: nil, delegateQueue: dispatchQueue, socketQueue: dispatchQueue)
	}
	
	var connectionHandler: ((Connection<Data, Data>) -> Void)?
	func listen(port: Port, accept: (Connection<Data, Data>) -> Void) throws {
		do {
			socket.delegate = self
			try socket.acceptOnPort(port)
			connectionHandler = accept
		} catch {
			print("Aww couldn't open port \(error)")
		}
		
	}
	
	func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
		print("SOCK IT BABY")
	}
	
	func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
		print("Read data \(tag)")
	}
}