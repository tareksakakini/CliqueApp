//
//  ImageCropperView.swift
//  CliqueApp
//
//  Created by AI Assistant on 4/25/25.
//

import SwiftUI

struct ImageCropperView: View {
    let image: UIImage
    let cropSize: CGSize
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        // Instructions
                        Text("Move and pinch to adjust")
                            .foregroundColor(.white)
                            .font(.subheadline)
                            .padding(.top, 20)
                        
                        Spacer()
                        
                        // Crop area
                        ZStack {
                            // Image
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        // Pan gesture
                                        DragGesture()
                                            .onChanged { value in
                                                let newOffset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                                offset = constrainOffset(newOffset, in: geometry.size)
                                            }
                                            .onEnded { _ in
                                                lastOffset = offset
                                            },
                                        
                                        // Zoom gesture
                                        MagnificationGesture()
                                            .onChanged { value in
                                                let newScale = lastScale * value
                                                scale = min(max(newScale, minScale), maxScale)
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                                // Adjust offset to keep image within bounds
                                                offset = constrainOffset(offset, in: geometry.size)
                                                lastOffset = offset
                                            }
                                    )
                                )
                            
                            // Crop overlay
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: cropSize.width, height: cropSize.height)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cropSize.width / 2)
                                        .stroke(Color.white, lineWidth: 2)
                                        .shadow(color: Color.black.opacity(0.5), radius: 5)
                                )
                            
                            // Dimming overlay
                            Rectangle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .mask(
                                    Rectangle()
                                        .overlay(
                                            Circle()
                                                .frame(width: cropSize.width, height: cropSize.height)
                                                .blendMode(.destinationOut)
                                        )
                                )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func constrainOffset(_ newOffset: CGSize, in containerSize: CGSize) -> CGSize {
        let imageSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        let maxOffsetX = max(0, (imageSize.width - cropSize.width) / 2)
        let maxOffsetY = max(0, (imageSize.height - cropSize.height) / 2)
        
        return CGSize(
            width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
            height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
        )
    }
    
    private func cropImage() {
        let renderer = UIGraphicsImageRenderer(size: cropSize)
        
        let croppedImage = renderer.image { context in
            // Create circular clipping path first
            let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: cropSize))
            path.addClip()
            
            // Calculate the image display size (accounting for aspect fit)
            let imageAspectRatio = image.size.width / image.size.height
            let cropAspectRatio = cropSize.width / cropSize.height
            
            var displaySize: CGSize
            if imageAspectRatio > cropAspectRatio {
                // Image is wider - fit to height
                displaySize = CGSize(width: cropSize.height * imageAspectRatio, height: cropSize.height)
            } else {
                // Image is taller - fit to width
                displaySize = CGSize(width: cropSize.width, height: cropSize.width / imageAspectRatio)
            }
            
            // Apply user's scale
            let scaledSize = CGSize(
                width: displaySize.width * scale,
                height: displaySize.height * scale
            )
            
            // Calculate the position to draw the image (centered, then offset by user's pan)
            let drawRect = CGRect(
                x: (cropSize.width - scaledSize.width) / 2 + offset.width,
                y: (cropSize.height - scaledSize.height) / 2 + offset.height,
                width: scaledSize.width,
                height: scaledSize.height
            )
            
            // Draw the image
            image.draw(in: drawRect)
        }
        
        onCrop(croppedImage)
    }
}

#Preview {
    ImageCropperView(
        image: UIImage(systemName: "person.fill") ?? UIImage(),
        cropSize: CGSize(width: 200, height: 200),
        onCrop: { _ in },
        onCancel: { }
    )
} 