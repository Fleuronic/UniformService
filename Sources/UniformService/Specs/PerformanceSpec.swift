// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Performance
import struct DrumKit.Corps
import struct DrumKit.Ensemble
import struct DrumKit.Placement
import struct DrumKitService.IdentifiedPerformance
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol PerformanceSpec {
	associatedtype PerformanceCreation: Identifying<Performance.Identified>

	func createPerformance(byCorpsWith corpsID: Corps.ID?, ensembleWith ensembleID: Ensemble.ID?, inPlacementWith placementID: Placement.ID?) async -> PerformanceCreation
}
