public protocol HTTPRequestType {
	typealias Body

	var body: Body? { get }
}

public struct HTTPRequest<T>: HTTPRequestType {
	public typealias Body = T
	
	public private(set) var body: Body?
}