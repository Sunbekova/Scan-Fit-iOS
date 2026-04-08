import SwiftUI
import SwiftData

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case profileIncomplete
    case authenticated
}
