// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Feature
import struct Diesel.Corps
import struct DieselService.IdentifiedCorps

public protocol FeatureSpec {
	associatedtype FeatureResult

	func find(_ feature: Feature, by corps: Corps.Identified?) async -> FeatureResult
}
