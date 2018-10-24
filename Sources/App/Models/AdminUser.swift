//
//  AdminUser.swift
//  App
//
//  Created by mac on 2018/10/2.
//

import Foundation
import FluentSQLite
import Authentication

struct AdminUser: Migration {
    typealias Database = SQLiteDatabase
    
    static func prepare(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        let user = User(name: "admin", email: "admin", password: hashedPassword)
        return user.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: SQLiteConnection) -> EventLoopFuture<Void> {
        return Future.map(on: conn, {})
    }
}
