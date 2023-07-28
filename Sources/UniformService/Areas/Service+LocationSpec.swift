// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Location
import struct DieselService.IdentifiedLocation

extension Service: LocationSpec where
    API: LocationSpec,
    API.LocationResult == APIResult<Location.Identified>,
    Database: LocationSpec,
    Database.LocationResult == Location.Identified? {
    public func find(_ location: Location) async -> APIResult<Location.Identified> {
        await database.find(location).map(APIResult.success).asyncMapNil {
            await api.find(location)
        }
    }
}
