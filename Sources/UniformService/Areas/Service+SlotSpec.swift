import struct Diesel.Event
import struct Diesel.Slot
import struct Diesel.Feature
import struct Diesel.Corps
import struct Diesel.Location
import struct Diesel.Performance
import struct DieselService.IdentifiedCorps
import struct DieselService.IdentifiedPerformance
import struct DieselService.IdentifiedPlacement
import struct DieselService.IdentifiedEvent
import struct Uniform.Placement
import protocol Catenary.API

extension Service: SlotSpec where
    Self: CorpsSpec,
    Self: FeatureSpec,
    Self: LocationSpec,
    Self: DivisionSpec {
    public func slotResult(
        data: CorpsPerformancePlacementData,
        event: Event.Identified,
        slot: Slot,
        feature: Feature?
    ) async -> API.Result<SlotPerformancePlacementData> {
        let (corps, performance, placement) = data
        let result = await feature.asyncMap { feature in
           await find(feature, by: corps).map { feature in
               slot.identified(
                   event: event,
                   feature: feature
               )
           }
        } ?? corps.map { _ in
            slot.identified(
                event: event,
                performance: performance
            )
        }.map(Result.success) ?? .success(
            slot.identified(event: event)
        )

        return result.map { slot in
            return (slot, performance, placement)
        }
    }

    public func slotsResult(
        event: Event.Identified,
        slots: [Slot],
        slotFeatures: [Feature?],
        slotCorps: [Corps?],
        slotLocations: [Location?],
        placements: [Placement]
    ) async -> APIResult<[SlotPerformancePlacementData]> {
        await zip(slots, zip(slotLocations, zip(slotFeatures, slotCorps))).asyncFlatMap { slot, locationFeatureCorps in
            let (location, featureCorps) = locationFeatureCorps
            let (feature, corps) = featureCorps

            let corpsResult = await corps.asyncFlatMap { corps in
                let corpsName = corps.name
                return await location.asyncMap { location in
                    await find(location).asyncFlatMap { location in
                        await find(corps, from: location).map { corps -> CorpsData in
                            (corps, corpsName)
                        }
                    }
				}.asyncMapNil {
					await find(corps, from: nil).map { corps -> CorpsData in
						(corps, corpsName)
					}
				}
            } ?? .success(nil)

            return await corpsResult.asyncFlatMap { data in
                await performanceResult(
                    data: data,
                    feature: feature,
                    placements: placements
                ).asyncFlatMap { data in
                    await slotResult(
                        data: data,
                        event: event,
                        slot: slot,
                        feature: feature
                    )
                }
            }
        }
    }
}
