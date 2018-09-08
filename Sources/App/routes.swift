import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    // "It works" page
    router.get { req in
        return try req.view().render("welcome")
    }
    // Says hello
    // 使用 String.parameter 指定第二个参数可以是任何String
    router.get("hello", String.parameter) { req -> Future<View> in
        //  提取在 Request对象中传递的用户名
        let name = try req.parameters.next(String.self)
        // 返回问候语
        return try req.view().render("hello", ["name": name])
    }
}
