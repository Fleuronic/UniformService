// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct Uniform.Event
import struct Catena.IDFields
import protocol Catena.Fields

public protocol EventFields: Fields where Model == Event.Identified {
	associatedtype EventLocationFields: LocationFields

	init?(
		id: Event.ID,
		date: Date,
		location: EventLocationFields,
		circuit: String,
		show: String
	)
}
