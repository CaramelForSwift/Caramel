import Jelly

let hostsFile = File.rootDirectory/"etc"/"hosts"

let splatoonFile = File.rootDirectory/"Users"/"syco"/"Downloads"/"Splatoon Squid Beatz"/"Splatoon Squid Beatz"/"18 - Final Boss Phase 2.mp3"
if let stream = splatoonFile.readPullStream, data = stream.drain() {
	print("Splatoon file is \(data.bytes.count) bytes")
}

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
			.map { (line: String) -> Int in
				line.characters.count
			}

		if let output = stringStream.pull() {
			print("Output: \(output)")
		}
	}
}

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
}

