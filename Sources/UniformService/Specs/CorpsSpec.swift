// Copyright © Fleuronic LLC. All rights reserved.

import struct Uniform.Corps
import protocol Catena.Scoped
import protocol Catena.ResultProviding
import protocol Catenoid.Fields
import protocol Caesura.Storage

public protocol CorpsSpec {
	associatedtype CorpsList: Scoped<CorpsListFields>

	associatedtype CorpsListFields: CorpsFields

	func listCorps() async -> CorpsList
}
