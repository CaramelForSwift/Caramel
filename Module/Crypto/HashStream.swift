//
//  HashStream.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class CryptoDigestStream<T: Pullable, U: Hasher where T.Sequence: DataConvertible>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = Data
	public typealias Hasher = U
	public let pullStream: InputStream
	
	public var buffer = Data()
	public let hasher: Hasher
	
	public var isAtEnd: Bool { 
        return pullStream.isAtEnd
	}
	
	private let context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
	public init(stream: InputStream, hasher: Hasher) {
		self.pullStream = stream
		self.hasher = hasher
	}
	
	public func pull() -> Data? {
		if let data = self.pullStream.pull() {
			self.hasher.update(data.data)
			
			if isAtEnd {
				return self.hasher.finish()
			}
		}
		return nil
	}
}
