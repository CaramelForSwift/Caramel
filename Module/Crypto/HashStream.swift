//
//  HashStream.swift
//  Jelly
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public enum CryptoHash {
	case MD5
}

public class CryptoDigestStream<T: Pullable where T.Sequence: DataConvertible>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = Data
	public let pullStream: InputStream
	
	public var buffer = Data()
	public let hash: CryptoHash
	
	public var isAtEnd: Bool { 
		get {
			return pullStream.isAtEnd
		}
	}
	
	private let context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(1)
	public init(stream: InputStream, hash: CryptoHash) {
		self.pullStream = stream
		self.hash = hash

		CC_MD5_Init(context)
	}
	
	public func pull() -> Data? {
		if let data = self.pullStream.pull() {
			CC_MD5_Update(context, data.data.unsafeVoidPointer, CC_LONG(data.data.bytes.count))
			
			if isAtEnd {
				var digest = Array<UInt8>(count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)
				CC_MD5_Final(&digest, context)
				var data = Data(numberOfZeroes: Int(CC_MD5_DIGEST_LENGTH))
				for i in 0.stride(to: Int(CC_MD5_DIGEST_LENGTH), by: 1) {
					data.bytes[i] = digest[i]
				}
				return data
			}
		}
		return nil
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	var MD5Stream: CryptoDigestStream<Self> {
		get {
			return CryptoDigestStream(stream: self, hash: .MD5)
		}
	}
}