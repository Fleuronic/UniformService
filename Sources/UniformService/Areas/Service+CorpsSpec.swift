// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Corps
import struct Diesel.Corps
import struct Diesel.Location
import struct DieselService.IdentifiedCorps

extension Service: CorpsSpec where
    API: CorpsSpec,
    API.CorpsResult == APIResult<Corps.Identified>,
    Database: CorpsSpec,
    Database.CorpsResult == DatabaseResult<Corps.Identified?> {
    public func find(_ corps: Corps, from location: Location.Identified) async -> APIResult<Corps.Identified> {
        await database.find(corps, from: location).value.map(APIResult.success).asyncMapNil {
            await api.find(corps, from: location)
        }
    }
}
