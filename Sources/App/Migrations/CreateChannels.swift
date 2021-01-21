import Fluent
import BogusApp_Common_Models

struct CreateChannels: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("channels")
            .id()
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("channels").delete()
    }
}
