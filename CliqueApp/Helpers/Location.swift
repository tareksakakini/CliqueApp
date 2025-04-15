//
//  LocationHelper.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/13/25.
//

import Foundation
import MapKit

class LocationSearchHelper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private var searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest] // Focus only on addresses
    }
    
    func updateSearchResults(for query: String) {
        searchCompleter.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = Array(completer.results.prefix(3))
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error fetching suggestions: \(error.localizedDescription)")
    }
}
