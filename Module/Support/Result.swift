//
//  Result.swift
//  Jelly
//
//  Created by Steve Streza on 9/24/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public enum Container<T> {
    case Success(T)
    case Error(U: ErrorType)
    
    public func result() throws -> T {
        switch self {
        case let .Success(value):
            return value
        case let .Error(error):
            throw error
        }
    }
}
