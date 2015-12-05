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
    
    public private(set) var isAtEnd: Bool = false
    public func end() {
        isAtEnd = true
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

public extension DataConvertible {
    public var stream: FulfilledPullableStream<Data> {
        return FulfilledPullableStream(values: self.data)
    }
}