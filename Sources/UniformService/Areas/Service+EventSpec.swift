// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Event
import struct Diesel.Venue
import struct Diesel.Location
import struct Diesel.Address
import struct Diesel.Slot
import struct Diesel.Feature
import struct Diesel.Performance
import struct Diesel.Corps
import struct Diesel.Placement
import struct DieselService.IdentifiedEvent
import struct Uniform.Event
import struct Uniform.Placement
import struct Uniform.Schedule
import struct Foundation.URL
import struct Foundation.Date
import struct Foundation.TimeZone
import struct Foundation.Calendar
import class Foundation.DateFormatter
import class Foundation.JSONDecoder
import class Foundation.URLSession
import protocol Caesura.HasuraAPI

import EventKit

extension Service: EventSpec where
    Self: AddressSpec,
    Self: VenueSpec,
    Self: SlotSpec,
    API: HasuraAPI {
	public func createEvents(for year: Int) async -> APIResult<[Diesel.Event.ID]> {
		await events(for: year).asyncFlatMap { data in
			await updateEvents(current: false, data: data)
		}
	}

    public func updateEvents(current: Bool) async -> APIResult<[Diesel.Event.ID]> {
		await eventPlacements(current: current).asyncFlatMap { data in
			await updateEvents(current: current, data: data)
		}
    }

    public func createSchedule(for year: Int) async -> APIResult<[EventCalendarFields]> {
        await api.fetch(EventCalendarFields.self).asyncFlatMap { events in
            await createSchedule(for: events, from: year)
            return .success(events)
        }
    }
}

// MARK: -
private extension Service {
	typealias EventData = (Diesel.Event, Diesel.Venue, Address, Location, [Slot], [Feature?], [Corps?], [Location?])
	typealias EventPlacementData = [(Uniform.Event, [Uniform.Placement])]

    func dates(for event: EventCalendarFields) -> (Date, Date) {
        let times = event.slots.compactMap(\.time)
        let startTime = times.count > 1 ? times.sorted()[1] : -31539600
        let endTime = times.count > 2 ? times.max()! : -31525200
		let startDate = Date(date: event.date, startTime: startTime)
        let endDate = startDate.addingTimeInterval(endTime - startTime)

        return (startDate, endDate)
    }

    func timeZone(for abbreviation: String) -> TimeZone {
        .init(abbreviation: abbreviation.replacingOccurrences(of: "T", with: "DT"))!
    }

