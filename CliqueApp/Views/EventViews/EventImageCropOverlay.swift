import SwiftUI

struct EventImageCropOverlay: View {
    let cropSize: CGSize
    let screenSize: CGSize
    
    private var darkOverlayWithCutout: some View {
        ZStack {
            // Dark overlay covering the entire screen
            Color.black.opacity(0.6)
            
            // Clear rectangle for the crop area (16:10 aspect ratio for events)
            RoundedRectangle(cornerRadius: 8)
                .frame(width: cropSize.width, height: cropSize.height)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
    
    private var borderElements: some View {
        ZStack {
            // Outer border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                .frame(width: cropSize.width, height: cropSize.height)
            
            // Inner border for better visibility
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .frame(width: cropSize.width - 6, height: cropSize.height - 6)
            
            // Corner indicators (positioned at the four corners)
            cornerIndicators
        }
    }
    
    private var cornerIndicators: some View {
        let cornerOffset: CGFloat = 12
        let indicatorLength: CGFloat = 20
        let indicatorWidth: CGFloat = 3
        
        return ZStack {
            // Top-left corner
            Group {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorLength, height: indicatorWidth)
                    .offset(x: -cropSize.width/2 + indicatorLength/2 - cornerOffset, y: -cropSize.height/2 - cornerOffset)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorWidth, height: indicatorLength)
                    .offset(x: -cropSize.width/2 - cornerOffset, y: -cropSize.height/2 + indicatorLength/2 - cornerOffset)
            }
            
            // Top-right corner
            Group {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorLength, height: indicatorWidth)
                    .offset(x: cropSize.width/2 - indicatorLength/2 + cornerOffset, y: -cropSize.height/2 - cornerOffset)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorWidth, height: indicatorLength)
                    .offset(x: cropSize.width/2 + cornerOffset, y: -cropSize.height/2 + indicatorLength/2 - cornerOffset)
            }
            
            // Bottom-left corner
            Group {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorLength, height: indicatorWidth)
                    .offset(x: -cropSize.width/2 + indicatorLength/2 - cornerOffset, y: cropSize.height/2 + cornerOffset)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorWidth, height: indicatorLength)
                    .offset(x: -cropSize.width/2 - cornerOffset, y: cropSize.height/2 - indicatorLength/2 + cornerOffset)
            }
            
            // Bottom-right corner
            Group {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorLength, height: indicatorWidth)
                    .offset(x: cropSize.width/2 - indicatorLength/2 + cornerOffset, y: cropSize.height/2 + cornerOffset)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: indicatorWidth, height: indicatorLength)
                    .offset(x: cropSize.width/2 + cornerOffset, y: cropSize.height/2 - indicatorLength/2 + cornerOffset)
            }
        }
        .opacity(0.8)
    }
    
    var body: some View {
        ZStack {
            // Dark overlay with rectangular cutout
            darkOverlayWithCutout
            
            // Border and corner indicators
            borderElements
            
            // Instructions text
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Pan")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Pinch to Zoom")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.bottom, 60)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    EventImageCropOverlay(
        cropSize: CGSize(width: 320, height: 200),
        screenSize: CGSize(width: 393, height: 852)
    )
}

