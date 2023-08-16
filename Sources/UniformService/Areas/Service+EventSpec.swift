// Copyright © Fleuronic LLC. All rights reserved.

import enum Uniform.Span
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
import struct Uniform.Site
import struct Foundation.URL
import struct Foundation.Date
import struct Foundation.Data
import struct Foundation.TimeInterval
import class Foundation.JSONDecoder
import class Foundation.URLSession
import class Foundation.DateFormatter
import class Foundation.Bundle
import protocol Caesura.HasuraAPI

extension Service: EventSpec where Self: AddressSpec & VenueSpec & SlotSpec, API: HasuraAPI {
	public func createEvents(for year: Int) async -> APIResult<[Diesel.Event.ID]> {
		await events(for: year).asyncFlatMap { data in
			await updateEvents(current: false, data: data)
		}
	}

    public func updateEvents(current: Bool) async -> APIResult<[Diesel.Event.ID]> {
		await eventPlacements(span: current ? .current : .upcoming).asyncFlatMap { data in
			await updateEvents(current: current, data: data)
		}
    }
}

// MARK: -
private extension Service {
	typealias EventData = (Diesel.Event, Diesel.Venue, Address, Location, [Slot], [Feature?], [Corps?], [Location?])
	typealias EventResult = (Diesel.Event.Identified, [Slot.Identified], [Performance.Identified], [Diesel.Placement.Identified])
	typealias EventPlacementData = [(Uniform.Event, [Uniform.Placement])]

	func placements(for slug: String) async -> [Uniform.Placement] {
		await Site(
			domain: .dci,
			path: .scores,
			slug: slug.normalized(from: .events)
		)?.data.flatMap { data in
			try! JSONDecoder().decode([Uniform.Placement].self, from: data)
		} ?? []
	}
}

// MARK: -
private extension Service where Self: AddressSpec & VenueSpec & SlotSpec, API: HasuraAPI {
	func events(for year: Int) async -> APIResult<EventPlacementData> {
		await eventPlacements(
			year: year,
			span: .season,
			slugs: Array(resource: .events).filter {
				$0.contains("\(year)")
			}
		)
	}

	func eventData(for events: [Uniform.Event]) -> [EventData] {
		events.map { event in
			event.data(
				timeFormatter: timeFormatter(timeZone: timeZone(for: event.timeZone)),
				dateFormatter: dateFormatter
			)
		}
	}

	func eventPlacements(
		year: Int? = nil,
		span: Span,
		slugs: [String]? = nil
	) async -> APIResult<EventPlacementData> {
		let slugs = await slugs.map(APIResult.success).asyncMapNil {
			await api.fetch(EventDateSlugSlotsFields.self).map { events in
				events.filter { event in
					let date: Date
					let times = event.slots.compactMap(\.time).sorted()
					let needsPlacements = event.slots.compactMap(\.placementID).isEmpty

					if times.count < 2 {
						date = event.date
					} else if span == .current {
						date = Date(date: event.date, startTime: times.last!)
					} else {
						date = Date(date: event.date, startTime: times[1])
					}

					switch span {
					case .season:
						return true
					case .current:
						return date < .init() && -date.timeIntervalSinceNow < 60 * 60 && needsPlacements
					case .upcoming:
						return date > .init()
					}
				}.compactMap(\.slug)
			}
		}

		if let eventData = (
			year.flatMap {
				Bundle.module.url(
					forResource: "\($0)",
					withExtension: "json"
				).map {
					try! Foundation.Data(
						contentsOf: $0,
						options: []
					)
				}
			}
		) {
			return await slugs.asyncMap { slugs in
				let events = try! JSONDecoder().decode([Uniform.Event].self, from: eventData)
				return await zip(
					events.sorted {
						$0.slug < $1.slug
					},
					slugs.asyncMap { slug in
						await placements(for: slug)
					}
				)
			}.map(Array.init)
		} else {
			return await slugs.asyncMap { slugs in
				await slugs.asyncCompactMap { slug in
					await Site(
						domain: .dci,
						path: .events,
						slug: slug
					)?.data.asyncMap { eventData in
						let event = try? JSONDecoder().decode(Event.self, from: eventData)
						let placements = (span == .upcoming || year == 2021) ? [] : await placements(for: slug)
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
			eventData(for: data.map(\.0)),
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
				let placementIDs = fields.compactMap(\.placementID)

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
		timeFormatter: DateFormatter,
		dateFormatter: DateFormatter
	) -> Service.EventData {
		(
			.init(
				name: name,
				slug: slug,
				date: dateFormatter.date(from: startDate)!,
				timeZone: timeZone
			),
			.init(
				name: venueName.replacingOccurrences(of: "\"", with: "")
			),
			.init(
				streetAddress: venueAddress,
				zipCode: venueZIP ?? .inserted(for: venueAddress, from: .addresses)!
			),
			.init(
				city: venueCity,
				state: venueState
			),
			schedules?.map { slot in
				.init(time: slot.time.flatMap(timeFormatter.date)?.timeIntervalSinceReferenceDate)
			} ?? [],
			schedules?.map(\.feature) ?? [],
			schedules?.map(\.corps) ?? [],
			schedules?.map { schedule in
				schedule.displayCity.map { city in
					var components = city.normalized(from: .locations).components(separatedBy: ", ")
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
