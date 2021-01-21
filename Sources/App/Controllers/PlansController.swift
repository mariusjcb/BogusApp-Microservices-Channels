import Fluent
import Vapor
import BogusApp_Common_Models

struct ChannelsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let plans = routes.grouped("")
        plans.post(use: create)
        plans.get(":channelId", "plans", use: getPlans)
        plans.post(":channelId", "plans", use: insertPlan)
        plans.get(use: index)
    }
    
    // GET

    func index(req: Request) throws -> EventLoopFuture<[BogusApp_Common_Models.Channel]> {
        return try getChannels(req: req)
    }
    
    func getChannels(req: Request) throws -> EventLoopFuture<[BogusApp_Common_Models.Channel]> {
        let query = (try? req.query.get(at: "id")) ?? [UUID]()
        return ChannelEntity
            .query(on: req.db)
            .with(\.$plans, { $0.with(\.$benefits) }) // Link Eager loaders for associative models
            .all()
            .mapEachCompact { (query.isEmpty || query.contains($0.id!)) ? $0 : nil }
            .flatMapEach(on: req.eventLoop) { channel in
                return channel.plans
                    .map { BenefitsApi.fetchBenefitsByIds($0.benefitIds, client: req.client) } // Fetch benefits from microservice to replace benefitIds in db entry
                    .flatten(on: req.eventLoop)
                    .map { $0.reduce([], +) } // Reduce [[Benefit]] to [Benefit] for channel conversion
                    .map { channel.convert(linking: $0) }
            }
    }
    
    func getPlans(req: Request) throws -> EventLoopFuture<[Plan]> {
        let query = (try? req.query.get(at: "id")) ?? [UUID]()
        return PlanEntity
            .query(on: req.db)
            .with(\.$channel).with(\.$benefits) // Link Eager loaders for associative models
            .all()
            .mapEachCompact { (query.isEmpty || query.contains($0.id!)) ? $0 : nil }
            .sequencedFlatMapEachCompact { plan -> EventLoopFuture<Plan?> in
                BenefitsApi
                    .fetchBenefitsByIds(plan.benefitIds, client: req.client) // Fetch benefits to replace benefitIds from db entity
                    .map { Plan(id: plan.id!, price: plan.price, benefits: $0, type: plan.type) }
            }
    }
    
    // POST
    
    func create(req: Request) throws -> EventLoopFuture<BogusApp_Common_Models.Channel> {
        let channel = try req.content.decode(BogusApp_Common_Models.Channel.self)
        return insertChannel(channel, req: req)
    }
    
    func insertPlan(req: Request) throws -> EventLoopFuture<Plan> {
        let plan = try req.content.decode(Plan.self)
        guard let idStr = req.parameters.get("channelId"), let channelId = UUID.init(uuidString: idStr) else {
            throw Abort(.notFound)
        }
        return insertPlan(plan, channelId: channelId, req: req)
    }
    
    // Helpers
    // Todo: Move this code into some repository
    
    func insertChannel(_ channel: BogusApp_Common_Models.Channel, req: Request) -> EventLoopFuture<BogusApp_Common_Models.Channel> {
        ChannelEntity(channel).save(on: req.db)// Try to save channel
            .flatMapAlways { _ in
                ChannelEntity.query(on: req.db) // Fetch saved channel
                    .filter(.string("name"), .equal, channel.name)
                    .first()
            }.flatMap { channelEntity in
                channel.plans.map { plan in
                    self.insertPlan(plan, channelId: channelEntity!.id!, req: req) // Insert plans for channel in db
                }.flatten(on: req.eventLoop)
                .map { channelEntity!.convert(linking: $0.map { $0.benefits }.reduce([], +)) } // Return common Channel model
            }
    }
    
    func insertPlan(_ plan: Plan, channelId: UUID, req: Request) -> EventLoopFuture<Plan> {
        PlanEntity(plan, channelId: channelId).save(on: req.db) // Try to save plan
            .flatMapAlways { _ in
                PlanEntity.query(on: req.db) // Fetch saved plan from db
                    .filter(.string("price"), .equal, plan.price)
                    .filter(.string("channelId"), .equal, channelId)
                    .filter(.string("type"), .equal, plan.type)
                    .first()
            }.flatMap { planEntity in
                BenefitsApi
                    .createBenefits(plan.benefits, client: req.client) // Create benefits for plan
                    .flatMap { benefits in
                        benefits.map {
                            PlanBenefitEntity(planEntity!.id!, $0.id).save(on: req.db) // Save benefit-plan association in db
                        }.flatten(on: req.eventLoop)
                        .map { planEntity!.convert(linking: benefits) } // Return common Plan model
                    }
            }
    }
}
