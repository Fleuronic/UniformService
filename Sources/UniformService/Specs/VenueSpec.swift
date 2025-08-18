// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Venue
import struct DrumKit.Address
import struct DrumKitService.IdentifiedVenue
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol VenueSpec {
	associatedtype VenueCreation: Identifying<Venue.Identified>

	func createVenue(named name: String, hostedBy host: String?, atAddressWith addressID: Address.ID) async -> VenueCreation
}
