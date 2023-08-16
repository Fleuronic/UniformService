// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Division

public protocol ShowSpec {
	associatedtype ShowResult

	func find(_ show: Show) async -> DivisionResult
}
