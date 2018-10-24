import Vapor
import Fluent
import Authentication

final class ApiBlogController: RouteCollection {
    func boot(router: Router) throws {
        router.versioned { build in
            // 获取所有博客
            build.get("blogs", use: getAllBlog)
            // 通过ID 获取博客
            build.get("blogs", Blog.parameter, use: getHandler)
            // 这里是搜索
            build.get("blogs", "search", use: searchHandler)
            // 这里是获取第一个数据
            build.get("blogs", "first", use: getFirstHandler)
            // 这里是升序排序
            build.get("blogs", "sorted", use: sortedHandler)
            // 这里通过博客ID 查找用户
            build.get("blogs", Blog.parameter, "user", use: getUserHandler)
            // 通过博客ID 查找所有分类
            build.get("blogs", Blog.parameter, "categories", use: getCategoriesHandler)
        }
        // 这里是需要用户认证的
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = router.grouped(tokenAuthMiddleware, guardAuthMiddleware).grouped("blogs")
        tokenAuthGroup.versioned { (build) in
            // 创建博客
            build.post(BlogCreateData.self, use: createHandler)
            // 根据ID 删除博客
            build.delete(Blog.parameter, use: deleteHandler)
            // 这里是根据ID 修改博客
            build.put(Blog.parameter, use: updateHandler)
            // 这里是根据 博客ID 类别ID 添加关系
            tokenAuthGroup.post(Blog.parameter, "categories", Category.parameter, use: addCategoriesHandler)
            // 这里是根据 博客ID 类别ID 删除关系
            tokenAuthGroup.delete(Blog.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
        }
    }
    // MARK: http://localhost:8013/api/blogs?page=1
    func getAllBlog(req: Request) throws -> Future<Response> {
        let page = req.query[Int.self, at: "page"] ?? 1
        // 这里是页面
        return Blog.query(on: req).count().flatMap { count in
            let page = PageContext(item_count: count, page_index: page)
            let blogs = Blog.query(on: req).range(page.range).join(\User.id, to: \Blog.userID).alsoDecode(User.self).all()
            // 组装数据
            let contextBlogs = blogs.map { blogTuples in
                return try blogTuples.map { context -> BlogApiContext in
                    let (blogItem, userItem) = context
                    let id =  try userItem.requireID()
                    let name = userItem.nickname
                    return BlogApiContext(userName: name, userId: id, blog: blogItem)
                }
            }
            // 这里组装page 数据
            let pageContext = contextBlogs.map { tempBlogs in
                return BlogApiIndexContext(page: page, blogs: tempBlogs)
            }
            // 这里格式化显示数据
            return try pageContext.makeJson(on: req)
        }
    }
    
    // MARK:GET /api/blogs/1.   get the blog with ID 1
    func getHandler(_ req: Request) throws -> Future<Blog> {
        return try req.parameters.next(Blog.self)
    }
    // MARK:GET /api/blogs/search?name=Hello
    func searchHandler(_ req: Request) throws -> Future<[Blog]> {
        guard let searchTerm = req.query[String.self, at: "name"] else {
            throw Abort(.badRequest)
        }
        return Blog.query(on: req).group(.or) { or in
            or.filter(\.name == searchTerm)
            or.filter(\.content == searchTerm)
        }.all()
    }
    // MARK:GET /api/blogs/first.    get first blog
    func getFirstHandler(_ req: Request) throws -> Future<Blog> {
        return Blog.query(on: req).first().map(to: Blog.self) { blog in
            guard let blog = blog else {
                throw Abort(.notFound)
            }
            return blog
        }
    }
    // MARK:GET /api/blogs/sorted.   ascending get blogs
    func sortedHandler(_ req: Request) throws -> Future<[Blog]> {
        return Blog.query(on: req).sort(\.name, .ascending).all()
    }
    // MARK:GET /api/blogs/1/user.   get user with blogID 1
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Blog.self).flatMap(to: User.Public.self) { blog in
            blog.user.get(on: req).convertToPublic()
        }
    }
    // MARK:GET /api/blogs/1/categories.    get categories with blogID 1
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Blog.self).flatMap(to: [Category].self) { blog in
            try blog.categories.query(on: req).all()
        }
    }
    
    /************下面需要用户权限**************/
    // MARK:POST /api/blogs.
    func createHandler(_ req: Request, data: BlogCreateData) throws -> Future<Blog> {
        let user = try req.requireAuthenticated(User.self)
        let blog = try Blog(name: data.name, summary: data.content, content: data.content, userID: user.requireID())
        return blog.save(on: req)
    }
    // MARK:DELETE /api/blogs/1.
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Blog.self).delete(on: req).transform(to: HTTPStatus.noContent)
    }
    // MARK:PUT /api/blogs/1.
    func updateHandler(_ req: Request) throws -> Future<Blog> {
        return try flatMap(to: Blog.self,
                           req.parameters.next(Blog.self),
                           req.content.decode(BlogCreateData.self)) { blog, updateData in
                            blog.name = updateData.name
                            blog.content = updateData.content
                            let user = try req.requireAuthenticated(User.self)
                            blog.userID = try user.requireID()
                            return blog.save(on: req)
        }
    }
//    func updateHandler(_ req: Request) throws -> Future<Blog> {
//        return try req.parameters.next(Blog.self).flatMap { blog in
//            return try req.content.decode(BlogCreateData.self).flatMap { updateData in
//                blog.name = updateData.name
//                blog.content = updateData.content
//                let user = try req.requireAuthenticated(User.self)
//                blog.userID = try user.requireID()
//                return blog.save(on: req)
//            }
//        }
//    }
    // MARK:POST /api/<BLOG ID>/categories/<CATEGORY ID>.
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Blog.self), req.parameters.next(Category.self)) { blog, category in
            return blog.categories.attach(category, on: req).transform(to: .created)
        }
    }
    // MARK:DELETE /api/<BLOG ID>/categories/<CATEGORY ID>.
    func removeCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Blog.self), req.parameters.next(Category.self)) { blog, category in
            return blog.categories.detach(category, on: req).transform(to: .noContent)
        }
    }
}

struct BlogApiIndexContext: Content {
    let page: PageContext
    let blogs: [BlogApiContext]
}

struct BlogApiContext: Content {
    let userName: String
    let userId: User.ID
    let blog: Blog
}

//
struct BlogCreateData: Content {
    let name: String
    let content: String
}
