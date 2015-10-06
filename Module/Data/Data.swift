//
//  Data.swift
//  Caramel
//
//  Created by Steve Streza on 26.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public typealias Byte = UInt8

public enum Encoding {
	case UTF8
	case UTF16
}

public struct Data {
	public var bytes: [Byte] = []
	public mutating func append(bytes: [Byte]) {
		self.bytes += bytes
	}
	
	public init() {}
	
	public init(numberOfZeroes: Int) {
		for _ in 0.stride(to: numberOfZeroes, by: 1) {
			self.bytes.append(0)
		}
		assert(numberOfZeroes == self.bytes.count)
	}

	public mutating func append(buffer: UnsafePointer<Void>, length: Int) {
		let bytes = UnsafePointer<Byte>(buffer)
		var byteArray: [Byte] = []
		for i in 0.stride(to: length, by: 1) {
			byteArray.append(bytes[i])
		}
		self.append(byteArray)
	}
}

public extension UInt8 {
	static let nibbleCharacters = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
	var byteString: String {
		get {
			let value = self
			let highNibble = ((value & 0xF0) >> 4) & 0x0F
			let lowNibble = value & 0x0F
			let highCharacter = UInt8.nibbleCharacters[Int(highNibble)]
			let  lowCharacter = UInt8.nibbleCharacters[Int( lowNibble)]
			let string = highCharacter + lowCharacter
			return string

		}
	}
}

extension Data: CustomDebugStringConvertible {
	public var debugDescription: String {
		get {
			var hexString = ""
			for byte in self.bytes {
				hexString += byte.byteString
			}
			return hexString
		}
	}
}

// MARK: String to Data
public extension String.UTF8View {
	public var data: Data {
		get {
			var data = Data()
			var bytes: [Byte] = []
			for thing in self {
				bytes.append(Byte(thing))
			}
			data.append(bytes)
			return data
		}
	}
}

public extension String.UTF16View {
	public var data: Data {
		get {
			var data = Data()
			var bytes: [Byte] = []
			for thing in self {
				bytes.append(Byte((thing & 0xFF00) >> 8))
				bytes.append(Byte(thing & 0xFF))
			}
			data.append(bytes)
			return data
		}
	}
}

public extension String {
	public var UTF8Data: Data {
		get {
			return self.utf8.data
		}
	}
	public var UTF16Data: Data {
		get {
			return self.utf16.data
		}
	}
	public var UTF32Data: Data {
		get {
			var data = Data()
			var bytes: [Byte] = []
			for scalar in self.unicodeScalars {
				UTF32.encode(scalar) { (thing: UTF32.CodeUnit) -> () in
					bytes.append(Byte((thing & 0xFF000000) >> 24))
					bytes.append(Byte((thing & 0x00FF0000) >> 16))
					bytes.append(Byte((thing & 0x0000FF00) >> 8))
					bytes.append(Byte((thing & 0x000000FF)))
				}
			}
			data.append(bytes)
			return data
		}
	}
}

// Data to String
public extension Data {
	public var UTF8String: String? {
		get {
			return stringWithEncoding(.UTF8)
		}
	}
	
	public var UTF16String: String? {
		get {
			return stringWithEncoding(.UTF16)
		}
	}
	
	public func stringWithEncoding(encoding: Encoding) -> String? {
		switch encoding {
		case .UTF8:
			var view = String.UnicodeScalarView()
			
			var utf8 = UTF8()
			var generator = self.bytes.generate()
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
			return String(view)
		case .UTF16:
			var view = String.UnicodeScalarView()
			
			var utf16 = UTF16()
			let batchGenerator = GeneratorBatcher(generator: self.bytes.generate(), size: 2)
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
			return String(view)
		}
	}
}

// MARK: Equatable
extension Data: Equatable {}
public func ==(lhs: Data, rhs: Data) -> Bool {
	return lhs.bytes == rhs.bytes
}

// MARK: Hashable
extension Data: Hashable {
	public var hashValue: Int {
		get {
			return self.jenkinsHash
		}
	}

	// https://en.wikipedia.org/wiki/Jenkins_hash_function
	public var jenkinsHash: Int {
		get {
			var hash = bytes.reduce(0, combine: { (initial: Int, byte: Byte) -> Int in
				var value = initial + Int(byte)
				value = value &+ (value << 10)
				value ^= (value >> 6)
				return value
			})
			hash = hash &+ (hash << 3);
			hash ^= (hash >> 11);
			hash = hash &+ (hash << 15);
			return hash
		}
	}
}

// MARK: SequenceType
extension Data: SequenceType {
	public typealias Generator = Data.DataGenerator
	public struct DataGenerator: GeneratorType {
		public typealias Element = Byte
		let data: Data
		var offset = 0
		public init(data: Data) {
			self.data = data
		}
		public mutating func next() -> Byte? {
			if offset < data.bytes.count {
				return data.bytes[offset++]
			} else {
				return nil
			}
		}
	}

	public func generate() -> Data.DataGenerator {
		return Data.Generator(data: self)
	}
	
	public func underestimateCount() -> Int {
		return self.bytes.count
	}
	
	public func map<T>(@noescape transform: (Byte) -> T) -> [T] {
		var result: [T] = []
		for byte in self.bytes {
			let output = transform(byte)
			result.append(output)
		}
		return result
	}
	
	public func filter(@noescape includeElement: (Byte) -> Bool) -> [Byte] {
		var filteredBytes: [Byte] = []
		for byte in self.bytes {
			if includeElement(byte) {
				filteredBytes.append(byte)
			}
		}
		return filteredBytes
	}
}

// MARK: Indexable
extension Data: Indexable {
    public typealias Index = Int

	public var startIndex: Data.Index { 
		get {
			return self.bytes.startIndex
		}
	}
	
	public var endIndex: Data.Index { 
		get {
			return self.bytes.endIndex
		} 
	}

	public subscript (position: Data.Index) -> Byte { 
		get {
			return self.bytes[position]
		}
	}
}

public protocol DataConvertible: StreamBuffer {
	var data: Data { get }
}

extension Data: DataConvertible {
	public var data: Data {
		get {
			return self
		}
	}
}
