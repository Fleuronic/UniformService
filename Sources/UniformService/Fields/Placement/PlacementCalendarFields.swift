// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Placement
import struct Diesel.Corps
import struct Diesel.Division
import struct Schemata.Projection
import protocol DieselService.PlacementFields
import protocol Identity.Identifiable

public struct PlacementCalendarFields {
	public let id: Placement.ID
	public let rank: Int
	public let score: Double
	public let division: DivisionCalendarFields
}

// MARK: -
extension PlacementCalendarFields: PlacementFields {
	// MARK: ModelProjection
	public static let projection = Projection<Placement.Identified, Self>(
		Self.init,
		\.id,
		\.value.rank,
		\.value.score,
		\.division.id,
		\.division.value.name
	)
}

// MARK: -
private extension PlacementCalendarFields {
	init(
		id: Placement.ID,
		rank: Int,
		score: Double,
		divisionID: Division.ID,
		divisionName: String
	) {
		self.id = id
		self.rank = rank
		self.score = score
		
		division = .init(
			id: divisionID,
			name: divisionName
		)
	}
}
