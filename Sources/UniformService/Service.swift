// Copyright © Fleuronic LLC. All rights reserved.

import InitMacro
import PersistDB

import struct Diesel.Corps
import struct Diesel.Slot
import struct Diesel.Performance
import struct Diesel.Placement
import struct DieselService.IdentifiedCorps
import struct Foundation.TimeZone
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter
import protocol Catenary.API
import protocol Catenoid.Database
import protocol DieselService.EventFields

@Init public struct Service<API: Catenary.API, Database: Catenoid.Database> where Database.Store == Store<ReadWrite> {
	let api: API
	let database: Database
}

// MARK: -
public extension Service {
	typealias APIResult<Resource> = API.Result<Resource>
	typealias DatabaseResult<Resource> = Database.Result<Resource>
	
	typealias CorpsData = (
		corps: Corps.Identified, 
		corpsName: String
	)?
	
	typealias SlotPerformancePlacementData = (
		slot: Slot.Identified, 
		performance: Performance.Identified?, 
		placement: Placement.Identified?
	)
	
	typealias CorpsPerformancePlacementData = (
		corps: Corps.Identified?,
		performance: Performance.Identified?, 
		placement: Placement.Identified?
	)

	var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = .dateFormat
		return formatter
	}

	func timeFormatter(with timeZone: TimeZone) -> DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = .timeFormat
		formatter.timeZone = timeZone
		return formatter
	}

	func dateTimeFormatter(with timeZone: TimeZone) -> DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = "\(String.dateFormat) \(String.timeFormat)"
		formatter.timeZone = timeZone
		return formatter
	}

	func timestampFormatter(with timeZone: TimeZone) -> ISO8601DateFormatter {
		let formatter = ISO8601DateFormatter()
		formatter.timeZone = timeZone
		formatter.formatOptions = [
			.withInternetDateTime,
			.withDashSeparatorInDate,
			.withFullDate,
			.withFractionalSeconds
		]
		return formatter
	}

	func timeZone(for abbreviation: String) -> TimeZone {
		.init(abbreviation: abbreviation.replacingOccurrences(of: "T", with: "DT"))!
	}
}

private extension String {
	static let dateFormat = "YYYY-MM-dd"
	static let timeFormat = "h:mm a"
}
