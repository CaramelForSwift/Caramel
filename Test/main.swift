import SwiftWebServer

let file = File(path: "/etc/passwd")
if let contents = file.data?.stringWithEncoding(.UTF8) {
	print("Contents: \(contents)")
}

print("File: \(file.fileStat)")
print("Should be true: \(file.exists)")
if let data = file.data?.stringWithEncoding(.UTF8) {
	print("Contents: \(data)")
}

let file2 = File(path: "/Users/syco/hello.txt.nope")
print("Should be false: \(file2.exists)")

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
//	let response = HTTPResponse()
//	response.statusCode = 200
//	response.body = request.body
//	connection.write(response)
}
