//
//  StreamBuffer.swift
//  Caramel
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public protocol StreamBuffer: SequenceType {
	init()
	mutating func appendContentsOf(elements: Self)
	mutating func append(element: Self.Generator.Element)
}

extension Data: StreamBuffer {
	public mutating func appendContentsOf(newBytes: Data) {
		self.bytes += newBytes
	}
	public mutating func append(newByte: Byte) {
		self.bytes.append(newByte)
	}
}

extension Array: StreamBuffer {
	public mutating func append(elements: Array<Array.Generator.Element>) {
		self.appendContentsOf(elements)
	}
}