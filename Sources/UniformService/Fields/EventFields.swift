// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct Uniform.Event
import struct Catena.IDFields
import protocol Catena.Fields

public protocol EventFields: Fields where Model == Event.Identified {
	associatedtype EventLocationFields: LocationFields
	associatedtype EventCircuitFields: CircuitFields
	associatedtype EventShowFields: ShowFields
	associatedtype EventVenueFields: VenueFields
	associatedtype EventSlotFields: SlotFields

	init?(
		id: Event.ID,
		date: Date,
		detailsURL: URL?,
		scoresURL: URL?,
		timeZone: String,
		location: EventLocationFields?,
		circuit: EventCircuitFields?,
		show: EventShowFields?,
		venue: EventVenueFields?,
		slots: [EventSlotFields]
	)
}
