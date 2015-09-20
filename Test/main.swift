import Jelly

let splatoonFile = File.rootDirectory/"Users"/"syco"/"Downloads"/"Splatoon Squid Beatz"/"Splatoon Squid Beatz"/"18 - Final Boss Phase 2.mp3"
//if let stream = splatoonFile.readPullStream?.MD5Stream, data = stream.drain() {
//	print("Splatoon file MD5 is \(data.debugDescription.lowercaseString)")
//}

	let hostsFile = File.rootDirectory/"etc"/"hosts"

	if let
		data1 = hostsFile.readPullStream?.SHA512Stream.drain(),
		data2 = hostsFile.data?.SHA512,
		data3 = hostsFile.SHA512 
	{
		print("SHA512 values for hosts file:\n\(data1)\n\(data2)\n\(data3)")
	}

if let data = hostsFile.readPullStream?.SHA512Stream.drain() {
	print("Hosts file SHA512 is \(data)")
}

if let data = hostsFile.data?.SHA512 {
	print("Hosts file SHA512 is \(data)")	
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

