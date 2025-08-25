// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct DrumKit.Corps
import struct DrumKit.Location
import struct DrumKitService.IdentifiedLocation
import protocol Catena.Scoped
import protocol Catena.Identifying
import protocol Catena.ResultProviding

public protocol CorpsSpec {
	associatedtype CorpsFetch: Scoped<CorpsFetchFields>
	associatedtype CorpsList: Scoped<CorpsListFields>
	associatedtype CorpsCreation: Identifying<DrumKit.Corps.Identified>

	associatedtype CorpsFetchFields: CorpsFields
	associatedtype CorpsListFields: CorpsFields

	associatedtype CorpsID: Identifying<Uniform.Corps.Identified>
	associatedtype LocationID: Identifying<Location.Identified>

	func fetchCorps(with id: CorpsID) async -> CorpsFetch
	func listCorps() async -> CorpsList
	func createCorps(named name: String, basedInLocationWith locationID: LocationID) async -> CorpsCreation
}
