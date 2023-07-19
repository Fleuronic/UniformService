// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Address
import struct Diesel.Location
import struct DieselService.IdentifiedLocation

public protocol AddressSpec {
	associatedtype AddressResult

	func find(_ address: Address, in location: Location.Identified) async -> AddressResult
}
