// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Slot
import struct DrumKit.Event
import struct DrumKit.Time
import struct DrumKit.Performance
import struct DrumKit.Feature
import struct DrumKitService.IdentifiedSlot
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol SlotSpec {
	associatedtype SlotCreation: Identifying<Slot.Identified>

	func createSlots(with parameters: [Slot.CreationParameters], inEventWith eventID: Event.ID) async -> SlotCreation
}

// MARK: -
public extension Slot {
	@MemberwiseInit(.public)
	struct CreationParameters {
		public let time: Time?
		public let performanceID: Performance.ID?
		public let featureID: Feature.ID?
	}
}
