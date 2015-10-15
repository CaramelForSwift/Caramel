import Caramel

let hostsFile = File.rootDirectory/"etc"/"hosts"
let splatoonFile = File.rootDirectory/"Users"/"syco"/"Downloads"/"Splatoon Squid Beatz"/"Splatoon Squid Beatz"/"18 - Final Boss Phase 2.mp3"

//if let stream = splatoonFile.readPullStream?.MD5Stream, data = stream.drain() {
//	print("Splatoon file MD5 is \(data.debugDescription.lowercaseString)")
//}

hostsFile.readPushStream
	.UTF8String
	.UTF8Data
	.base64Encode
	.UTF8String
	.drain { (result: Result<[String]>) -> Void in
		do {
			let data = try result.result()
	//		if let string = data.UTF8String {
				print("yay: \(data)")
	//		}
		} catch let error {
			print("Fail: \(error)")
		}
		print("done")
	}

hostsFile.readPushStream.writeTo(File.homeDirectory / "hostsFile")

do {
    let hostsStream = try hostsFile.readPullStream()
    
//	let tempFile = File.homeDirectory/"ayy.hosts"
//	tempFile.createWithData(hostsText.UTF8Data)
//	if let data = tempFile.data?.UTF8String {
//		print("Hosts file:\n\(data)")
//	}
    
    let stringStream = hostsStream
        // convert binary data from file to string
        .transform { (data: Data) throws -> [String] in
            [data.UTF8String!]
        }
        // split buffer by newline into separate strings
        .flatMap { (buffer: String) -> [String] in
            buffer.characters.split { $0 == "\n" }.map { String($0) }
        }
	
	let lines = stringStream.drain()
	lines.forEach({ (line: String) -> () in
		print("-- \(line)")
	})
} catch let error {
    print("File error: \(error)")
}

//Server(port: 8080) { connection in
//	if let data = connection.read() {
//		connection.write(data)
//	}
//}
//

EventLoop.defaultLoop.run()