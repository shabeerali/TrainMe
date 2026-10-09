//
//  LoginView.swift
//  TrainMe
//
//  Created by ShabeerAli K on 08/10/26.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                VStack(alignment: .leading, spacing: 16) {
                    field(title: Constants.Presentation.emailPlaceholder, error: viewModel.emailError) {
                        TextField(Constants.Presentation.emailPlaceholder, text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }

                    field(title: Constants.Presentation.passPlaceHolder, error: viewModel.passwordError) {
                        SecureField(Constants.Presentation.passPlaceHolder, text: $viewModel.password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit { submit() }
                    }
                }
                
             
                if case .failed(let message) = viewModel.state {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }

                Button(action: submit) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(Constants.Presentation.loginMsg).fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isLoading)

                Text(Constants.Presentation.demoAccount + MockAuthService.demoEmail + MockAuthService.demoPassword)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(Constants.Presentation.trainMe).font(.largeTitle.bold())
            Text(Constants.Presentation.loginToContinueMsg).foregroundStyle(.secondary)
        }
        .padding(.top, 48)
    }

    private func field<Content: View>(title: String, error: String?,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            content()
                .padding(12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(error == nil ? Color.clear : Color.red, lineWidth: 1)
                )
            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }

    private func submit() {
        focusedField = nil
        Task { await viewModel.login() }
    }
}
