// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Location
import struct Schemata.Projection
import protocol DieselService.LocationFields
import protocol Identity.Identifiable

public struct LocationCalendarFields {
	public let id: Location.ID
	public let city: String
	public let state: String
}

// MARK: -
extension LocationCalendarFields: LocationFields {
	// MARK: ModelProjection
	public static let projection = Projection<Location.Identified, Self>(
		Self.init,
		\.id,
		\.value.city,
		\.value.state
	)
}
