import SwiftUI
import AudioEngine

@main
struct MetronomeApp: App {
    private let viewModel: MainMetronomeViewModel

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-PulsecraftUITestingInMemoryLibrary") {
            viewModel = MainMetronomeViewModel(audioEngine: AudioEngineStub(), libraryStore: nil)
        } else {
            viewModel = MainMetronomeViewModel()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainMetronomeView(viewModel: viewModel)
        }
    }
}
