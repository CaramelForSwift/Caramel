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

public class StringUnicodeScalarViewToDataTransformer: Transformer<String.UnicodeScalarView, Data> {
    let encoding: String.Encoding
    public init(encoding: String.Encoding) {
        self.encoding = encoding
    }

    public override func transform(input: Input) throws -> Data {
        var data = Data()
        switch self.encoding {
        case .UTF8:
            input.forEach { (scalar: UnicodeScalar) -> () in
                UTF8.encode(scalar, output: { (unit: UTF8.CodeUnit) -> () in
                    data.append(Byte(unit))
                })
            }
        case .UTF16:
            input.forEach({ (scalar: UnicodeScalar) -> () in
                UTF16.encode(scalar, output: { (unit: UTF16.CodeUnit) -> () in
                    data.append(Byte((unit & 0xFF00) >> 8))
                    data.append(Byte(unit & 0xFF))
                })
            })
        }
        return data;
    }
    
    public override func finish() throws -> Data? {
        return nil
    }
}

public class DataToStringUnicodeScalarViewTransformer<T: DataConvertible>: Transformer<T, String.UnicodeScalarView> {
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

public class UnicodeScalarViewToStringTransformer: Transformer<String.UnicodeScalarView, [String]> {
    public override func transform(input: String.UnicodeScalarView) throws -> [String] {
        self.appendToBuffer(input)
        return []
    }

    public override func finish() throws -> [String]? {
        let scalars = self.drainBuffer()
        return [String(scalars)]
    }
}

public class UnicodeScalarViewToSplitStringTransformer: Transformer<String.UnicodeScalarView, [String]> {
    private func split(input: String.UnicodeScalarView) -> ([String], String.UnicodeScalarView) {
        var strings: [String] = []
        var slicedInput = input
        while let next = slicedInput.indexOf(splitter) {
            let slice = slicedInput.prefixUpTo(next)
            strings.append(String(slice))
            slicedInput = slicedInput.suffixFrom(next.advancedBy(1))
        }
        return (strings, slicedInput)
    }

    public let splitter: UnicodeScalar
    public init(splitter: UnicodeScalar) {
        self.splitter = splitter
    }

    public override func transform(input: String.UnicodeScalarView) throws -> [String] {
        let (strings, remainder) = split(input)
        self.appendToBuffer(remainder)
        return strings
    }

    public override func finish() throws -> [String]? {
        let input = self.drainBuffer()
        var (strings, remainder) = split(input)
        if remainder.count > 0 {
            strings.append(String(remainder))
        }
        return strings
    }
}

public extension String {
	public var pullStream: FulfilledPullableStream<[String]> {
		return FulfilledPullableStream(values: [self])
	}
}

public extension Pullable where Self.Sequence.Generator.Element == String {
	public var UTF8Data: TransformingPullStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
        return self.transformWith(StringToDataTransformer(encoding: .UTF8))
	}
	public var UTF16Data: TransformingPullStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
        return self.transformWith(StringToDataTransformer(encoding: .UTF16))
	}
}

public extension Pushable where Self.Sequence.Generator.Element == String {
	public var UTF8Data: TransformingPushStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
        return self.transformWith(StringToDataTransformer(encoding: .UTF8))
	}
	public var UTF16Data: TransformingPushStream<Self, Data, StringToDataTransformer<Self.Sequence>> {
        return self.transformWith(StringToDataTransformer(encoding: .UTF16))
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	public var UTF8StringView: TransformingPullStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>> {
        return self.transformWith(DataToStringUnicodeScalarViewTransformer(encoding: .UTF8))
	}
	public var UTF16StringView: TransformingPullStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>> {
        return self.transformWith(DataToStringUnicodeScalarViewTransformer(encoding: .UTF16))
	}

    public var UTF8String: TransformingPullStream<TransformingPullStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>>, [String], UnicodeScalarViewToStringTransformer> {
        return self.UTF8StringView.transformWith(UnicodeScalarViewToStringTransformer())
    }
    public var UTF16String: TransformingPullStream<TransformingPullStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>>, [String], UnicodeScalarViewToStringTransformer> {
        return self.UTF16StringView.transformWith(UnicodeScalarViewToStringTransformer())
    }
}

public extension Pushable where Self.Sequence: DataConvertible {
	public var UTF8StringView: TransformingPushStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: DataToStringUnicodeScalarViewTransformer(encoding: .UTF8))
	}
	public var UTF16StringView: TransformingPushStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>> {
		return TransformingPushStream(inputStream: self, transformer: DataToStringUnicodeScalarViewTransformer(encoding: .UTF16))
	}

    public var UTF8String: TransformingPushStream<TransformingPushStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>>, [String], UnicodeScalarViewToStringTransformer> {
        return TransformingPushStream(inputStream: self.UTF8StringView, transformer: UnicodeScalarViewToStringTransformer())
    }
    public var UTF16String: TransformingPushStream<TransformingPushStream<Self, String.UnicodeScalarView, DataToStringUnicodeScalarViewTransformer<Self.Sequence>>, [String], UnicodeScalarViewToStringTransformer> {
        return TransformingPushStream(inputStream: self.UTF16StringView, transformer: UnicodeScalarViewToStringTransformer())
    }
}

