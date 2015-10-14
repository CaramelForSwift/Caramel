//
//  EventLoop.swift
//  Caramel
//
//  Created by Steve Streza on 2.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

public class EventLoop {
	public static var defaultLoop: EventLoop = {
		let loop = EventLoop()
		loop.uvLoop = uv_default_loop()
		return loop
	}()
	
	internal var uvLoop: UnsafeMutablePointer<uv_loop_t> = {
		let pointer = UnsafeMutablePointer<uv_loop_t>.alloc(1)
		let result = uv_loop_init(pointer)
		if result != 0 {
			fatalError()
		}
		return pointer
	}()
	
	public init() {
	}
	
	public func run() {
		uv_run(uvLoop, UV_RUN_DEFAULT)
	}
}
