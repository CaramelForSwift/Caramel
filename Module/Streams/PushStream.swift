public protocol Pushable: Buffered {
    typealias PushHandler = (Result<Sequence> -> Void)
    func wait(handler: PushHandler)
}

public class PushStream<T: StreamBuffer>: Pushable {
    public typealias Sequence = T
    
    public var buffer = Sequence()
    
    func appendToBuffer(newElements: Sequence) {
        self.buffer.append(newElements)
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

    private var handlers: [PushStream.PushHandler] = []
    public func wait(handler: PushStream.PushHandler) {
        handlers.append(handler)
    }
    public func write(sequence: Sequence) {
        let result = Result.Success(sequence)
        for handler in handlers {
            handler(result)
        }
    }
    
    public init() {
        
    }
}
