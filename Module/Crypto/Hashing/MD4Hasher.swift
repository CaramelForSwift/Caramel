//
//  MD4Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class MD4Hasher: Hasher {
	public var hashLength = Int(CC_MD4_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_MD4_CTX>.alloc(1)
	
	public required init() {
		CC_MD4_Init(context)
	}
	
	public func update(data: Data) {
		CC_MD4_Update(context, data.unsafeVoidPointer, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_MD4_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var MD4Stream: CryptoDigestStream<Self, MD4Hasher> {
		get {
			return CryptoDigestStream(stream: self, hasher: MD4Hasher())
		}
	}
}

public extension Data {
	var MD4: Data? {
		get {
			return FulfilledPullableStream(values: self).MD4Stream.drain()
		}
	}
}

public extension File {
	var MD4: Data? {
		get {
			return self.readPullStream?.MD4Stream.drain()
		}
	}
}
