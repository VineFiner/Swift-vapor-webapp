//
//  User.swift
//  App
//
//  Created by mac on 2018/9/15.
//

import Foundation
import FluentSQLite
import Authentication

final class User: SQLiteUUIDModel {
    var id: UUID?
    
    var email: String
    var password: String
    var nickname: String
    
    var userimage: String
    var create_at: String
    
    init(name: String, email: String, password: String) {
        self.email = email
        self.password = password

        self.nickname = name;
        self.userimage = "";
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.create_at = formatter.string(from: Date())
    }
}
extension User {
    struct Public: Content {
        let id: UUID?
        let email: String
        let name: String
        let image: String
        let create_at: String
    }
    func convertToPublic() -> User.Public {
        return User.Public(id: id, email: email, name: nickname, image: userimage, create_at: create_at)
    }
}
extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User {
    // 这里是父子关系，一对多
    var blogs: Children<User, Blog> {
        return children(\.userID)
    }
}

extension User: Migration { }
extension User: Content { }
extension User: Parameter { }

// 这里是密码基础认证
extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.email
    }
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
}
extension User: SessionAuthenticatable {}
// 添加Token 认证
extension User: TokenAuthenticatable {
    typealias TokenType = Token
}
