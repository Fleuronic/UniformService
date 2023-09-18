// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Venue
import struct Diesel.Address
import struct Diesel.Location
import struct Schemata.Projection
import protocol DieselService.VenueFields
import protocol Identity.Identifiable

public struct VenueCalendarFields {
    public let id: Venue.ID
    public let name: String
	public let host: String?
    public let address: AddressCalendarFields
}

// MARK: -
extension VenueCalendarFields: VenueFields {
    // MARK: ModelProjection
    public static let projection = Projection<Venue.Identified, Self>(
        Self.init,
        \.id,
        \.value.name,
		\.value.host,
        \.address.id,
        \.address.value.streetAddress,
        \.address.value.zipCode,
        \.address.location.id,
        \.address.location.value.city,
        \.address.location.value.state
    )
}

// MARK: -
private extension VenueCalendarFields {
    init(
        id: Venue.ID,
        name: String,
		host: String?,
        addressID: Address.ID,
        streetAddress: String,
        zipCode: String,
        locationID: Location.ID,
        city: String,
        state: String
    ) {
        self.id = id
        self.name = name
		self.host = host

        address = .init(
            id: addressID,
            streetAddress: streetAddress,
            zipCode: zipCode,
            location: .init(
                id: locationID,
                city: city,
                state: state
            )
        )
    }
}
