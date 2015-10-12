//
//  SHA224Hasher.swift
//  Caramel
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
		CC_SHA224_Update(context, data.bytes, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_SHA224_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
    var SHA224: TransformingPullStream<Self, Data, CryptoDigestTransformer<Self.Sequence, SHA224Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: SHA224Hasher()))
    }
}

public extension Pushable where Self.Sequence: DataConvertible {
    var SHA224: TransformingPushStream<Self, Data, CryptoDigestTransformer<Self.Sequence, SHA224Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: SHA224Hasher()))
    }
}

public extension DataConvertible {
	var SHA224: Data {
        return self.stream.SHA224.drain()
	}
}

public extension File {
	public func SHA224() throws -> Data {
        return try self.readPullStream().SHA224.drain()
	}
}
