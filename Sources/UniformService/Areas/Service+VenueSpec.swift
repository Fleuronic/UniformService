// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Venue
import struct Diesel.Address
import struct DieselService.IdentifiedVenue

extension Service: VenueSpec where
	API: VenueSpec,
	API.VenueResult == APIResult<Venue.Identified>,
	Database: VenueSpec,
	Database.VenueResult == DatabaseResult<Venue.Identified?> {
	public func find(_ venue: Venue, at address: Address.Identified) async -> APIResult<Venue.Identified> {
		await database.find(venue, at: address).value.map(APIResult.success).asyncMapNil {
			await api.find(venue, at: address).asyncFlatMap { venue in
				await database.insert(venue).map { _ in
					.success(venue)
				}.value
			}
		}
	}
}
