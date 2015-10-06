//
//  StreamBuffer.swift
//  Caramel
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public protocol StreamBuffer: SequenceType {
	init()
	mutating func append(elements: Self)
}

extension Data: StreamBuffer {
	public mutating func append(newBytes: Data) {
		self.bytes += newBytes
	}
}

extension Array: StreamBuffer {
	public mutating func append(elements: Array<Array.Generator.Element>) {
		self.appendContentsOf(elements)
	}
}