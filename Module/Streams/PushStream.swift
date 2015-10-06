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
        return _isAtEnd
    }
    public func end() {
        _isAtEnd = true
		
		let result = Result.Success(Sequence())
		for handler in handlers {
			handler(result)
		}
		
		retained = nil
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
    
	private var retained: PushStream? = nil
    public init() {
        retained = self
    }
}

public extension PushStream {
	public func drain(handler: (Result<Sequence>) -> Void) {
		var buffer = Sequence()
		var ended = false
		self.wait { (result: Result<Sequence>) in 
			guard ended == false else { return }

			do {
				let data = try result.result()
				buffer.append(data)
				if self.isAtEnd {
					ended = true
					handler(Result.Success(buffer))
				}
			} catch {
				ended = true
				handler(result)
			}
		}
	}
}

public protocol TransformPushable: Pushable {
	typealias InputStream: Pushable
	var pushStream: InputStream { get }
}
