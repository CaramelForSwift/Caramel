import Jelly

let home = File.homeDirectory
let documents = home.fileByAppendingPathComponent("Documents")

let root = File.rootDirectory
print("Root: \(root.path) \(root.pathComponents)")

let localTimeFile = root.fileByAppendingPathComponent("etc").fileByAppendingPathComponent("localtime")
print("Localtime exists? \(localTimeFile.exists)")
print("Localtime isDir? \(localTimeFile.isDirectory)")
print("Localtime isFile? \(localTimeFile.isFile)")

let home2 = root.fileByAppendingPathComponent("Users").fileByAppendingPathComponent("syco")
print("equal? \(home == home2)")

let home3 = documents.parentDirectory
print("still equal? \(home3 == home)")

let file = File(path: "/etc/passwd")
if let data = file.data, contents = data.stringWithEncoding(.UTF8) {
	print("Hash: \(data.hashValue)")
} else {
	print("OOPS");
}

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
//	let response = HTTPResponse()
//	response.statusCode = 200
//	response.body = request.body
//	connection.write(response)
}

