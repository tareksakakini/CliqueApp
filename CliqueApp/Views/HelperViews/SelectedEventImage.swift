//
//  SelectedEventImage.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/15/25.
//

import SwiftUI

struct SelectedEventImage: View {
    let image: UIImage
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .cornerRadius(10)
            .padding()
    }
}
