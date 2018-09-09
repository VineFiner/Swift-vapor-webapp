import Vapor
import Fluent

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
    // “Use String.parameter to specify that the second parameter can be any String.”
    // 使用 String.parameter 指定第二个参数可以是任何String
    router.get("hello", String.parameter) { req -> String in
        //    “Extract the user’s name which is passed in the Request object.”
        //  提取在 Request对象中传递的用户名
        let name = try req.parameters.next(String.self)
        // “Use the name to return your greeting.”
        // “使用名称返回你的问候语。”
        return "Hello, \(name)!"
    }
}

// MARK: curd data operations
public func crudRoutes(_ router: Router) throws {
    
    // “路由处理程序接受Content类型作为第一个参数以及at：参数名称后的任何路径参数。 路由处理程序解码数据并将其作为第二个参数传递给闭包。“
    router.post(InfoData.self, at: "info") { req, data -> InfoResponse in
        //    “通过从数据变量中提取名称来返回字符串。”
        print("This is name:\(data.name)")
        // “使用已解码的请求构建新的InfoResponse类型。”
        return InfoResponse(request: data)
    }
    
    // MARK: POST http://localhost:8012/api/blogs
    // “Register a new route at /api/blogs/ that accepts a POST request and returns Future<Blog>.”
    router.post("api", "blogs") { req -> Future<Blog> in
        // “Decode the request’s JSON into an Blog. This is made simple because Blog conforms to Content. decode(_:) returns a Future; use flatMap(to:) to extract the Blog when decoding completes.”
        return try req.content.decode(Blog.self).flatMap(to: Blog.self) { blog in
            //“Save the model using Fluent. When the save completes, it returns the model as a Future — in this case, Future<Blog>.”
            return blog.save(on: req)
        }
    }
    // MARK: GET http://localhost:8012/api/blogs/
    // “Register a new route handler for the request which returns Future<[Blog]>, a future array of Blogs.”
    router.get("api", "blogs") { req -> Future<[Blog]> in
        // “Perform a query to get all the blogs.”
        // 执行一个查询获取所有blog
        // “Fluent adds functions to models to be able to perform queries on them. You must give the query a DatabaseConnectable. This is almost always the request and provides a thread to perform the work. all() returns all the models of that type in the database. This is equivalent to the SQL query SELECT * FROM blogs;.”
        return Blog.query(on: req).all()
    }
    
    // MARK: GET http://localhost:8012/api/blogs/1
    // “Vapor’s powerful type safety for parameters extends to models that conform to Parameter. To make this work for Blog, open Blog.swift and add the following at the end of the file:" 👉   extension Blog: Parameter { }
    // “Register a route at /api/blogs/<ID> to handle a GET request. The route takes the blog’s id property as the final path segment. This returns Future<blog>.”
    router.get("api", "blogs", Blog.parameter) { req -> Future<Blog> in
        // “Extract the blog from the request using the parameter function. This function performs all the work necessary to get the blog from the database. It also handles the error cases when the blog does not exist, or the ID type is wrong, for example, when you pass it an integer when the ID is a UUID.”
        return try req.parameters.next(Blog.self)
    }
    
    // MARK: PUT http://localhost:8012/api/blogs/1  👉  Add two parameters with titles and contents
    // “Register a route for a PUT request to /api/blogs/<ID> that returns Future<blog>.”
    router.put("api", "blogs", Blog.parameter) { req -> Future<Blog> in
        // “Use flatMap(to:_:_:), the dual future form of flatMap, to wait for both the parameter extraction and content decoding to complete. This provides both the blog from the database and blog from the request body to the closure.”
        return try flatMap(to: Blog.self,req.parameters.next(Blog.self),req.content.decode(Blog.self))
        { blog, updatedBlog in
            // “Update the acronym’s properties with the new values.”
            blog.title = updatedBlog.title
            blog.content = updatedBlog.content
            // Save the blog and return the result
            return blog.save(on: req)
        }
    }
    
    // MARK: DELETE http://localhost:8012/api/blogs/1
    // “Register a route for a DELETE request to /api/blogs/<ID> that returns Future<HTTPStatus>.”
    router.delete("api", "blogs", Blog.parameter) { req -> Future<HTTPStatus> in
        //“Extract the blog to delete from the request’s parameters.”
        return try req.parameters.next(Blog.self)
            //“Delete the blog using delete(on:). Instead of requiring you to unwrap the returned Future, Fluent allows you to call delete(on:) directly on that Future. This helps tidy up code and reduce nesting. Fluent provides convenience functions for delete, update, create and save.”
            .delete(on: req)
            //“Transform the result into a 204 No Content response. This tells the client the request has successfully completed but there’s no content to return.”
            .transform(to: HTTPStatus.noContent)
    }
    
    // MARK: Fluent queries
    // 1、import Fluent
    
    // MARK: QUERY GET http://localhost:8012/api/blogs/search?term=haha
    // “Register a new route handler for /api/blogs/search that returns Future<[Blogs]>.”
    router.get("api", "blogs", "search") { req -> Future<[Blog]> in
        // “Retrieve the search term from the URL query string. You can do this with any Codable object by calling req.query.decode(_:). If this fails, throw a 400 Bad Request error.”
        // “Query strings in URLs allow clients to pass information to the server that doesn’t fit sensibly in the path. For example, they are commonly used for defining the page number of a search result.”
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        // “Use filter(_:) to find all blogs whose `title` property matches the searchTerm. Because this uses key paths, the compiler can enforce type-safety on the properties and filter terms. This prevents run-time issues caused by specifying an invalid column name or invalid type to filter on.”
        //  return Blog.query(on: req).filter(\.title == searchTerm).all()
        
        
        //  “If you want to search multiple fields — for example both the title and content fields — you need to change your query. You can’t chain filter(_:) functions as that would only match blogs whose title and content properties were identical. Instead, you must use a filter group. Replace return Blog.query(on: req).filter(\.title == searchTerm).all() with the following:”
        // Create a filter group using th .or relation
        return Blog.query(on: req).group(.or) { or in
            //“Add a filter to the group to filter for blogs whose title property matches the search term.”
            or.filter(\.title == searchTerm)
            //“Add a filter to the group to filter for blogs whose content property matches the search term.”
            or.filter(\.content == searchTerm)
            // "Return all the results"
            }.all()
    }
    
    // MARK: QUERY FIRST GET http://localhost:8012/api/blogs/first
    // “Register a new HTTP GET route for /api/blogs/first that returns Future<Blogs>.”
    router.get("api", "blogs", "first") { req -> Future<Blog> in
        //“Perform a query to get the first Blog. Use the map(to:) function to unwrap the result of the query.”
        return Blog.query(on: req).first().map(to: Blog.self) { blog in
            // “Ensure an blog exists. first() returns an optional as there may be no blogs in the database. Throw a 404 Not Found error if no blog is returned.”
            guard let blog = blog else {
                throw Abort(.notFound)
            }
            // “Return the first blog.”
            return blog
        }
    }
    // MARK: QUERY Sorting GET “http://localhost:8012/api/blogs/sorted”
    // “Register a new HTTP GET route for /api/blogs/sorted that returns Future<[Blogs]>.”
    router.get("api", "blogs", "sorted") { req -> Future<[Blog]> in
        // “Create a query for Blog and use sort(_:_:) to perform the sort. This function takes the field to sort on and the direction to sort in. Finally use all() to return all the results of the query.”
        return Blog.query(on: req).sort(\.title, .ascending).all()
    }
    
}


struct InfoData: Content {
    let name: String
}

struct InfoResponse: Content {
    let request: InfoData
}
