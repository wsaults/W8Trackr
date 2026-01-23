//
//  ShareableProgressImage.swift
//  W8Trackr
//
//  Transferable wrapper for UIImage to enable sharing via ShareLink.
//

import SwiftUI
import UniformTypeIdentifiers

/// Transferable wrapper for sharing progress images
struct ShareableProgressImage: Transferable {
    let image: UIImage
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { shareableImage in
            guard let data = shareableImage.image.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}
