// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import protocol Catena.Scoped
import protocol Catena.Identifying
import protocol Catena.ResultProviding

public protocol CorpsSpec {
	associatedtype CorpsFetch: Scoped<CorpsFetchFields>
	associatedtype CorpsList: Scoped<CorpsListFields>

	associatedtype CorpsFetchFields: CorpsFields
	associatedtype CorpsListFields: CorpsFields

	associatedtype CorpsID: Identifying<Corps.Identified>

	func fetchCorps(with id: CorpsID) async -> CorpsFetch
	func listCorps() async -> CorpsList
}
