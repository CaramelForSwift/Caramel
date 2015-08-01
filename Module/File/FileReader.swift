//
//  FileReader.swift
//  Jelly
//
//  Created by Steve Streza on 25.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class FileReader {
	enum StatError: ErrorType {
		case PermissionDenied
		case UnknownError
	}
	let file: File
	let filePointer: UnsafeMutablePointer<FILE>
	
	private(set) var isAtEnd: Bool = false
	
	public init?(file: File) {
		self.file = file
		self.filePointer = fopen(self.file.path, "r")
		if self.filePointer == nil {
			return nil
		}
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
	
	public func readData(size: Int = 32 * 1024) -> DataChunk {
		let buffer = UnsafeMutablePointer<Void>.alloc(size)
		defer {
			buffer.dealloc(size)
		}
		
		let readBytes = fread(buffer, 1, size, self.filePointer)
		if readBytes < size {
			isAtEnd = true
		}
		
		var data = DataChunk()
		data.append(buffer, length: readBytes)
		return data
	}
	
	deinit {
		fclose(self.filePointer)
	}
}

extension File {
	public var data: DataChunk? {
		get {
			if let reader = FileReader(file: self) {
				var data = DataChunk()
				while reader.isAtEnd == false {
					data.append(reader.readData().bytes)
				}
				return data
			}
			return nil
		}
	}

	internal var fileStat: stat? {
		get {
			guard let fileReader = FileReader(file: self) else {
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
			return FileReader(file: self) != nil
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
