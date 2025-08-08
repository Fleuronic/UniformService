// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Venue
import struct DrumKitService.IdentifiedVenue
import struct Catena.IDFields
import protocol Catena.Fields

public protocol VenueFields: Fields where Model == Venue.Identified {
	init(name: String)
}
