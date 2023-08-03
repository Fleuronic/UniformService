// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Division
import struct Schemata.Projection
import protocol DieselService.DivisionFields
import protocol Identity.Identifiable

public struct DivisionCalendarFields {
	public let id: Division.ID
	public let name: String
}

// MARK: -
extension DivisionCalendarFields: DivisionFields {
	// MARK: ModelProjection
	public static let projection = Projection<Division.Identified, Self>(
		Self.init,
		\.id,
		\.value.name
	)
}
