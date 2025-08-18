// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Address
import struct DrumKit.Location
import struct DrumKit.ZIPCode
import struct DrumKitService.IdentifiedAddress
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol AddressSpec {
	associatedtype AddressCreation: Identifying<Address.Identified>

	func createAddress(at streetAddress: String, inLocationWith locationID: Location.ID, inZIPCodeWith zipCodeID: ZIPCode.ID) async -> AddressCreation
}
