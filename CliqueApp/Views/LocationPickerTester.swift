import SwiftUI
import MapKit

struct LocationPickerView: View {
    @StateObject private var viewModel = LocationPickerViewModel()

    var body: some View {
        VStack {
            TextField("Search for a location", text: $viewModel.query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: viewModel.query) { _ in
                    viewModel.searchForLocations()
                }
            
            if !viewModel.suggestions.isEmpty {
                List(viewModel.suggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.selectLocation(suggestion)
                    }) {
                        Text(suggestion)
                    }
                }
                .frame(maxHeight: 200) // Limit dropdown height
            }
            
            if let selectedLocation = viewModel.selectedLocation {
                Text("Selected: \(selectedLocation)")
                    .font(.headline)
                    .padding()
            }
        }
        .padding()
    }
}

class LocationPickerViewModel: NSObject, ObservableObject {
    @Published var query = ""
    @Published var suggestions: [String] = []
    @Published var selectedLocation: String?

    private var searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }

    func searchForLocations() {
        searchCompleter.queryFragment = query
    }

    func selectLocation(_ location: String) {
        selectedLocation = location
        query = location // Fill text field with selected location
        suggestions.removeAll() // Hide dropdown after selection
    }
}

extension LocationPickerViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = completer.results.map { $0.title }
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error searching locations: \(error)")
    }
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPickerView()
    }
}

