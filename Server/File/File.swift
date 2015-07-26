/**
 * A `File` is 
 */

import Darwin

public struct File {
	public typealias Descriptor = Int32
	
	public let source: String
	
	public init(path: String) {
		source = path
	}
	
	public var fileStat: stat? {
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
	
	public var exists: Bool {
		get {
			return FileReader(file: self) != nil
		}
	}
	
	public var data: DataChunk? {
		get {
			if let reader = FileReader(file: self) {
				let data = DataChunk()
				while let readData = reader.readData() {
					data.append(readData.bytes)
				}
				return data
			}
			return nil
		}
	}
}

