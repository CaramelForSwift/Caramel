//
//  FileDirectoryListPushStream.swift
//  Caramel
//
//  Created by Steve Streza on 11/24/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

func FileDirectoryListPushStream_uv_fs_scandir_cb(req: UnsafeMutablePointer<uv_fs_t>) {
    let ptr = req.memory.ptr
    guard ptr != nil else { return }
    print("ptr read:  \(ptr) \(req)")
    let unmanaged = Unmanaged<FileDirectoryListPushStream>.fromOpaque(COpaquePointer(ptr))
    let stream = unmanaged.takeUnretainedValue()
    print("Stream did open: \(stream.file)")
    stream.didOpen(req)
}

public final class FileDirectoryListPushStream: PushStream<[File]> {
    let file: File
    let eventLoop: EventLoop

    deinit {
        print("STOP")
    }

    private var scandirRequest: UnsafeMutablePointer<uv_fs_t> = nil

    public init(file: File, eventLoop: EventLoop = EventLoop.defaultLoop) {
        self.file = file
        self.eventLoop = eventLoop
        super.init()
        start()
    }

    internal override func start() {
        super.start()

        scandirRequest = UnsafeMutablePointer<uv_fs_t>.alloc(1)
        let unmanaged = Unmanaged<FileDirectoryListPushStream>.passUnretained(self)
        let ptr = UnsafeMutablePointer<Void>(unmanaged.toOpaque())
        print("ptr start: \(ptr)")

        scandirRequest.memory.ptr = ptr
        uv_fs_scandir(eventLoop.uvLoop, scandirRequest, self.file.path, 0, FileDirectoryListPushStream_uv_fs_scandir_cb)
        scandirRequest.memory.ptr = ptr
    }

    public func didOpen(request: UnsafeMutablePointer<uv_fs_t>) {
        let dirent = UnsafeMutablePointer<uv_dirent_t>.alloc(1)

        var files: [File] = []
        while uv_errno_t(uv_fs_scandir_next(request, dirent)) != UV_EOF {
            let length = Int(strlen(dirent.memory.name))
            var filenameData = Data()
            filenameData.append(UnsafePointer<Void>(dirent.memory.name), length: length)
            print("Data: \(filenameData.bytes)")
            guard let filename = filenameData.UTF8String else { continue }
            print("Filename: \(filename)")

            let file = self.file.fileByAppendingPathComponent(filename)
            print("File: \(file)")
            files.append(file)
        }
        self.write(files)

        dirent.destroy(1)
    }

    private func read() {

    }

    public func didRead(request: UnsafeMutablePointer<uv_fs_t>) {
//        guard request == readRequest else { return }
//        guard request.memory.result >= 0 else {
//            print("problem reading: \(request.memory.result)")
//            return
//        }
//
//        guard request.memory.result > 0 else {
//            self.end()
//            return
//        }
//
//        self.bytesRead += request.memory.result
//        self.nextData!.bytes.removeRange(Range<Array<Byte>.Index>(start: request.memory.result, end: self.nextData!.bytes.endIndex))
//        write(self.nextData!)
//        
//        read()

        //		print("Data: \(self.nextData) \(request == readRequest)")
        //		print("")
    }
}

public extension File {
    public enum ListDirectoryError: ErrorType {
        case NotADirectory
    }

    public func directoryListPushStream() throws -> FileDirectoryListPushStream {
        guard try isDirectory() else { throw File.ListDirectoryError.NotADirectory }
        return FileDirectoryListPushStream(file: self)
    }
}