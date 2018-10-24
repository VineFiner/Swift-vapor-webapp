import Vapor

/// Register your application's routes here.
public func viewRoutes(_ router: Router) throws {
    // 用户管理页面
    try router.register(collection: AuthViewController())
    // 这里是主页
    try router.register(collection: HomeViewController())
    // 这里是管理页面
    try router.register(collection: ManageViewController())
    // 这里是博客页面
    try router.register(collection: BlogDetailViewController())
}
