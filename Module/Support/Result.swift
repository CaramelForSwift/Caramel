//
//  Result.swift
//  Caramel
//
//  Created by Steve Streza on 9/24/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public enum Result<T> {
    case Success(T)
    case Error(ErrorType)
    
    public func result() throws -> T {
        switch self {
        case let .Success(value):
            return value
        case let .Error(error):
            throw error
        }
    }
    
    public static func attempt<T>(@autoclosure handler: () throws -> T) -> Result<T> {
        do {
            let value = try handler()
            return .Success(value)
        } catch let error {
            return .Error(error)
        }
    }
}
