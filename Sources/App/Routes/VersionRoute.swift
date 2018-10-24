import Vapor

struct VersionRoute {
    static let path = "api"
}

extension Router {
    func versioned(handler: (Router) -> ()) {
        return group(VersionRoute.path, configure: handler)
    }
    
    func versioned() -> Router {
        return grouped(VersionRoute.path)
    }
}

extension Router {
    fileprivate func middleware(_ type: FrontendMiddlewareType) -> [Middleware] {
        
        var middleware: [Middleware] = []
        
        middleware.append(User.authSessionsMiddleware())
        
        if type == .all {
//            middleware.append(AuthedMiddleware())
        }
        return middleware
    }
    
    func frontend(_ type: FrontendMiddlewareType = .all, handler: (Router) -> ()) {
        group(middleware(type), configure: handler)
    }
    
    func frontend(_ type: FrontendMiddlewareType = .all) -> Router {
        return grouped(middleware(type))
    }
}

enum FrontendMiddlewareType {
    case all
    case noAuthed
}
