// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Placement
import struct DrumKitService.IdentifiedPlacement
import struct Catena.IDFields
import protocol Catena.Fields

public protocol PlacementFields: Fields where Model == Placement.Identified {
	init(
		rank: Int,
		score: Double,
		divisionName: String,
		circuitAbbreviation: String
	)
}
