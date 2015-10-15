//
//  Transforming.swift
//  Caramel
//
//  Created by Steve Streza on 4.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public protocol Transforming {
	typealias Input: StreamBuffer
	typealias Output: StreamBuffer
	
	func start()
	func transform(input: Input) throws -> Output
	func finish() throws -> Output?

    func appendToBuffer(input: Input)
    func drainBuffer() -> Input
}

public class Transformer<T, U where T: StreamBuffer, U: StreamBuffer> : Transforming {
	public typealias Input = T
	public typealias Output = U
	
	public func start() {
		
	}
	
	public func transform(input: Input) throws -> Output {
		return Output()
	}
	
	public func finish() throws -> Output? {
		return nil
	}

    private(set) var buffer: Input = Input()
    public func appendToBuffer(input: Input) {
        buffer.appendContentsOf(input)
    }

    public func drainBuffer() -> Input {
        defer { buffer = Input() }
        return buffer
    }
}

public final class BlockTransformer<T, U where T: StreamBuffer, U: StreamBuffer>: Transformer<T, U> {
	public typealias TransformBlock = (T, BlockTransformer) throws -> U
	
	public let transformer: TransformBlock
	
	public init(transformer: TransformBlock) {
		self.transformer = transformer
	}

	public override func transform(input: Input) throws -> Output {
		return try self.transformer(input, self)
	}
}

public class TransformingPullStream<T, U, V: Transforming where U: StreamBuffer, T: Pullable, V.Input == T.Sequence, V.Output == U>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = U
	public typealias Output = U

	public typealias StreamTransformer = V
	let transformer: StreamTransformer
	
	public var pullStream: InputStream
	
	public var inputBuffer: InputStream.Sequence
	public var buffer: Sequence
	
	public init(inputStream: InputStream, transformer: StreamTransformer) {
		self.pullStream = inputStream

		self.inputBuffer = InputStream.Sequence()
		self.buffer = Sequence()
		
		self.transformer = transformer
	}

    private var didStart = false
    private var didEnd = false

	public func pull() -> Sequence? {
        if !didStart {
            didStart = true
            self.transformer.start()
        }

        do {
            var output = Output()

            if let input = self.pullStream.pull() {
                transformer.appendToBuffer(input)

                let data = transformer.drainBuffer()
                let transformed = try self.transformer.transform(data)
                output.appendContentsOf(transformed)
            }

            if isAtEnd && !didEnd {
                didEnd = true
                if let endData = try self.transformer.finish() {
                    output.appendContentsOf(endData)
                }
            }

            return output
        } catch let error {
            print("Do something with this error \(error)")
            return Output()
        }
	}
	
	public var isAtEnd: Bool {
		return self.pullStream.isAtEnd
	}
}

public class TransformingPushStream<T, U, V: Transforming where U: StreamBuffer, T: Pushable, V.Input == T.Sequence, V.Output == U>: TransformPushable {
	public typealias InputStream = T
	public typealias Sequence = U
	public typealias Output = U
	public typealias PushHandler = (Result<U>) -> Void
	
	public typealias StreamTransformer = V
	let transformer: StreamTransformer
	
	public var pushStream: InputStream
	public var inputBuffer: InputStream.Sequence
	public var buffer: Sequence = Sequence()
	
	public init(inputStream: InputStream, transformer: StreamTransformer) {
		self.pushStream = inputStream
		self.inputBuffer = InputStream.Sequence()
		self.transformer = transformer

		self.pushStream.wait(({ [weak self] (result: Result<InputStream.Sequence>) -> Void in
            self?.received(result)
		}) as! InputStream.PushHandler)
	}

    private var didStart = false
    private var didEnd = false
    private func received(result: Result<InputStream.Sequence>) {
        if didStart == false {
            didStart = true
            self.transformer.start()
        }

        do {
            var buffer = Output()

            let inValue = try result.result()
            let outValue = try self.transformer.transform(inValue)
            buffer.appendContentsOf(outValue)

            if isAtEnd && !didEnd {
                didEnd = true
                if let endData = try self.transformer.finish() {
                    buffer.appendContentsOf(endData)
                }
            }

            self.write(buffer)
        } catch let error {
            self.writeError(error)
        }
    }
	
