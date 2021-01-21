import Fluent
import BogusApp_Common_Models
import Vapor

struct CreatePlan: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("plans")
            .id()
            .field("channelId", .uuid, .required)
            .field("price", .double, .required)
            .field("type", .string, .required)
            .unique(on: "channelId", "price", "type")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("plans").delete()
    }
}
