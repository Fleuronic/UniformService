// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Slot
import struct Diesel.Performance
import struct Diesel.Location
import struct Diesel.Placement
import struct Diesel.Division
import struct Catena.IDFields
import struct Schemata.Projection
import struct Foundation.Date
import protocol DieselService.SlotFields

struct SlotTimePerformancePlacementFields {
	let id: Slot.ID
	let time: Date?
	let performance: PerformancePlacementFields?
}

// MARK: -
extension SlotTimePerformancePlacementFields: SlotFields {
	// MARK: ModelProjection
	static let projection = Projection<Slot.Identified, Self>(
		Self.init,
		\.id,
		\.value.time,
		\.performance.id,
		\.performance.placement.id
	)
}

// MARK: -
private extension SlotTimePerformancePlacementFields {
	init(
		id: Slot.ID,
		time: Date?,
		performanceID: Performance.ID?,
		placementID: Placement.ID?
	) {
		self.id = id
		self.time = time
		
		performance = performanceID.map {
			.init(
				id: $0,
				placement: placementID.map { .init(id: $0) }
			)
		}
	}
}
