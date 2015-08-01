//
//  Data.swift
//  Jelly
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

public protocol Data
{
	var bytes: [Byte] { get }
	mutating func append(bytes: [Byte])
}

public func ==<T: Data>(lhs: T, rhs: T) -> Bool {
	return lhs.bytes == rhs.bytes
}

extension Data {
	public var unsafeVoidPointer: UnsafePointer<Void> {
		get {
			let buffer = UnsafeMutablePointer<UInt8>.alloc(self.bytes.count + 1)
			for (i, byte) in bytes.enumerate() {
				buffer[i] = byte
			}
			buffer[self.bytes.count] = 0
			return UnsafePointer<Void>(buffer)
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
	
	public mutating func append(buffer: UnsafePointer<Void>, length: Int) {
		var bytes = UnsafePointer<Byte>(buffer)
		var byteArray: [Byte] = []
		for i in stride(from: 0, to: length, by: 1) {
			byteArray.append(bytes[i])
		}
		self.append(byteArray)
	}
	
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
		default:
			return nil
		}
	}
}
