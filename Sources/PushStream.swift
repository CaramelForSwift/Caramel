public protocol Pushable: Buffered {
    typealias PushHandler = (Result<Sequence>) -> Void
    func wait(handler: PushHandler)
}

public protocol Writeable: Buffered {
    func write(sequence: Self.Sequence)
}

public protocol BufferedAppendable: Buffered {
    func appendToBuffer(newElements: Sequence)
}

public class PushStream<T: StreamBuffer>: Pushable, Writeable, BufferedAppendable {
    public typealias Sequence = T
    
    public var buffer = Sequence()
    
    public func appendToBuffer(newElements: Sequence) {
        self.buffer.appendContentsOf(newElements)
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
    private var started: Bool = false
    public func wait(handler: PushStream.PushHandler) {
        handlers.append(handler)

        if started == false {
            started = true
            start()
        }
    }

	public func write(sequence: Sequence) {
        let result = Result.Success(sequence)
        for handler in handlers {
            handler(result)
        }
    }

	public func writeError(error: ErrorType) {
		let result = Result<Sequence>.Error(error)
		for handler in handlers {
			handler(result)
		}
	}

	internal var retained: PushStream? = nil
    public required init() {
        retained = self
    }

    internal func start() {
        started = true
    }
}

public extension Pushable {
	public func drain(handler: (Result<Sequence>) -> Void) {
		var buffer = Sequence()
		var ended = false
		self.wait(({ (result: Result<Sequence>) in 
			guard ended == false else { return }

			do {
				let data = try result.result()
				buffer.appendContentsOf(data)
				if self.isAtEnd {
					ended = true
					handler(Result.Success(buffer))
				}
			} catch {
				ended = true
				handler(result)
			}
		}) as! PushHandler)
	}
}

public protocol TransformPushable: Pushable {
	typealias InputStream: Pushable
	var pushStream: InputStream { get }
}
