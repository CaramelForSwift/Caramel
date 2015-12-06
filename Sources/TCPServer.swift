//
//  TCPServer.swift
//  Caramel
//
//  Created by Steve Streza on 17.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import CUv

internal typealias TCPServerUVCallback = (UnsafeMutablePointer<uv_stream_t>, Int32) -> Void

internal func TCPServer_uv_connection_cb(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
	let ptr = req.memory.data
	let cb = unsafeBitCast(ptr, TCPServerUVCallbackClosureBox.self).callback
	cb(req, status)
}

internal class TCPServerUVCallbackClosureBox {
	let callback: TCPServerUVCallback
	init(_ callback: TCPServerUVCallback) {
		self.callback = callback
	}
}

public protocol Listenable {
    typealias InputStream: Pushable
    typealias OutputStream: Pushable

    typealias Connection = NetConnection<InputStream, OutputStream>

    typealias Input = InputStream.Sequence
	typealias Output = OutputStream.Sequence

    typealias ListenHandler = ((Connection) -> Void)
	func listen(listener: ListenHandler) throws
}

public class TCPServer: Listenable {
	public enum Error: ErrorType {
		case AlreadyListening
	}
	
	public typealias InputStream = PushStream<Data>
	public typealias OutputStream = PushStream<Data>
	
	internal var eventLoop = EventLoop.defaultLoop
	internal var uvTCP = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
	internal var uvStream: UnsafeMutablePointer<uv_stream_t> {
		return UnsafeMutablePointer<uv_stream_t>(uvTCP)
	}
	
	public var strongSelf: TCPServer?
	
	private var connectCallback: TCPServerUVCallbackClosureBox? = nil
	
	private var listener: TCPServer.ListenHandler? = nil
	public func listen(listener: TCPServer.ListenHandler) throws {
		guard self.listener == nil else { 
			throw Error.AlreadyListening
		}
		
		connectCallback = TCPServerUVCallbackClosureBox { [weak self] (stream: UnsafeMutablePointer<uv_stream_t>, status: Int32) in
			self?.didConnect(UnsafeMutablePointer<uv_tcp_t>(stream), status: status)
		}

		self.listener = listener
		
		strongSelf = self
		
		let addr = UnsafeMutablePointer<sockaddr_in>.alloc(1)
		defer { addr.dealloc(1) }

		let rc1 = uv_ip4_addr([Int8(0),Int8(0),Int8(0),Int8(0)], Int32(port), addr)
		let rc2 = uv_tcp_init(EventLoop.defaultLoop.uvLoop, uvTCP)
		let rc3 = uv_tcp_bind(uvTCP, UnsafePointer<sockaddr>(addr), 0)
		let rc4 = uv_listen(UnsafeMutablePointer<uv_stream_t>(uvTCP), 1000, TCPServer_uv_connection_cb)
		uvTCP.memory.data = unsafeBitCast(connectCallback, UnsafeMutablePointer<Void>.self)
		
		print("Bind: \(rc1) \(rc2) \(rc3) \(rc4)")
	}
	
	private func didConnect(tcp: UnsafeMutablePointer<uv_tcp_t>, status: Int32) {
        let readStream = PushStream<Data>()
        let writeStream = PushStream<Data>()
        let connection = TCPConnection(incoming: readStream, outgoing: writeStream)
		connection.listen(self)
		self.listener?(connection)
	}
	
	public func stopListening() {
		strongSelf = nil
		listener = nil
	}

    private let port: UInt16
    public init(port: UInt16) {
        self.port = port
	}
	
	deinit {
		uvTCP.dealloc(1)
		uvStream.dealloc(1)
	}
}

