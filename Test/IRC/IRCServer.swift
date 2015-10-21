//
//  IRCServer.swift
//  Caramel
//
//  Created by Steve Streza on 10/20/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Caramel

class IRCServer {
    typealias Server = ServerTransformer<ServerTransformer<TCPServer, DataToStringUnicodeScalarViewTransformer<Data>, StringUnicodeScalarViewToDataTransformer>, UnicodeScalarViewToSplitStringTransformer, IdentityTransformer<Data>>

    let server: Server
    init(port: UInt16) {
        server = TCPServer(port: port).toStringUnicodeScalarsViewWithEncoding(.UTF8).stringsSplitByNewline
    }

    var connections: [Server.Connection] = []

    func start() throws {
        try server.listen { connection in
            self.connections.append(connection)
            
            connection.incoming.wait { result in
                do {
                    let lines = try result.result()
                    for line in lines {
                        if let
                            spaceIndex = line.characters.indexOf(" ")
                        {
                            let range = Range<String.CharacterView.Index>(start: line.characters.startIndex, end: spaceIndex)
                            let foo = String(line[range])
                            print("Command: \(foo)")
                        }
                        print("line: \(line)")
                    }
                } catch {
                    connection.outgoing.end()
                }
            }
        }
    }
}