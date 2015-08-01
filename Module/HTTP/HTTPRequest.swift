public protocol HTTPRequestType {
	typealias Body

	var body: Body? { get }
}

public struct HTTPRequest<T>: HTTPRequestType {
	public typealias Body = T
	
	private var _body: Body?
	public var body: Body? {
		get {
			return _body
		}
	}
}