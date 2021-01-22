import Fluent
import Vapor
import BogusApp_Common_Models

final class PlanBenefitEntity: Model, Content {
    static let schema = "plan_benefit_assoc"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "planId")
    var planId: PlanEntity.IDValue

    @Field(key: "benefitId")
    var benefitId: UUID
    
    @Parent(key: "planId")
    var plan: PlanEntity
    
    @Field(key: "createdAt")
    var createdAt: Date
    
    init() { }
    
    init(_ planId: PlanEntity.IDValue, _ benefitId: UUID) {
        self.planId = planId
        self.benefitId = benefitId
        self.createdAt = Date()
    }
}
