import SwiftUI

struct EventImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var minimumAllowedScale: CGFloat = 1.0
    @State private var viewSize: CGSize = .zero
    
    // Constants for better UX - rectangular crop for events
    private let cropSize = CGSize(width: 320, height: 200) // 16:10 aspect ratio
    private let maxScale: CGFloat = 4.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black.ignoresSafeArea()
                    
                    // Main image container
                    ZStack {
                        // The actual image
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
                                            scale = min(max(newScale, minimumAllowedScale), maxScale)
                                            offset = constrainOffset(offset, in: geometry.size)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            lastOffset = offset
                                        }
                                )
                            )
                        
                        // Crop overlay with rectangular preview
                        EventImageCropOverlay(
                            cropSize: cropSize,
                            screenSize: geometry.size
                        )
                        .allowsHitTesting(false)
                    }
                }
                .onAppear {
                    configureScale(in: geometry.size, shouldReset: true)
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    guard oldValue != newValue else { return }
                    configureScale(in: newValue, shouldReset: false)
                }
            }
            .navigationTitle("Crop Event Picture")
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
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureScale(in screenSize: CGSize, shouldReset: Bool) {
        guard screenSize.width > 0, screenSize.height > 0 else { return }
        
        viewSize = screenSize
        
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height
        
        // Calculate how the image is displayed
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        
        if imageAspectRatio > screenAspectRatio {
            displayWidth = screenSize.width
            displayHeight = screenSize.width / imageAspectRatio
        } else {
            displayHeight = screenSize.height
            displayWidth = screenSize.height * imageAspectRatio
        }
        
        // Calculate scale needed to fill the crop area
        let scaleToFitWidth = cropSize.width / displayWidth
        let scaleToFitHeight = cropSize.height / displayHeight
        let requiredScale = max(scaleToFitWidth, scaleToFitHeight)
        
        minimumAllowedScale = min(requiredScale, maxScale)
        
        if shouldReset {
            let initialScale = min(max(requiredScale * 1.05, minimumAllowedScale), maxScale)
            scale = initialScale
            lastScale = initialScale
            offset = .zero
            lastOffset = .zero
        } else if scale < minimumAllowedScale {
            scale = minimumAllowedScale
            lastScale = minimumAllowedScale
            offset = constrainOffset(offset, in: screenSize)
            lastOffset = offset
        } else {
            offset = constrainOffset(offset, in: screenSize)
            lastOffset = offset
        }
    }
    
    private func constrainOffset(_ proposedOffset: CGSize, in screenSize: CGSize) -> CGSize {
        // Calculate the actual displayed image size using the same logic as cropImage()
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height
        
        // Determine how the image is displayed (aspect fit)
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        
        if imageAspectRatio > screenAspectRatio {
            // Image is wider relative to screen - fit to width
            displayWidth = screenSize.width
            displayHeight = screenSize.width / imageAspectRatio
        } else {
            // Image is taller relative to screen - fit to height
            displayHeight = screenSize.height
            displayWidth = screenSize.height * imageAspectRatio
        }
        
        // Apply current scale
        let scaledWidth = displayWidth * scale
        let scaledHeight = displayHeight * scale
        
        // Calculate maximum allowed offset to keep crop area filled
        let maxOffsetX = max(0, (scaledWidth - cropSize.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - cropSize.height) / 2)
        
        // Constrain the offset
        let constrainedWidth = max(proposedOffset.width, -maxOffsetX)
        let finalWidth = min(constrainedWidth, maxOffsetX)
        
        let constrainedHeight = max(proposedOffset.height, -maxOffsetY)
        let finalHeight = min(constrainedHeight, maxOffsetY)
        
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    private func cropImage() {
        let imageSize = image.size
        let outputSize = CGSize(width: 640, height: 400) // Final event image size (16:10 ratio)
        let workingScale = max(scale, minimumAllowedScale)
        
        // Get the actual screen size being used for display
        let screenSize = viewSize == .zero ? UIScreen.main.bounds.size : viewSize
        
        // Calculate how the image is actually displayed (aspect fit within screen)
        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height
        
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        
        if imageAspectRatio > screenAspectRatio {
            // Image is wider relative to screen - fit to width
            displayWidth = screenSize.width
            displayHeight = screenSize.width / imageAspectRatio
        } else {
            // Image is taller relative to screen - fit to height
            displayHeight = screenSize.height
            displayWidth = screenSize.height * imageAspectRatio
        }
        
        // Calculate the scale factor from displayed image to actual image
        let imageToDisplayScale = min(displayWidth / imageSize.width, displayHeight / imageSize.height)
        
        // Calculate the crop rectangle in the original image coordinates
        // The crop size in image coordinates, accounting for user's zoom
        let cropWidthInImage = cropSize.width / (imageToDisplayScale * workingScale)
        let cropHeightInImage = cropSize.height / (imageToDisplayScale * workingScale)
        
        // Calculate the center point in image coordinates, accounting for user's pan
        let imageCenterX = imageSize.width / 2
        let imageCenterY = imageSize.height / 2
        
        // Convert the user's offset to image coordinates
        let offsetXInImage = offset.width / (imageToDisplayScale * workingScale)
        let offsetYInImage = offset.height / (imageToDisplayScale * workingScale)
        
        // Calculate the crop rectangle center
        let cropCenterX = imageCenterX - offsetXInImage
        let cropCenterY = imageCenterY - offsetYInImage
        
        // Define the crop rectangle
        let cropRect = CGRect(
            x: cropCenterX - cropWidthInImage / 2,
            y: cropCenterY - cropHeightInImage / 2,
            width: cropWidthInImage,
            height: cropHeightInImage
        )
        
        // Ensure crop rect is within image bounds
        let clampedCropRect = CGRect(
            x: max(0, min(cropRect.origin.x, imageSize.width - cropRect.width)),
            y: max(0, min(cropRect.origin.y, imageSize.height - cropRect.height)),
            width: min(cropRect.width, imageSize.width),
            height: min(cropRect.height, imageSize.height)
        )
        
        // Perform the crop
        guard let cgImage = image.cgImage?.cropping(to: clampedCropRect) else {
            // Fallback
            let fallbackImage = resizeImageToRectangle(image, to: outputSize)
            onCrop(fallbackImage)
            return
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        let finalImage = resizeImageToRectangle(croppedImage, to: outputSize)
        
        onCrop(finalImage)
    }
    
    private func resizeImageToRectangle(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Draw the image to fill the rectangle
            image.draw(in: rect)
        }
    }
} 
