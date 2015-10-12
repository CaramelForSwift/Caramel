//
//  StringData.swift
//  Caramel
//
//  Created by Steve Streza on 10/7/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

extension String.UnicodeScalarView: StreamBuffer {
    public mutating func append(elements: String.UnicodeScalarView) {
        self.appendContentsOf(elements)
    }
}

public extension Pushable where Self.Sequence: DataConvertible {
    var UTF8StringView: TransformingPushStream<Self, String.UnicodeScalarView> {
        return self.transformWith(DataToStringTransformer(encoding: .UTF8))
    }
    var UTF16StringView: TransformingPushStream<Self, String.UnicodeScalarView> {
        return self.transformWith(DataToStringTransformer(encoding: .UTF16))
    }
}

public extension Pullable where Self.Sequence: DataConvertible {
    var UTF8StringView: TransformingPullStream<Self, String.UnicodeScalarView> {
        return self.transformWith(DataToStringTransformer(encoding: .UTF8))
    }
    var UTF16StringView: TransformingPullStream<Self, String.UnicodeScalarView> {
        return self.transformWith(DataToStringTransformer(encoding: .UTF16))
    }
}

public class DataToStringTransformer<T: DataConvertible>: Transformer<T, String.UnicodeScalarView> {
    public init(encoding: String.Encoding) {
        super.init { (dataConvertible: T, transformer: Transformer<T, String.UnicodeScalarView>) throws -> String.UnicodeScalarView in
            return String.UnicodeScalarView()
        }
    }
}
