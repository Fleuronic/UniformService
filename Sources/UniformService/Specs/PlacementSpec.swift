// Copyright © Fleuronic LLC. All rights reserved.

import enum Uniform.Span
import struct Uniform.Placement
import struct Foundation.Data

public protocol PlacementSpec {
	associatedtype SlugsResult
	associatedtype EventPlacementDataResult
	
	func placements(
		slug: String,
		year: Int,
		data: Data?
	) async -> [Placement]
	
	func eventPlacementData(
		year: Int,
		eventData: Data,
		slugsResult: SlugsResult
	) async -> EventPlacementDataResult

	func eventPlacementData(
		year: Int,
		span: Span,
		slugsResult: SlugsResult
	) async -> EventPlacementDataResult
}
