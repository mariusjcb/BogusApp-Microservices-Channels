import Foundation
import Fluent
import BogusApp_Common_Models
import BogusApp_Common_MockDataProvider
import Vapor

struct InsertDemoPlans: Migration {
    private weak var app: Application!
    
    init(app: Application) {
        self.app = app
    }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return MockData.fetch()!
            .convertAllChannelsOnly()
            .compactMap { channel -> EventLoopFuture<Void> in
                ChannelEntity(id: channel.id, name: channel.name)
                    .save(on: database)
                    .flatMapAlways { _ in
                        ChannelEntity
                            .query(on: database)
                            .filter(.string("name"), .equal, channel.name)
                            .first()
                            .flatMap { channelEntity in
                                channel.plans.map { plan in
                                    PlanEntity(id: plan.id, channelId: channelEntity!.id!, price: plan.price, type: plan.type)
                                        .save(on: database)
                                        .flatMapAlways { _ in PlanEntity.query(on: database)
                                            .filter(.string("price"), .equal, plan.price)
                                            .filter(.string("channelId"), .equal, channelEntity!.id)
                                            .filter(.string("type"), .equal, plan.type)
                                            .first()
                                        } .flatMap { planEntity in
                                            BenefitsApi
                                                .createBenefits(plan.benefits, client: app.client)
                                                .flatMap { benefits in
                                                    benefits.map {
                                                        PlanBenefitEntity(planEntity!.id!, $0.id).save(on: database)
                                                    }.flatten(on: database.eventLoop)
                                                }
                                        }
                                }.flatten(on: database.eventLoop)
                            }
                    }
            }.flatten(on: database.eventLoop)
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return PlanEntity.query(on: database).delete()
    }
}
