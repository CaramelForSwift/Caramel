//
//  StringSupport.swift
//  Caramel
//
//  Created by Steve Streza on 10/12/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public extension Pullable where Self.Sequence.Generator.Element == String {
    public func splitBy(split: Character) -> TransformingPullStream<Self, [String], BlockTransformer<Self.Sequence, [String]>> {
        return self.flatMap({ (string: String) -> [String] in
            string.characters.split { $0 == split }.map { String($0) }
        })
    }
}

public extension Pushable where Self.Sequence.Generator.Element == String {
    public func splitBy(split: Character) -> TransformingPushStream<Self, [String], BlockTransformer<Self.Sequence, [String]>> {
        return self.flatMap({ (string: String) -> [String] in
            string.characters.split { $0 == split }.map { String($0) }
        })
    }
}
