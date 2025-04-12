//
//  BackNavigation.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/11/25.
//

import SwiftUI

struct BackNavigation: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                    Text("Back")
                        .font(.system(size: 20))
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

#Preview {
    BackNavigation()
}
