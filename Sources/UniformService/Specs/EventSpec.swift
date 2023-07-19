// Copyright © Fleuronic LLC. All rights reserved.

public protocol EventSpec {
	associatedtype EventUpdateResult
	associatedtype ScheduleResult

	func updateCurrentEvent() async -> EventUpdateResult
	func updateFutureEvents(for year: Int) async -> EventUpdateResult
	func createSchedule(for year: Int) async -> ScheduleResult
}
