//
//  ImageSelectionField.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/14/25.
//

import SwiftUI
import PhotosUI

struct ImageSelectionField: View {
    @Binding var imageSelection: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    
    @State private var selectionProxy: PhotosPickerItem? = nil

    var body: some View {
        ZStack {
            PhotosPicker(selection: $selectionProxy, matching: .images) {
                if let image = selectedImage {
                    selectedImageView(image)
                } else {
                    placeholderView
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
    
    private func selectedImageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .cornerRadius(10)
            .padding()
    }
    
    private var placeholderView: some View {
        ZStack {
            Color(.white.opacity(0.7))
            VStack {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .padding()
                Text("Add Event Picture")
                    .bold()
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
        .cornerRadius(10)
        .foregroundColor(Color(.accent))
        .padding()
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
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
    ImageSelectionField(imageSelection: .constant(nil), selectedImage: .constant(nil))
}
