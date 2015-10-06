//
//  FileReadPushStream.swift
//  Caramel
//
//  Created by Steve Streza on 2.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

func FileReadPushStream_uv_fs_open_cb(req: UnsafeMutablePointer<uv_fs_t>) {
	let ptr = req.memory.ptr
	let foo = unsafeBitCast(ptr, FileReadPushStream.self)
	foo.didOpen(req)
}

func FileReadPushStream_uv_fs_read_cb(req: UnsafeMutablePointer<uv_fs_t>) {
	let ptr = req.memory.ptr
	let foo = unsafeBitCast(ptr, FileReadPushStream.self)
	foo.didRead(req)
}

public class FileReadPushStream: PushStream<Data> {
	let file: File
	let eventLoop: EventLoop
	let numberOfBytes = 32 * 1024
	var nextData: Data! = nil
	
	private var openRequest: UnsafeMutablePointer<uv_fs_t> = nil
	private var readRequest: UnsafeMutablePointer<uv_fs_t> = nil
	
	public init(file: File, eventLoop: EventLoop = EventLoop.defaultLoop) {
		self.file = file
		self.eventLoop = eventLoop
		super.init()

		open()
	}
	func open() {
		openRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_open(eventLoop.uvLoop, openRequest, self.file.path, O_RDONLY, 0, FileReadPushStream_uv_fs_open_cb)
		openRequest.memory.ptr = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
	}
	
	private var fileDescriptor: File.Descriptor? = nil
	private var bytesRead: Int64 = 0
	
	public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
		self.fileDescriptor = File.Descriptor(request.memory.result)
		read()
	}
	
	private func read() {
		self.nextData = Data(numberOfZeroes: numberOfBytes)
		var buffer = uv_buf_init_d(&nextData!.bytes, UInt32(self.numberOfBytes))
		self.readRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_read(self.eventLoop.uvLoop, self.readRequest, uv_file(self.fileDescriptor!), &buffer, UInt32(buffer.len), self.bytesRead, FileReadPushStream_uv_fs_read_cb)
		self.readRequest.memory.ptr = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
	}
	public func didRead(request: UnsafeMutablePointer<uv_fs_t>) {
		guard request == readRequest else { return }
		guard request.memory.result >= 0 else { 
			print("problem reading: \(request.memory.result)")
			return
		}
		
		guard request.memory.result > 0 else {
			self.end()
			return
		}
		
		self.bytesRead += request.memory.result
		self.nextData!.bytes.removeRange(Range<Array<Byte>.Index>(start: request.memory.result, end: self.nextData!.bytes.endIndex))
		write(self.nextData!)
		
		read()
		
//		print("Data: \(self.nextData) \(request == readRequest)")
//		print("")
	}
}

public extension File {
	public var readPushStream: FileReadPushStream {
		return FileReadPushStream(file: self)
	}
}