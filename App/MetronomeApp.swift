import SwiftUI
import AudioEngine

@main
struct MetronomeApp: App {
    private let viewModel: MainMetronomeViewModel
    private let initialTab: String
    private let showsStagePulseOnLaunch: Bool
    private let skipsSetupOnLaunch: Bool
    private let forcesSetupOnLaunch: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        initialTab = Self.argumentValue(after: "-ClickTrackInitialTab", in: arguments)
            ?? Self.argumentValue(after: "-PulsecraftInitialTab", in: arguments)
            ?? "play"
        showsStagePulseOnLaunch = arguments.contains("-ClickTrackShowStagePulse") || arguments.contains("-PulsecraftShowStagePulse")
        skipsSetupOnLaunch = arguments.contains("-ClickTrackUITestingInMemoryLibrary") || arguments.contains("-PulsecraftUITestingInMemoryLibrary") || arguments.contains("-ClickTrackSkipSetup")
        forcesSetupOnLaunch = arguments.contains("-ClickTrackShowSetup")
        if arguments.contains("-ClickTrackUITestingInMemoryLibrary") || arguments.contains("-PulsecraftUITestingInMemoryLibrary") {
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
                showsStagePulseOnLaunch: showsStagePulseOnLaunch,
                skipsSetupOnLaunch: skipsSetupOnLaunch,
                forcesSetupOnLaunch: forcesSetupOnLaunch
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
