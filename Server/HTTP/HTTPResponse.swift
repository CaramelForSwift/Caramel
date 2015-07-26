public struct HTTPResponse {
	public var statusCode = 200
	public var headers: [String: String] = [:]
	public var body: UnsafeBufferPointer<Void>?
}