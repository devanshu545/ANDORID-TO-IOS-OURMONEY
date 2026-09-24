import XCTest
import Foundation // Required for Bundle

// This class converts the Android instrumented test to an XCTestCase for iOS.
// The original test verifies that the application's runtime package name matches its build-time application ID.
// In iOS, the `Bundle.main.bundleIdentifier` serves as the equivalent of both the application ID and package name.
// Since we cannot use placeholders for a specific expected bundle ID, this test asserts that the bundle identifier
// exists, is not empty, and starts with the prefix derived from the original Android package name "com.example".
class ExampleInstrumentedTest: XCTestCase {

    func testUseAppContext() {
        // Retrieve the bundle identifier, which is the iOS equivalent of Android's package name and application ID.
        let bundleIdentifier = Bundle.main.bundleIdentifier

        // Assert that the bundle identifier is not nil.
        XCTAssertNotNil(bundleIdentifier, "The application's bundle identifier should not be nil.")

        // Assert that the bundle identifier is not empty.
        XCTAssertFalse(bundleIdentifier?.isEmpty ?? true, "The application's bundle identifier should not be empty.")

        // Further assert that the bundle identifier starts with "com.example.".
        // This is derived from the original Android package name "com.example" and serves as a
        // non-placeholder way to verify the expected application identity based on the project structure.
        if let bundleIdentifier = bundleIdentifier {
            XCTAssertTrue(bundleIdentifier.hasPrefix("com.example."), "The bundle identifier should start with 'com.example.' based on the original package name.")
        }
    }
}