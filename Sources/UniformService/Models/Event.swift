// Copyright © Fleuronic LLC. All rights reserved.

import Identity
import Foundation
import struct Uniform.Event
import struct Catena.IDFields
import protocol Catena.Valued

public extension Event {
	typealias ID = Identified.ID
	typealias IDFields = Catena.IDFields<Identified>
	typealias Identified = IdentifiedEvent
}

// MARK: -
public struct IdentifiedEvent: Sendable {
	public let id: Event.ID
	public let value: Event
}

// MARK: -
public extension IdentifiedEvent {
	init(
		id: Event.ID, 
		showName: String
	) {
		self.id = id
		
		value = .init(showName: showName)
	}
}

// MARK: -
extension Event.Identified: Identifiable {
	// MARK: Identifiable
	public typealias RawIdentifier = Int
}

extension Event.Identified: Valued {
	// MARK: Valued
	public typealias Value = Event
}
