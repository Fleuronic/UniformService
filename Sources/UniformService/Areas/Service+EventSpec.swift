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
import struct CoreLocation.CLLocationDegrees
import class Foundation.JSONDecoder
import class Foundation.URLSession
import class Foundation.DateFormatter
import class Foundation.ISO8601DateFormatter
import class Foundation.Bundle
import class Foundation.JSONSerialization
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
		await data.map { data in
			try! api.decoder.decode([Uniform.Placement].self, from: data)
		}.asyncMapNil {
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

	func eventData(for events: [Uniform.Event]) async -> [EventData] {
		await events.asyncMap { event in
			let timeZone = await event.timeZone.map(self.timeZone).asyncMapNil {
				let address = "\(event.venueCity), \(event.venueState)"
				let apiKey = "AIzaSyAQuB9CVQf_m9huLNCnzjqscI12DoazZI8"
				let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(address)&key=\(apiKey)")!
				let (data, _) = try! await URLSession.shared.data(from: url)
				let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
				if let result = json["results"] as? [[String: Any]] {
					if let geometry = result[0]["geometry"] as? [String: Any] {
						if let location = geometry["location"] as? [String: Any] {
							let latitude = location["lat"] as! CLLocationDegrees
							let longitude = location["lng"] as! CLLocationDegrees
							let timestamp = Date().timeIntervalSince1970
							let url = URL(string: "https://maps.googleapis.com/maps/api/timezone/json?location=\(latitude),\(longitude)&timestamp=\(timestamp)&key=\(apiKey)")!
							let (data, _) = try! await URLSession.shared.data(from: url)
							let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
							let timeZoneID = json["timeZoneId"] as! String
							return TimeZone.init(identifier: timeZoneID)!
						}
					}
				}
				return TimeZone.current
			}
			
			return event.data(
				timeZone: timeZone,
				interval: .init(self.timeZone(for: "ET").secondsFromGMT() - timeZone.secondsFromGMT()),
				dateFormatter: dateFormatter,
				dateTimeFormatter: dateTimeFormatter(with: timeZone),
				timestampFormatter: timestampFormatter(with: timeZone)
			)
		}
	}

	func eventPlacements(
		year: Int,
		span: Span,
		slugs: [String]? = nil
	) async -> APIResult<EventPlacementData> {
		let slugs = await slugs.map(APIResult.success).asyncMapNil {
			await api.fetch(EventDateSlugSlotsFields.self).map { events in
				events.filter { event in
					let date: Date
					let times = event.slots.compactMap(\.time).sorted()
					let needsPlacements = event.slots.compactMap(\.performance?.placement).isEmpty
					
					if times.count < 2 {
						date = event.date
					} else if span == .current {
						date = times.last!
					} else {
						date = times[1]
					}
					
					return switch span {
					case .season: true
					case .current: date < .init() && -date.timeIntervalSinceNow < 60 * 60 && needsPlacements
					case .upcoming: date > .init()
					}
				}.compactMap(\.slug)
			}
		}
		
		return if let eventData = (
			Bundle.module.url(
				forResource: "\(year)",
				withExtension: "json"
			).map { url in
				try! Foundation.Data(
					contentsOf: url,
					options: []
				)
			}
		) {
			await slugs.asyncMap { slugs in
				let events = try! api.decoder.decode([Uniform.Event].self, from: eventData)
				return await zip(
					events.sorted { $0.slug < $1.slug },
					slugs.asyncMap { slug in
						await placements(
							slug: slug,
							year: year
						)
					}
				).map {
					(
						event: $0.0,
						placements: $0.1
					)
				}
			}.map(Array.init)
		} else {
			await slugs.asyncMap { slugs in
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

	func eventResult(
		data: EventData,
		placements: [Uniform.Placement]
	) async -> APIResult<EventResult> {
		let result: APIResult<Diesel.Event.Identified>
		let (event, show, venue, address, location, slots, slotFeatures, slotCorps, slotLocations) = data
    	
		if let address, let show, let venue {
			result = await find(location).asyncFlatMap { location in
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
		} else {
			result = await find(location).asyncFlatMap { location in
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
		
		let count = placements.count
		let hasSlots = !slots.isEmpty
		
		return await result.asyncFlatMap { event in
			await slotsResult(
				event: event,
				slots: hasSlots ? slots : .init(repeating: .init(time: nil), count: count),
				slotFeatures: hasSlots ? slotFeatures : .init(repeating: nil, count: count),
				slotCorps: hasSlots ? slotCorps : placements.map(\.groupName).map(Corps.init),
				slotLocations: hasSlots ? slotLocations : .init(repeating: nil, count: count),
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
			
			let events = data.map(\.event)
			let slots = data.flatMap(\.slots)
			let performances = data.flatMap(\.performances)
			let placements = data.flatMap(\.placements)
			
			guard !events.isEmpty, !(current && placements.isEmpty) else { return .success([]) }
			
			return await api.fetch(SlotTimePerformancePlacementFields.self, where: Slot.isPartOfEvent(from: events)).asyncFlatMap { fields in
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
					dateTimeFormatter.date(from: "\(startDate) \(startTime)") ??
						timestampFormatter.date(from: startTime)?.addingTimeInterval(interval)
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
