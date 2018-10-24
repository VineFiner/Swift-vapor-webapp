//
//  ApiUsersController.swift
//  App
//
//  Created by mac on 2018/10/21.
//

import Foundation
import Vapor
import Crypto
import Fluent

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        // 这里是获取所有用户
        usersRoute.get(use: getAllHandler)
        // 这里是根据用户ID 获取用户
        usersRoute.get(User.parameter, use: getHandler)
        // 这里是根据用户ID 获取所有博客
        usersRoute.get(User.parameter, "blogs", use: getBlogsHandler)
        
        // 这里是登录
        usersRoute.post("normalLogin", use: login)
        
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        // 这里是登录
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        // 这里是创建用户
        tokenAuthGroup.post(User.self, use: createHandler)
        
        // 这里退出登录
        tokenAuthGroup.get("logout", use:logoutHandler)
    }
    
    // 这里是注册
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    
    func getBlogsHandler(_ req: Request) throws -> Future<[Blog]> {
        return try req.parameters.next(User.self).flatMap(to: [Blog].self) { user in
            try user.blogs.query(on: req).all()
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        
        let user = try req.requireAuthenticated(User.self)
        let token = try Token(token: "", userID: user.requireID())
        return token.save(on: req)
    }
    // 这里是登录
    func login(_ req: Request) throws -> Future<Token> {
        return try req.content.decode(User.self).flatMap { user in
            return User.query(on: req).filter(\.email == user.email).first().flatMap { fetchedUser in
                guard let existingUser = fetchedUser else {
                    throw Abort(HTTPStatus.notFound)
                }
                
                let hasher = try req.make(BCryptDigest.self)
                if try hasher.verify(user.password, created: existingUser.password) {
                    // 这里是认证成功
                    // 这里查找token，删除token
                    return try Token.query(on:req).filter(\Token.userID, .equal,existingUser.requireID()).delete().flatMap { _ in
                        // 这里重新生成token
                        let tokenString = try CryptoRandom().generateData(count: 32).base64EncodedString()
                        let token = try Token(token: tokenString, userID: existingUser.requireID())
                        return token.save(on: req)
                    }
                } else {
                    // 这里是认证失败
                    throw Abort(HTTPStatus.unauthorized)
                }
            }
        }
    }
    func logoutHandler(_ req: Request) throws -> Future<HTTPResponse> {
        let user = try req.requireAuthenticated(User.self)
        // 这里是根据用户ID进行查找token然后进行删除
        return try Token.query(on: req).filter(\Token.userID, .equal, user.requireID()).delete().transform(to: HTTPResponse(status: .ok))
    }
}