	func location(for event: EventCalendarFields) -> String {
		[
			event.venue.name,
			event.venue.address.streetAddress,
			"\(event.venue.address.location.city), \(event.venue.address.location.state) \(event.venue.address.zipCode)"
		].joined(separator: "\n")
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
                let score = String(format: "%.2f", placement.0.score)
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
            let timeString = slot.time.map {
                timeFormatter.string(from: .init(timeIntervalSinceReferenceDate: $0))
            } ?? "TBD"

            if let corps = slot.performance?.corps {
                return "\(timeString): \(corps.name) (\(corps.location.city), \(corps.location.state))"
            } else if let feature = slot.feature {
                return "\(timeString): \(feature.name)" + ((feature.corps?.name).map { " (\($0))" } ?? "")
            }
            return ""
        }.joined(separator: "\n")
    }

	func placements(for slug: String) async -> [Uniform.Placement] {
		var slug = slug
		if slug == "2023-drums-across-america-atlanta" {
			slug = "2023-drums-across-america"
		} else if slug == "2023-the-thunder-of-drums" {
			slug = "2023-the-kiwanis-thunder-of-drums"
		}
		
		let url = URL(string: "https://dci.org/scores/final-scores/\(slug)")!
		guard let (data, _) = try? await URLSession.shared.data(from: url) else { return [] }
		
		let string = String(decoding: data, as: UTF8.self)
		let placementString = string.firstMatch(of: try! Regex("current\":(\\[\\{\"categories.*?),\"listing")).flatMap {
			$0.output[1].substring
		}
		
		return placementString?.data(using: .utf8).flatMap { data in
			try! JSONDecoder().decode([Uniform.Placement].self, from: data)
		} ?? []
	}


	func eventData(events: [Uniform.Event]) -> [EventData] {
		events.map { event in
			let timeFormatter = timeFormatter(timeZone: timeZone(for: event.timeZone))
			return (
				.init(
					name: event.name,
					slug: event.slug,
					date: dateFormatter.date(from: event.startDate)!,
					timeZone: event.timeZone
				),
				.init(
					name: event.venues.name.replacingOccurrences(of: "\"", with: "")
				),
				.init(
					streetAddress: event.venueAddress,
					zipCode: event.venueZIP ?? "66061"
				),
				.init(
					city: event.venueCity,
					state: event.venueState
				),
				event.schedules?.map { slot in
					.init(time: slot.time.flatMap(timeFormatter.date)?.timeIntervalSinceReferenceDate)
				} ?? [],
				event.schedules?.map(\.feature) ?? [],
				event.schedules?.map(\.corps) ?? [],
				event.schedules?.map { schedule in
					schedule.displayCity.map { city in
						var components = city.components(separatedBy: ", ")
						if components.count == 1 {
							components.append("WI")
						}
						return .init(
							city: components[0],
							state: components[1]
						)
					}
				} ?? []
			)
		}
	}

    func removeExistingEvents(for year: Int, from calendar: EKCalendar, in store: EKEventStore) {
        let existingEvents = store.events(
            matching: store.predicateForEvents(
                withStart: Calendar.current.date(from: .init(year: year))!,
                end: Calendar.current.date(from: .init(year: year + 1))!,
                calendars: [calendar]
            )
        )
        for event in existingEvents {
            try! store.remove(event, span: .thisEvent)
        }
    }

    func createSchedule(for events: [EventCalendarFields], from year: Int) async {
        let store = EKEventStore()
        _ = try! await store.requestAccess(to: .event)

        let calendar = store.calendars(for: .event).filter { $0.title == "Drum Corps" }.first!
        removeExistingEvents(for: year, from: calendar, in: store)

        for event in events {
            let timeZone = timeZone(for: event.timeZone)
            let notes = notes(for: event, in: timeZone)
            let (startDate, endDate) = dates(for: event)
            let calendarEvent = EKEvent(eventStore: store)

            calendarEvent.calendar = calendar
            calendarEvent.title = event.name!
            calendarEvent.location = location(for: event)
            calendarEvent.notes = notes
            calendarEvent.startDate = startDate
            calendarEvent.endDate = endDate
            calendarEvent.timeZone = timeZone

            try! store.save(calendarEvent, span: .thisEvent)
        }
    }
}

