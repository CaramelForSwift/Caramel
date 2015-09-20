//
//  Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public protocol Hasher {
	var hashLength: Int { get }

	init()
	func update(data: Data)
	func finish() -> Data
}

public extension Data {
	public init(byteArray array: [UInt8]) {
		self.init(numberOfZeroes: array.count)

		for i in 0.stride(to: array.count, by: 1) {
			self.bytes[i] = array[i]
		}
	}
}