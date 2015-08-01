public class HTTPServer<T>: SocketServer<T: HTTPRequestType, HTTPResponse> {
	public required init(handler: RequestHandler) {
		super.init(handler: handler)
	}
}

public extension NetConnection where Self.RequestType : HTTPRequestType {
	public var request: Self.RequestType {
		get {
			return self.read()
		}
	}
}