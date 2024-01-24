// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Corps
import struct Diesel.Location
import struct DieselService.IdentifiedCorps
import struct DieselService.LocationBaseFields
import struct Schemata.Projection
import protocol DieselService.CorpsFields
import protocol Identity.Identifiable

public struct CorpsNameCityStateFields {
	public let id: Corps.ID
	public let name: String
	public let city: String
	public let state: String
}

// MARK: -
extension CorpsNameCityStateFields: CorpsFields {
	// MARK: ModelProjection
	public static let projection = Projection<Corps.Identified, Self>(
		Self.init,
		\.id,
		\.value.name,
		\.location.value.city,
		\.location.value.state
	)
}
