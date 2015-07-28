import Darwin

/**
A `File` is an object that represents a location on a file system, and offers methods for 
manipulating files and directories.

The existence of a `File` object does not imply the existence of a file or directory within a file 
system. `File` objects also don't manipulate directly, but instead use a `FileReader` or 
`FileWriter` object to manipulate files.
*/

public struct File: Hashable, Equatable {
	public typealias Descriptor = Int32
	
	public let path: String
	
	public init(path: String) {
		self.path = path
	}
	
	public init(pathComponents: [String]) {
		var components = pathComponents
		if components.count == 0 {
			components.append(File.pathSeparator)
		}
		
		let basePath: String
		if let first = components.first where first == File.pathSeparator {
			components.removeAtIndex(components.startIndex)
			basePath = File.pathSeparator
		} else {
			basePath = ""
		}
		
		let path = basePath + File.pathSeparator.join(components)
		self.init(path: path)
	}
	
	public var pathComponents: [String] {
		get {
			var components = split(self.path.characters) { (character: Character) -> Bool in
				return String(character) == File.pathSeparator
			}.map({String($0)})
			if String(self.path.characters[self.path.characters.startIndex]) == File.pathSeparator {
				components.insert(File.pathSeparator, atIndex: 0)
			}
			return components
		}
	}
	
	public var lastPathComponent: String? {
		get {
			return self.pathComponents.last
		}
	}
	
	public func fileByAppendingPathComponent(component: String) -> File {
		var pathComponents = self.pathComponents
		pathComponents.append(component)
		return File(pathComponents: pathComponents)
	}
	
	public var parentDirectory: File {
		get {
			var pathComponents = self.pathComponents
			if pathComponents.count > 1 {
				pathComponents.removeLast()
			}
			return File(pathComponents: pathComponents)
		}
	}
	
	public static var pathSeparator = "/"
	public static var pathExtensionSeparator = "."
	
	public static var rootDirectory: File {
		get {
			return File(path: self.pathSeparator)
		}
	}
	
	public static var homeDirectory: File {
		get {
			let passwd = getpwuid(getuid())
			let dirPtr = passwd.memory.pw_dir
			var data = DataChunk()
			data.append(UnsafePointer<Void>(dirPtr), length: Int(strlen(dirPtr)))
			if let path = data.stringWithEncoding(.UTF8) {
				return File(path: path)
			} else {
				fatalError()
			}
		}
	}
	
	public var hashValue: Int {
		get {
			return self.path.hashValue
		}
	}
}

public func ==(lhs: File, rhs: File) -> Bool {
	return lhs.path == rhs.path
}