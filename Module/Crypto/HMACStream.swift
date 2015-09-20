//
//  HMACStream.swift
//  Jelly
//
//  Created by Steve Streza on 20.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public enum HMACAlgorithm {
	case MD5
	case SHA1
	case SHA224
	case SHA256
	case SHA384
	case SHA512
}

public class CryptoHMACStream<T: Pullable where T.Sequence: DataConvertible>: TransformPullable {
	public typealias InputStream = T
	public typealias Sequence = Data
	public let pullStream: InputStream
	
	public var buffer = Data()

	public let algorithm: HMACAlgorithm
	public let key: Data
	
	private let context = UnsafeMutablePointer<CCHmacContext>.alloc(1)
	
	public var isAtEnd: Bool { 
		get {
			return pullStream.isAtEnd
		}
	}
	
	private var ccAlgorithm: CCHmacAlgorithm {
		get {
			switch algorithm {
			case .MD5: return CCHmacAlgorithm(kCCHmacAlgMD5)
			case .SHA1: return CCHmacAlgorithm(kCCHmacAlgSHA1)
			case .SHA224: return CCHmacAlgorithm(kCCHmacAlgSHA224)
			case .SHA256: return CCHmacAlgorithm(kCCHmacAlgSHA256)
			case .SHA384: return CCHmacAlgorithm(kCCHmacAlgSHA384)
			case .SHA512: return CCHmacAlgorithm(kCCHmacAlgSHA512)
			}
		}
	}
	
	private var hmacLength: Int {
		get {
			switch algorithm {
			case .MD5: return Int(CC_MD5_DIGEST_LENGTH)
			case .SHA1: return Int(CC_SHA1_DIGEST_LENGTH)
			case .SHA224: return Int(CC_SHA224_DIGEST_LENGTH)
			case .SHA256: return Int(CC_SHA256_DIGEST_LENGTH)
			case .SHA384: return Int(CC_SHA384_DIGEST_LENGTH)
			case .SHA512: return Int(CC_SHA512_DIGEST_LENGTH)
			}
		}
	}
	
	public init(stream: InputStream, algorithm: HMACAlgorithm, key: Data) {
		self.pullStream = stream
		self.algorithm = algorithm
		self.key = key
		
		CCHmacInit(context, self.ccAlgorithm, key.bytes, key.bytes.count)
	}
	
	public func pull() -> Data? {
		if let data = self.pullStream.pull() {
			CCHmacUpdate(self.context, data.data.unsafeVoidPointer, data.data.bytes.count)
			
			if isAtEnd {
				var digest = Array<UInt8>(count: self.hmacLength, repeatedValue:0)
				CCHmacFinal(self.context, &digest)
				return Data(byteArray: digest)
			}
		}
		return nil
	}
}

public extension Pullable where Self.Sequence: DataConvertible {
	func HMAC(algorithm: HMACAlgorithm, withKey key: Data) -> CryptoHMACStream<Self> {
		return CryptoHMACStream(stream: self, algorithm: algorithm, key: key)
	}
}

public extension DataConvertible {
	func HMAC(algorithm: HMACAlgorithm, withKey key: Data) -> Data? {
		return self.stream.HMAC(algorithm, withKey: key).drain()
	}
}

public extension File {
	func HMAC(algorithm: HMACAlgorithm, withKey key: Data) -> Data? {
		return self.readPullStream?.HMAC(algorithm, withKey: key).drain()
	}
}
