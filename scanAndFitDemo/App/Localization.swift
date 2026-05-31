import Foundation

extension String {
    //Returns the localized version of the string
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    // Localized string with format arguments
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

