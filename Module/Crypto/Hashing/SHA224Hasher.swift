//
//  SHA224Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class SHA224Hasher: Hasher {
	public var hashLength = Int(CC_SHA224_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_SHA256_CTX>.alloc(1)
	
	public required init() {
		CC_SHA224_Init(context)
	}
	
	public func update(data: Data) {
		CC_SHA224_Update(context, data.unsafeVoidPointer, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_SHA224_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var SHA224Stream: CryptoDigestStream<Self, SHA224Hasher> {
		get {
			return CryptoDigestStream(stream: self, hasher: SHA224Hasher())
		}
	}
}

public extension DataConvertible {
	var SHA224: Data? {
		get {
			return self.stream.SHA224Stream.drain()
		}
	}
}

public extension File {
	var SHA224: Data? {
		get {
			return self.readPullStream?.SHA224Stream.drain()
		}
	}
}
