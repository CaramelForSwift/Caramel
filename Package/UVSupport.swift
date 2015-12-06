//
//  UVSupport.swift
//  Caramel
//
//  Created by Steve Streza on 18.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import CUv

internal func Caramel_uv_alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
	buf.memory = uv_buf_init(UnsafeMutablePointer<Int8>.alloc(size), UInt32(size))
}

internal func uv_buf_init_d(buf: UnsafeMutablePointer<Void>, _ len: UInt32) -> uv_buf_t {
	let buffer = unsafeBitCast(buf, UnsafeMutablePointer<Int8>.self)
	return uv_buf_init(buffer, len)
}

