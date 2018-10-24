import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Blog API
    try router.register(collection: ApiBlogController())
}
