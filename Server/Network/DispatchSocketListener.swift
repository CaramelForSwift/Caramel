import Dispatch
import Darwin

enum ControlProtocol {
	case TCP
	case UDP
}

enum ProtocolVersion {
	case IPv4
	case IPv6
}

class DispatchSocketListener : SocketListener {
//	let dispatchQueue = dispatch_queue_create("DispatchSocketListener", DISPATCH_QUEUE_CONCURRENT)
	let dispatchQueue = dispatch_get_main_queue()
	
	let controlProtocol: ControlProtocol
	let version: ProtocolVersion
	
	required init(controlProtocol: ControlProtocol, version: ProtocolVersion) {
		self.controlProtocol = controlProtocol
		self.version = version
	}
	
	private var IPProtocol: Int32 {
		get {
			switch controlProtocol {
			case .UDP:
				return IPPROTO_UDP
			case .TCP:
				return IPPROTO_TCP
			}
		}
	}
	
	private var IPVersion: Int32 {
		get {
			switch version {
			case .IPv4:
				return PF_INET
			case .IPv6:
				return PF_INET6
			}
		}
	}
	
	private var socketType: Int32 {
		get {
			switch controlProtocol {
			case .UDP:
				return SOCK_DGRAM
			case .TCP:
				return SOCK_STREAM
			}
		}
	}
	
	func listen(port: Server.Port, accept: (Connection<Server.Data, Server.Data>) -> Void) throws {
		let socketFD = socket(self.IPVersion, self.socketType, self.IPProtocol)
		
		let nonblockRC = SocketUtils_fcntl(socketFD, F_SETFL, O_NONBLOCK)
			if nonblockRC < 0 {
			print("Couldn't set nonblock")
		}
		
		var sin = sockaddr_in()
		sin.sin_len = UInt8(sizeofValue(sin))
		sin.sin_family = sa_family_t(AF_INET)
		sin.sin_port = in_port_t(SocketUtils_htons(port))
		
		let bindRC = withUnsafePointer(&sin) { ptr -> Int32 in
			return Darwin.bind(socketFD, UnsafePointer<sockaddr>(ptr), socklen_t(sin.sin_len))
		}
		
		let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(socketFD), 0, self.dispatchQueue)
		dispatch_source_set_event_handler(source) {
			var clientSockaddrIn = sockaddr_in()
			var clientSockaddrLength: socklen_t = socklen_t(sizeofValue(clientSockaddrIn))
			
			let acceptFD = withUnsafePointers(&clientSockaddrIn, &clientSockaddrLength) { clientSockaddrInPtr, clientSockaddrLengthPtr -> Int32 in
				return Darwin.accept(socketFD, UnsafeMutablePointer<sockaddr>(clientSockaddrInPtr), UnsafeMutablePointer<socklen_t>(clientSockaddrLengthPtr))
			}

			if acceptFD > 0 {
				print("Accept FD: \(acceptFD) - \(clientSockaddrIn)")
				let acceptedSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(acceptFD), 0, self.dispatchQueue)

				var on: Int32 = 1
				let setsockoptRC = withUnsafePointer(&on) { ptr -> Int32 in
					return setsockopt(acceptFD, SOL_SOCKET, SO_NOSIGPIPE, UnsafePointer<Void>(ptr), clientSockaddrLength)
				}
				print("setsockoptRC: \(setsockoptRC) \(acceptedSource) \(on)")
				
				dispatch_source_set_event_handler(acceptedSource) {
					print("SOURS \(acceptedSource)")
					let buffer = malloc(4096)
					defer { free(buffer) }

					let bytesRead = read(acceptFD, buffer, 4096)
					if (bytesRead > 0) {
						print("read \(bytesRead)")
						write(acceptFD, buffer, bytesRead)
					}
				}
				dispatch_resume(acceptedSource as dispatch_object_t)
			}
		}
		dispatch_resume(source as dispatch_object_t)
		
		let listenRC = Darwin.listen(socketFD, Int32(50))
		
		print("Socket FD: \(socketFD), \(bindRC), \(listenRC)")
		print("")
		
//		while(true) {
//			var clientSockaddrIn = sockaddr_in()
//			var clientSockaddrLength: socklen_t = socklen_t(sizeofValue(clientSockaddrIn))
//			
//			let acceptFD = withUnsafePointers(&clientSockaddrIn, &clientSockaddrLength) { clientSockaddrInPtr, clientSockaddrLengthPtr -> Int32 in
//				return Darwin.accept(socketFD, UnsafeMutablePointer<sockaddr>(clientSockaddrInPtr), UnsafeMutablePointer<socklen_t>(clientSockaddrLengthPtr))
//			}
//
//			if acceptFD > 0 {
//				print("Accept FD: \(acceptFD) - \(clientSockaddrIn)")
//			}
//		}
		
		dispatch_main()
	}
}