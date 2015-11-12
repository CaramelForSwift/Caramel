//
//  User.swift
//  Caramel
//
//  Created by Steve Streza on 10/20/15.
//  Copyright © 2015 Lunar Guard. All rights reserved.
//

import Caramel

class UserGenerator {
    var username: String? = nil
    var realName: String? = nil
    var mode: Int? = nil
    var nick: String? = nil

    var user: User? {
        if let username = username, realName = realName, mode = mode, nick = nick {
            return User(username: username, realName: realName, mode: mode, nick: nick)
        } else {
            return nil
        }
    }
}

class User {
    weak var connection: IRCServer.Server.Connection? = nil

    var username: String
    var realName: String
    var mode: Int
    var nick: String
    var rooms = Set<String>()

    init(username: String, realName: String, mode: Int, nick: String) {
        self.username = username
        self.realName = realName
        self.mode = mode
        self.nick = nick
    }

    func joinRoom(room: String) {
        rooms.insert(room)
    }

    func partRoom(room: String) {
        rooms.remove(room)
    }

    func isInRoom(room: String) -> Bool {
        return rooms.contains(room)
    }
}
