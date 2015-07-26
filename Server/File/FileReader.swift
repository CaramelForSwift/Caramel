//
//  FileReader.swift
//  SwiftWebServer
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
		self.filePointer = fopen(self.file.source, "r")
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
	
	public func readData(size: Int = 4 * 1024) -> DataChunk? {
		let buffer = UnsafeMutablePointer<Void>.alloc(size)
		defer {
			buffer.dealloc(size)
		}
		
		let readBytes = fread(buffer, 1, size, self.filePointer)
		if readBytes == 0 {
			isAtEnd = true
			return nil
		}
		
		let data = DataChunk()
		data.append(buffer, length: readBytes)
		return data
	}
	
	deinit {
		fclose(self.filePointer)
	}
}