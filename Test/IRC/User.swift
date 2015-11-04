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
    var username: String
    var realName: String
    var mode: Int
    var nick: String

    init(username: String, realName: String, mode: Int, nick: String) {
        self.username = username
        self.realName = realName
        self.mode = mode
        self.nick = nick
    }
}