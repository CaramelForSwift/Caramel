public protocol Pullable: Buffered {
    func pull() -> Sequence?
}

public class PullableStream<T: StreamBuffer>: Pullable {
    public typealias Sequence = T
    
    public var buffer = Sequence()
    
    public func pull() -> Sequence? {
        fatalError("Unimplemented")
    }
    
    func appendToBuffer(newElements: Sequence) {
        self.buffer.appendContentsOf(newElements)
    }
    
    public func read() -> Sequence? {
        guard isAtEnd == false else { return nil }
        return pull()
    }
    
    private var _isAtEnd = false
    public var isAtEnd: Bool {
        return _isAtEnd
    }
    public func end() {
        _isAtEnd = true
    }
}

public class FulfilledPullableStream<T: StreamBuffer>: PullableStream<T> {
    public typealias Sequence = T
    
    private var values: Sequence
    
    public override func pull() -> Sequence? {
        defer {
            end()
        }
        return values
    }
    
    public required init(values: Sequence) {
        self.values = values
        super.init()
    }
}

public extension Pullable {
    func drain() -> Self.Sequence {
        var output = Self.Sequence()
        while (self.isAtEnd == false) {
            if let read = self.pull() {
                output.appendContentsOf(read)
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
        return _pullStream
    }
    
    private let transform: Transformer
	
	private var didStart = false
    
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
        return self.pullStream.isAtEnd
    }
}

public extension DataConvertible {
    public var stream: FulfilledPullableStream<Data> {
        return FulfilledPullableStream(values: self.data)
    }
}