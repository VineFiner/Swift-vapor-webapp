//
//  BlogsController.swift
//  App
//
//  Created by mac on 2018/9/9.
//

import Foundation
import Vapor

final class BlogsController: RouteCollection {
    func boot(router: Router) throws {
        let blogRoutes = router.grouped("api", "v1", "blogs")
        blogRoutes.post(Blog.self, use: createHandler)
        blogRoutes.put(Blog.parameter, use: updateHandler)
    }
    // “This helper function takes the type to decode as the first parameter. You can provide any path components before the use: parameter, if required.”
    func createHandler(_ req: Request, blog: Blog) throws -> Future<Blog> {
        // return try req.content.decode(Blog.self).flatMap(to: Blog.self) { blog in
        //  return blog.save(on: req)
        // }
        //“Save the model using Fluent. When the save completes, it returns the model as a Future — in this case, Future<Blog>.”
        return blog.save(on: req)
    }
    func updateHandler(_ req: Request) throws -> Future<Blog> {
        return try req.parameters.next(Blog.self).flatMap { blog in
            return try req.content.decode(Blog.self).flatMap { updateBlog in
                blog.title = updateBlog.title
                blog.content = updateBlog.content
                return blog.save(on: req)
            }
        }
    }
}
