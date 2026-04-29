import Foundation

class ConverterService {
    static let shared = ConverterService()
    
    private let atomicNumbers: [String: Int] = [
        "H": 1, "He": 2, "Li": 3, "Be": 4, "B": 5, "C": 6, "N": 7, "O": 8,
        "F": 9, "Ne": 10, "Na": 11, "Mg": 12, "Al": 13, "Si": 14, "P": 15, "S": 16,
        "Cl": 17, "Ar": 18, "K": 19, "Ca": 20, "Sc": 21, "Ti": 22, "V": 23, "Cr": 24,
        "Mn": 25, "Fe": 26, "Co": 27, "Ni": 28, "Cu": 29, "Zn": 30, "Ga": 31, "Ge": 32,
        "As": 33, "Se": 34, "Br": 35, "Kr": 36, "Rb": 37, "Sr": 38, "Y": 39, "Zr": 40,
        "Nb": 41, "Mo": 42, "Tc": 43, "Ru": 44, "Rh": 45, "Pd": 46, "Ag": 47, "Cd": 48,
        "In": 49, "Sn": 50, "Sb": 51, "Te": 52, "I": 53, "Xe": 54, "Cs": 55, "Ba": 56,
        "La": 57, "Ce": 58, "Pr": 59, "Nd": 60, "Pm": 61, "Sm": 62, "Eu": 63, "Gd": 64,
        "Tb": 65, "Dy": 66, "Ho": 67, "Er": 68, "Tm": 69, "Yb": 70, "Lu": 71, "Hf": 72,
        "Ta": 73, "W": 74, "Re": 75, "Os": 76, "Ir": 77, "Pt": 78, "Au": 79, "Hg": 80,
        "Tl": 81, "Pb": 82, "Bi": 83, "Po": 84, "At": 85, "Rn": 86, "Fr": 87, "Ra": 88,
        "Ac": 89, "Th": 90, "Pa": 91, "U": 92, "Np": 93, "Pu": 94, "Am": 95, "Cm": 96,
        "Bk": 97, "Cf": 98, "Es": 99, "Fm": 100, "Md": 101, "No": 102, "Lr": 103,
        "Rf": 104, "Db": 105, "Sg": 106, "Bh": 107, "Hs": 108, "Mt": 109, "Ds": 110,
        "Rg": 111, "Cn": 112, "Nh": 113, "Fl": 114, "Mc": 115, "Lv": 116, "Ts": 117, "Og": 118
    ]
    
    private init() {}
    
    func convertXyzToGjf(_ xyzText: String) throws -> ConversionResult {
        let lines = splitLinesPreservingXyzHeader(xyzText)
        guard !lines.isEmpty else { throw ConversionError.emptyInput }
        
        // Parse XYZ format
        let molecule = try parseXyz(lines)
        
        // Generate GJF content
        let gjfContent = generateGjf(from: molecule)
        
        let filename = "structure_\(Date().timeIntervalSince1970.rounded()).gjf"
        return ConversionResult(content: gjfContent, filename: filename)
    }
    
    func convertGviewToXyz(_ text: String) throws -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty else { throw ConversionError.emptyInput }
        
        // Simplified parsing - assumes standard format
        var atoms: [Atom] = []
        let comment = "Converted from GaussianView"
        
        for line in lines {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard parts.count >= 4 else { continue }
            
            if let x = Double(parts[1]), let y = Double(parts[2]), let z = Double(parts[3]) {
                let symbol = try normalizeElementSymbol(parts[0])
                let atomNumber = atomicNumbers[symbol] ?? 0
                atoms.append(Atom(symbol: symbol, x: x, y: y, z: z, atomicNumber: atomNumber))
            }
        }
        
