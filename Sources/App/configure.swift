import FluentSQLite
import Leaf
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentSQLiteProvider())
    try services.register(LeafProvider())
    
    /// Register routes to the router
    let router = EngineRouter.default()
    // 这里注册路由
    try routes(router)
    try viewRoutes(router)
    services.register(router, as: Router.self)

    // 进行配置
    let myService = NIOServerConfig.default(port: 8013)
    services.register(myService)
    
    /// Use Leaf for rendering views
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    /// Configure Session
    try services.register(AuthenticationProvider())
    // Session 缓存策略
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    // 这里注册自定义中间件
    services.register(LogMiddleware.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self) // Session
    middlewares.use(LogMiddleware.self) // log
    services.register(middlewares)

    // Configure a SQLite database
    let sqlite = try SQLiteDatabase(storage: .file(path: "db.sqlite"))

    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: sqlite, as: .sqlite)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .sqlite)
    migrations.add(model: Token.self, database: .sqlite)
    migrations.add(model: Blog.self, database: .sqlite)
    migrations.add(model: Category.self, database: .sqlite)
    migrations.add(model: BlogCategoryPivot.self, database: .sqlite)
    switch env {
    case .development, .testing:
        // 这里是默认用户
        migrations.add(migration: AdminUser.self, database: .sqlite)
    default:
        break
    }

    services.register(migrations)

}
