// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Slot
import struct Diesel.Feature
import struct Diesel.Corps
import struct Diesel.Performance
import struct Diesel.Location
import struct Diesel.Placement
import struct Diesel.Division
import struct Foundation.Date
import struct Catena.IDFields
import struct Schemata.Projection
import protocol DieselService.PerformanceFields

struct PerformancePlacementFields {
	let id: Performance.ID
	let placement: IDFields<Placement.Identified>?
}

// MARK: -
extension PerformancePlacementFields: PerformanceFields {
	// MARK: ModelProjection
	static let projection = Projection<Performance.Identified, Self>(
		Self.init,
		\.id,
		\.placement.id
	)
}

// MARK: -
private extension PerformancePlacementFields {
	init(
		id: Performance.ID,
		placementID: Placement.ID?
	) {
		self.id = id
		
		placement = placementID.map { .init(id: $0) }
	}
}
