
// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.Show
import struct DrumKitService.IdentifiedShow
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol ShowSpec {
	associatedtype ShowCreation: Identifying<Show.Identified>

	func createShow(named name: String) async -> ShowCreation
}
