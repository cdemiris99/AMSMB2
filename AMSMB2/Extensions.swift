//
//  Extensions.swift
//  AMSMB2
//
//  Created by Amir Abbas Mousavian.
//  Copyright © 2018 Mousavian. Distributed under MIT license.
//

import Foundation

extension POSIXError {
    static func throwIfError(_ result: Int32, description: String?, default: POSIXError.Code) throws {
        guard result < 0 else {
            return
        }
        let errno = -result
        let code = POSIXErrorCode(rawValue: errno) ?? `default`
        let errorDesc = description.map { "Error code \(errno): \($0)" }
        throw POSIXError(code, description: errorDesc)
    }
    
    init(_ code: POSIXError.Code, description: String?) {
        let userInfo: [String: Any] = description.map({ [NSLocalizedFailureReasonErrorKey: $0] }) ?? [:]
        self = POSIXError(code, userInfo: userInfo)
    }
}

extension Dictionary where Key == URLResourceKey, Value == Any {
    var filename: String? {
        return self[.nameKey] as? String
    }
    
    var filepath: String? {
        return self[.pathKey] as? String
    }
    
    var filetype: URLFileResourceType? {
        return self[.fileResourceTypeKey] as? URLFileResourceType
    }
    
    var filesize: Int64? {
        return self[.fileSizeKey] as? Int64
    }
}

extension Data {    
    mutating func append<T: FixedWidthInteger>(value: T) {
        var value = value.littleEndian
        let bytes = Swift.withUnsafeBytes(of: &value) { Array($0) }
        self.append(contentsOf: bytes)
    }
    
    mutating func append(value uuid: UUID) {
        // Microsoft GUID is mixed-endian
        self.append(contentsOf: [uuid.uuid.3,  uuid.uuid.2,  uuid.uuid.1,  uuid.uuid.0,
                             uuid.uuid.5,  uuid.uuid.4,  uuid.uuid.7,  uuid.uuid.6,
                             uuid.uuid.8,  uuid.uuid.9,  uuid.uuid.10, uuid.uuid.11,
                             uuid.uuid.12, uuid.uuid.13, uuid.uuid.14, uuid.uuid.15])
    }
    
    func scanValue<T: FixedWidthInteger>(start: Int) -> T? {
        let length = MemoryLayout<T>.size
        guard self.count >= start + length else { return nil }
        var result: T = 0
        (self as NSData).getBytes(&result, range: NSRange(location: start, length: length))
        return result.littleEndian
    }
    
    func scanValue<T: FixedWidthInteger>(start: Int, as: T.Type) -> T? {
        let length = MemoryLayout<T>.size
        guard self.count >= start + length else { return nil }
        var result: T = 0
        (self as NSData).getBytes(&result, range: NSRange(location: start, length: length))
        return result.littleEndian
    }
}

extension InputStream {
    func readData(ofLength length: Int) throws -> Data {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { (p) -> Int in
            self.read(p, maxLength: length)
        }
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO, description: "Unknown stream error.")
        } else {
            data.count = result
            return data
        }
    }
}

extension OutputStream {
    func write(data: Data) throws -> Int {
        let count = data.count
        let result = data.withUnsafeBytes { (p) -> Int in
            self.write(p, maxLength: count)
        }
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO, description: "Unknown stream error.")
        } else {
            return result
        }
    }
}
