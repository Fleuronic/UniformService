// Copyright © Fleuronic LLC. All rights reserved.

import PersistDB

import struct Diesel.Corps
import struct Diesel.Slot
import struct Diesel.Performance
import struct Diesel.Placement
import struct DieselService.IdentifiedCorps
import protocol Catenary.API
import protocol Catenoid.Database

public struct Service<API: Catenary.API, Database: Catenoid.Database> where Database.Store == Store<ReadWrite> {
    let api: API
    let database: Database

    public init(
        api: API,
        database: Database
    ) {
        self.api = api
        self.database = database
    }
}

// MARK: -
public extension Service {
    typealias APIResult<Resource> = API.Result<Resource>
    typealias DatabaseResult<Resource> = Database.Result<Resource>
    typealias CorpsData = (Corps.Identified, String)?
    typealias SlotPerformancePlacementData = (Slot.Identified, Performance.Identified?, Diesel.Placement.Identified?)
    typealias CorpsPerformancePlacementData = (Corps.Identified?, Performance.Identified?, Diesel.Placement.Identified?)
}
