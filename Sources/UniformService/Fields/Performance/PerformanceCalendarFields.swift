// Copyright © Fleuronic LLC. All rights reserved.

import struct Schemata.Projection
import struct Diesel.Performance
import struct Diesel.Corps
import struct Diesel.Placement
import struct Diesel.Location
import struct Diesel.Division
import struct DieselService.CorpsNameLocationFields
import protocol DieselService.PerformanceFields
import protocol Identity.Identifiable

public struct PerformanceCalendarFields {
	public let id: Performance.ID
	public let corps: CorpsNameLocationFields
	public let placement: PlacementCalendarFields?
}

// MARK: -
extension PerformanceCalendarFields: PerformanceFields {
	// MARK: ModelProjection
	public static let projection = Projection<Performance.Identified, Self>(
		Self.init,
		\.id,
		\.corps.id,
		\.corps.value.name,
		\.corps.location.id,
		\.corps.location.value.city,
		\.corps.location.value.state,
		\.placement.id,
		\.placement.value.rank,
		\.placement.value.score,
		\.placement.division.id,
		\.placement.division.value.name
	)
}

// MARK: -
private extension PerformanceCalendarFields {
	init(
		id: Performance.ID,
		corpsID: Corps.ID,
		name: String,
		locationID: Location.ID,
		city: String,
		state: String,
		placementID: Placement.ID,
		rank: Int,
		score: Double,
		divisionID: Division.ID,
		divisionName: String
	) {
		self.id = id
		
		corps = .init(
			id: corpsID,
			name: name,
			location: .init(
				id: locationID,
				city: city,
				state: state
			)
		)
		
		placement = .init(
			id: placementID,
			rank: rank,
			score: score,
			division: .init(
				id: divisionID,
				name: divisionName
			)
		)
	}
}
