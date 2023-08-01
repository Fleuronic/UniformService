// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventUpdateResult
	associatedtype ScheduleResult

	func createEvents(for year: Int) async -> EventUpdateResult
    func updateEvents(current: Bool) async -> EventUpdateResult
	func createSchedule(for year: Int) async -> ScheduleResult
}
