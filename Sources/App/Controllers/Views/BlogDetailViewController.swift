// 这里是博客内容页面
import Vapor
import Authentication

final class BlogDetailViewController: RouteCollection {
    func boot(router: Router) throws {
        // 这里是博客页面
        let blogRoutes = router.grouped("blogs")
        // 这里是blog页面
        blogRoutes.frontend(.noAuthed) { (build) in
            // 获取单个页面
            // MARK: /blogs/1
            build.get(Blog.parameter, use: blogHandler)
        }
        // 博客管理页面
        // blogs/
        blogRoutes.frontend().group(RedirectMiddleware<User>(path: "/login")) { (build) in
            // 博客创建页面
            build.get("create", use: createBlogHandler)
            // 这里是创建POST请求
            build.post(CreateBlogData.self, at: "create", use: createBlogPostHandler)
            // 这里是博客编辑页面
            build.get(Blog.parameter, "edit", use: editBlogHandler)
            // 这里是博客编辑POST请求
            build.post(Blog.parameter, "edit", use: editBlogPostHandler)
            // 这是博客删除POST请求
            build.post(Blog.parameter, "delete", use: deleteBlogHandler)
        }
        
    }
    // 获取博客单个页面
    func blogHandler(_ req: Request) throws -> Future<View> {
        // 根据参数数据库查找到当前ID的blog
        return try req.parameters.next(Blog.self).flatMap(to: View.self, { blog in
            // 获取当前blog的user
            return blog.user.get(on: req).flatMap(to: View.self, { user in
                // 获取当前blog的 category
                let categories = try blog.categories.query(on: req).all()
                let context = BlogContext(title: blog.name, blog: blog, user: user, categories: categories)
                return try req.view().render("manage/blog", context)
            })
        })
    }
    //博客创建页面
    func createBlogHandler(_ req: Request) throws -> Future<View> {
        let token = try CryptoRandom().generateData(count: 16).base64EncodedString()
        let context = CreateBlogContext(csrfToken: token)
        try req.session()["CSRF_TOKEN"] = token
        return try req.view().render("manage/createBlog", context)
    }
    // 博客创建POST请求
    func createBlogPostHandler(_ req: Request, data: CreateBlogData) throws -> Future<Response> {
        let expectedToken = try req.session()["CSRF_TOKEN"]
        try req.session()["CSRF_TOKEN"] = nil
        guard expectedToken == data.csrfToken else {
            throw Abort(.badRequest)
        }
        
        // 这里是数据内容信息
        // 用户
        let user = try req.requireAuthenticated(User.self)
        // 博客
        let blog = try Blog(name: data.name, summary: data.content, content: data.content, userID: user.requireID())
        return blog.save(on: req).flatMap(to: Response.self, { blog in
            // 获取博客ID
            guard let id = blog.id else {
                throw Abort(.internalServerError)
            }
            // 保存类别
            var categorySaves: [Future<Void>] = []
            for category in data.categories ?? [] {
                // 添加类别
                try categorySaves.append(Category.addCategory(category, to: blog, on: req))
            }
            // 重定向
            let redirect = req.redirect(to: "/blogs/\(id)")
            return categorySaves.flatten(on: req).transform(to: redirect)
        })
    }
    // 获取编辑页面
    func editBlogHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Blog.self)
            .flatMap(to: View.self) { Blog in
                let categories = try Blog.categories.query(on: req).all()
                let context = EditBlogContext(blog: Blog,
                                                 categories: categories)
                return try req.view().render("manage/createBlog", context)
        }
    }
    // 编辑POST请求
    func editBlogPostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(
            to: Response.self,
            req.parameters.next(Blog.self),
            req.content.decode(CreateBlogData.self)) { blog, data in
                let user = try req.requireAuthenticated(User.self)
                blog.name = data.name
                blog.content = data.content
                blog.userID = try user.requireID()
                
                return blog.save(on: req).flatMap(to: Response.self) { savedBlog in
                    guard let id = savedBlog.id else {
                        throw Abort(.internalServerError)
                    }
                    
                    return try blog.categories.query(on: req).all()
                        .flatMap(to: Response.self) { existingCategories in
                            let existingStringArray = existingCategories.map { $0.name }
                            
                            let existingSet = Set<String>(existingStringArray)
                            let newSet = Set<String>(data.categories ?? [])
                            
                            let categoriesToAdd = newSet.subtracting(existingSet)
                            let categoriesToRemove = existingSet.subtracting(newSet)
                            
                            var categoryResults: [Future<Void>] = []
                            
                            for newCategory in categoriesToAdd {
                                categoryResults.append(
                                    try Category.addCategory(newCategory,
                                                             to: blog,
                                                             on: req))
                            }
                            
                            for categoryNameToRemove in categoriesToRemove {
                                let categoryToRemove = existingCategories.first {
                                    $0.name == categoryNameToRemove
                                }
                                
                                if let category = categoryToRemove {
                                    categoryResults.append(
                                        try BlogCategoryPivot
                                            .query(on: req)
                                            .filter(\.blogID == blog.requireID())
                                            .filter(\.categoryID == category.requireID())
                                            .delete())
                                }
                            }
                            
                            return categoryResults
                                .flatten(on: req)
                                .transform(to: req.redirect(to: "/Blogs/\(id)"))
                    }
                }
        }
    }
    // 删除操作
    func deleteBlogHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Blog.self).delete(on: req)
            .transform(to: req.redirect(to: "/"))
    }
}

// 博客展示数据
struct BlogContext: Encodable {
    let title: String
    let blog: Blog
    let user: User
    let categories: Future<[Category]>
}
// 创建上下文
struct CreateBlogContext: Encodable {
    let title = "Create An Blog"
    let csrfToken: String
}

// 创建数据
struct CreateBlogData: Content {
    let name: String
    let content: String
    let categories: [String]?
    let csrfToken: String
}
// 这是编辑上下文
struct EditBlogContext: Encodable {
    let title = "Edit Blog"
    let blog: Blog
    let editing = true
    let categories: Future<[Category]>
}