// MARK: -
private extension Service where
    Self: AddressSpec,
    Self: VenueSpec,
    Self: SlotSpec,
	API: HasuraAPI {
	func events(for year: Int) async -> APIResult<EventPlacementData> {
		 await eventPlacements(
			 current: false,
			 slugs: slugs.filter { $0.contains("\(year)") }
		 )
	 }

	func eventPlacements(current: Bool, slugs: [String]? = nil) async -> APIResult<EventPlacementData> {
		let slugs = await slugs.map(APIResult.success).asyncMapNil {
			await api.fetch(EventSlugSlotsFields.self).map { events in
				events.filter { event in
					guard
						case let times = event.slots.compactMap(\.time).sorted(),
						times.count > 1 else { return !current }
					 
					let time = current ? times.last! : times[1]
					let date = Date(date: event.date, startTime: time)
					let needsPlacements = event.slots.compactMap(\.placementID).isEmpty
					return date > .init() && (current ? date.timeIntervalSinceNow < 60 * 60 && needsPlacements : true)
				}.compactMap(\.slug)
			}
		}

		return await slugs.asyncMap { slugs in
			await slugs.asyncCompactMap { slug in
				let url = URL(string: "https://dci.org/events/\(slug)")!
				guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }

				return await String(decoding: data, as: UTF8.self).firstMatch(
					 of: try! Regex("current\":(\\{\"id.*?),\"liveStreams")
				).flatMap(\.output[1].substring)?.data(using: .utf8).asyncMap { eventData in
					 (
						 try! JSONDecoder().decode(Event.self, from: eventData),
						 current ? await placements(for: slug) : []
					 )
				}
			}.compactMap { $0 }
		}
	}

    func eventResult(
        data: EventData,
		placements: [Uniform.Placement]
    ) async -> APIResult<(Diesel.Event.Identified, [Slot.Identified], [Performance.Identified], [Diesel.Placement.Identified])> {
        let (event, venue, address, location, slots, slotFeatures, slotCorps, slotLocations) = data
        return await find(location).asyncFlatMap { location in
            await find(address, in: location).asyncFlatMap { address in
                await find(venue, at: address).asyncFlatMap { venue in
                    let event = event.identified(
                        location: location,
                        venue: venue
                    )
                    
                    return await slotsResult(
                        event: event,
                        slots: slots,
                        slotFeatures: slotFeatures,
                        slotCorps: slotCorps,
                        slotLocations: slotLocations,
                        placements: placements
                    ).map { data in
                        (
                            event: event,
                            slots: data.map(\.0),
                            performances: data.compactMap(\.1),
                            placements: data.compactMap(\.2)
                        )
                    }
                }
            }
        }
    }

	func updateEvents(
		current: Bool,
		data: EventPlacementData
	) async -> APIResult<[Diesel.Event.ID]> {
		await zip(
			eventData(events: data.map(\.0)),
			data.map(\.1)
		).asyncFlatMap { eventData, placements in
			await eventResult(
				data: eventData,
				placements: placements
			)
		}.asyncFlatMap { data in
			let data = current ? (data.enumerated().filter {
				Set(data.enumerated().filter { !$0.1.3.isEmpty }.map(\.0)).contains($0.0)
			}).map(\.1) : data

			let events = data.map(\.0)
			let slots = data.flatMap(\.1)
			let performances = data.flatMap(\.2)
			let placements = data.flatMap(\.3)

			guard !events.isEmpty, !(current && placements.isEmpty) else { return .success([]) }

			return await api.fetch(SlotTimePerformancePlacementFields.self, where: Slot.isPartOfEvent(from: events)).asyncFlatMap { fields in
				let slotIDs = fields.map(\.id)
				let performanceIDs = fields.compactMap(\.performanceID)

				return await api.delete(Slot.Identified.self, with: slotIDs).asyncMap { _ in
					await api.delete(Performance.Identified.self, with: performanceIDs)
				}.asyncMap { _ in
					await api.delete(Diesel.Event.Identified.self, where: Diesel.Event.hasName(fromNamesOf: events))
				}.asyncMap { _ in
					await api.insert(placements)
				}.asyncFlatMap { _ in
					await api.insert(events)
				}.asyncFlatMap { eventIDs in
					await api.insert(performances).asyncMap { _ in
						await api.insert(slots)
					}.map { _ in eventIDs }
				}
			}
		}
	}
}

// MARK: -
private extension Schedule {
    var feature: Feature? {
        if unitName.contains("Encore") {
            return .init(name: "Encore")
        } else if displayCity == nil {
            return .init(name: unitName)
        }
        return nil
    }

    var corps: Corps? {
        if feature == nil {
            return .init(name: unitName.replacingOccurrences(of: "\"", with: ""))
        }

        if unitName.contains("Encore") {
            var components = unitName.components(separatedBy: " - ")
            if components.count < 2 {
                components = unitName.components(separatedBy: "- ")
            }

            return components.count == 2 ? .init(name: components[1]) : nil
        }

        return nil
    }
}

