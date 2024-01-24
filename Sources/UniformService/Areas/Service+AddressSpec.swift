// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Address
import struct Diesel.Location
import struct DieselService.IdentifiedAddress

extension Service: AddressSpec where
	API: AddressSpec,
	API.AddressResult == APIResult<Address.Identified>,
	Database: AddressSpec,
	Database.AddressResult == DatabaseResult<Address.Identified?> {
	public func find(_ address: Address, in location: Location.Identified) async -> APIResult<Address.Identified> {
		await database.find(address, in: location).value.map(APIResult.success).asyncMapNil {
			await api.find(address, in: location).asyncFlatMap { address in
				await database.insert(address).map { _ in .success(address) }.value
			}
		}
	}
}
