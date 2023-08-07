// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Feature
import struct Diesel.Corps
import struct Diesel.Location
import struct Schemata.Projection
import protocol DieselService.FeatureFields
import protocol Identity.Identifiable

public struct FeatureCalendarFields {
    public let id: Feature.ID
    public let name: String
    public let corps: CorpsNameFields?
}

// MARK: -
extension FeatureCalendarFields: FeatureFields {
    // MARK: ModelProjection
    public static let projection = Projection<Feature.Identified, Self>(
        Self.init,
        \.id,
        \.value.name,
        \.corps.id,
        \.corps.value.name
    )
}

// MARK: -
private extension FeatureCalendarFields {
	init(
		id: Feature.ID,
		name: String,
		corpsID: Corps.ID,
		corpsName: String
	) {
		self.id = id
		self.name = name

		corps = .init(
			id: corpsID,
			name: name
		)
	}
}
