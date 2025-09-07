//
//  ROMFile.swift
//  LOTWEdit
//
//  Created by Angelo Di Paolo on 9/5/25.
//

import Foundation

class ROMFile: ObservableObject {
    @Published var data: Data?
    @Published var isValid: Bool = false
    
    private let headerSize = 16
    private let prgBankSize = 16384  // 16KB
    private let chrBankSize = 8192   // 8KB
    
    var prgRomSize: Int {
        guard let data = data, data.count >= headerSize else { return 0 }
        return Int(data[4]) * prgBankSize
    }
    
    var chrRomSize: Int {
        guard let data = data, data.count >= headerSize else { return 0 }
        return Int(data[5]) * chrBankSize
    }
    
    func loadROM(from url: URL) throws {
        let romData = try Data(contentsOf: url)
        
        // Validate iNES header
        guard romData.count >= headerSize,
              romData[0] == 0x4E, // 'N'
              romData[1] == 0x45, // 'E'
              romData[2] == 0x53, // 'S'
              romData[3] == 0x1A  // MS-DOS EOF
        else {
            throw ROMError.invalidHeader
        }
        
        // Check mapper (should be 4 for MMC3)
        let mapper = ((romData[6] >> 4) | (romData[7] & 0xF0))
        guard mapper == 4 else {
            throw ROMError.unsupportedMapper(Int(mapper))
        }
        
        self.data = romData
        self.isValid = true
    }
    
    func readByte(at offset: Int) -> UInt8? {
        guard let data = data, offset < data.count else { return nil }
        return data[offset]
    }
    
    func readBytes(from offset: Int, count: Int) -> [UInt8]? {
        guard let data = data, 
              offset + count <= data.count else { return nil }
        return Array(data[offset..<offset + count])
    }
    
    func writeByte(at offset: Int, value: UInt8) {
        guard var data = data, offset < data.count else { return }
        data[offset] = value
        self.data = data
    }
    
    func writeBytes(at offset: Int, values: [UInt8]) {
        guard var data = data, 
              offset + values.count <= data.count else { return }
        for (index, value) in values.enumerated() {
            data[offset + index] = value
        }
        self.data = data
    }
    
    func saveROM(to url: URL) throws {
        guard let data = data else {
            throw ROMError.noDataToSave
        }
        try data.write(to: url)
    }
}

enum ROMError: LocalizedError {
    case invalidHeader
    case unsupportedMapper(Int)
    case noDataToSave
    
    var errorDescription: String? {
        switch self {
        case .invalidHeader:
            return "Invalid NES ROM header"
        case .unsupportedMapper(let mapper):
            return "Unsupported mapper: \(mapper). LOTW requires MMC3 (mapper 4)"
        case .noDataToSave:
            return "No ROM data to save"
        }
    }
}