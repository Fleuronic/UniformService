// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Location

public protocol LocationSpec {
	associatedtype LocationResult

	func find(_ location: Location) async -> LocationResult
}
