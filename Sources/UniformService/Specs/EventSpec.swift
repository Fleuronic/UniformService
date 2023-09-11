// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventsResult

	func createEvents(for year: Int) async -> EventsResult
	func updateEvents(for year: Int, current: Bool) async -> EventsResult
}
