//
//  ApiCategoriesController.swift
//  App
//
//  Created by mac on 2018/10/21.
//

import Foundation
import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoute = router.grouped("api", "categories")
        // 这里是获取所有类别
        categoriesRoute.get(use: getAllHandler)
        // 这里是根据ID 获取类别
        categoriesRoute.get(Category.parameter, use: getHandler)
        // 这里是根据类别ID 获取所有 博客
        categoriesRoute.get(Category.parameter, "blogs", use: getBlogsHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        // 这里是创建类别
        tokenAuthGroup.post(Category.self, use: createHandler)
    }
    
    func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        return category.save(on: req)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
    }
    
    func getBlogsHandler(_ req: Request) throws -> Future<[Blog]> {
        return try req.parameters.next(Category.self).flatMap(to: [Blog].self) { category in
            try category.blogs.query(on: req).all()
        }
    }
}
