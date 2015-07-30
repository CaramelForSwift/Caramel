import Jelly

//if let fart = Process.environment("farty") {
//	print(" Fart: \(fart)")
//	let time: tm
//}

let home = File.homeDirectory
	
print("Home: \(home.path) \(home.pathComponents) \(Date.now.instant.seconds)")

let documents = home.fileByAppendingPathComponent("Documents")
print("Documents: \(documents.path)")

let root = File.rootDirectory
print("Root: \(root.path) \(root.pathComponents)")

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
