// Copyright © Fleuronic LLC. All rights reserved.

import struct Schemata.Projection
import struct Diesel.Corps
import struct Diesel.Location
import protocol DieselService.CorpsFields
import protocol Identity.Identifiable

public struct CorpsNameFields {
    public let id: Corps.ID
    public let name: String

	public init(
		id: Corps.ID,
		name: String
	) {
		self.id = id
		self.name = name
	} 
}

// MARK: -
extension CorpsNameFields: CorpsFields {
    // MARK: ModelProjection
    public static let projection = Projection<Corps.Identified, Self>(
        Self.init,
        \.id,
        \.value.name
    )
}
