/*
A `PushStream`
*/

public protocol Pullable {
	typealias Sequence: StreamBuffer
	
	func pull() -> Sequence?
	var isAtEnd: Bool { get }
	
	var buffer: Sequence { get set }
}

public class PullableStream<T: StreamBuffer>: Pullable {
	public typealias Sequence = T
	
	public var buffer = Sequence()
	
	public func pull() -> Sequence? {
		fatalError("Unimplemented")
	}
	
	func appendToBuffer(newElements: Sequence) {
		fatalError("Unimplemented")		
	}

	public func read() -> Sequence? {
		guard isAtEnd == false else { return nil }
		return pull()
	}
	
	private var _isAtEnd = false
	public var isAtEnd: Bool {
		get {
			return _isAtEnd
		}
	}
	public func end() {
		_isAtEnd = true
	}
}

public extension Pullable {
	func drain() -> Self.Sequence? {
		var output = Self.Sequence()
		while (self.isAtEnd == false) {
			if let read = self.pull() {
				output.append(read)
			}
		}
		return output
	}
}

public protocol TransformPullable: Pullable {
	typealias InputStream: Pullable
	var pullStream: InputStream { get }
}

public class TransformPullStream<T: Pullable, U>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = [U]
	
	public typealias Transformer = (T.Sequence) -> [U]
	
	public var buffer = Array<U>()
	
	private(set) var _pullStream: InputStream
	public var pullStream: InputStream {
		get {
			return _pullStream
		}
	}
	
	private let transform: Transformer

	public init(stream: InputStream, transformer: Transformer) {
		_pullStream = stream
		transform = transformer
	}
	
	public func pull() -> [U]? {
		if let data = self.pullStream.pull() {
			return self.transform(data)
		} else {
			return nil
		}
	}
	public var isAtEnd: Bool {
		get {
			return true
		}
	}
}

public extension Pullable {
	func transform<U>(transformer: (Self.Sequence) -> [U]) -> TransformPullStream<Self, U> {
		return TransformPullStream(stream: self, transformer: transformer)
	}
	func map<U>(transformer: (Self.Sequence.Generator.Element) -> U) -> TransformPullStream<Self, U> {
		return TransformPullStream(stream: self, transformer: { $0.map({ transformer($0) }) })
	}
	func flatMap<U>(transformer: (Self.Sequence.Generator.Element) -> [U]) -> TransformPullStream<Self, U> {
		return TransformPullStream(stream: self, transformer: { $0.flatMap({ transformer($0) }) })
	}
}