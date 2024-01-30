// swift-tools-version:5.8
import PackageDescription

let package = Package(
	name: "UniformService",
	platforms: [
		.iOS(.v13),
		.macOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6)
	],
	products: [
		.library(
			name: "UniformService",
			targets: ["UniformService"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/Fleuronic/Uniform", branch: "main"),
		.package(url: "https://github.com/Fleuronic/DieselService", branch: "main"),
		.package(url: "https://github.com/Fleuronic/GeodeAPI", branch: "main"),
		.package(url: "https://github.com/Fleuronic/Caesura", branch: "main"),
		.package(url: "https://github.com/JohnSundell/Identity", from: "0.1.0")
	],
	targets: [
		.target(
			name: "UniformService",
			dependencies: [
				"Uniform",
				"DieselService",
				"GeodeAPI",
				"Caesura",
				"Identity"
			],
			resources: [
				.copy("Resources/Events/2018.json"),
			]
		)
	]
)
