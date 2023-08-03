// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Feature
import struct Diesel.Performance

public protocol PerformanceSpec {
    associatedtype Data
    associatedtype Placements
    associatedtype PerformanceResult

    func performanceResult(
        data: Data,
        feature: Feature?,
        placements: Placements
    ) async -> PerformanceResult
}
