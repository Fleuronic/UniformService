
// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Circuit
import struct DrumKitService.IdentifiedCircuit
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol CircuitSpec {
	associatedtype CircuitCreation: Identifying<Circuit.Identified>

	func createCircuit(abbreviatedAs abbreviation: String) async -> CircuitCreation
}
