//
//  DataChunk.swift
//  Jelly
//
//  Created by Steve Streza on 26.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public struct DataChunk: Data {
	public private(set) var bytes: [Byte] = []
	public mutating func append(bytes: [Byte]) {
		self.bytes += bytes
	}
	
	public var hashValue: Int {
		get {
			return self.jenkinsHash
		}
	}
}

public extension String.UTF8View {
	public var data: Data {
		get {
			var data = DataChunk()
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
			var data = DataChunk()
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
