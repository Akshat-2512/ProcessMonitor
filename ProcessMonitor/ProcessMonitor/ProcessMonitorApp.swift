import SwiftUI

@main
struct ProcessMonitorApp: App {
    @State private var store = ProcessStore()

    var body: some Scene {
        MenuBarExtra {
            MainView(store: store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu bar icon + title

struct MenuBarLabel: View {
    var store: ProcessStore

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(store.running.isEmpty ? Color.secondary : Color.green)
                .frame(width: 7, height: 7)
            Text(store.menuBarTitle)
                .font(.system(size: 12))
        }
    }
}
