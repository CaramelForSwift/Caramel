//
//  MD4Hasher.swift
//  Caramel
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
		CC_MD4_Update(context, data.bytes, CC_LONG(data.bytes.count))
	}
	
	public func finish() -> Data {
		var digest = Array<UInt8>(count: self.hashLength, repeatedValue:0)
		CC_MD4_Final(&digest, context)
		return Data(byteArray: digest)
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
    var MD4: TransformingPullStream<Self, Data, CryptoDigestTransformer<Self.Sequence, MD4Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: MD4Hasher()))
    }
}

public extension Pushable where Self.Sequence: DataConvertible {
    var MD4: TransformingPushStream<Self, Data, CryptoDigestTransformer<Self.Sequence, MD4Hasher>> {
        return self.transformWith(CryptoDigestTransformer(hasher: MD4Hasher()))
    }
}

public extension DataConvertible {
	var MD4: Data {
        return self.stream.MD4.drain()
	}
}

public extension File {
    public func MD4() throws -> Data {
        return try self.readPullStream().MD4.drain()
	}
}
