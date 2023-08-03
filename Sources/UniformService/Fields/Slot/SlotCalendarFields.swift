// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Slot
import struct Diesel.Corps
import struct Diesel.Performance
import struct Diesel.Feature
import struct Diesel.Location
import struct Diesel.Placement
import struct Diesel.Division
import struct Schemata.Projection
import struct Foundation.TimeInterval
import protocol DieselService.SlotFields
import protocol Identity.Identifiable

public struct SlotCalendarFields {
    public let id: Slot.ID
    public let time: TimeInterval?
    public let performance: PerformanceCalendarFields?
    public let feature: FeatureCalendarFields?
}

// MARK: -
extension SlotCalendarFields: SlotFields {
    // MARK: ModelProjection
    public static let projection = Projection<Slot.Identified, Self>(
        Self.init,
        \.id,
        \.value.time,
        \.performance.id,
        \.performance.corps.id,
        \.performance.corps.value.name,
        \.performance.corps.location.id,
        \.performance.corps.location.value.city,
        \.performance.corps.location.value.state,
		\.performance.placement.id,
		\.performance.placement.value.rank,
		\.performance.placement.value.score,
		\.performance.placement.division.id,
		\.performance.placement.division.value.name,
        \.feature.id,
        \.feature.value.name,
        \.feature.corps.id,
        \.feature.corps.value.name
    )
}

// MARK: -
private extension SlotCalendarFields {
	init(
		id: Slot.ID,
		time: TimeInterval?,
		performanceID: Performance.ID,
		corpsID: Corps.ID,
		corpsName: String,
		locationID: Location.ID,
		city: String,
		state: String,
		placementID: Placement.ID,
		rank: Int,
		score: Double,
		divisionID: Division.ID,
		divisionName: String,
		featureID: Feature.ID,
		featureName: String,
		featuredCorpsID: Corps.ID,
		featuredCorpsName: String
	) {
		self.id = id
		self.time = time

		performance = .init(
			id: performanceID,
			corps: .init(
				id: corpsID,
				name: corpsName,
				location: .init(
					id: locationID,
					city: city,
					state: state
				)
			),
			placement: .init(
				id: placementID,
				rank: rank,
				score: score,
				division: .init(
					id: divisionID,
					name: divisionName
				)
			)
		)

		feature = .init(
			id: featureID,
			name: featureName,
			corps: .init(
				id: featuredCorpsID,
				name: featuredCorpsName
			)
		)
	}
}
