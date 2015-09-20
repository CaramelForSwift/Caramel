import Jelly

let hostsFile = File.rootDirectory/"etc"/"hosts"

let splatoonFile = File.rootDirectory/"Users"/"syco"/"Downloads"/"Splatoon Squid Beatz"/"Splatoon Squid Beatz"/"18 - Final Boss Phase 2.mp3"
if let stream = splatoonFile.readPullStream?.MD5Stream, data = stream.drain() {
	print("Splatoon file MD5 is \(data.debugDescription.lowercaseString)")
}

if let hostsText = hostsFile.data?.UTF8String {
	let tempFile = File.homeDirectory/"ayy.hosts"
//	tempFile.createWithData(hostsText.UTF8Data)
//	if let data = tempFile.data?.UTF8String {
//		print("Hosts file:\n\(data)")
//	}
	
	if let stream = tempFile.readPullStream {
		let stringStream = stream
			// convert binary data from file to string
			.transform { (data: Data) -> [String] in
				return [data.UTF8String!]
			}
			// split buffer by newline into separate strings
			.flatMap { (buffer: String) -> [String] in
				buffer.characters.split { $0 == "\n" }.map { String($0) }
			}
		
		if let output = stream.drain() {
			print("Output: \(output.debugDescription)")
		}
	}
}

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
}

