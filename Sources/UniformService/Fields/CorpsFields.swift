// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct Catena.IDFields
import protocol Catena.Fields

public protocol CorpsFields: Fields where Model == Corps.Identified {
	init(
		id: Corps.ID,
		value: Corps
	)
}

// MARK: -
extension IDFields: CorpsFields where Model == Corps.Identified {
	public init(
		id: Corps.ID,
		value: Corps
	) {
		self.init(id: id)
	}
}
