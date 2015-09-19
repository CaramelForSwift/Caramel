import Jelly

let hostsFile = File.rootDirectory/"etc"/"hosts"


if let hostsText = hostsFile.data?.UTF8String {
	let tempFile = File.homeDirectory/"ayy.hosts"
//	tempFile.createWithData(hostsText.UTF8Data)
//	if let data = tempFile.data?.UTF8String {
//		print("Hosts file:\n\(data)")
//	}
	
	if let stream = FileReadPullStream(file: tempFile) {
		let stringStream = stream
			// convert binary data from file to string
			.transform { (data: Data) -> [String] in
				return [data.UTF8String!]
			}
			// split buffer by newline into separate strings
			.flatMap { (buffer: String) -> [String] in
				buffer.characters.split { $0 == "\n" }.map { String($0) }
			}
			// capitalize each string
			.map { (line: String) -> String in
				line.uppercaseString
			}

		if let output: [String] = stringStream.read() {
			print("Output: \(output)")
		}
	}
}

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
}

