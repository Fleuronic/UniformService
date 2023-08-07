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
		.package(url: "https://github.com/Fleuronic/Caesura", branch: "main"),
		.package(url: "https://github.com/JohnSundell/Identity", from: "0.1.0"),
		.package(url: "https://github.com/behrang/YamlSwift", from: "3.4.4")
	],
    targets: [
        .target(
            name: "UniformService",
            dependencies: [
				"Uniform",
				"DieselService",
				"Caesura",
				"Identity",
				.product(name: "Yaml", package: "YamlSwift")
			],
			resources: [
				.copy("Resources/slugs.yaml")
			]
		)
    ]
)
