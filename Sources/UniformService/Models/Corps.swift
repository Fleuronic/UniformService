// Copyright © Fleuronic LLC. All rights reserved.

import Identity
import Foundation
import struct Uniform.Corps
import struct Catena.IDFields
import protocol Catena.Valued

public extension Corps {
	typealias ID = Identified.ID
	typealias IDFields = Catena.IDFields<Identified>
	typealias Identified = IdentifiedCorps
}

// MARK: -
public struct IdentifiedCorps: Sendable {
	public let id: Corps.ID
	public let value: Corps
}

// MARK: -
extension Corps.Identified: Identifiable {
	// MARK: Identifiable
	public typealias RawIdentifier = Int
}

extension Corps.Identified: Valued {
	// MARK: Valued
	public typealias Value = Corps
}
