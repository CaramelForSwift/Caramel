//
//  SHA512Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class SHA512Hasher: Hasher {
	public var hashLength = Int(CC_SHA512_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_SHA512_CTX>.alloc(1)
	
	public required init() {
		CC_SHA512_Init(context)
	}
	
	public func update(data: Data) {
		CC_SHA512_Update(context, data.unsafeVoidPointer, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_SHA512_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var SHA512: CryptoDigestStream<Self, SHA512Hasher> {
		get {
			return CryptoDigestStream(stream: self, hasher: SHA512Hasher())
		}
	}
}

public extension DataConvertible {
	var SHA512: Data {
		get {
			return self.stream.SHA512.drain()
		}
	}
}

public extension File {
	public func SHA512() throws -> Data {
        return try self.readPullStream().SHA512.drain()
	}
}
