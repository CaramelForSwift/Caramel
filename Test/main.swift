import Jelly

Server(port: 8080) { connection in
	if let data = connection.read() {
		connection.write(data)
	}
}

