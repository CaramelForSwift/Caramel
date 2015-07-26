//
//  Data.swift
//  SwiftWebServer
//
//  Created by Steve Streza on 26.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public typealias Byte = UInt8

public enum Encoding {
	case UTF8
}

public protocol Data: class, Hashable
{
	var bytes: [Byte] { get }
	func append(bytes: [Byte])
}

public func ==<T: Data>(lhs: T, rhs: T) -> Bool {
	return lhs.bytes == rhs.bytes
}

extension Data {
	public var unsafeVoidPointer: UnsafePointer<Void> {
		get {
			let buffer = UnsafeMutablePointer<UInt8>.alloc(self.bytes.count)
			for (i, byte) in bytes.enumerate() {
				buffer[i] = byte
			}
			return UnsafePointer<Void>(buffer)
		}
	}
	
	// https://en.wikipedia.org/wiki/Jenkins_hash_function
	public var jenkinsHash: Int {
		get {
			var hash = bytes.reduce(0, combine: { (initial: Int, byte: Byte) -> Int in
				var value = initial + Int(byte)
				value += (value << 10)
				value ^= (value >> 6)
				return value
			})
			hash += (hash << 3);
			hash ^= (hash >> 11);
			hash += (hash << 15);
			return hash
		}
	}
	
	public func append(buffer: UnsafePointer<Void>, length: Int) {
		var bytes = UnsafePointer<Byte>(buffer)
		var byteArray: [Byte] = []
		for i in stride(from: 0, to: length, by: 1) {
			byteArray.append(bytes[i])
		}
		self.append(byteArray)
	}
	
	public func stringWithEncoding(encoding: Encoding) -> String? {
		switch encoding {
		case .UTF8:
			return String.fromCString(UnsafePointer<CChar>(self.unsafeVoidPointer))
		default:
			return nil
		}
	}
}
