//
//  DataChunk.swift
//  SwiftWebServer
//
//  Created by Steve Streza on 26.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class DataChunk: Data {
	public private(set) var bytes: [Byte] = []
	public func append(bytes: [Byte]) {
		self.bytes += bytes
	}
	
	public var hashValue: Int {
		get {
			return self.jenkinsHash
		}
	}
}
