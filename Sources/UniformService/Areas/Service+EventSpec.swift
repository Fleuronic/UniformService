// Copyright © Fleuronic LLC. All rights reserved.

import enum Uniform.Span
import struct Diesel.Event
import struct Diesel.Show
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
import struct Uniform.Site
import struct Foundation.URL
import struct Foundation.Date
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.Data
import class Foundation.JSONDecoder
import class Foundation.URLSession
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter
import class Foundation.Bundle
import protocol Caesura.HasuraAPI

extension Service: EventSpec where Self: ShowSpec & AddressSpec & VenueSpec & SlotSpec, API: HasuraAPI {
	public func createEvents(for year: Int) async -> APIResult<[Diesel.Event.ID]> {
		await events(for: year).asyncFlatMap { data in
			await updateEvents(current: false, data: data)
		}
	}

	public func updateEvents(for year: Int, current: Bool) async -> APIResult<[Diesel.Event.ID]> {
		await eventPlacements(
			year: year,
			span: current ? .current : .upcoming
		).asyncFlatMap { data in
			await updateEvents(current: current, data: data)
		}
	}
}

// MARK: -
private extension Service {
	typealias EventData = (
		event: Diesel.Event,
		show: Diesel.Show?,
		venue: Diesel.Venue?,
		address: Address?,
		location: Location, 
		slots: [Slot], 
		features: [Feature?],
		corps: [Corps?],
		locations: [Location?]
	)

	typealias EventResult = (
		event: Diesel.Event.Identified, 
		slots: [Slot.Identified], 
		performances: [Performance.Identified], 
		placements: [Diesel.Placement.Identified]
	)

	typealias EventPlacementData = [
		(
			event: Uniform.Event,
			placements: [Uniform.Placement]
		)
	]

	func placements(
		slug: String,
		year: Int,
		data: Data? = nil
	) async -> [Uniform.Placement] {
		if let data {
			try! api.decoder.decode([Uniform.Placement].self, from: data)
		} else {
			await Site(
				domain: .dci,
				path: .scores,
				slug: slug.normalized(from: .events),
				year: year
			)?.data.flatMap { data in
				try! api.decoder.decode([Uniform.Placement].self, from: data)
			} ?? []
		}
	}
	
	func eventData(for events: [Uniform.Event]) async -> [EventData] {
		await events.asyncMap { event in
			let timeZone = await timeZone(for: event)
			return event.data(
				timeZone: timeZone,
				interval: .init(self.timeZone(for: "ET").secondsFromGMT() - timeZone.secondsFromGMT()),
				dateFormatter: dateFormatter,
				dateTimeFormatter: dateTimeFormatter(with: timeZone),
				timestampFormatter: timestampFormatter(with: timeZone)
			)
		}
	}
	
	func timeZone(for event: Uniform.Event) async -> TimeZone {
		await event.timeZone.map(self.timeZone).asyncMapNil {
			let address = "\(event.venueCity), \(event.venueState)"
			let timestamp = Date().timeIntervalSince1970
			
			return try! await geodeAPI.listGeocodes(for: address).asyncFlatMap { geocodes in
				let location = geocodes.first!.geometry.location
				return await geodeAPI.fetchTimeZone(in: location, at: timestamp).asyncMap { timeZone in
					TimeZone(identifier: timeZone.timeZoneID)!
				}
			}.get()
		}
	}

	func eventPlacementData(
		year: Int,
		eventData: Data,
		slugsResult: APIResult<[String]>
	) async -> APIResult<EventPlacementData> {
		await slugsResult.asyncMap { slugs in
			let events = try! api.decoder.decode([Uniform.Event].self, from: eventData)
			return await zip(
				events.sorted { $0.slug < $1.slug },
				slugs.asyncMap { slug in
					await placements(
						slug: slug,
						year: year
					)
				}
			).map { (event: $0.0, placements: $0.1) }
		}.map(Array.init)
	}
	
