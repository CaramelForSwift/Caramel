//
//  TCPConnection.swift
//  Caramel
//
//  Created by Steve Streza on 18.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal typealias TCPConnectionUVReadCallback = (UnsafeMutablePointer<uv_stream_t>, Int, UnsafePointer<uv_buf_t>) -> Void
internal typealias TCPConnectionUVWriteCallback = (UnsafeMutablePointer<uv_write_t>, Int32) -> Void

internal func TCPConnection_uv_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
	let ptr = stream.memory.data
	let cb = unsafeBitCast(ptr, TCPConnectionUVReadCallbackClosureBox.self).callback
	cb(stream, size, buf)
}

internal func TCPConnection_uv_write_cb(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
	let ptr = handle.memory.data
	let cb = unsafeBitCast(ptr, TCPConnectionUVWriteCallbackClosureBox.self).callback
	cb(handle, size)
}

internal class TCPConnectionUVReadCallbackClosureBox {
	let callback: TCPConnectionUVReadCallback
	init(_ callback: TCPConnectionUVReadCallback) {
		self.callback = callback
	}
}

internal class TCPConnectionUVWriteCallbackClosureBox {
	let callback: TCPConnectionUVWriteCallback
	init(_ callback: TCPConnectionUVWriteCallback) {
		self.callback = callback
	}
}

private var NetConnectionHashValueAccumulator: Int = 0
public class NetConnection<T: Pushable, U: Pushable where T.Sequence: StreamBuffer, U.Sequence: StreamBuffer>: Hashable {
	public typealias IncomingStream = T
	public typealias OutgoingStream = U
    public typealias Incoming = IncomingStream.Sequence
    public typealias Outgoing = OutgoingStream.Sequence
	public let incoming: IncomingStream
	public let outgoing: OutgoingStream

    public let hashValue: Int = NetConnectionHashValueAccumulator++
	public required init(incoming: IncomingStream, outgoing: OutgoingStream) {
		self.incoming = incoming
		self.outgoing = outgoing
	}
}

extension NetConnection: Equatable {}
public func ==<T, U>(lhs: NetConnection<T,U>, rhs: NetConnection<T,U>) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public class TCPConnection<T: Pushable, U: Pushable where T: Writeable, U: BufferedAppendable, T.Sequence == Data, U.Sequence == Data>: NetConnection<T, U> {
    public required init(incoming: IncomingStream, outgoing: OutgoingStream) {
		super.init(incoming: incoming, outgoing: outgoing)

        outgoing.wait({ [weak self] (result: Result<OutgoingStream.Sequence>) -> Void in
			self?.writeResult(result)
		} as! OutgoingStream.PushHandler)
	}
	
	private var clientTCP: UnsafeMutablePointer<uv_tcp_t> = nil
	private var clientStream: UnsafeMutablePointer<uv_stream_t> {
		return UnsafeMutablePointer<uv_stream_t>(clientTCP)
	}
	private var readClosure: TCPConnectionUVReadCallbackClosureBox?
	private var writeClosure: TCPConnectionUVWriteCallbackClosureBox?
	
	private var connection: TCPConnection? = nil
	
	internal func listen(server: TCPServer) {
		guard clientTCP == nil else { return }

		readClosure = TCPConnectionUVReadCallbackClosureBox { [weak self] handle, size, buf in
			self?.didRead(handle, size: size, buffer: buf)
		}
		connection = self
		
		clientTCP = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
        guard uv_tcp_init(server.eventLoop.uvLoop, clientTCP) >= 0 else { return }
        guard uv_accept(server.uvStream, clientStream) >= 0 else { return }
        guard uv_read_start(clientStream, Caramel_uv_alloc_cb, TCPConnection_uv_read_cb) >= 0 else { return }
		clientTCP.memory.data = unsafeBitCast(readClosure, UnsafeMutablePointer<Void>.self)
	}
	
	private func didRead(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buffer buf: UnsafePointer<uv_buf_t>) {
		guard size >= 0 else { return }
		var data = IncomingStream.Sequence()
		data.append(UnsafePointer<Void>(buf.memory.base), length: size)
		self.incoming.write(data)
	}
	
	private var currentWrite: UnsafeMutablePointer<uv_write_t> = nil
	private func writeResult(result: Result<Data>) {
		do {
			var data = try result.result()
			guard currentWrite == nil else {
				self.outgoing.appendToBuffer(data)
				return
			}
			
			writeClosure = TCPConnectionUVWriteCallbackClosureBox { [weak self] handle, size in
				self?.didWrite(handle, size: size)
			}
			
			currentWrite = UnsafeMutablePointer<uv_write_t>.alloc(1)
			var buffer = uv_buf_init_d(&data.bytes, UInt32(data.bytes.count))
			uv_write(currentWrite, self.clientStream, &buffer, 1, TCPConnection_uv_write_cb)
			currentWrite.memory.data = unsafeBitCast(writeClosure, UnsafeMutablePointer<Void>.self)
		} catch {
			
		}
	}
	
	private func didWrite(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
		writeClosure = nil
		currentWrite.dealloc(1)
		currentWrite = nil

        let buffer = self.outgoing.buffer
        if buffer.bytes.count > 0 {
            self.outgoing.buffer = Data()
            self.writeResult(Result.Success(buffer))
        }
    }
}

