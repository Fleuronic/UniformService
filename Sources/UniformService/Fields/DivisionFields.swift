// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Division
import struct DrumKitService.IdentifiedDivision
import struct Catena.IDFields
import protocol Catena.Fields

public protocol DivisionFields: Fields where Model == Division.Identified {
	associatedtype DivisionCircuitFields: CircuitFields

	var name: String { get }
	var circuit: DivisionCircuitFields { get }

	init(
		name: String,
		circuit: DivisionCircuitFields
	)
}
