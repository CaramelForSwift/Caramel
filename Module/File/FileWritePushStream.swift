//
//  FileWritePushStream.swift
//  Caramel
//
//  Created by Steve Streza on 12.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

internal func FileWritePushStream_uv_cb(req: UnsafeMutablePointer<uv_fs_t>) {
	let ptr = req.memory.data
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

public class FileWritePushStream<T: Pushable where T.Sequence: DataConvertible> {
	public typealias InputStream = T

	let file: File
	let mode: File.Mode
	let eventLoop: EventLoop

	private let numberOfBytes = 32 * 1024
	private var nextData = Data()
	
	private var openRequest: UnsafeMutablePointer<uv_fs_t> = nil
	private var writeRequest: UnsafeMutablePointer<uv_fs_t> = nil

	private let inputStream: InputStream

	public init(file: File, mode: File.Mode, inputStream: InputStream, eventLoop: EventLoop = EventLoop.defaultLoop) {
		self.file = file
		self.inputStream = inputStream
		self.mode = mode
		self.eventLoop = eventLoop

		openBlock = UVCallbackClosureBox({ (req: UnsafeMutablePointer<uv_fs_t>) -> Void in
			self.didOpen(req)
		})
		writeBlock = UVCallbackClosureBox({ (req: UnsafeMutablePointer<uv_fs_t>) -> Void in
			self.didWrite(req)
		})

		self.inputStream.wait(({ (result: Result<InputStream.Sequence>) -> Void in
			do {
				let data = try result.result()
				self.write(data)
			} catch let error {
				print("Welp")
			}
		}) as! InputStream.PushHandler)

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
	private var closeBlock: UVCallbackClosureBox? = nil

	private func open() {
		openRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_open(eventLoop.uvLoop, openRequest, self.file.path, O_WRONLY | O_CREAT, Int32(self.mode.unixMode), FileWritePushStream_uv_cb)
		openRequest.memory.data = unsafeBitCast(openBlock!, UnsafeMutablePointer<Void>.self)
		attemptWrite()
	}

	public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
		defer { openBlock = nil }
		guard request.memory.result >= 0 else {
			/* Failed to open! */
			
			return
		}

		self.fileDescriptor = File.Descriptor(request.memory.result)
		attemptWrite()
	}
	
	public func write(data: InputStream.Sequence) {
		nextData.appendContentsOf(data.data)
		attemptWrite()
	}

	var isWriting = false
	private func attemptWrite() {
		guard let fileDescriptor = self.fileDescriptor else { return }
		guard nextData.bytes.count > 0 else { return }
		guard isWriting == false else { return }

		isWriting = true
		
		var buffer = uv_buf_init_d(&nextData.bytes, UInt32(nextData.bytes.count))
		self.writeRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_write(self.eventLoop.uvLoop, self.writeRequest, uv_file(fileDescriptor), &buffer, 1, self.bytesWritten, FileWritePushStream_uv_cb)
		self.writeRequest.memory.data = unsafeBitCast(writeBlock!, UnsafeMutablePointer<Void>.self)
	}
	
	public func didWrite(request: UnsafeMutablePointer<uv_fs_t>) {
		guard request == writeRequest else { return }

		isWriting = false
		
		guard request.memory.result >= 0 else { 
			print("problem writing: \(request.memory.result)")
			return
		}
		
		guard request.memory.result > 0 else {
			self.end()
			return
		}
		
		self.bytesWritten += request.memory.result
		self.nextData.bytes.removeRange(Range<Array<Byte>.Index>(start: self.nextData.bytes.startIndex, end: self.nextData.bytes.startIndex.advancedBy(request.memory.result)))
		if self.nextData.bytes.count > 0 {
			self.attemptWrite()
		}
	}

	func end() {

	}
}

public extension Pushable where Self.Sequence == Data {
	public func writeTo(file: File, mode: File.Mode) -> FileWritePushStream<Self> {
		return FileWritePushStream(file: file, mode: mode, inputStream: self)
	}
}