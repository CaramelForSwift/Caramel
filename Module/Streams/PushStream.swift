/*
A `PushStream`
*/

public protocol Pullable {
	typealias Sequence: SequenceType
	
	func read() -> Sequence?
	var isAtEnd: Bool { get }
}

public extension Pullable where Self.Sequence == Data {
	func drain() -> Self.Sequence? {
		var output = Self.Sequence()
		while (self.isAtEnd == false) {
			if let read = self.read() {
				output.append(read.bytes)
			}
		}
		return output
	}
}

class PushStream<T>: Stream<T> {
	
}

public protocol TransformPullable: Pullable {
	typealias InputStream: Pullable
	var pullStream: InputStream { get }
}

public struct TransformPullStream<T: Pullable, U>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = [U]
	
	public typealias Transformer = (T.Sequence) -> [U]
	
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
	
	public func read() -> [U]? {
		if let data = self.pullStream.read() {
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