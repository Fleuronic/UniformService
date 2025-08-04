// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Country
import struct DrumKitService.IdentifiedCountry
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol CountrySpec {
	associatedtype CountryCreation: Identifying<Country.Identified>

	func createCountry(named name: String) async -> CountryCreation
}
