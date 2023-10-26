// Copyright © Fleuronic LLC. All rights reserved.

import PersistDB

import struct Diesel.Corps
import struct Diesel.Slot
import struct Diesel.Performance
import struct Diesel.Placement
import struct DieselService.IdentifiedCorps
import struct Foundation.TimeZone
import class Foundation.DateFormatter
import protocol Catenary.API
import protocol Catenoid.Database

public struct Service<API: Catenary.API, Database: Catenoid.Database> where Database.Store == Store<ReadWrite> {
	let api: API
	let database: Database
	let dateFormatter: DateFormatter

	public init(
		api: API,
		database: Database
	) {
		self.api = api
		self.database = database
		
		dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY-MM-dd"
	}
}

// MARK: -
public extension Service {
	typealias APIResult<Resource> = API.Result<Resource>
	typealias DatabaseResult<Resource> = Database.Result<Resource>
	typealias CorpsData = (Corps.Identified, String)?
	typealias SlotPerformancePlacementData = (Slot.Identified, Performance.Identified?, Placement.Identified?)
	typealias CorpsPerformancePlacementData = (Corps.Identified?, Performance.Identified?, Placement.Identified?)

	func timeZone(for abbreviation: String) -> TimeZone {
		.init(abbreviation: abbreviation.replacingOccurrences(of: "T", with: "DT"))!
	}

	func timeFormatter(timeZone: TimeZone) -> DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = "h:mm a"
		formatter.timeZone = timeZone
		return formatter
	}
}
