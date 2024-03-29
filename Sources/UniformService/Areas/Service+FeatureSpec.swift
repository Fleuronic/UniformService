// Copyright © Fleuronic LLC. All rights reserved.

import struct Diesel.Corps
import struct Diesel.Feature
import struct DieselService.IdentifiedFeature

extension Service: FeatureSpec where
	API: FeatureSpec,
	API.FeatureResult == APIResult<Feature.Identified>,
	Database: FeatureSpec,
	Database.FeatureResult == DatabaseResult<Feature.Identified?> {
	public func find(_ feature: Feature, by corps: Corps.Identified?) async -> APIResult<Feature.Identified> {
		await database.find(feature, by: corps).value.map(APIResult.success).asyncMapNil {
			await api.find(feature, by: corps).asyncFlatMap { feature in
				await database.insert(feature).map { _ in .success(feature) }.value
			}
		}
	}
}
