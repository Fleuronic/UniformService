// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Placement
import struct DrumKit.Division
import struct DrumKitService.IdentifiedPlacement
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol PlacementSpec {
	associatedtype PlacementCreation: Identifying<Placement.Identified>

	func createPlacement(at rank: Int, with score: Double, inDivisionWith divisionID: Division.ID?) async -> PlacementCreation
}
