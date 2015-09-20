//
//  SHA256Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class SHA256Hasher: Hasher {
	public var hashLength = Int(CC_SHA256_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_SHA256_CTX>.alloc(1)
	
	public required init() {
		CC_SHA256_Init(context)
	}
	
	public func update(data: Data) {
		CC_SHA256_Update(context, data.unsafeVoidPointer, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_SHA256_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var SHA256Stream: CryptoDigestStream<Self, SHA256Hasher> {
		get {
			return CryptoDigestStream(stream: self, hasher: SHA256Hasher())
		}
	}
}

public extension DataConvertible {
	var SHA256: Data? {
		get {
			return FulfilledPullableStream(values: self.data).SHA256Stream.drain()
		}
	}
}

public extension File {
	var SHA256: Data? {
		get {
			return self.readPullStream?.SHA256Stream.drain()
		}
	}
}
