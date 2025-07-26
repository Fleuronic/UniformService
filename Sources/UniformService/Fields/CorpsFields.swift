// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct Catena.IDFields
import struct Catena.ImpossibleFields
import protocol Catena.Fields

public protocol CorpsFields: Fields where Model == Corps.Identified {
	init(
		id: Corps.ID,
		name: String
	)
}

// MARK: -
extension IDFields: CorpsFields where Model == Corps.Identified {
	public init(
		id: Corps.ID,
		name: String
	) {
		self.init(id: id)
	}
}

extension ImpossibleFields: CorpsFields where Model == Corps.Identified {}