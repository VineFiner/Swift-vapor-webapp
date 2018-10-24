//
//  BlogCategoryPivot.swift
//  App
//
//  Created by mac on 2018/9/24.
//

import Foundation
import Vapor
import FluentSQLite

final class BlogCategoryPivot: SQLiteUUIDPivot, ModifiablePivot {
    var id: UUID?
    var blogID: Blog.ID
    var categoryID: Category.ID
    
    typealias Left = Blog
    typealias Right = Category
    static let leftIDKey: LeftIDKey = \.blogID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ blog: Blog, _ category: Category) throws {
        self.blogID = try blog.requireID()
        self.categoryID = try category.requireID()
    }
}

// 外键约束
extension BlogCategoryPivot: Migration {
    static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.blogID, to: \Blog.id, onDelete: .cascade)
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        }
    }
}



























