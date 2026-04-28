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
	associatedtype PerformanceUpdate: Identifying<Performance.Identified>
	associatedtype PerformanceDeletion: Identifying<Performance.Identified>

	func createPerformance(byCorpsWith corpsID: Corps.ID?, ensembleWith ensembleID: Ensemble.ID?, toPlacementWith placementID: Placement.ID?) async -> PerformanceCreation
	func updatePerformance(with id: Performance.ID, toPlacementWith placementID: Placement.ID) async -> PerformanceUpdate
	func deletePerformances(with ids: [Performance.ID]) async -> PerformanceDeletion
}
