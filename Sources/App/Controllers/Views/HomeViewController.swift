// 这里是HOME主页

import Vapor

final class HomeViewController: RouteCollection {
    func boot(router: Router) throws {
        // 这里是主页、不需要用户认证
        router.frontend(.noAuthed) { (build) in
            build.get("/", use: home)
        }
    }
    
    /// 这里是主页
    func home(req: Request) throws -> Future<View> {
        // 获取所有的博客
        let allBlog = Blog.query(on: req).all()
        
        return allBlog.flatMap(to: View.self) { blogs in
            // 是否已登录
            let userLoggedIn = try req.isAuthenticated(User.self)
            let context = IndexContext.configData(title: "Homepage", blogs: blogs, userLoggedIn: userLoggedIn, req: req)
            return try req.view().render("index", context)
        }
    }
}


struct IndexContext: Encodable {
    let title: String
    let blogs: Future<[RecombinationBlogContext]>
    let userLoggedIn: Bool
    
    struct RecombinationBlogContext: Content {
        let blog: Blog
        let user: User
    }
    
    // 这里是配置数据
    static func configData(title: String, blogs: [Blog], userLoggedIn: Bool, req: Request) -> IndexContext {
        // 这里是重组数据
        let recombinationBlogs = blogs.map({ (blog) -> Future<RecombinationBlogContext> in
            blog.user.get(on: req).map({ user in
                print("This is blog:\(String(describing: blog.createdAt))")
                return RecombinationBlogContext(blog: blog, user: user)
            })
        }).flatten(on: req)
        let context = IndexContext(title: "Homepage", blogs: recombinationBlogs, userLoggedIn: userLoggedIn)
        return context
    }
}


