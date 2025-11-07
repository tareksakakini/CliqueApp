import SwiftUI
import ContactsUI
import MessageUI

// MARK: - Contact Data Structure
struct ContactInfo: Equatable {
    let name: String
    let phoneNumber: String
}

// MARK: - Contact Picker Wrapper
struct ContactPicker: UIViewControllerRepresentable {
    var onSelect: ([String]) -> Void
    var onSelectWithNames: (([ContactInfo]) -> Void)?

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker

        init(parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let numbers = contact.phoneNumbers.map { $0.value.stringValue }
            let contactName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let displayName = contactName.isEmpty ? "Unknown Contact" : contactName
            
            if !numbers.isEmpty {
                // Call the old callback for backward compatibility
                parent.onSelect(numbers)
                
                // Call the new callback with contact info
                if let onSelectWithNames = parent.onSelectWithNames {
                    let contactInfos = numbers.map { ContactInfo(name: displayName, phoneNumber: $0) }
                    onSelectWithNames(contactInfos)
                }
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {}
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
}


// MARK: - Message Composer Wrapper
struct MessageComposer: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    var onFinish: (MessageComposeResult) -> Void  // closure with result parameter

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposer

        init(parent: MessageComposer) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            parent.onFinish(result)  // pass the result to the callback
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = context.coordinator
        composer.recipients = recipients
        composer.body = body
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}
