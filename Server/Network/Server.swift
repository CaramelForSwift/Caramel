public class Server {
	public typealias Data = UnsafeBufferPointer<UInt8>
	public typealias RequestHandler = (Connection<Data, Data>) -> Void
	public typealias Port = UInt16

	public lazy var socketListener: SocketListener = {
		#if USE_GCDASYNCSOCKET
			let listener = GCDAsyncSocketListener()
			return listener
		#elseif USE_LIBDISPATCH
			let listener = DispatchSocketListener(controlProtocol: .TCP, version: .IPv4)
			return listener
		#else
			fatalError("No SocketListener implementation supplied")
		#endif
	}()
	
	internal let requestHandler: RequestHandler
	
	public convenience init(port: Port, handler: RequestHandler) {
		self.init(handler: handler)
		listen(port)
	}
	
	public required init(handler: RequestHandler) {
		requestHandler = handler
	}
	
	public func listen(port: UInt16) {
		print("Listening on port \(port)")
		do {
			try self.socketListener.listen(port) { (connection: Connection<Data, Data>) in
				print("SOCKET")
			}
		} catch {
			print("Oops")
		}
	}
	
	
}

