class V01::Entities::Zoning < Grape::Entity
  expose(:id, documentation: { type: 'Integer' })
  expose(:name, documentation: { type: 'String' })
  expose(:zones, using: V01::Entities::Zone, documentation: { type: 'Json' })
end
