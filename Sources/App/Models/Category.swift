//
//  Category.swift
//  App
//
//  Created by mac on 2018/9/24.
//

import Foundation
import Vapor
import FluentSQLite

final class Category: Codable {
    var id: Int?
    var name: String
    init(name: String) {
        self.name = name
    }
}
extension Category: SQLiteModel {}
extension Category: Content {}
extension Category: Migration {}
extension Category: Parameter {}

extension Category {
    // 这里是多对多
    var blogs: Siblings<Category, Blog, BlogCategoryPivot>{
        return siblings()
    }
}

extension Category {
    static func addCategory(_ name: String, to blog: Blog, on req: Request) throws -> Future<Void> {
        return Category.query(on: req).filter(\.name == name).first().flatMap(to: Void.self){ foundCategory in
                if let existingCategory = foundCategory {
                    return blog.categories.attach(existingCategory, on: req).transform(to: ())
                } else {
                    let category = Category(name: name)
                    return category.save(on: req).flatMap(to: Void.self) { savedCategory in
                            return blog.categories.attach(savedCategory, on: req).transform(to: ())
                    }
                }
        }
    }
}
