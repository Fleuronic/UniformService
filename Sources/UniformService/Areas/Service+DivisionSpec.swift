// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Division
import struct DieselService.IdentifiedDivision

extension Service: DivisionSpec where
	API: DivisionSpec,
	API.DivisionResult == APIResult<Division.Identified>,
	Database: DivisionSpec,
	Database.DivisionResult == DatabaseResult<Division.Identified?> {
	public func find(_ division: Division) async -> APIResult<Division.Identified> {
		await database.find(division).value.map(APIResult.success).asyncMapNil {
			await api.find(division).asyncFlatMap { division in
				await database.insert(division).map { _ in .success(division) }.value
			}
		}
	}
}
