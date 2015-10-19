//
//  UVSupport.swift
//  Caramel
//
//  Created by Steve Streza on 18.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal func Caramel_uv_alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
	buf.memory = uv_buf_init(UnsafeMutablePointer<Int8>.alloc(size), UInt32(size))
}
