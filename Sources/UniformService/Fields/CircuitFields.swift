// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Circuit
import struct DrumKitService.IdentifiedCircuit
import struct Catena.IDFields
import protocol Catena.Fields

public protocol CircuitFields: Fields where Model == Circuit.Identified {
	init?(name: String)
}
