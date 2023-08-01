// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Location
import struct DieselService.IdentifiedLocation

extension Service: LocationSpec where
    API: LocationSpec,
    API.LocationResult == APIResult<Location.Identified>,
    Database: LocationSpec,
    Database.LocationResult == DatabaseResult<Location.Identified?> {
    public func find(_ location: Location) async -> APIResult<Location.Identified> {
        await database.find(location).value.map(APIResult.success).asyncMapNil {
            await api.find(location).asyncFlatMap { location in
                await database.insert(location).map { _ in
                    .success(location)
                }.value
            }
        }
    }
}
