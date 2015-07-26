import SwiftWebServer

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
