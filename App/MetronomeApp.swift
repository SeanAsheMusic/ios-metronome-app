import SwiftUI
import AudioEngine

@main
struct MetronomeApp: App {
    private let viewModel: MainMetronomeViewModel
    private let initialTab: String
    private let showsStagePulseOnLaunch: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        initialTab = Self.argumentValue(after: "-PulsecraftInitialTab", in: arguments) ?? "play"
        showsStagePulseOnLaunch = arguments.contains("-PulsecraftShowStagePulse")
        if arguments.contains("-PulsecraftUITestingInMemoryLibrary") {
            viewModel = MainMetronomeViewModel(audioEngine: AudioEngineStub(), libraryStore: nil)
        } else {
            viewModel = MainMetronomeViewModel()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainMetronomeView(
                viewModel: viewModel,
                initialTab: initialTab,
                showsStagePulseOnLaunch: showsStagePulseOnLaunch
            )
        }
    }

    private static func argumentValue(after name: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: name) else {
            return nil
        }

        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        return arguments[valueIndex]
    }
}
