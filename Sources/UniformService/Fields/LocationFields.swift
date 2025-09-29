// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Location
import struct DrumKitService.IdentifiedLocation
import struct Catena.IDFields
import protocol Catena.Fields

public protocol LocationFields: Fields where Model == Location.Identified {
	var city: String { get }
	var state: String { get }
	var country: String { get }

	init?(name: String)
}
