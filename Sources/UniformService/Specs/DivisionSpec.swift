// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Division
import struct DrumKit.Circuit
import struct DrumKitService.IdentifiedDivision
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol DivisionSpec {
	associatedtype DivisionCreation: Identifying<Division.Identified>

	func createDivision(named name: String, inCircuitWith circuitID: Circuit.ID) async -> DivisionCreation
}
