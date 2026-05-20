// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Slot
import struct DrumKitService.IdentifiedSlot
import struct Catena.IDFields
import protocol Catena.Fields

public protocol SlotFields: Fields where Model == Slot.Identified {
	associatedtype SlotPlacementFields: PlacementFields

	var feature: String? { get }

	init(
		time: String,
		name: String,
		placement: SlotPlacementFields?,
		isPotentiallyEncore: Bool
	)
}
