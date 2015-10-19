//
//  TCPConnection.swift
//  Caramel
//
//  Created by Steve Streza on 18.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal typealias TCPConnectionUVCallback = (UnsafeMutablePointer<uv_stream_t>, Int, UnsafePointer<uv_buf_t>) -> Void

internal func TCPConnection_uv_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
	let ptr = stream.memory.data
	let cb = unsafeBitCast(ptr, TCPConnectionUVCallbackClosureBox.self).callback
	cb(stream, size, buf)
}

internal class TCPConnectionUVCallbackClosureBox {
	let callback: TCPConnectionUVCallback
	init(_ callback: TCPConnectionUVCallback) {
		self.callback = callback
	}
}

public class NetConnection<T: StreamBuffer> {
	public typealias Source = T
	public let input: PushStream<T>
	public required init(input: PushStream<T>) {
		self.input = input
	}
}

public class TCPConnection: NetConnection<Data> {
	public required init(input: PushStream<TCPConnection.Source>) {
		super.init(input: input)
	}
	
	private var clientTCP: UnsafeMutablePointer<uv_tcp_t> = nil
	private var clientStream: UnsafeMutablePointer<uv_stream_t> {
		return UnsafeMutablePointer<uv_stream_t>(clientTCP)
	}
	private var readClosure: TCPConnectionUVCallbackClosureBox?
	
	private var connection: TCPConnection? = nil
	
	internal func listen(server: TCPServer) {
		guard clientTCP == nil else { return }

		readClosure = TCPConnectionUVCallbackClosureBox { [weak self] handle, size, buf in
			self?.didRead(handle, size: size, buffer: buf)
		}
		connection = self
		
		clientTCP = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
		let rc0 = uv_tcp_init(server.eventLoop.uvLoop, clientTCP)
		let rc1 = uv_accept(server.uvStream, clientStream)
		let rc2 = uv_read_start(clientStream, Caramel_uv_alloc_cb, TCPConnection_uv_read_cb)
		print("accept read: \(rc0) \(rc1) \(rc2)")
		clientTCP.memory.data = unsafeBitCast(readClosure, UnsafeMutablePointer<Void>.self)
	}
	
	private func didRead(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buffer buf: UnsafePointer<uv_buf_t>) {
		print("Did read: \(size)")
		var data = Data()
		data.append(UnsafePointer<Void>(buf.memory.base), length: size)
		self.input.write(data)
	}
}

