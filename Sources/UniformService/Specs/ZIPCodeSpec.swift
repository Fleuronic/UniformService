// Copyright © Fleuronic LLC. All rights reserved.

import struct DrumKit.ZIPCode
import struct DrumKitService.IdentifiedZIPCode
import protocol Catena.Scoped
import protocol Catena.Identifying

private import MemberwiseInit

public protocol ZIPCodeSpec {
	associatedtype ZIPCodeCreation: Identifying<ZIPCode.Identified>

	func createZIPCode(with code: String) async -> ZIPCodeCreation
}
