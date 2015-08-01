public class Server: SocketServer<Data?, Data> {
	public required init(handler: RequestHandler) {
		super.init(handler: handler)
	}
}