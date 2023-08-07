// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Event
import struct Diesel.Slot
import struct Diesel.Performance
import struct Diesel.Placement
import struct Schemata.Projection
import struct Foundation.Date
import struct Foundation.TimeInterval
import protocol DieselService.EventFields
import protocol Identity.Identifiable

public struct EventDateSlugSlotsFields {
	public let id: Event.ID
	public let date: Date
	public let slug: String?
	public let slots: [SlotTimePlacementFields]
}

extension EventDateSlugSlotsFields: EventFields {
	// MARK: ModelProjection
	public static let projection = Projection<Event.Identified, Self>(
		Self.init,
		\.id,
		\.value.date,
		\.value.slug,
		\.slots.id,
		\.slots.value.time,
		\.slots.performance.placement.id
	)

	// MARK: Fields
	public static var toManyKeys: [PartialKeyPath<Event.Identified>: [String]] {
		let keys: [PartialKeyPath<Event.Identified>: [ToManyKeys]] = [
			\.slots.id: [.id],
			\.slots.value.time: [.time],
			\.slots.performance.placement.id: [.performance, .placement, .id]
		]

		return keys.mapValues {
			([.slots] + $0).map(\.rawValue)
		}
	}
}

// MARK: -
private extension EventDateSlugSlotsFields {
	enum ToManyKeys: String {
		case slots
		case id
		case time
		case performance
		case placement
	}

	init(
		id: Event.ID,
		date: Date,
		slug: String?,
		slotIDs: [Slot.ID],
		slotTimes: [TimeInterval?],
		placementIDs: [Placement.ID?]
	) {
		self.id = id
		self.date = date
		self.slug = slug

		slots = slotIDs.enumerated().map { index, id in
			.init(
				id: id,
				time: slotTimes[index],
				placementID: placementIDs[index]
			)
		}
	}
}
