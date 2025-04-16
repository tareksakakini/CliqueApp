//
//  ImageSelectionField.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/14/25.
//

import SwiftUI
import PhotosUI

struct ImageSelectionField: View {
    let whichView: String
    var user: UserModel? = nil
    @Binding var imageSelection: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    var diameter: CGFloat? = nil
    var isPhone: Bool? = nil
    
    @State private var selectionProxy: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            PhotosPicker(selection: $selectionProxy, matching: .images) {
                if whichView == "EventImagePlaceholder" {
                    EventImagePlaceholder()
                } else if whichView == "SelectedEventImage" {
                    if let selectedImage {
                        SelectedEventImage(image: selectedImage)
                    }
                } else if whichView == "ProfilePictureView" {
                    if let user, let diameter, let isPhone {
                        ProfilePictureView(user: user, diameter: diameter, isPhone: isPhone, isViewingUser: true)
                    }
                }
            }
        }
        .task(id: selectionProxy) {
            await loadImage(from: selectionProxy)
            imageSelection = selectionProxy
        }
        .onAppear {
            selectionProxy = imageSelection
        }
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
            }
        } catch {
            print("Failed to load image data:", error)
        }
    }
}

#Preview {
    ImageSelectionField(whichView: "EventImagePlaceholder", imageSelection: .constant(nil), selectedImage: .constant(nil))
}
