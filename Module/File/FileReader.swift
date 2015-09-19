//
//  FileReader.swift
//  Jelly
//
//  Created by Steve Streza on 25.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class FileReadPullStream: PullableStream<Data> {
	public enum StatError: ErrorType {
		case PermissionDenied
		case UnknownError
	}
	public let file: File
	let filePointer: UnsafeMutablePointer<FILE>
	
	public init?(file: File) {
		self.file = file
		self.filePointer = fopen(self.file.path, "r")
		if self.filePointer == nil {
			super.init()
			return nil
		}
		super.init()
	}

	public func statFile() throws -> stat {
		var statPointer = stat()
		guard fstat(Int32(self.filePointer.memory._file), &statPointer) == 0 else {
			if let posixError = POSIXError(rawValue: errno) {
				switch posixError {
				case POSIXError.EACCES:
					throw StatError.PermissionDenied
				default:
					throw StatError.UnknownError
				}
			} else {
				throw StatError.UnknownError
			}
		}
		
		return statPointer
	}
	
	public override func pull() -> Data? {
		return readData()
	}
	
	public func readData(size: Int = 32 * 1024) -> Data {
		let buffer = UnsafeMutablePointer<Void>.alloc(size)
		defer {
			buffer.dealloc(size)
		}
		
		let readBytes = fread(buffer, 1, size, self.filePointer)
		if readBytes < size {
			defer {
				end()
			}
		}
		
		var data = Data()
		data.append(buffer, length: readBytes)
		return data
	}
	
	deinit {
		fclose(self.filePointer)
	}
}

public extension File {
	public var data: Data? {
		get {
			return self.readPullStream?.drain()
		}
	}
	
	public var readPullStream: FileReadPullStream? {
		get {
			return FileReadPullStream(file: self)
		}
	}

	internal var fileStat: stat? {
		get {
			guard let fileReader = FileReadPullStream(file: self) else {
				return nil
			}
			
			let fileStat: stat
			do {
				fileStat = try fileReader.statFile()
				return fileStat
			} catch {
				return nil
			}
		}
	}
	
	public var metadata: FileMetadata? {
		get {
			if let fileStat = self.fileStat {
				return FileMetadata(fileStat: fileStat)
			} else {
				return nil
			}
		}
	}
	
	public var exists: Bool {
		get {
			return FileReadPullStream(file: self) != nil
		}
	}
	
	public var isDirectory: Bool {
		get {
			return self.metadata?.isDirectory ?? false
		}
	}
	
	public var isFile: Bool {
		get {
			return self.metadata?.isFile ?? false
		}
	}
}
