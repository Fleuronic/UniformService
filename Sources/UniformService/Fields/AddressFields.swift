// Copyright © Fleuronic LLC. All rights reserved.

import Foundation
import struct DrumKit.Address
import struct DrumKitService.IdentifiedAddress
import protocol Catena.Fields

public protocol AddressFields: Fields where Model == Address.Identified {
	init(records: [String])
}
