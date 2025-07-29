// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Event
import protocol Catena.Scoped
import protocol Catena.Identifying
import protocol Catena.ResultProviding

public protocol EventSpec {
	associatedtype EventList: Scoped<EventListFields>

	associatedtype EventListFields: EventFields

	func listEvents() async -> EventList
}
