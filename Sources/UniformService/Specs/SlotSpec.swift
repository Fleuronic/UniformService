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
	associatedtype SlotUpdate: Identifying<Slot.Identified>
	associatedtype SlotDeletion: Identifying<Slot.Identified>

	func createSlots(with parameters: [Slot.CreationParameters], inEventWith eventID: Event.ID) async -> SlotCreation
	func updateSlot(with id: Slot.ID, to time: Time) async -> SlotUpdate
	func deleteSlots(with ids: [Slot.ID]) async -> SlotDeletion
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
