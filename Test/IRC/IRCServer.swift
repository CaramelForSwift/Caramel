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

    var connectionsToUsers: [Server.Connection: User] = [:]

    func start() throws {
        try server.listen { connection in
            let user = User()
            self.connectionsToUsers[connection] = user
            
            connection.incoming.wait { result in
                do {
                    let lines = try result.result()
                    for line in lines {
                        if let
                            spaceIndex = line.characters.indexOf(" ")
                        {
                            let commandRange = Range<String.CharacterView.Index>(start: line.characters.startIndex, end: spaceIndex)
                            let remainderRange = Range<String.CharacterView.Index>(start: spaceIndex.advancedBy(1), end: line.characters.endIndex)
                            let command = String(line[commandRange])
                            let remainder = String(line[remainderRange])
                            if let response = self.user(user, performedCommand: command, withContents: remainder) {
                                connection.outgoing.write("\(response)\n".utf8.data)
                            }
                        }
                    }
                } catch {
                    connection.outgoing.end()
                }
            }
        }
    }

    func user(user: User, performedCommand command: String, withContents contents: String) -> String? {
        switch command {
        case "NICK":
            user.nick = contents
            print("Nick: \(user.nick)")
            return "OK"
        case "USER":
            return "OK"
        default:
            print("Dropping command \(command) \(contents)")
            return nil
        }
    }
}

extension IRCServer {
    enum Reply(Int, String) {
        case UserHost = (302, "RPL_USERHOST")
        case ISON = (303, "RPL_ISON")
    }
}