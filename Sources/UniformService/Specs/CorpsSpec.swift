// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import struct DrumKit.Corps
import struct DrumKit.Location
import struct DrumKitService.IdentifiedLocation
import protocol Catena.Scoped
import protocol Catena.Identifying
import protocol Catena.ResultProviding

public protocol CorpsSpec {
	associatedtype CorpsList: Scoped<CorpsListFields>
	associatedtype CorpsFetch: Scoped<CorpsFetchFields>
	associatedtype CorpsCreation: Identifying<DrumKit.Corps.Identified>

	associatedtype CorpsListFields: CorpsFields
	associatedtype CorpsFetchFields: CorpsFields

	associatedtype CorpsID: Identifying<Uniform.Corps.Identified>
	associatedtype LocationID: Identifying<Location.Identified>

	func listCorps() async -> CorpsList
	func fetchCorps(with id: CorpsID) async -> CorpsFetch
	func fetchCorps(with name: String) async -> CorpsFetch
	func createCorps(named name: String, basedInLocationWith locationID: LocationID) async -> CorpsCreation
}
