// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Venue
import struct Diesel.Address
import struct Diesel.Location
import struct DieselService.IdentifiedAddress
import struct DieselService.IdentifiedLocation

public protocol VenueSpec {
    associatedtype VenueResult

	func find(_ venue: Venue, at address: Address.Identified) async -> VenueResult
}
