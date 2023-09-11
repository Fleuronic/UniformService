// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Show

public protocol ShowSpec {
	associatedtype ShowResult

	func find(_ show: Show) async -> ShowResult
}