        return formatXyz(atoms: atoms, comment: comment)
    }

    func convertGaussianClipboardFileToXyz(filePath: String) throws -> String {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        guard lines.count >= 2 else {
            throw ConversionError.parseError("Gaussian clipboard file is too short")
        }

        let atomCountLine = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard let expectedAtoms = Int(atomCountLine), expectedAtoms > 0 else {
            throw ConversionError.parseError("Cannot parse atom count from Gaussian clipboard")
        }

        var atoms: [Atom] = []
        let symbolMap = Dictionary(uniqueKeysWithValues: atomicNumbers.map { ($0.value, $0.key) })

        for index in 0..<expectedAtoms {
            let lineIndex = 2 + index
            guard lineIndex < lines.count else { break }

            let parts = lines[lineIndex].split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard parts.count >= 4,
                  let atomicNumber = Int(parts[0]),
                  let x = Double(parts[1]),
                  let y = Double(parts[2]),
                  let z = Double(parts[3]) else {
                continue
            }

            guard let symbol = symbolMap[atomicNumber] else { continue }
            atoms.append(Atom(symbol: symbol, x: x, y: y, z: z, atomicNumber: atomicNumber))
        }

        guard !atoms.isEmpty else {
            throw ConversionError.emptyInput
        }

        return formatXyz(atoms: atoms, comment: "Converted from Gaussian clipboard")
    }
    
    private func splitLinesPreservingXyzHeader(_ text: String) -> [String] {
        var normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        var lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        while lines.last?.isEmpty == true {
            lines.removeLast()
        }

        return lines
    }

    private func normalizeElementSymbol(_ rawSymbol: String) throws -> String {
        let trimmed = rawSymbol.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ConversionError.parseError("Missing element symbol")
        }

        let normalized = trimmed.prefix(1).uppercased() + trimmed.dropFirst().lowercased()
        guard atomicNumbers[normalized] != nil else {
            throw ConversionError.parseError("Unknown element symbol: \(rawSymbol)")
        }

        return normalized
    }

    private func parseXyz(_ lines: [String]) throws -> Molecule {
        var atoms: [Atom] = []
        var comment = ""

        guard lines.count >= 2 else {
            throw ConversionError.parseError("XYZ input must include atom count and comment lines")
        }

        guard let atomCount = Int(lines[0].trimmingCharacters(in: .whitespacesAndNewlines)), atomCount > 0 else {
            throw ConversionError.parseError("First XYZ line must be a positive atom count")
        }

        comment = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)

        guard lines.count >= atomCount + 2 else {
            throw ConversionError.parseError("Expected \(atomCount) atom lines, got \(max(0, lines.count - 2))")
        }

        for atomIndex in 0..<atomCount {
            let lineIndex = atomIndex + 2
            let trimmed = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)

            guard parts.count >= 4 else {
                throw ConversionError.parseError("Invalid atom line \(atomIndex + 1): expected symbol and 3 coordinates")
            }

            guard let x = Double(parts[1]), let y = Double(parts[2]), let z = Double(parts[3]) else {
                throw ConversionError.parseError("Invalid coordinates on atom line \(atomIndex + 1)")
            }

            let symbol = try normalizeElementSymbol(parts[0])
            let atomNumber = atomicNumbers[symbol] ?? 0

            atoms.append(Atom(symbol: symbol, x: x, y: y, z: z, atomicNumber: atomNumber))
        }
        
        guard atoms.count == atomCount, !atoms.isEmpty else {
            throw ConversionError.parseError("Expected \(atomCount) atoms, got \(atoms.count)")
        }
        
        return Molecule(atoms: atoms, comment: comment)
    }
    
    private func generateGjf(from molecule: Molecule) -> String {
        var gjf = ""
        gjf += "%nproc=8\n"
        gjf += "%mem=16GB\n"
        gjf += "# B3LYP/6-31G(d) Opt\n"
        gjf += "\n"
        gjf += "Converted from XYZ\n"
        gjf += "\n"
        gjf += "0 1\n"
        
        for atom in molecule.atoms {
            let paddedSymbol = atom.symbol.padding(toLength: 3, withPad: " ", startingAt: 0)
            gjf += "\(paddedSymbol) \(String(format: "%12.8f", atom.x)) \(String(format: "%12.8f", atom.y)) \(String(format: "%12.8f", atom.z))\n"
        }
        
        gjf += "\n\n"
        return gjf
    }
    
    private func formatXyz(atoms: [Atom], comment: String) -> String {
        var xyz = String(atoms.count) + "\n"
        xyz += comment + "\n"
        
        for atom in atoms {
            let paddedSymbol = atom.symbol.padding(toLength: 3, withPad: " ", startingAt: 0)
            xyz += "\(paddedSymbol) \(String(format: "%12.8f", atom.x)) \(String(format: "%12.8f", atom.y)) \(String(format: "%12.8f", atom.z))\n"
        }
        
        return xyz
    }
}
