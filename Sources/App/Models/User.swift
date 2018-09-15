//
//  User.swift
//  App
//
//  Created by mac on 2018/9/9.
//

import Foundation
import Vapor
import FluentSQLite


final class User: Codable {
    var id: UUID?
    
    var username: String
    var password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    final class Public: Codable {
        var id: UUID?
        var username: String
        
        var name: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: SQLiteUUIDModel{}
extension User: Migration {}
extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {}

