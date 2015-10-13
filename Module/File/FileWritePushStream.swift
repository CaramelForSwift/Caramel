//
//  FileWritePushStream.swift
//  Caramel
//
//  Created by Steve Streza on 12.10.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

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

	public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
		self.fileDescriptor = File.Descriptor(request.memory.result)
	}
	
	private var bytesWritten: Int64 = 0
	
	private func open() {
		openRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
		uv_fs_open(eventLoop.uvLoop, openRequest, self.file.path, O_RDONLY, 0, FileWritePushStream_uv_fs_open_cb)
		openRequest.memory.ptr = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
	}
	
	public override func write(data: Data) {
		var data = data
		var buffer = uv_buf_init_d(&data.bytes, UInt32(self.numberOfBytes))
		self.writeRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)

		uv_fs_write(self.eventLoop.uvLoop, self.writeRequest, uv_file(self.fileDescriptor!), &buffer, UInt32(buffer.len), self.bytesWritten) { (req: UnsafeMutablePointer<uv_fs_t>) in
			let object = req.memory.ptr
			if object != nil {
				let ptr = unsafeBitCast(object, FileWritePushStream<InputStream>.self)
				ptr.didWrite(req)
			}
		}

		self.writeRequest.memory.ptr = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
	}
	
	public func didRead(req: UnsafeMutablePointer<uv_fs_t>) { 
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

func FileWritePushStream_uv_fs_open_cb(req: UnsafeMutablePointer<uv_fs_t>) {
	/*
	let ptr = req.memory.ptr
	// The compiler needs a generic FileWritePushStream to call into, so this doesn't work
	let fileWrite = unsafeBitCast(ptr, FileWritePushStream.self)
	fileWrite.didOpen(req)
	*/
}
