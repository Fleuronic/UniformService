// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Corps
import struct Diesel.Location
import struct DieselService.IdentifiedLocation

public protocol CorpsSpec {
	associatedtype CorpsResult

	func find(_ corps: Corps, from location: Location.Identified?) async -> CorpsResult
}
