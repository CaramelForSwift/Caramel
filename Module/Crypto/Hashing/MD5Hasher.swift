//
//  MD5Hasher.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class MD5Hasher: Hasher {
	public var hashLength = Int(CC_MD5_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
	
	public required init() {
		CC_MD5_Init(context)
	}
	
	public func update(data: Data) {
		CC_MD5_Update(context, data.bytes, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_MD5_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var MD5: CryptoDigestStream<Self, MD5Hasher> {
        return CryptoDigestStream(stream: self, hasher: MD5Hasher())
	}
}

public extension DataConvertible {
	var MD5: Data {
        return self.stream.MD5.drain()
	}
}

public extension File {
    public func MD5() throws -> Data {
        return try self.readPullStream().MD5.drain()
	}
}
