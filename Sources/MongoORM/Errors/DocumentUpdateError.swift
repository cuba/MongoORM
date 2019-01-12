//
//  DocumentUpdateError.swift
//  App
//
//  Created by Jacob Sikorski on 2018-12-05.
//

import Foundation

public enum DocumentUpdateError: Error, CustomStringConvertible {
    case missingObjectId
    case unknown(id: String)
    
    public var description: String {
        switch self {
        case .missingObjectId  : return "Could not update the document because it is not saved"
        case .unknown(let id)   : return "Failed to update document \(id) for an unknown reason"
        }
    }
}
