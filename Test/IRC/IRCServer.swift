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
    let host: String
    var messageOfTheDay: [String]? = nil
    init(host: String, port: UInt16) {
        self.host = host
        self.server = TCPServer(port: port).toStringUnicodeScalarsViewWithEncoding(.UTF8).stringsSplitByNewline
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
                            let command = String(line[commandRange]).stringByTrimmingSpaces
                            let remainder = String(line[remainderRange]).stringByTrimmingSpaces

                            if let user = user {
                                let responses = self.user(user, performedCommand: command, withContents: remainder)
                                responses.forEach { response in
                                    self.write(response, toConnection: connection)
                                }
                            } else {
                                if let response = self.unauthenticatedUser(userGenerator, performedCommand: command, withContents: remainder) where user == nil {
                                    connection.outgoing.write("\(response)\r\n".utf8.data)
                                }

                                user = userGenerator.user
                                if let user = user {
                                    self.connectionsToUsers[connection] = user
                                    user.connection = connection

                                    self.write(ReplyMessage(.Welcome, "Welcome to the first IRC server written in Swift!"), toConnection: connection)
                                    self.write(ReplyMessage(.MyInfo, parameters: [self.host, "Caramel"]), toConnection: connection)

                                    if let motd = self.messageOfTheDay where motd.count > 0 {
                                        self.write(ReplyMessage(.MOTDStart, "- \(self.host) Message of the Day -"), toConnection: connection)
                                        motd.forEach { line in
                                            self.write(ReplyMessage(.MOTD, line), toConnection: connection)
                                            return
                                        }
                                        self.write(ReplyMessage(.EndOfMOTD, "End of /MOTD"), toConnection: connection)
                                    }
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

    func user(user: User, performedCommand command: String, withContents contents: String) -> [ReplyMessage] {
        print("Command: \(command) \(contents)")
        switch command {
        case "NICK":
            user.nick = contents
            return []
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
            return []
        case "PING":
            return [/*ReplyMessage(.Pong, "PONG")*/]
        case "JOIN":
            self.user(user, joinedRoom: contents)
            let allUsers = connectionsToUsers.values.filter { $0.rooms.contains(contents) }.map { "\($0.nick)" }
            var commands: [ReplyMessage] = allUsers.map { ReplyMessage(.NameReply, $0, room: contents, parameters: ["="]) }
            commands.insert(ReplyMessage(.Topic, "Room! \(contents)", room: contents), atIndex: 0)
            commands.append(ReplyMessage(.EndOfNames, "End of /NAMES list", room: contents))
            return commands
        case "PRIVMSG":
            let strings = contents.ircFields
            if let room = strings.first, message = strings.last where user.isInRoom(room) {
                let users = self.connectionsToUsers.filter { $1.isInRoom(room) }
                for (connection, _) in users {
                    if connection != user.connection {
                        write("PRIVMSG \(room) :\(message)", toConnection: connection, from: user)
                    }
                }
            }
            return []
        default:
            print("Dropping command \(command) \(contents)")
            return []
        }
    }

    func user(user: User, joinedRoom room: String) {
        user.joinRoom(room)

        let matchingConnectionsToUsers = connectionsToUsers.filter { $1.isInRoom(room) }
        for (connection, _) in matchingConnectionsToUsers {
            write("JOIN \(room)", toConnection: connection, from: user)
        }
    }

    func write(reply: ReplyMessage, toConnection connection: Server.Connection, from user: User? = nil) {
        var fields: [String] = []
        fields.append(reply.reply.message)

        if let user = connectionsToUsers[connection] {
            fields.append(user.nick)
        }

        if let room = reply.room {
            fields.append(room)
        }

        reply.parameters.forEach { fields.append($0) }

        if reply.message.characters.count > 0 {
            fields.append(":\(reply.message)")
        }

        let string = "\(fields.joinWithSeparator(" "))\r\n"
        write(string, toConnection: connection, from: user)
    }

    func write(string: String, toConnection connection: Server.Connection, from user: User? = nil) {
        let prefix = { () -> String in
            if let user = user {
                return ":\(user.nick)!\(user.username)@127.0.0.1"
            } else {
                return ":\(self.host)"
            }
        }()

        let fullString = "\(prefix) \(string)\r\n"
        connection.outgoing.write(fullString.utf8.data)
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

    struct ReplyMessage {
        let reply: Reply
        let message: String
        let room: String?
        let parameters: [String]

        init(_ reply: Reply, _ message: String = "", room: String? = nil, parameters: [String] = []) {
            self.reply = reply
            self.message = message
            self.room = room
            self.parameters = parameters
        }
    }
}

extension IRCServer.Reply {
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

        case .NameReply: return "NAMREPLY"
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

    var message: String {
        var value: String
        if rawValue >= 100 {
            value = "\(rawValue)"
        } else if rawValue >= 10 {
            value = "0\(rawValue)"
        } else {
            value = "00\(rawValue)"
        }
        return "\(value)"
    }

    func messageWithResponse(string: String, nick: String? = nil, channel: String? = nil, parameters: [String] = []) -> String {
        var allParameters: [String] = []
        if let nick = nick {
            allParameters.append(nick)
        }
        if let channel = channel {
            allParameters.append(channel)
        }
        allParameters.appendContentsOf(parameters)

        allParameters = allParameters.filter { $0.characters.count > 0 }

        let parametersString = (allParameters.count == 0 ? "" : allParameters.joinWithSeparator(" ") + " ")
        return "\(self.message) \(parametersString):\(string)"
    }

    func messageDataWithResponse(string: String, nick: String? = nil, channel: String? = nil, parameters: [String] = []) -> Data {
        return "\(messageWithResponse(string, nick: nick, channel: channel, parameters: parameters))\r\n".utf8.data
    }
}
