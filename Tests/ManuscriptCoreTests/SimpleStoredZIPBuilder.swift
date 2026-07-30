import Foundation

enum SimpleStoredZIPBuilder {
    static func buildSingleEntryArchive(path: String, payload: Data) throws -> Data {
        try buildArchive(entries: [(path, payload)])
    }

    static func buildArchive(entries: [(path: String, payload: Data)]) throws -> Data {
        guard !entries.isEmpty else {
            return Data()
        }

        var data = Data()
        for entry in entries {
            data.append(try buildLocalFileEntry(path: entry.path, payload: entry.payload))
        }
        return data
    }

    private static func buildLocalFileEntry(path: String, payload: Data) throws -> Data {
        let pathData = Data(path.utf8)
        var data = Data()

        data.append(littleEndian32(0x04034B50))
        data.append(littleEndian16(20))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian32(0))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian16(UInt16(pathData.count)))
        data.append(littleEndian16(0))
        data.append(pathData)
        data.append(payload)

        return data
    }

    private static func littleEndian16(_ value: UInt16) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    private static func littleEndian32(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
}
