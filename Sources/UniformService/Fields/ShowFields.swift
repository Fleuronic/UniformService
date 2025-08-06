// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Show
import struct DrumKitService.IdentifiedShow
import struct Catena.IDFields
import protocol Catena.Fields

public protocol ShowFields: Fields where Model == Show.Identified {
	init?(name: String)
}
