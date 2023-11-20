// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Slot
import struct Diesel.Feature
import struct Diesel.Corps
import struct Diesel.Performance
import struct Diesel.Location
import struct Diesel.Placement
import struct Diesel.Division
import struct Catena.IDFields
import struct Schemata.Projection
import struct Foundation.TimeInterval
import enum Catenary.IDCodingKeys
import protocol DieselService.SlotFields
import protocol Identity.Identifiable

public struct SlotTimePlacementFields {
	public let id: Slot.ID
	public let time: TimeInterval?
	public let placement: IDFields<Placement.Identified>?
}

// MARK: -
extension SlotTimePlacementFields: SlotFields {
	// MARK: ModelProjection
	public static let projection = Projection<Slot.Identified, Self>(
		Self.init,
		\.id,
		\.value.time,
		\.performance.placement.id
	)
}

// MARK: -
private extension SlotTimePlacementFields {
	init(
		id: Slot.ID,
		time: TimeInterval?,
		placementID: Placement.ID?
	) {
		self.id = id
		self.time = time

		placement = placementID.map { .init(id: $0) }
	}
}
