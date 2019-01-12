//
//  DocumentLoadError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-11-26.
//

import Foundation

public enum DocumentLoadError: Error, CustomStringConvertible {
    case documentNotFound
    case failedToDeserialize(cause: Error)
    case unknown()
    
    public var description: String {
        switch self {
        case .documentNotFound:
            return "Document not found."
        case .failedToDeserialize(let cause):
            if let error = cause as? LocalizedError {
                return "Could not deserialize the object. \(error.localizedDescription)"
            } else {
                return "Could not deserialize the object. \(String(describing: cause))"
            }
        case .unknown:
            return "Failed to load the document for an unknown reason"
        }
    }
}
