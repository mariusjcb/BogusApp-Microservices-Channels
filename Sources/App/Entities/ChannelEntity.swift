import Fluent
import Vapor
import BogusApp_Common_Models

final class ChannelEntity: Model, Content {
    static let schema = "channels"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Children(for: \.$channel)
    var plans: [PlanEntity]
    
    init() { }
    
    init(_ channel: BogusApp_Common_Models.Channel) {
        self.id = channel.id
        self.name = channel.name
    }

    init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
    
    func convert(linking benefits: [Benefit]) -> BogusApp_Common_Models.Channel {
        let benefits = benefits.orderedSet
        return BogusApp_Common_Models.Channel(id: id ?? UUID(), name: name, plans: $plans.wrappedValue.map { $0.convert(linking: benefits) })
    }
}

extension BogusApp_Common_Models.Channel: Content { }