// MARK: -
private extension Date {
	init(
		date: Date,
		startTime: TimeInterval
	) {
		self = Calendar.current.date(
			byAdding: .hour,
			value: 19,
			to: Calendar.current.date(
				byAdding: .year,
				value: 1,
				to: date.addingTimeInterval(startTime)
			)!
		)!
	}
}

private let dateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY-MM-dd"
    return formatter
}()

private func timeFormatter(timeZone: TimeZone) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.timeZone = timeZone
    return formatter
}

private let slugs = [
    "2023-dci-little-rock",
    "2023-drums-along-the-rockies",
    "2023-show-of-shows",
    "2023-dci-world-championship-finals",
    "2023-dci-open-class-world-championship-prelims",
    "2023-dci-open-class-world-championship-finals",
    "2023-whitewater-classic",
    "2023-gold-showcase",
    "2023-brass-impact",
    "2023-music-on-the-march",
    "2023-shoremen-brass-classic",
    "2023-drums-across-the-smokies",
    "2023-drums-across-the-river-region",
    "2023-dci-birmingham",
    "2023-dci-huntington",
    "2023-dci-glassboro",
    "2023-midwest-classic",
    "2023-celebration-in-brass",
    "2023-so-cal-classic",
    "2023-lake-erie-fanfare",
    "2023-summer-music-games-in-cincinnati",
    "2023-nightbeat",
    "2023-summer-music-games-of-southwest-virginia",
    "2023-dci-broken-arrow",
    "2023-soaring-sounds",
    "2023-the-beanpot",
    "2023-western-corps-connection",
    "2023-march-on",
    "2023-corps-at-the-crest-san-diego",
    "2023-midcal-champions-showcase",
    "2023-dci-capital-classic",
    "2023-drums-on-parade",
    "2023-dci-west",
    "2023-cavalcade-of-brass",
    "2023-the-thunder-of-drums",
    "2023-corps-encore",
    "2023-the-masters-of-the-summer-music-games",
    "2023-dci-monroe",
    "2023-dci-eastern-illinois",
    "2023-dci-austin",
    "2023-music-on-the-mountain",
    "2023-drum-corps-at-the-rose-bowl",
    "2023-rotary-music-festival",
    "2023-tournament-of-drums",
    "2023-resound",
    "2023-riverside-open",
    "2023-west-texas-drums",
    "2023-drums-across-the-desert",
    "2023-river-city-rhapsody-la-crosse",
    "2023-drums-across-america-atlanta",
    "2023-drums-on-the-chippewa",
    "2023-dci-central-indiana",
    "2023-dci-world-championship-prelims",
    "2023-drums-along-the-rockies-cheyenne-edition",
    "2023-summer-thunder",
    "2023-dci-new-hampshire",
    "2023-dci-world-championship-semifinals",
    "2023-dci-eastern-classic",
    "2023-drum-corps-an-american-tradition",
    "2023-dci-mckinney",
    "2023-dci-southeastern-championship",
    "2023-dci-tupelo",
    "2023-dci-eastern-classic-2",
    "2023-dci-pittsburgh",
    "2023-dci-cincinnati",
    "2023-dci-denton",
    "2023-dci-houston",
    "2023-dci-southwestern-championship",
    "2023-crownbeat",
    "2023-dci-mesquite",
    "2023-dci-southern-mississippi",
    "2023-midwest-premiere",
    "2023-dci-east-coast-showcase-quincy",
    "2023-dci-east-coast-showcase-lawrence",
    "2023-innovations-in-brass",
    "2023-white-rose-classic",
    "2023-drums-in-the-heartland",
    "2023-dci-connecticut",
    "2023-brigadiers-pageant-of-drums",
    "2023-dci-macon",
    "2023-dci-abilene",
    "2023-beats-in-the-brook"
]
