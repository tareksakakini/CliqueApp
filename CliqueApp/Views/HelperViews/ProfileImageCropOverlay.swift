import SwiftUI

struct ProfileImageCropOverlay: View {
    let cropSize: CGSize
    let screenSize: CGSize
    
    private var darkOverlayWithCutout: some View {
        ZStack {
            // Dark overlay covering the entire screen
            Color.black.opacity(0.6)
            
            // Clear circle for the crop area
            Circle()
                .frame(width: cropSize.width, height: cropSize.height)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
    
    private var borderElements: some View {
        ZStack {
            // Outer border
            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                .frame(width: cropSize.width, height: cropSize.height)
            
            // Inner border for better visibility
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                .frame(width: cropSize.width - 6, height: cropSize.height - 6)
            
            // Corner indicators (positioned around the circle)
            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) * 45.0 * .pi / 180.0
                let radius = cropSize.width / 2 + 15
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(x: x, y: y)
                    .opacity(0.8)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dark overlay with circular cutout
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
    ProfileImageCropOverlay(
        cropSize: CGSize(width: 300, height: 300),
        screenSize: CGSize(width: 393, height: 852)
    )
} 