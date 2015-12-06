//
//  FileDirectoryListPushStream.swift
//  Caramel
//
//  Created by Steve Streza on 11/24/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

typealias FDIRENT = uv_fs_s

func FileDirectoryListPushStream_uv_fs_scandir_cb(req: UnsafeMutablePointer<uv_fs_t>) {
    let ptr = req.memory.data
    guard ptr != nil else { return }
    let unmanaged = Unmanaged<FileDirectoryListPushStream>.fromOpaque(COpaquePointer(ptr))
    let stream = unmanaged.takeUnretainedValue()
    stream.didOpen(req)
}

public final class FileDirectoryListPushStream: PushStream<[File]> {
    let file: File
    let eventLoop: EventLoop

    private var scandirRequest: UnsafeMutablePointer<uv_fs_t> = nil

    public init(file: File, eventLoop: EventLoop = EventLoop.defaultLoop) {
        self.file = file
        self.eventLoop = eventLoop
        super.init()
    }

    internal override func start() {
        super.start()

        scandirRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)

		let unmanaged = Unmanaged<FileDirectoryListPushStream>.passUnretained(self)
        let ptr = UnsafeMutablePointer<Void>(unmanaged.toOpaque())
        let rc = uv_fs_scandir(eventLoop.uvLoop, scandirRequest, self.file.path, 0, FileDirectoryListPushStream_uv_fs_scandir_cb)
		guard uv_errno_t(rc) != UV_ENOTDIR else {
			self.writeError(File.ListDirectoryError.NotADirectory)
			return
		}
		
		scandirRequest.memory.data = ptr
    }

    public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
		print("Result: \(request.memory.result)")
		guard request.memory.result > 0 else {
			let errno = uv_errno_t(Int32(request.memory.result))
			switch errno {
			case UV_ENOTDIR:
				self.writeError(File.ListDirectoryError.NotADirectory)
			case UV_ENOENT:
				self.writeError(File.ListDirectoryError.DoesNotExist)
			default:
				let errname = uv_err_name(Int32(request.memory.result))
				var data = Data()
				data.append(errname, length: Int(strlen(errname)))
				self.writeError(File.ListDirectoryError.UnknownError(request.memory.result, data.UTF8String))
			}
			self.end()
			return
		}
        let dirent = UnsafeMutablePointer<uv_dirent_t>.alloc(1)

        var files: [File] = []
        while uv_errno_t(uv_fs_scandir_next(request, dirent)) != UV_EOF {
            let length = Int(strlen(dirent.memory.name))
            var filenameData = Data()
            filenameData.append(UnsafePointer<Void>(dirent.memory.name), length: length)
            guard let filename = filenameData.UTF8String else { continue }

            let file = self.file.fileByAppendingPathComponent(filename)
            files.append(file)
        }
		
		if files.count > 0 {
			self.write(files)
		} else {
			end()
		}

        dirent.destroy(1)
    }
	
	
}

public extension File {
    public enum ListDirectoryError: ErrorType {
        case NotADirectory
		case DoesNotExist
		case UnknownError(Int, String?)
    }

    public func directoryListPushStream() -> FileDirectoryListPushStream {
        return FileDirectoryListPushStream(file: self)
    }
}