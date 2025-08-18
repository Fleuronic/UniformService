
// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Feature
import struct DrumKitService.IdentifiedFeature
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol FeatureSpec {
	associatedtype FeatureCreation: Identifying<Feature.Identified>

	func createFeature(named name: String) async -> FeatureCreation
}
