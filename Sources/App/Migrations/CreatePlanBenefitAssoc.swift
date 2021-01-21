import Fluent
import BogusApp_Common_Models
import Vapor

struct CreatePlanBenefitAssoc: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("plan_benefit_assoc")
            .id()
            .field("planId", .uuid, .required)
            .field("benefitId", .uuid, .required)
            .unique(on: "planId", "benefitId")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("plans").delete()
    }
}
