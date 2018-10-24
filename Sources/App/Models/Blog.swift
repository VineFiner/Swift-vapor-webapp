//
//  Blog.swift
//  App
//
//  Created by mac on 2018/9/15.
//

import Foundation
import Vapor
import FluentSQLite

final class Blog: Codable {
    var id: Int?
    
    // 章节名
    var name: String
    // 章节简介
    var summary: String
    // 章节内容
    var content: String
    
    // 这里是时间
    var createdAt: Date?
    var updatedAt: Date?
    static var createdAtKey: TimestampKey? { return \.createdAt }
    static var updatedAtKey: TimestampKey? { return \.updatedAt }
    
    // 用户id、用户名、用户头像
    var userID: User.ID
    
    // 创建一个新的`Blog`
    init(name: String, summary: String, content: String, userID: User.ID) {
        self.name = name;
        self.summary = summary;
        self.content = content;
        
        self.userID = userID
    }
    
}
extension Blog: SQLiteModel { }
extension Blog: Content { }
extension Blog: Parameter { }

/// 数据库关系
extension Blog {
    // 父子关系
    var user: Parent<Blog, User> {
        return parent(\.userID)
    }
    // 兄弟关系
    var categories: Siblings<Blog, Category, BlogCategoryPivot> {
        return siblings()
    }
}
// 添加外键约束
extension Blog: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
