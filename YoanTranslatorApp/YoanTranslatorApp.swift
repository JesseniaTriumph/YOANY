import ManuscriptCore
import ManuscriptAppShell
import SwiftUI

@main
struct YoanTranslatorApp: App {
    var body: some Scene {
        WindowGroup {
            NativeAppRootView()
        }
    }
}

private struct NativeAppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var securityModel = NativeAppSecurityModel()

    var body: some View {
        ZStack {
            AppShellView()

            if securityModel.shouldObscureSnapshots {
                Color.black
                    .ignoresSafeArea()
                    .overlay(alignment: .center) {
                        VStack(spacing: 12) {
                            Text("Protected")
                                .font(.title.weight(.semibold))
                            Text(securityModel.statusText)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding(24)
                    }
                    .transition(.opacity)
            }
        }
        .task {
            await securityModel.refreshState()
        }
        .onChange(of: scenePhase) { _, newValue in
            Task {
                await securityModel.handle(scenePhase: newValue)
            }
        }
    }
}

@MainActor
private final class NativeAppSecurityModel: ObservableObject {
    @Published private(set) var shouldObscureSnapshots = false
    @Published private(set) var statusText = "Local manuscript content is hidden while the app is not active."

    private let coordinator = AppLifecycleSecurityCoordinator()

    func handle(scenePhase: ScenePhase) async {
        let mappedPhase: AppScenePhaseState
        switch scenePhase {
        case .active:
            mappedPhase = .active
        case .inactive:
            mappedPhase = .inactive
        case .background:
            mappedPhase = .background
        @unknown default:
            mappedPhase = .inactive
        }

        await coordinator.scenePhaseChanged(mappedPhase)
        await refreshState()
    }

    func refreshState() async {
        let state = await coordinator.state()
        shouldObscureSnapshots = state.shouldObscureSnapshots
        if let reason = state.lastLockReason {
            statusText = lockMessage(for: reason)
        } else {
            statusText = "Local manuscript content is hidden while the app is not active."
        }
    }

    private func lockMessage(for reason: AppLockReason) -> String {
        switch reason {
        case .backgrounded:
            "The active manuscript was locked because the app moved to the background."
        case .inactivityTimeout:
            "The active manuscript was locked after inactivity."
        case .authenticationInvalidated:
            "The active manuscript was locked because device authentication changed."
        case .deviceLocked:
            "The active manuscript was locked because the device was locked."
        case .manualLock:
            "The active manuscript was manually locked."
        }
    }
}
