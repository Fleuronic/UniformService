// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Slot
import struct Diesel.Feature
import struct Diesel.Corps
import struct Diesel.Performance
import struct Diesel.Location
import struct Diesel.Placement
import struct Diesel.Division
import struct Schemata.Projection
import struct Foundation.TimeInterval
import enum Catenary.IDCodingKeys
import protocol DieselService.SlotFields
import protocol Identity.Identifiable

public struct SlotTimePlacementFields {
	public let id: Slot.ID
	public let time: TimeInterval?
	public let placementID: Placement.ID?
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

extension SlotTimePlacementFields: Decodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Model.CodingKeys.self)
		id = try container.decode(Slot.ID.self, forKey: .id)
		time = try container.decodeIfPresent(TimeInterval.self, forKey: .time)
		
		let performanceContainer = try? container.nestedContainer(keyedBy: Performance.CodingKeys.self, forKey: .performance)
		let placementContainer = try? performanceContainer?.nestedContainer(keyedBy: IDCodingKeys.self, forKey: .placement)
		placementID = try placementContainer?.decodeIfPresent(Placement.ID.self, forKey: .id)
	}
}

// MARK: -
private extension Performance {
	enum CodingKeys: String, CodingKey {
		case id
		case placement
	}
}
