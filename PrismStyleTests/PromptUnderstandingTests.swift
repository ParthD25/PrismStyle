import XCTest
@testable import PrismStyle

final class PromptUnderstandingTests: XCTestCase {

    func testParse_EmptyInput_ReturnsNilInferences() {
        let parsed = PromptUnderstanding.parse(styleGoal: "", occasion: "")
        XCTAssertNil(parsed.inferredStylePreference)
        XCTAssertNil(parsed.inferredColorPreference)
        XCTAssertNil(parsed.inferredPrioritizeComfort)
    }

    func testParse_InfersStyleColorComfort() {
        let parsed = PromptUnderstanding.parse(styleGoal: "minimal warm comfy", occasion: "date night")
        XCTAssertEqual(parsed.inferredStylePreference, "minimalist")
        XCTAssertEqual(parsed.inferredColorPreference, "warm")
        XCTAssertEqual(parsed.inferredPrioritizeComfort, true)
    }

    func testParse_InfersProfessionalDark() {
        let parsed = PromptUnderstanding.parse(styleGoal: "office professional", occasion: "dark colors")
        XCTAssertEqual(parsed.inferredStylePreference, "professional")
        XCTAssertEqual(parsed.inferredColorPreference, "dark")
    }
}
