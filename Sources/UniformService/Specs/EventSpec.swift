// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct Uniform.Event
import struct DrumKit.Event
import struct DrumKit.Location
import struct DrumKit.Circuit
import struct DrumKit.Show
import struct DrumKit.Venue
import struct DrumKitService.IdentifiedEvent
import protocol Catena.Scoped
import protocol Catena.Identifying
import protocol Catena.ResultProviding

public protocol EventSpec {
	associatedtype EventList: Scoped<EventListFields>
	associatedtype EventCreation: Identifying<DrumKit.Event.Identified>

	associatedtype EventListFields: EventFields

	func listEvents(for year: Int, with corpsRecord: (String) async -> String) async -> EventList
	func createEvent(on date: Date, inLocationWith locationID: Location.ID, byCircuitWith circuitID: Circuit.ID?, forShowWith showID: Show.ID?, atVenueWith venueID: Venue.ID?) async -> EventCreation
}
