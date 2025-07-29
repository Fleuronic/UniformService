// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct Uniform.Event
import struct Catena.IDFields
import protocol Catena.Fields

public protocol EventFields: Fields where Model == Event.Identified {
	init(
		id: Event.ID,
		date: Date,
		city: String,
		state: String,
		country: String,
		show: String,
		circuit: String
	)
}

// MARK: -
extension IDFields: EventFields where Model == Event.Identified {
	public init(
		id: Event.ID,
		date: Date,
		city: String,
		state: String,
		country: String,
		show: String,
		circuit: String
	) {
		self.init(id: id)
	}
}
