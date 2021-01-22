import Fluent
import Vapor
import BogusApp_Common_Models

final class PlanEntity: Model, Content {
    static let schema = "plans"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "channelId")
    var channelId: ChannelEntity.IDValue

    @Field(key: "price")
    var price: Double
    
    @Field(key: "type")
    var type: PlanType
    
    @Parent(key: "channelId")
    var channel: ChannelEntity
    
    @Children(for: \.$plan)
    var benefits: [PlanBenefitEntity]
    
    @Field(key: "createdAt")
    var createdAt: Date
        
    var benefitIds: [UUID] { $benefits.wrappedValue.map { $0.benefitId } }

    init() { }
    
    init(_ plan: Plan, channelId: ChannelEntity.IDValue) {
        self.id = plan.id
        self.price = plan.price
        self.type = plan.type
        self.channelId = channelId
        self.createdAt = Date()
    }

    init(id: UUID, channelId: ChannelEntity.IDValue, price: Double, type: PlanType) {
        self.id = id
        self.price = price
        self.type = type
        self.channelId = channelId
        self.createdAt = Date()
    }
    
    func convert(linking benefits: [Benefit]) -> Plan {
        let benefits = benefits.orderedSet
        return .init(id: id ?? UUID(), price: price, benefits: benefits.filter { benefitIds.contains($0.id) }, type: type)
    }
}

extension Plan: Content { }
