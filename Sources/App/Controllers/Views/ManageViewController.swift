// 这里是管理页面
import Vapor

final class ManageViewController: RouteCollection {
    func boot(router: Router) throws {
        
        router.frontend(.noAuthed).group("manage") { (build) in
            //
            build.get("/", use: manage)
            // 所有博客
            // MARK: http://localhost:8013/manage/blogs
            build.get("blogs", use: allBlogsHandler)
            // 获取所有用户
            // MARK:
            build.get("users", use: allUsersHandler)
            // 获取单个用户
            build.get("users", User.parameter, use: userHandler)
            // 获取所有类别
            build.get("categories", use: allCategoriesHandler)
            // 获取单个类别
            build.get("categories", Category.parameter, use: categoryHandler)
            
        }
    }
    
    // 这里是管理页面
    func manage(req: Request) throws -> Future<View> {
        // 获取所有的博客
        let allBlog = Blog.query(on: req).all()
        
        return allBlog.flatMap(to: View.self) { blogs in
            let blogsData = blogs.isEmpty ? nil : blogs
            let userLoggedIn = try req.isAuthenticated(User.self)
            let context = ManageContext(title: "Managepage", blogs: blogsData, userLoggedIn: userLoggedIn)
            return try req.view().render("manage/index", context)
        }
    }
    
    // 这里获取所有博客
    func allBlogsHandler(_ req: Request) throws -> Future<View> {
        return Blog.query(on: req).all().flatMap(to: View.self, { blogs in
            let blogsData = blogs.isEmpty ? nil : blogs
            let userLoggedIn = try req.isAuthenticated(User.self)
            let context = AllBlogsContext(title: "All Blogs", blogs: blogsData, userLoggedIn: userLoggedIn)
            return try req.view().render("manage/allBlogs", context)
        })
    }
    // 这里获取所有用户
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).all().flatMap(to: View.self, { users in
            let context = AllUsersContext(title: "All Users",
                                          users: users)
            return try req.view().render("manage/allUsers", context)
        })
    }
    // 获取单个用户
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
                // 这里是 一对多 父子关系。获取用户博客
                return try user.blogs.query(on: req).all().flatMap(to: View.self) { blogs in
                        let context = UserContext(title: user.nickname,
                                                  user: user,
                                                  blogs: blogs)
                        return try req.view().render("manage/user", context)
                }
        }
    }
    // 获取所有类别
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        let categories = Category.query(on: req).all()
        // 这里是Future类型
        let context = AllCategoriesContext(categories: categories)
        return try req.view().render("manage/allCategories", context)
    }
    // 获取单个类别
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self).flatMap(to: View.self) { category in
                let blogs = try category.blogs.query(on: req).all()
                let context = CategoryContext(title: category.name, category: category, blogs: blogs)
                return try req.view().render("namage/category", context)
        }
    }
}

struct ManageContext: Encodable {
    let title: String
    let blogs: [Blog]?
    let userLoggedIn: Bool
}
struct AllBlogsContext: Encodable {
    let title: String
    let blogs: [Blog]?
    let userLoggedIn: Bool
}
struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}
struct UserContext: Encodable {
    let title: String
    let user: User
    let blogs: [Blog]
}

struct AllCategoriesContext: Encodable {
    let title = "All Categories"
    // 这里和用户那里不一样、这里是FUture类型
    let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let blogs: Future<[Blog]>
}
