public protocol NetConnection {
	typealias RequestType
	typealias ResponseType
}

public extension NetConnection {
	public func read() -> RequestType {
		fatalError()
	}
	
	public func write(data: ResponseType) -> Void {
		
	}
 }

public class Connection<T, U> : NetConnection {

	public typealias RequestType = T
	public typealias ResponseType = U
}
