//
//  SHA1Hasher.swift
//  Caramel
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class SHA1Hasher: Hasher {
	public var hashLength = Int(CC_SHA1_DIGEST_LENGTH)
	
	private let context = UnsafeMutablePointer<CC_SHA1_CTX>.alloc(1)
	
	public required init() {
		CC_SHA1_Init(context)
	}
	
	public func update(data: Data) {
		CC_SHA1_Update(context, data.bytes, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_SHA1_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
    var SHA1: TransformingPullStream<Self, Data, CryptoDigestTransformer<Self.Sequence, SHA1Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: SHA1Hasher()))
    }
}

public extension Pushable where Self.Sequence: DataConvertible {
    var SHA1: TransformingPushStream<Self, Data, CryptoDigestTransformer<Self.Sequence, SHA1Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: SHA1Hasher()))
    }
}

public extension DataConvertible {
	var SHA1: Data {
        return self.stream.SHA1.drain()
	}
}

public extension File {
    public func SHA1() throws -> Data {
        return try self.readPullStream().SHA1.drain()
	}
}
