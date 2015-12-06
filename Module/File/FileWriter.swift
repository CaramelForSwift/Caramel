//
//  FileWriter.swift
//  Caramel
//
//  Created by Steve Streza on 1.8.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class FileWriter {
	public let file: File
	private let filePointer: UnsafeMutablePointer<FILE>
	
	public enum Error: ErrorType {
		case GenericError(Int)
	}
	
	public init(file: File) throws {
		self.file = file
		self.filePointer = fopen(self.file.path, "w")
		if self.filePointer == nil {
			let error = Int(errno)
			throw Error.GenericError(error)
		}
	}
	
	public func writeData(data: Data) throws {
		assert(__error().memory == errno)
		let result = fwrite(data.bytes, sizeof(UInt8), data.bytes.count, self.filePointer)
		print("Wrote \(result) of \(data.bytes.count)")
	}
	
	deinit {
		fclose(self.filePointer)
	}	
}

public extension File {
	public func createWithData(data: Data) throws {
		try FileWriter(file: self).writeData(data)
	}
}

public extension Data {
	public func createFile(file: File) throws {
		try FileWriter(file: file).writeData(self)
	}
}

