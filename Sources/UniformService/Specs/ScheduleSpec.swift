// Copyright © Fleuronic LLC. All rights reserved.

public protocol ScheduleSpec {
	associatedtype ScheduleResult

	func createSchedule(for year: Int) async -> ScheduleResult
}
