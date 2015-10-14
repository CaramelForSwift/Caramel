//
//  FileWritePushStream.swift
//  Caramel
//
//  Created by Steve Streza on 12.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal func FileWritePushStream_uv_cb(req: UnsafeMutablePointer<uv_fs_t>) {
	let ptr = req.memory.ptr
	let cb = unsafeBitCast(ptr, UVCallbackClosureBox.self).callback
	cb(req)
}

internal class UVCallbackClosureBox {
	let callback: UVCallback
	init(_ callback: UVCallback) {
		self.callback = callback
	}
}

internal typealias UVCallback = (UnsafeMutablePointer<uv_fs_t>) -> Void

public class FileWritePushStream<T: Pushable where T.Sequence: DataConvertible>: PushStream<Data> {
	public typealias InputStream = T
	
	let file: File
	let eventLoop: EventLoop
	let numberOfBytes = 32 * 1024
	var nextData: Data! = nil
	
	private var openRequest: UnsafeMutablePointer<uv_fs_t> = nil
	private var writeRequest: UnsafeMutablePointer<uv_fs_t> = nil

	private let inputStream: InputStream
	
	public init(file: File, inputStream: InputStream, eventLoop: EventLoop = EventLoop.defaultLoop) {
		self.file = file
		self.inputStream = inputStream
		self.eventLoop = eventLoop
		super.init()

		openBlock = UVCallbackClosureBox({ (req: UnsafeMutablePointer<uv_fs_t>) -> Void in
			self.didOpen(req)
		})
		writeBlock = UVCallbackClosureBox({ (req: UnsafeMutablePointer<uv_fs_t>) -> Void in
			self.didWrite(req)
		})

		open()
	}
	
	deinit {
		if openRequest != nil {
			openRequest.dealloc(1)
			openRequest = nil
		}
		
		if writeRequest != nil {
			writeRequest.dealloc(1)
			writeRequest = nil
		}
	}
	
	private var fileDescriptor: File.Descriptor? = nil

	private var bytesWritten: Int64 = 0
	
	private var openBlock: UVCallbackClosureBox? = nil
	private var writeBlock: UVCallbackClosureBox? = nil
	
	private func open() {
		openRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_open(eventLoop.uvLoop, openRequest, self.file.path, O_RDONLY, 0, FileWritePushStream_uv_cb)
		openRequest.memory.ptr = unsafeBitCast(openBlock!, UnsafeMutablePointer<Void>.self)
	}
	
	public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
		defer { openBlock = nil }

		self.fileDescriptor = File.Descriptor(request.memory.result)
	}
	
	public override func write(data: Data) {
		var data = data
		var buffer = uv_buf_init_d(&data.bytes, UInt32(self.numberOfBytes))
		self.writeRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)

		uv_fs_write(self.eventLoop.uvLoop, self.writeRequest, uv_file(self.fileDescriptor!), &buffer, UInt32(buffer.len), self.bytesWritten, FileWritePushStream_uv_cb)

		self.writeRequest.memory.ptr = unsafeBitCast(writeBlock!, UnsafeMutablePointer<Void>.self)
	}
	
	public func didWrite(request: UnsafeMutablePointer<uv_fs_t>) {
		guard request == writeRequest else { return }
		guard request.memory.result >= 0 else { 
			print("problem reading: \(request.memory.result)")
			return
		}
		
		guard request.memory.result > 0 else {
			self.end()
			return
		}
		
		self.bytesWritten += request.memory.result
		self.nextData!.bytes.removeRange(Range<Array<Byte>.Index>(start: request.memory.result, end: self.nextData!.bytes.endIndex))
		write(self.nextData!)
	}
}

public extension Pushable where Self.Sequence: DataConvertible {
	public func writeTo(file: File) -> FileWritePushStream<Self> {
		return FileWritePushStream(file: file, inputStream: self)
	}
}