// 这里是用户管理页面

import Vapor
import Authentication

final class AuthViewController: RouteCollection {
    func boot(router: Router) throws {
        // 这里是默认添加session Middlerware
        router.frontend { (build) in
            // 获取注册视图
            build.get("register", use: registerHandler)
            // 注册Post请求
            build.post(RegisterData.self, at: "register", use: registerPostHandler)
            
            // 这里是登录视图
            build.get("login", use: loginHandler)
            // 这里是登录Post请求
            build.post(LoginPostData.self, at: "login", use: loginPostHandler)
            
            // 这里是退出登录
            build.post("logout", use: logoutHandler)
        }
    }
    
    // 这里是注册
    func registerHandler(_ req: Request) throws -> Future<View> {
        // 如果有错误提示信息，错误弹框警告
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return try req.view().render("register", context)
    }
    func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let redirect: String
            if let error = error as? ValidationError,
                let message = error.reason.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }
        
        let password = try BCrypt.hash(data.password)
        let user = User(name: data.nickName, email: data.email, password: password)
        return user.save(on: req).map(to: Response.self) { user in
            try req.authenticateSession(user)
            return req.redirect(to: "/")
        }
    }
    
    // 这里是登录
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return try req.view().render("login", context)
    }
    // 这里是登录POST请求
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(),on: req)
            .map(to: Response.self) { user in
                guard let user = user else {
                    return req.redirect(to: "/login?error")
                }
                try req.authenticateSession(user)
                return req.redirect(to: "/")
        }
    }
    
    // 这里是退出登录
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/")
    }
}

struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
}

// 注册数据
struct RegisterData: Content {
    let nickName: String
    let email: String
    let password: String
    let confirmPassword: String // 确认密码
}
// 这里是密码认证
extension RegisterData: Validatable, Reflectable {
    static func validations() throws -> Validations<RegisterData> {
        var validations = Validations(RegisterData.self)
        try validations.add(\.nickName, .count(1...))
        try validations.add(\.email, .count(3...))
        try validations.add(\.password, .count(3...))
        validations.add("密码匹配") { model in
            guard model.password == model.confirmPassword else {
                throw BasicValidationError("密码不匹配")
            }
        }
        return validations
    }
}

// 登录数据
struct LoginContext: Encodable {
    let title = "登录"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Content {
    let username: String
    let password: String
}
