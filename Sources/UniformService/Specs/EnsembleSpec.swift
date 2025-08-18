// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Ensemble
import struct DrumKit.Location
import struct DrumKitService.IdentifiedEnsemble
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol EnsembleSpec {
	associatedtype EnsembleCreation: Identifying<Ensemble.Identified>

	func createEnsemble(named name: String, basedInLocationWith locationID: Location.ID?) async -> EnsembleCreation
}
