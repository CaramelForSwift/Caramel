//
//  IRCServer.swift
//  Caramel
//
//  Created by Steve Streza on 10/20/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Caramel

extension String {
    var ircFields: [String] {
        let lastField: String?
        let whereToStop: String.CharacterView.Index
        if let colon = self.characters.indexOf(":") {
            lastField = String(self.characters.suffixFrom(colon.successor()))
            whereToStop = colon.predecessor()
        } else {
            lastField = nil
            whereToStop = self.characters.endIndex
        }

        var fields: [String] = self.characters.prefixUpTo(whereToStop).split(" ").map { String($0) }
        if let lastField = lastField {
            fields.append(lastField)
        }
        return fields
    }
}

class IRCServer {
    typealias Server = ServerTransformer<ServerTransformer<TCPServer, DataToStringUnicodeScalarViewTransformer<Data>, StringUnicodeScalarViewToDataTransformer>, UnicodeScalarViewToSplitStringTransformer, IdentityTransformer<Data>>

    let server: Server
    init(port: UInt16) {
        server = TCPServer(port: port).toStringUnicodeScalarsViewWithEncoding(.UTF8).stringsSplitByNewline
    }

    var connectionsToUsers: [Server.Connection: User] = [:]

    func start() throws {
        try server.listen { connection in
            let userGenerator = UserGenerator()
            var user: User? = nil

            connection.incoming.wait { result in
                do {
                    let lines = try result.result()
                    for line in lines {
                        if let
                            spaceIndex = line.characters.indexOf(" ")
                        {
                            let commandRange = Range<String.CharacterView.Index>(start: line.characters.startIndex, end: spaceIndex)
                            let remainderRange = Range<String.CharacterView.Index>(start: spaceIndex.advancedBy(1), end: line.characters.endIndex.predecessor())
                            let command = String(line[commandRange])
                            let remainder = String(line[remainderRange])

                            if let user = user {
                                if let response = self.user(user, performedCommand: command, withContents: remainder) {
                                    connection.outgoing.write("\(response)\r\n".utf8.data)
                                }
                            } else {
                                if let response = self.unauthenticatedUser(userGenerator, performedCommand: command, withContents: remainder) where user == nil {
                                    connection.outgoing.write("\(response)\r\n".utf8.data)
                                }

                                user = userGenerator.user
                                if let _ = user {
                                    self.connectionsToUsers[connection] = user
                                    connection.outgoing.write(Reply.Welcome.messageWithResponse("Welcome to the first IRC server ever written in Swift! 🎉"))
                                }
                            }
                        }
                    }
                } catch {
                    connection.outgoing.end()
                }
            }
        }
    }

    func unauthenticatedUser(user: UserGenerator, performedCommand command: String, withContents contents: String) -> String? {
        switch command {
        case "NICK":
            user.nick = contents
            return nil
        case "USER":
            let strings = contents.ircFields
            if strings.count >= 4 {
                if let
                    mode = Int(strings[1])
                {
                    user.username = strings[0]
                    user.mode = mode
                    user.realName = strings[3]
                }
            }
            return nil
        default:
            print("Dropping command \(command) \(contents)")
            return nil
        }
    }

    func user(user: User, performedCommand command: String, withContents contents: String) -> String? {
        print("Command: \(command) \(contents)")
        switch command {
        case "NICK":
            user.nick = contents
            return "OK"
        case "USER":
            let strings = contents.ircFields
            if strings.count >= 4 {
                if let
                    mode = Int(strings[1])
                {
                    user.username = strings[0]
                    user.mode = mode
                    user.realName = strings[3]
                }
            }
            return "OK"
        case "PING":
            return "PONG \(contents)"
        default:
            print("Dropping command \(command) \(contents)")
            return nil
        }
    }
}

extension IRCServer {
    enum Reply: Int {
        case Welcome = 1
        case YourHost = 2
        case Created = 3
        case MyInfo = 4
        case Bounce = 5

        case None = 300

        case UserHost = 302
        case ISON = 303

        case Away = 301
        case NoLongerAway = 305
        case NowAway = 306

        case WhoIsUser = 311
        case WhoIsServer = 312
        case WhoIsOperator = 313
        case WhoIsIdle = 317
        case WhoIsChannels = 319
        case EndOfWhoIs = 318

        case WhoWasUser = 314
        case EndOfWhoWas = 369

        case ListStart = 321
        case List = 322
        case ListEnd = 323

        case ChannelModeIs = 324

        case NoTopic = 331
        case Topic = 332

        case Inviting = 341
        case Summoning = 342

        case Version = 351

        case WhoReply = 352
        case EndOfWho = 315

        case NameReply = 353
        case EndOfNames = 366

        case BanList = 367
        case EndOfBanList = 368

        case Info = 371
        case EndOfInfo = 374

        case MOTDStart = 375
        case MOTD = 372
        case EndOfMOTD = 376
    }
}

extension IRCServer.Reply {
    var message: String {
        var value: String
        if rawValue >= 100 {
            value = "\(rawValue)"
        } else if rawValue >= 10 {
            value = "0\(rawValue)"
        } else {
            value = "00\(rawValue)"
        }
        return "\(value) RPL_\(command)"
    }
    var command: String {
        switch (self) {
        case .Welcome: return "WELCOME"
        case .YourHost: return "YOURHOST"
        case .Created: return "CREATED"
        case .MyInfo: return "MYINFO"
        case .Bounce: return "BOUNCE"

        case .None: return "NONE"
        case .UserHost: return "USERHOST"
        case .ISON: return "ISON"
        case .Away: return "AWAY"
        case .NoLongerAway: return "UNAWAY"
        case .NowAway: return "NOWAWAY"
        case .WhoIsUser: return "WHOISUSER"
        case .WhoIsServer: return "WHOISSERVER"

        case .WhoIsOperator: return "WHOISOPERATOR"
        case .WhoIsIdle: return "WHOISIDLE"
        case .WhoIsChannels: return "WHOISCHANNELS"
        case .EndOfWhoIs: return "ENDOFWHOIS"

        case .WhoWasUser: return "WHOWASUSER"
        case .EndOfWhoWas: return "ENDOFWHOWAS"

        case .ListStart: return "LISTSTART"
        case .List: return "LIST"
        case .ListEnd: return "LISTEND"

        case .ChannelModeIs: return "CHANNELMODES"

        case .NoTopic: return "NOTOPIC"
        case .Topic: return "TOPIC"

        case .Inviting: return "INVITING"
        case .Summoning: return "SUMMONING"

        case .Version: return "VERSION"

        case .WhoReply: return "WHOREPLY"
        case .EndOfWho: return "ENDOFWHO"

        case .NameReply: return "NAMEREPLY"
        case .EndOfNames: return "ENDOFNAMES"

        case .BanList: return "BANLIST"
        case .EndOfBanList: return "ENDOFBANLIST"
            
        case .Info: return "INFO"
        case .EndOfInfo: return "ENDOFINFO"
            
        case .MOTDStart: return "MOTDSTART"
        case .MOTD: return "MOTD"
        case .EndOfMOTD: return "ENDOFMOTD"
        }
    }

    func messageWithResponse(string: String) -> Data {
        return "\(self.message) :\(string)\r\n".utf8.data
    }
}
