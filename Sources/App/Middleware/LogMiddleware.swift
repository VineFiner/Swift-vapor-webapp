import Vapor

final class LogMiddleware: Middleware {
    // 创建一个存储属性来保存 Logger
    let logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    // 实现 MIddleware 协议
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        // 打印请求的描述
        let reqInfo = "\(request.http.method.string) \(request.http.url.path)"
        print(reqInfo)
//        logger.info(reqInfo)
        //“Forward the incoming request to the next responder.”
        // 将传入的请求转发的下一个响应者
        return try next.respond(to: request)
    }
}

// “Allow LogMiddleware to be registered as a service in your application.”
// “允许LogMiddleware在您的应用程序中注册为服务。”
extension LogMiddleware: ServiceType {
    static func makeService(for worker: Container) throws -> Self {
        // “初始化LogMiddleware实例，使用容器创建必要的Logger。”
        return try .init(logger: worker.make())
    }
}
