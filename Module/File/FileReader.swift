//
//  FileReader.swift
//  Jelly
//
//  Created by Steve Streza on 25.7.15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Darwin

public class FileReadPullStream: PullableStream<Data> {
	public enum FileError: ErrorType {
        case FileNotFound(File)
		case PermissionDenied(File)
		case UnknownError(File)
	}
	public let file: File
	let filePointer: UnsafeMutablePointer<FILE>
	
	public init(file: File) throws {
		self.file = file
		self.filePointer = fopen(self.file.path, "r")
        super.init()

        guard self.filePointer != nil else {
            throw FileError.FileNotFound(file)
		}
	}

	public func statFile() throws -> stat {
		var statPointer = stat()
		guard fstat(Int32(self.filePointer.memory._file), &statPointer) == 0 else {
			if let posixError = POSIXError(rawValue: errno) {
				switch posixError {
				case POSIXError.EACCES:
					throw FileError.PermissionDenied(self.file)
				default:
					throw FileError.UnknownError(self.file)
				}
			} else {
				throw FileError.UnknownError(self.file)
			}
		}
		
		return statPointer
	}
	
	public override func pull() -> Data? {
		return readData()
	}
	
	public func readData(size: Int = 32 * 1024) -> Data {
		var data = Data(numberOfZeroes: size)

		let readBytes = fread(&data.bytes, 1, size, self.filePointer)
		if readBytes < size {
			let offset = data.bytes.startIndex.advancedBy(readBytes)
			data.bytes.removeRange(Range<Array<Byte>.Index>(start: offset, end: data.bytes.endIndex))
			assert(data.bytes.count == readBytes)
			defer {
				end()
			}
		}
		
		return data
	}
	
	deinit {
		fclose(self.filePointer)
	}
}

public extension File {
    public func data() throws -> Data {
        return try self.readPullStream().drain()
	}
	
    public func readPullStream() throws -> FileReadPullStream {
        return try FileReadPullStream(file: self)
	}

    internal func fileStat() throws -> stat {
        do {
            let fileReader = try FileReadPullStream(file: self)
			let fileStat: stat = try fileReader.statFile()
            return fileStat
        } catch let error {
            throw error
        }
	}
	
    public func metadata() throws -> FileMetadata {
        do {
            let fileStat = try self.fileStat()
            return FileMetadata(fileStat: fileStat)
        } catch let error {
            throw error
        }
	}
	
	public var exists: Bool {
		get {
            do {
                let _ = try FileReadPullStream(file: self)
                return true
            } catch {
                return false
            }
		}
	}
	
    public func isDirectory() throws -> Bool {
        do {
            let metadata = try self.metadata()
            return metadata.isDirectory
        } catch let error {
            throw error
        }
	}
	
	public func isFile() throws -> Bool {
        do {
            let metadata = try self.metadata()
            return metadata.isFile
        } catch let error {
            throw error
        }
	}
}
