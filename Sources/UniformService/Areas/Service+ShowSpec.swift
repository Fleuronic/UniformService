// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Show
import struct DieselService.IdentifiedShow

extension Service: ShowSpec where
	API: ShowSpec,
	API.ShowResult == APIResult<Show.Identified>,
	Database: ShowSpec,
	Database.ShowResult == DatabaseResult<Show.Identified?> {
	public func find(_ show: Show) async -> APIResult<Show.Identified> {
		await database.find(show).value.map(APIResult.success).asyncMapNil {
			await api.find(show).asyncFlatMap { show in
				await database.insert(show).map { _ in
					.success(show)
				}.value
			}
		}
	}
}
