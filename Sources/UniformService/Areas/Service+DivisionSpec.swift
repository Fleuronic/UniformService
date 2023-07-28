// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Division
import struct DieselService.IdentifiedDivision

extension Service: DivisionSpec where
    API: DivisionSpec,
    API.DivisionResult == APIResult<Division.Identified>,
    Database: DivisionSpec,
    Database.DivisionResult == Division.Identified? {
    public func find(_ division: Division) async -> APIResult<Division.Identified> {
        await database.find(division).map(APIResult.success).asyncMapNil {
            await api.find(division)
        }
    }
}
