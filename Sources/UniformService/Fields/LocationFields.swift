// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Location
import struct DrumKitService.IdentifiedLocation
import struct Catena.IDFields
import protocol Catena.Fields

public protocol LocationFields: Fields where Model == Location.Identified {
	init(name: String)
}
