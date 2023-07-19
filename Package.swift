// swift-tools-version:5.6
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
		)
	],
	dependencies: [
		.package(url: "https://github.com/Fleuronic/Uniform", branch: "main"),
		.package(url: "https://github.com/JohnSundell/Identity", from: "0.1.0"),
		.package(url: "https://github.com/Fleuronic/Catenary", branch: "main"),
		.package(url: "https://github.com/Fleuronic/Catenoid", branch: "main")
	],
	targets: [
		.target(
			name: "UniformService",
			dependencies: [
				"Uniform",
				"Identity",
				"Catenary",
				"Catenoid"
			]
		)
	]
)
