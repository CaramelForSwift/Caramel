//
//  TCPServer.swift
//  Caramel
//
//  Created by Steve Streza on 17.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

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
	typealias InputStream: StreamBuffer
	typealias OutputStream: StreamBuffer
	typealias ListenHandler = (NetConnection<Self.InputStream, Self.OutputStream>) -> Void
	func listen(port: UInt16, listener: Self.ListenHandler) throws
}

public class TCPServer: Listenable {
	public enum Error: ErrorType {
		case AlreadyListening
	}
	
	public typealias InputStream = Data
	public typealias OutputStream = Data
	
	internal var eventLoop = EventLoop.defaultLoop
	internal var uvTCP = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
	internal var uvStream: UnsafeMutablePointer<uv_stream_t> {
		return UnsafeMutablePointer<uv_stream_t>(uvTCP)
	}
	
	public var strongSelf: TCPServer?
	
	private var connectCallback: TCPServerUVCallbackClosureBox? = nil
	
	private var listener: TCPServer.ListenHandler? = nil
	public func listen(port: UInt16, listener: TCPServer.ListenHandler) throws {
		guard self.listener == nil else { 
			throw Error.AlreadyListening
		}
		
		connectCallback = TCPServerUVCallbackClosureBox { [weak self] (stream: UnsafeMutablePointer<uv_stream_t>, status: Int32) in
			print("Status: \(status)")
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
		let connection = TCPConnection(incoming: readStream)
		connection.listen(self)
		self.listener?(connection)
	}
	
	public func stopListening() {
		strongSelf = nil
		listener = nil
	}
	
	public init() {
	}
	
	deinit {
		uvTCP.dealloc(1)
		uvStream.dealloc(1)
	}
}
