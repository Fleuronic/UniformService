// Copyright © Fleuronic LLC. All rights reserved.

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

public protocol SlotSpec {
    associatedtype SlotData
    associatedtype Placements
    associatedtype SlotResult
    associatedtype SlotsResult
    
    func slotResult(
        data: SlotData,
        event: Event.Identified,
        slot: Slot,
        feature: Feature?
    ) async -> SlotResult

    func slotsResult(
        event: Event.Identified,
        slots: [Slot],
        slotFeatures: [Feature?],
        slotCorps: [Corps?],
        slotLocations: [Location?],
        placements: Placements
    ) async -> SlotsResult
}
