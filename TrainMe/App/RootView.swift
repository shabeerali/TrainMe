//
//  RootView.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import SwiftUI

struct RootView: View {
    let container: AppContainer
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if container.session.user != nil {
                DashboardView(
                    viewModel: container.makeDashboardViewModel(),
                    makeDetailViewModel: { container.makeCourseDetailViewModel(for: $0) },
                    onLogout: { Task { await container.logout() } }
                )
            } else {
                LoginView(viewModel: container.makeLoginViewModel())
            }
        }
        // Opening the app (or returning to it) after the 30-minute token expired lands on Login.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { container.session.endSessionIfExpired() }
        }
    }
}
