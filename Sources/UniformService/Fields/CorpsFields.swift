// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct Catena.IDFields
import protocol Catena.Fields

public protocol CorpsFields: Fields where Model == Corps.Identified {
	init(corps: Corps.Identified)
}

// MARK: -
extension IDFields: CorpsFields where Model == Corps.Identified {
	public init(corps: Corps.Identified) {
		self.init(id: corps.id)
	}
}
