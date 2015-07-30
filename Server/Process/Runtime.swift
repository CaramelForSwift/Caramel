//
//  Runtime.swift
//  Jelly
//
//  Created by Steve Streza on 29.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public extension Process {
	public static func environment(variable: String) -> String? {
		let value = getenv(variable)
		if value != nil {
			let env = String.fromCString(UnsafePointer<CChar>(value))
			return env
		}
		return nil
	}
}