//
//  Blog.swift
//  App
//
//  Created by mac on 2018/9/9.
//

import Foundation
import Vapor
import FluentSQLite

/// A single entry of a Blog list.
final class Blog: SQLiteModel {
    /// The unique identifier for this `Blog`.
    var id: Int?
    
    /// A title describing what this `Blog` entails.
    var title: String
    var content: String
    
    /// Creates a new `Blog`.
    init(title: String, content: String) {
        self.title = title
        self.content = content
    }
}

/// Allows `Blog` to be used as a dynamic migration.
extension Blog: Migration { }

/// Allows `Blog` to be encoded to and decoded from HTTP messages.
extension Blog: Content { }

/// Allows `Blog` to be used as a dynamic parameter in route definitions.
extension Blog: Parameter { }
