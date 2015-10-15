import Darwin

/// A `File` is an object that represents a location on a file system, and offers methods for 
/// manipulating files and directories.
///
/// The existence of a `File` object does not imply the existence of a file or directory within a 
/// file system. `File` objects also don't manipulate directly, but instead use a `FileReader` or 
/// `FileWriter` object to manipulate files.

public struct File: Hashable, Equatable {
	public typealias Descriptor = Int32

	public struct Permissions : OptionSetType{
		public let rawValue : UInt
		public init(rawValue: UInt){ self.rawValue = rawValue}

		public static let None = Permissions(rawValue:0)
		public static let Execute = Permissions(rawValue:1)
		public static let Write = Permissions(rawValue:2)
		public static let Read = Permissions(rawValue:4)

		public static let WriteExecute = Permissions(rawValue: 3)
		public static let ReadExecute = Permissions(rawValue: 5)
		public static let ReadWrite = Permissions(rawValue: 6)
		public static let All = Permissions(rawValue: 7)
	}

	public struct Mode {
		public let user: File.Permissions
		public let group: File.Permissions
		public let everyone: File.Permissions

		public var unixMode: UInt {
			return (user.rawValue * 8 * 8) + (group.rawValue * 8) + (everyone.rawValue)
		}

		public init(user: File.Permissions, group: File.Permissions, everyone: File.Permissions) {
			self.user = user
			self.group = group
			self.everyone = everyone
		}
	}
	
	/// The path to the file on disk. This will be platform dependent. In general, you should not
	/// manipulate the path directly, but use the methods on `File` to navigate the filesystem.
	public let path: String
	
	/// Creates a `File` at the given path.
	public init(path: String) {
		self.path = path
	}
	
	/// Creates a `File` at a composed path created from supplied path components.
	/// - Parameter pathComponents: An array of components to compose at a path, joined by `File.pathSeparator`.
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
		
		let path = basePath + components.joinWithSeparator(File.pathSeparator)
		self.init(path: path)
	}
	
	/// An array of path components	that make up the path.
	public var pathComponents: [String] {
		var components = self.path.characters.split { (character: Character) -> Bool in
			return String(character) == File.pathSeparator
		}.map({String($0)})
		if String(self.path.characters[self.path.characters.startIndex]) == File.pathSeparator {
			components.insert(File.pathSeparator, atIndex: 0)
		}
		return components
	}
	
	/// The last piece of the path, if one exists. This is the file or directory name of the `File`.
	public var lastPathComponent: String? {
		return self.pathComponents.last
	}
	
	/// Returns a new `File` made by appending the `component` to the current path, as a child 
	/// element.
	/// - Returns: A new `File` made of `path` + `File.pathSeparator` + `component`. Note that this
	///	does not guarantee the returned `File` exists.
	public func fileByAppendingPathComponent(component: String) -> File {
		var pathComponents = self.pathComponents
		pathComponents.append(component)
		return File(pathComponents: pathComponents)
	}
	
	/// Returns a new `File` made by removing the last path component from the current path.
	/// - Note: If this is equal to the `File.rootDirectory`, it will return an equivalent `File`.
	/// - Returns: A new `File` made by deleting the last path component.
	public var parentDirectory: File {
		var pathComponents = self.pathComponents
		if pathComponents.count > 1 {
			pathComponents.removeLast()
		}
		return File(pathComponents: pathComponents)
	}
	
	/// The `String` representing the system's path separator. On UNIX systems this is a `/`.
	public static var pathSeparator = "/"

	/// The `String` representing the system's path extension separator. On UNIX systems this is `.`.
	public static var pathExtensionSeparator = "."
	
	/// The root directory for the system. On UNIX systems this represents the directory at `/`.
	public static var rootDirectory: File {
		return File(path: self.pathSeparator)
	}
	
	/// The root directory for the current user's home directory.
	public static var homeDirectory: File {
		let passwd = getpwuid(getuid())
		let dirPtr = passwd.memory.pw_dir
		var data = Data()
		data.append(UnsafePointer<Void>(dirPtr), length: Int(strlen(dirPtr)))
		if let path = data.stringWithEncoding(.UTF8) {
			return File(path: path)
		} else {
			fatalError()
		}
	}
	
	/// The hash value.
	public var hashValue: Int {
		return self.path.hashValue
	}
}

/// Determines if two `File` objects are equivalent.
/// - Returns: `true` if two `File` objects have the same path, `false` otherwise
public func ==(lhs: File, rhs: File) -> Bool {
	return lhs.path == rhs.path
}

public func /(lhs: File, rhs: String) -> File {
	return lhs.fileByAppendingPathComponent(rhs)
}
