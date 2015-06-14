import SwiftWebServer

Server(port: 8080) { (connection: Connection<Server.Data, Server.Data>) in
	if let data = connection.read() {
		connection.write(data)
	}
}