	func eventPlacementData(
		year: Int,
		span: Span,
		slugsResult: APIResult<[String]>
	) async -> APIResult<EventPlacementData> {
		await slugsResult.asyncMap { slugs in
			await slugs.asyncCompactMap { slug in
				let site = await Site(
					domain: .dci,
					path: .events,
					slug: slug,
					year: year
				)
				
				return await site?.data.asyncMap { eventData in
					let event = try? api.decoder.decode(Event.self, from: eventData)
					let placements = (span == .upcoming || year == 2021) ? [] : await placements(
						slug: slug,
						year: year,
						data: year <= 2017 ? site?.data(at: .scores) : nil
					)
					
					return await event.asyncMap { ($0, placements) }
				}
			}.compactMap { $0 }
		}
	}
}

// MARK: -
private extension Service where Self: ShowSpec & AddressSpec & VenueSpec & SlotSpec, API: HasuraAPI {
	func events(for year: Int) async -> APIResult<EventPlacementData> {
		await eventPlacements(
			year: year,
			span: .season,
			slugs: Array(resource: .events).filter {
				$0.contains("\(year)")
			}
		)
	}

	func eventPlacements(
		year: Int,
		span: Span,
		slugs: [String]? = nil
	) async -> APIResult<EventPlacementData> {
		let url = Bundle.module.url(forResource: "\(year)", withExtension: "json")
		let slugsResult = await slugs.map(APIResult.success).asyncMapNil { await self.slugs(from: span) }
		
		return if let url {
			await eventPlacementData(
				year: year,
				eventData: try! Foundation.Data(contentsOf: url, options: []),
				slugsResult: slugsResult
			)
		} else {
			await eventPlacementData(
				year: year,
				span: span,
				slugsResult: slugsResult
			)
		}
	}
	
	func slugs(from span: Span) async -> APIResult<[String]> {
		await api.fetch(EventDateSlugSlotsFields.self).map { events in
			events.filter { event in
				let times = event.slots.compactMap(\.time).sorted()
				let needsPlacements = event.slots.compactMap(\.performance?.placement).isEmpty
				
				let date = if times.count < 2 {
					event.date
				} else if span == .current {
					times.last!
				} else {
					times[1]
				}
				
				return switch span {
				case .season: true
				case .current: date < .init() && -date.timeIntervalSinceNow < 60 * 60 && needsPlacements
				case .upcoming: date > .init()
				}
			}.compactMap(\.slug)
		}
	}

	func eventResult(
		data: EventData,
		placements: [Uniform.Placement]
	) async -> APIResult<EventResult> {
		let count = placements.count
		let hasSlots = !data.slots.isEmpty
		
		return await eventResult(for: data).asyncFlatMap { event in
			await slotsResult(
				event: event,
				slots: hasSlots ? data.slots : .init(repeating: .init(time: nil), count: count),
				slotFeatures: hasSlots ? data.features : .init(repeating: nil, count: count),
				slotCorps: hasSlots ? data.corps : placements.map(\.groupName).map(Corps.init),
				slotLocations: hasSlots ? data.locations : .init(repeating: nil, count: count),
				placements: placements
			).map { data in
				(
					event: event,
					slots: data.map(\.slot),
					performances: data.compactMap(\.performance),
					placements: data.compactMap(\.placement)
				)
			}
		}
	}
	
	func eventResult(for data: EventData) async -> APIResult<Diesel.Event.Identified> {
		let (event, show, venue, address, location, _, _, _, _) = data
		return if let address, let show, let venue {
			await eventResult(
				event: event,
				location: location,
				address: address,
				show: show,
				venue: venue
			)
		} else {
			await eventResult(
				event: event,
				location: location,
				show: show
			)
		}
	}
	
	func eventResult(
		event: Diesel.Event,
		location: Location,
		show: Show?
	) async -> APIResult<Diesel.Event.Identified> {
		await find(location).asyncFlatMap { location in
			await show.asyncMap { show in
				await find(show).asyncMap { show in
					event.identified(
						show: show,
						location: location,
						venue: nil
					)
				}
			} ?? .success(
				event.identified(
					show: nil,
					location: location,
					venue: nil
				)
			)
		}
	}
	
