//
//  FileWriter.swift
//  Jelly
//
//  Created by Steve Streza on 1.8.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class FileWriter {
	let file: File
	let filePointer: UnsafeMutablePointer<FILE>
	
	public init?(file: File) {
		self.file = file
		self.filePointer = fopen(self.file.path, "w")
		if self.filePointer == nil {
			let wat = errno
			print("wat: \(wat)")
			return nil
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
	public func createWithData(data: Data) {
		if let writer = FileWriter(file: self) {
			do {
				try writer.writeData(data)
			} catch {
				fatalError("Should rethrow here")
			}
		}  else {
			fatalError("Throw here at some point idk")
		}
	}
}