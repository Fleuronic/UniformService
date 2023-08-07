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
import struct Foundation.URL
import struct Foundation.Date
import class Foundation.JSONDecoder
import class Foundation.URLSession
import class Foundation.DateFormatter
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
	typealias EventPlacementData = [(Uniform.Event, [Uniform.Placement])]

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
}

// MARK: -
private extension Service where Self: AddressSpec & VenueSpec & SlotSpec, API: HasuraAPI {
	func events(for year: Int) async -> APIResult<EventPlacementData> {
//		let slugs: [String] = []
		return await eventPlacements(
			span: .season,
			slugs: slugs.filter { $0.contains("\(year)") }
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
		span: Span,
		slugs: [String]? = nil
	) async -> APIResult<EventPlacementData> {
		let slugs = await slugs.map(APIResult.success).asyncMapNil {
			await api.fetch(EventDateSlugSlotsFields.self).map { events in
				events.filter { event in
					guard
						case let times = event.slots.compactMap(\.time).sorted(),
						times.count > 1 else { return span == .season }

					let time = span == .current ? times.last! : times[1]
					let date = Date(date: event.date, startTime: time)
					let needsPlacements = event.slots.compactMap(\.placementID).isEmpty

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

		return await slugs.asyncMap { slugs in
			await slugs.asyncCompactMap { slug in
				let url = URL(string: "https://dci.org/events/\(slug)")!
				guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }

				return await String(decoding: data, as: UTF8.self).firstMatch(
					 of: try! Regex("current\":(\\{\"id.*?),\"liveStreams")
				).flatMap(\.output[1].substring)?.data(using: .utf8).asyncMap { eventData in
					 (
						 try! JSONDecoder().decode(Event.self, from: eventData),
						 span == .upcoming ? [] : await placements(for: slug)
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

				return await api.delete(Slot.Identified.self, with: slotIDs).asyncMap { _ in
					await api.delete(Performance.Identified.self, with: performanceIDs)
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
				name: venues.name.replacingOccurrences(of: "\"", with: "")
			),
			.init(
				streetAddress: venueAddress,
				zipCode: venueZIP ?? "66061"
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

let slugs = [
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