	private var handlers: [PushHandler] = []
	public func wait(handler: PushHandler) {
		handlers.append(handler)
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
	
	public var isAtEnd: Bool {
		return self.pushStream.isAtEnd
	}
}

public extension Pullable {
	func transform<T: StreamBuffer>(block: (Self.Sequence) throws -> T) -> TransformingPullStream<Self, T, BlockTransformer<Sequence, T>> {
		return transformWith(BlockTransformer(transformer: { (sequence: Sequence, _: BlockTransformer<Sequence, T>) throws -> T in
			return try block(sequence)
		}))
	}

	func transformWith<T: StreamBuffer, U: Transforming where U.Input == Sequence, U.Output == T>(transformer: U) -> TransformingPullStream<Self, T, U> {
		return TransformingPullStream(inputStream: self, transformer: transformer)
	}

	func map<T: StreamBuffer>(transformer: (Self.Sequence.Generator.Element) -> T.Generator.Element) -> TransformingPullStream<Self, T, BlockTransformer<Self.Sequence, T>> {
		let transformer = BlockTransformer { (elements: Self.Sequence, _: BlockTransformer<Self.Sequence, T>) -> T in
			// why wont they let me use map here ;~;
			var outElements = T()
			elements.forEach({ (element: Self.Sequence.Generator.Element) -> Void in
				let outElement = transformer(element)
				outElements.append(outElement)
			})
			return outElements
		}
        return self.transformWith(transformer)
	}
	
	func flatMap<T: StreamBuffer>(transformer: (Self.Sequence.Generator.Element) -> T) -> TransformingPullStream<Self, T, BlockTransformer<Self.Sequence, T>> {
		let transformer = BlockTransformer { (elements: Self.Sequence, _: BlockTransformer<Self.Sequence, T>) -> T in
			// why wont they let me use map here ;~;
			var outElements = T()
			elements.forEach({ (element: Self.Sequence.Generator.Element) -> Void in
				let out = transformer(element)
				outElements.appendContentsOf(out)
			})
			return outElements
		}
        return self.transformWith(transformer)
	}
}

public extension Pushable {
	func transform<T: StreamBuffer>(block: (Sequence) throws -> T) -> TransformingPushStream<Self, T, BlockTransformer<Sequence, T>> {
		return transformWith(BlockTransformer(transformer: { (sequence: Sequence, _: BlockTransformer<Sequence, T>) throws -> T in
			return try block(sequence)
		}))
	}

	func transformWith<T: StreamBuffer, U: Transforming where U.Input == Sequence, U.Output == T>(transformer: U) -> TransformingPushStream<Self, T, U> {
		return TransformingPushStream(inputStream: self, transformer: transformer)
	}

	
	func map<T: StreamBuffer>(transformer: (Self.Sequence.Generator.Element) -> T.Generator.Element) -> TransformingPushStream<Self, T, BlockTransformer<Self.Sequence, T>> {
		let transformer = BlockTransformer { (elements: Self.Sequence, _: BlockTransformer<Self.Sequence, T>) -> T in
			// why wont they let me use map here ;~;
			var outElements = T()
			elements.forEach({ (element: Self.Sequence.Generator.Element) -> Void in
				let outElement = transformer(element)
				outElements.append(outElement)
			})
			return outElements
		}
		return TransformingPushStream(inputStream: self, transformer: transformer)
	}
	
	func flatMap<T: StreamBuffer>(transformer: (Self.Sequence.Generator.Element) -> T) -> TransformingPushStream<Self, T, BlockTransformer<Self.Sequence, T>> {
		let transformer = BlockTransformer { (elements: Self.Sequence, _: BlockTransformer<Self.Sequence, T>) -> T in
			// why wont they let me use map here ;~;
			var outElements = T()
			elements.forEach({ (element: Self.Sequence.Generator.Element) -> Void in
				let out = transformer(element)
				outElements.appendContentsOf(out)
			})
			return outElements
		}
		return TransformingPushStream(inputStream: self, transformer: transformer)
	}
}

