//
//  Token.swift
//  App
//
//  Created by mac on 2018/10/21.
//

import Foundation
import Vapor
import FluentSQLite
import Authentication

final class Token: Codable {
    var id: Int?
    var token: String
    var userID: User.ID
    
    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }
}

extension Token: SQLiteModel{}
extension Token: Content {}
// 添加外键约束
extension Token: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
// 添加认证
extension Token: Authentication.Token {
    static let userIDKey: UserIDKey = \Token.userID
    typealias UserType = User
}

extension Token: BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}
