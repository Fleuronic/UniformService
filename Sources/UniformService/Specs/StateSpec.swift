// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.State
import struct DrumKit.Country
import struct DrumKitService.IdentifiedState
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol StateSpec {
	associatedtype StateCreation: Identifying<State.Identified>

	func createState(abbreviatedAs abbreviation: String, inCountryWith countryID: Country.ID) async -> StateCreation
}
