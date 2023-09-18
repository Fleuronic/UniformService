// Copyright © Fleuronic LLC. All rights reserved.

import EventKit

import protocol Caesura.HasuraAPI

extension Service: ScheduleSpec where
	API: HasuraAPI {
	public func createSchedule(for year: Int) async -> APIResult<[EventCalendarFields]> {
		await api.fetch(EventCalendarFields.self).asyncFlatMap { events in
			await createSchedule(for: events, from: year)
			return .success(events)
		}
	}
}

// MARK: -
private extension Service {
	func dates(for event: EventCalendarFields) -> (Date, Date) {
		let times = event.slots.compactMap(\.time)
		let startTime = times.count > 1 ? times.sorted()[1] : .sixPM
		let endTime = times.count > 2 ? times.max()! : .tenPM
		let startDate = Date(date: event.date, startTime: startTime)
		let endDate = startDate.addingTimeInterval(endTime - startTime)

		return (startDate, endDate)
	}

	func location(for venue: VenueCalendarFields) -> String {
		[
			venue.name,
			venue.host,
			venue.address.streetAddress,
			"\(venue.address.location.city), \(venue.address.location.state) \(venue.address.zipCode)"
		].compactMap { $0 }.joined(separator: "\n")
	}

	func notes(for event: EventCalendarFields, in timeZone: TimeZone) -> String {
		[
			resultNotes(for: event),
			scheduleNotes(for: event, in: timeZone)
		].compactMap{ $0 }.joined(separator: "\n")
	}

	func resultNotes(for event: EventCalendarFields) -> String? {
		let performances = event.slots.map(\.performance)
		let placements = event.slots.map(\.performance?.placement)
		let grouping = zip(placements, performances).compactMap { placements, performances ->
			(PlacementCalendarFields, PerformanceCalendarFields)? in
			guard let placements, let performances else { return nil }
			return (placements, performances)
		}

		guard !grouping.isEmpty else { return nil }

		let results = Dictionary(grouping: grouping, by: \.0.division.name).sorted { $0.key > $1.key }
		return "Results:\n" + results.map { divisionName, placements in
			let sortedPlacements = placements.sorted { $0.0.rank < $1.0.rank }
			let placementStrings = sortedPlacements.map { placement in
				let score = String(format: "%.3f", placement.0.score)
				return "\(placement.0.rank). \(placement.1.corps.name) (\(score))"
			}

			return ([divisionName] + placementStrings).joined(separator: "\n")
		}.joined(separator: "\n\n") + "\n"
	}

	func scheduleNotes(for event: EventCalendarFields, in timeZone: TimeZone) -> String {
		let timeSlots = event.slots
			.filter { $0.time != nil }
			.sorted { $0.time! < $1.time! }
		let tbdSlots = event.slots
			.filter { $0.time == nil && $0.performance?.corps != nil }
			.sorted { $0.performance!.corps.name < $1.performance!.corps.name }
		let slots = timeSlots + tbdSlots
		let timeFormatter = timeFormatter(timeZone: timeZone)

		return "Schedule:\n" + slots.map { slot in
			let corps = slot.performance?.corps
			let feature = slot.feature
			let timeString = slot.time.map {
				timeFormatter.string(from: .init(timeIntervalSinceReferenceDate: $0))
			} ?? "TBD"

			return corps.map {
				"\(timeString): \($0.name) (\($0.location.city), \($0.location.state))"
			} ?? feature.map {
				"\(timeString): \($0.name)" + (($0.corps?.name).map { " (\($0))" } ?? "")
			} ?? ""
		}.joined(separator: "\n")
	}

	func createSchedule(for events: [EventCalendarFields], from year: Int) async {
		guard #available(macOS 14.0, *) else { return }

		let store = EKEventStore()
		_ = try! await store.requestFullAccessToEvents()

		let calendar = store.calendars(for: .event).filter { $0.title == "Drum Corps" }.first!
		let events = events.filter { event in
			Calendar.current.component(.year, from: event.date) == year
		}

		removeExistingEvents(for: year, from: calendar, in: store)

		for event in events {
			guard let eventTimeZone = event.timeZone else { continue }

			let timeZone = timeZone(for: eventTimeZone)
			let notes = notes(for: event, in: timeZone)
			let (startDate, endDate) = dates(for: event)
			let calendarEvent = EKEvent(eventStore: store)

			calendarEvent.calendar = calendar
			calendarEvent.title = event.show!.name
			calendarEvent.location = location(for: event.venue)
			calendarEvent.notes = notes
			calendarEvent.startDate = startDate
			calendarEvent.endDate = endDate
			calendarEvent.timeZone = timeZone

			try! store.save(calendarEvent, span: .thisEvent)
		}
	}

	func removeExistingEvents(for year: Int, from calendar: EKCalendar, in store: EKEventStore) {
		store.events(
			matching: store.predicateForEvents(
				withStart: Calendar.current.date(from: .init(year: year))!,
				end: Calendar.current.date(from: .init(year: year + 1))!,
				calendars: [calendar]
			)
		).forEach { event in
			try! store.remove(event, span: .thisEvent)
		}
	}
}

// MARK: -
private extension TimeInterval {
	static let sixPM: Self = -31539600
	static let tenPM: Self = -31525200
}
