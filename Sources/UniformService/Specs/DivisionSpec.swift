// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Division

public protocol DivisionSpec {
    associatedtype DivisionResult

    func find(_ division: Division) async -> DivisionResult
}