	func eventResult(
		event: Diesel.Event,
		location: Location,
		address: Address,
		show: Show,
		venue: Venue
	) async -> APIResult<Diesel.Event.Identified> {
		await find(location).asyncFlatMap { location in
			await find(address, in: location).asyncFlatMap { address in
				await find(show).asyncFlatMap { show in
					await find(venue, at: address).asyncMap { venue in
						event.identified(
							show: show,
							location: location,
							venue: venue
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
			eventData(for: data.map(\.0)),
			data.map(\.1)
		).asyncFlatMap { eventData, placements in
			await eventResult(
				data: eventData,
				placements: placements
			)
		}.asyncFlatMap { data in
			let data = current ? (data.enumerated().filter { index, _ in
				Set(
					data.enumerated().filter { _, result in
						!result.performances.isEmpty 
					}.map(\.offset)
				).contains(index)
			}).map(\.element) : data
			
			return await update(
				current: current,
				events: data.map(\.event),
				placements: data.flatMap(\.placements),
				performances: data.flatMap(\.performances),
				slots: data.flatMap(\.slots)
			)
		}
	}	
	
	func update(
		current: Bool,
		events: [Diesel.Event.Identified],
		placements: [Diesel.Placement.Identified],
		performances: [Performance.Identified],
		slots: [Slot.Identified]
	) async -> APIResult<[Diesel.Event.ID]> {
		guard !events.isEmpty, !(current && placements.isEmpty) else { return .success([]) }
		
		let relevant = Slot.isPartOfEvent(from: events)
		return await api.fetch(SlotTimePerformancePlacementFields.self, where: relevant).asyncFlatMap { fields in
			let slotIDs = fields.map(\.id)
			let performanceIDs = fields.compactMap(\.performance?.id)
			let placementIDs = fields.compactMap(\.performance?.placement?.id)
			
			return await api.delete(Slot.Identified.self, with: slotIDs).asyncMap { _ in
				await api.delete(Performance.Identified.self, with: performanceIDs)
			}.asyncMap { _ in
				await api.delete(Placement.Identified.self, with: placementIDs)
			}.asyncMap { _ in
				await api.delete(Diesel.Event.Identified.self, where: Diesel.Event.is(in: events))
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

// MARK: -
private extension Uniform.Event {
	func data(
		timeZone: TimeZone,
		interval: TimeInterval,
		dateFormatter: DateFormatter,
		dateTimeFormatter: DateFormatter,
		timestampFormatter: ISO8601DateFormatter
	) -> Service.EventData {
		(
			.init(
				slug: slug,
				date: dateFormatter.date(from: startDate)!,
				startTime: startTime.flatMap { startTime in
					let time = dateTimeFormatter.date(from: "\(startDate) \(startTime)")
					return time ?? timestampFormatter.date(from: startTime)?.addingTimeInterval(interval)
				},
				timeZone: timeZone.abbreviation()!.replacing("S", with: "")
			),
			.init(name: name),
			venueName.map { name in
				.init(
					name: name,
					host: venueHost
				)
			},
			venueAddress.map { streetAddress in
				.init(
					streetAddress: streetAddress,
					zipCode: .inserted(for: streetAddress, from: .addresses) ?? venueZIP!
				)
			},
			.init(
				city: venueCity,
				state: venueState
			),
			schedules?.compactMap { slot in
				let time = slot.time.map { "\(startDate) \($0)" }
				return .init(time: time.flatMap(dateTimeFormatter.date))
			} ?? [],
			schedules?.map(\.feature) ?? [],
			schedules?.map(\.corps) ?? [],
			schedules?.map { schedule in
				schedule.displayCity.map { city in
					var components = city.components(separatedBy: ", ")
					if components.count == 1 {
						components.append(.inserted(for: components[0], from: .locations)!)
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
