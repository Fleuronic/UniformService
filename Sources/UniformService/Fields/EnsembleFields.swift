// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Ensemble
import struct DrumKitService.IdentifiedEnsemble
import struct Catena.IDFields
import protocol Catena.Fields

public protocol EnsembleFields: Fields where Model == Ensemble.Identified {
	var name: String { get }

	init?(name: String)
}
