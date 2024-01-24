// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Corps
import struct Diesel.Location
import struct DieselService.IdentifiedCorps

extension Service: CorpsSpec where
	Self: LocationSpec,
	API: CorpsSpec,
	API.CorpsResult == APIResult<Corps.Identified>,
	Database: CorpsSpec,
	Database.CorpsResult == DatabaseResult<Corps.Identified?> {
	public func find(_ corps: Corps, from location: Location.Identified?) async -> APIResult<Corps.Identified> {
		await database.find(corps, from: location).value.map(APIResult.success).asyncMapNil {
			await api.find(corps, from: location).asyncMap { corps in
				await database.insert(corps).asyncFlatMap { _ in
					await database.find(corps.location.value)
				}.asyncMap { location in
					await location.map { _ in corps }.asyncMapNil {
						await database.insert(corps.location).map { _ in corps }.value
					}
				}.value
			}
		}
	}
}
