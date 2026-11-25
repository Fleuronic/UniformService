// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Location
import struct DrumKit.State
import struct DrumKit.Country
import struct DrumKitService.IdentifiedLocation
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol LocationSpec {
	associatedtype LocationCreation: Identifying<Location.Identified>

	func createLocation(in city: String?, inStateWith stateID: State.ID?, inCountryWith countryID: Country.ID) async -> LocationCreation
}
