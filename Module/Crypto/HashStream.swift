//
//  HashStream.swift
//  Caramel
//
//  Created by Steve Streza on 19.9.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class CryptoDigestTransformer<T: DataConvertible, U: Hasher>: Transformer<T, Data> {
    public typealias Hasher = U
    private var hasher: Hasher

    public init(hasher: Hasher) {
        self.hasher = hasher
    }

    public override func transform(input: Input) throws -> Data {
        self.hasher.update(input.data)
        return Data()
    }

    public override func finish() throws -> Data? {
        return self.hasher.finish()
    }
}
