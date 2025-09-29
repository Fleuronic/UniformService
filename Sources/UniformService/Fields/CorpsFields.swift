// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct Catena.IDFields
import protocol Catena.Fields

public protocol CorpsFields: Fields where Model == Corps.Identified {
	init(
		id: Corps.ID,
		name: String,
		city: String,
		state: String,
		country: String
	)
}

// MARK: -
extension IDFields: CorpsFields where Model == Corps.Identified {
	public init(
		id: Corps.ID,
		name: String,
		city: String,
		state: String,
		country: String
	) {
		self.init(id: id)
	}
}
