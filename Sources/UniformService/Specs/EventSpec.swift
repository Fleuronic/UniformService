// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventUpdateResult
	associatedtype ScheduleResult

    func updateEvents(current: Bool, for year: Int) async -> EventUpdateResult
	func createSchedule(for year: Int) async -> ScheduleResult
}
