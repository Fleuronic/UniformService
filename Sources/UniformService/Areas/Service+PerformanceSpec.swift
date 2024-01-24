import struct Diesel.Feature
import struct Diesel.Performance
import struct Diesel.Placement
import struct Diesel.Division
import struct Uniform.Placement
import protocol Catenary.API

extension Service: PerformanceSpec where
	Self: DivisionSpec {
	public func performanceResult(
		data: CorpsData,
		feature: Feature?,
		placements: [Uniform.Placement]
	) async -> API.Result<CorpsPerformancePlacementData> {
		await data.asyncFlatMap { corps, corpsName in
			let performance = Performance()
			let placement = feature == nil ? placements.first { $0.groupName == corpsName } : nil

			return await placement.asyncFlatMap { placement in
				let division = Division(name: placement.divisionName)
				return await find(division).map { division in
					let placement = Diesel.Placement(
						rank: placement.rank,
						score: placement.totalScore
					).identified(division: division)
					
					return (
						corps,
						performance.identified(
							corps: corps,
							placement: placement
						),
						placement
					)
				}
			} ?? .success(
				(
					corps,
					feature == nil ? performance.identified(corps: corps) : nil,
					nil
				)
			)
		} ?? .success((nil, nil, nil))
	}
}
