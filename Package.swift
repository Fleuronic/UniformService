// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "UniformService",
	platforms: [
		.iOS(.v15),
		.macOS(.v12),
		.tvOS(.v15),
		.watchOS(.v8)
	],
	products: [
		.library(
			name: "UniformService",
			targets: ["UniformService"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/Fleuronic/Uniform", branch: "main"),
		.package(url: "https://github.com/Fleuronic/Caesura", branch: "main")
	],
	targets: [
		.target(
			name: "UniformService",
			dependencies: [
				"Uniform",
				"Caesura"
			]
		)
	],
	swiftLanguageModes: [.v6]
)

for target in package.targets {
	target.swiftSettings = [
		.enableExperimentalFeature("StrictConcurrency"),
		.enableUpcomingFeature("ExistentialAny"),
	]
}
