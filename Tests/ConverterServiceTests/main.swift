import Foundation

struct TestFailure: Error, CustomStringConvertible {
    let description: String
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure(description: message)
    }
}

func expectThrows(_ message: String, _ operation: () throws -> Void, matching expectedMessage: String) throws {
    do {
        try operation()
    } catch {
        try expect(error.localizedDescription == expectedMessage, "\(message): got \(error.localizedDescription)")
        return
    }

    throw TestFailure(description: "\(message): expected throw")
}

func extractAtomLines(from gjf: String) -> [String] {
    let lines = gjf.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    guard let chargeLineIndex = lines.firstIndex(where: {
        $0.trimmingCharacters(in: .whitespacesAndNewlines) == "0 1"
    }) else {
        return []
    }

    var atomLines: [String] = []
    for line in lines[(chargeLineIndex + 1)...] {
        if line.isEmpty { break }
        atomLines.append(line)
    }
    return atomLines
}

func testCrlfAndEmptyCommentLine() throws {
    let xyz = "2\r\n\r\ncu 0 0 0\r\nH 0 0 1\r\n"
    let gjf = try ConverterService.shared.convertXyzToGjf(xyz).content
    let atomLines = extractAtomLines(from: gjf)

    try expect(atomLines.count == 2, "CRLF input should produce 2 atom lines")
    try expect(atomLines[0].hasPrefix("Cu "), "cu should normalize to Cu")
    try expect(atomLines[1].hasPrefix("H "), "H should stay H")
    try expect(!gjf.contains("CU "), "GJF should not contain uppercase CU")
}

func testLfAndElementCaseNormalization() throws {
    let xyz = "2\ncomment\nCU 0 0 0\nh 0 0 1\n"
    let gjf = try ConverterService.shared.convertXyzToGjf(xyz).content
    let atomLines = extractAtomLines(from: gjf)

    try expect(atomLines.count == 2, "LF input should produce 2 atom lines")
    try expect(atomLines[0].hasPrefix("Cu "), "CU should normalize to Cu")
    try expect(atomLines[1].hasPrefix("H "), "h should normalize to H")
}

func testUnknownElementFails() throws {
    let xyz = "1\ncomment\nXx 0 0 0\n"
    try expectThrows("Unknown element should fail", {
        _ = try ConverterService.shared.convertXyzToGjf(xyz)
    }, matching: "Parse error: Unknown element symbol: Xx")
}

func testZeroAtomCountFails() throws {
    let xyz = "0\ncomment\n"
    try expectThrows("Zero atom count should fail", {
        _ = try ConverterService.shared.convertXyzToGjf(xyz)
    }, matching: "Parse error: First XYZ line must be a positive atom count")
}

let tests: [(String, () throws -> Void)] = [
    ("testCrlfAndEmptyCommentLine", testCrlfAndEmptyCommentLine),
    ("testLfAndElementCaseNormalization", testLfAndElementCaseNormalization),
    ("testUnknownElementFails", testUnknownElementFails),
    ("testZeroAtomCountFails", testZeroAtomCountFails)
]

do {
    for (name, test) in tests {
        try test()
        print("PASS \(name)")
    }
    print("PASS \(tests.count) converter tests")
} catch {
    fputs("FAIL \(error)\n", stderr)
    exit(1)
}
