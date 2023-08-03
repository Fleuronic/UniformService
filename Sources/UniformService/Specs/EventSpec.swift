// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventListResult
	associatedtype ScheduleResult

	func createEvents(for year: Int) async -> EventListResult
    func updateEvents(current: Bool) async -> EventListResult
	func createSchedule(for year: Int) async -> ScheduleResult
}
