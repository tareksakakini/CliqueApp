import SwiftUI
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let pdfName: String
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        if let path = Bundle.main.path(forResource: pdfName, ofType: "pdf"),
           let document = PDFDocument(url: URL(fileURLWithPath: path)) {
            pdfView.document = document
        }
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct PrivacyPolicyView: View {
    var body: some View {
        PDFViewer(pdfName: "privacy_policy")
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    PrivacyPolicyView()
}
