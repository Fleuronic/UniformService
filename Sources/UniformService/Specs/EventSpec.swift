// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventsResult

	func createEvents(for year: Int) async -> EventsResult
    func updateEvents(current: Bool) async -> EventsResult
}
