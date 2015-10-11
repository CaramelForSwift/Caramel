//
//  StringToData.swift
//  Caramel
//
//  Created by Steve Streza on 10.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

extension String.UnicodeScalarView: StreamBuffer {
	public mutating func append(elements: String.UnicodeScalarView) {
		self.appendContentsOf(elements)
	}
}

public class StringToDataTransformer<T: StreamBuffer where T.Generator.Element == String>: Transformer<T, Data> {
	public typealias Input = T
	let encoding: String.Encoding
	public init(encoding: String.Encoding) {
		self.encoding = encoding
	}
	
	public override func transform(input: Input) throws -> Data {
		var data = Data()
		switch self.encoding {
		case .UTF8:
			input.forEach({ (string: String) -> () in
				var bytes: [Byte] = []
				for thing in string.utf8 {
					bytes.append(Byte(thing))
				}
				data.append(bytes)
			})
		case .UTF16:
			input.forEach({ (string: String) -> () in
				var bytes: [Byte] = []
				for thing in string.utf16 {
					bytes.append(Byte((thing & 0xFF00) >> 8))
					bytes.append(Byte(thing & 0xFF))
				}
				data.append(bytes)
			})
		}
		return data;
	}
	
	public override func finish() throws -> Data? {
		return nil
	}
}

public class DataToStringTransformer<T: DataConvertible>: Transformer<T, String.UnicodeScalarView> {
	public typealias Input = T
	let encoding: String.Encoding
	public init(encoding: String.Encoding) {
		self.encoding = encoding
	}
	
	public override func transform(input: Input) throws -> String.UnicodeScalarView {
		switch encoding {
		case .UTF8:
			var view = String.UnicodeScalarView()
			
			var utf8 = UTF8()
			var generator = input.data.bytes.generate()
			var result:	UnicodeDecodingResult
			repeat {
				result = utf8.decode(&generator)
				
				switch result {
				case .Result(let scalar):
					view.append(scalar)
				default:
					break
				}
			} while (!result.isEmptyInput())
			return view
		case .UTF16:
			var view = String.UnicodeScalarView()
			
			var utf16 = UTF16()
			let batchGenerator = GeneratorBatcher(generator: input.data.bytes.generate(), size: 2)
			var uint16Generator = GeneratorMapper(generator: batchGenerator, mapper: { (bytes: [Byte]) -> UInt16 in
				let uint16: UInt16
				if bytes.count == 2 {
					let byte1 = UInt16(bytes[0])
					let byte2 = UInt16(bytes[1])
					uint16 = byte1 << 8 + byte2
				} else if bytes.count == 1 {
					uint16 = UInt16(bytes[0])
				} else {
					uint16 = 0
				}
				return uint16
			})
			
			var result:	UnicodeDecodingResult
			repeat {
				result = utf16.decode(&uint16Generator)
				
				switch result {
				case .Result(let scalar):
					view.append(scalar)
				default:
					break
				}
			} while (!result.isEmptyInput())
			return view
		}
	}
	
	public override func finish() throws -> String.UnicodeScalarView? {
		return nil
	}
}

public extension String {
	public var pullStream: FulfilledPullableStream<[String]> {
		return FulfilledPullableStream(values: [self])
	}
}

public extension Pullable where Self.Sequence.Generator.Element == String {
	public var UTF8Data: TransformingPullStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
		return TransformingPullStream(inputStream: self, transformer: StringToDataTransformer(encoding: .UTF8))
	}
	public var UTF16Data: TransformingPullStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
		return TransformingPullStream(inputStream: self, transformer: StringToDataTransformer(encoding: .UTF16))
	}
}

public extension Pushable where Self.Sequence.Generator.Element == String {
	public var UTF8Data: TransformingPushStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: StringToDataTransformer(encoding: .UTF8))
	}
	public var UTF16Data: TransformingPushStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: StringToDataTransformer(encoding: .UTF16))
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	public var UTF8StringView: TransformingPullStream<Self, String.UnicodeScalarView, DataToStringTransformer<Self.Sequence>> {
		return TransformingPullStream(inputStream: self, transformer: DataToStringTransformer(encoding: .UTF8))
	}
	public var UTF16StringView: TransformingPullStream<Self, String.UnicodeScalarView, DataToStringTransformer<Self.Sequence>> {
		return TransformingPullStream(inputStream: self, transformer: DataToStringTransformer(encoding: .UTF16))
	}
}

public extension Pushable where Self.Sequence: DataConvertible {
	public var UTF8StringView: TransformingPushStream<Self, String.UnicodeScalarView, DataToStringTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: DataToStringTransformer(encoding: .UTF8))
	}
	public var UTF16StringView: TransformingPushStream<Self, String.UnicodeScalarView, DataToStringTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: DataToStringTransformer(encoding: .UTF16))
	}
}
