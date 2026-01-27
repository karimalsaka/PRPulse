import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .welcome
    @Published var tokenInput: String = ""
    @Published var isValidating: Bool = false
    @Published var validationResult: TokenValidationService.TokenValidationResult?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Dependencies

    private let tokenValidationService: TokenValidationService
    private let tokenManager: TokenManager

    // MARK: - Computed Properties

    var canProceedToTokenInput: Bool {
        currentStep == .welcome
    }

    var canValidateToken: Bool {
        !tokenInput.trimmingCharacters(in: .whitespaces).isEmpty && !isValidating
    }

    var shouldShowValidationResult: Bool {
        validationResult != nil
    }

    var canCompleteOnboarding: Bool {
        guard let result = validationResult else { return false }
        return result.hasMinimumPermissions
    }

    // MARK: - Initialization

    init(
        tokenValidationService: TokenValidationService = TokenValidationService(),
        tokenManager: TokenManager = .shared
    ) {
        self.tokenValidationService = tokenValidationService
        self.tokenManager = tokenManager
    }

    // MARK: - Navigation Actions

    func proceedToInstructions() {
        currentStep = .instructions
    }

    func proceedToTokenInput() {
        currentStep = .tokenInput
    }

    func goBack() {
        switch currentStep {
        case .welcome:
            break
        case .instructions:
            currentStep = .welcome
        case .tokenInput:
            currentStep = .instructions
        case .validation:
            currentStep = .tokenInput
            validationResult = nil
        }
    }

    // MARK: - Token Actions

    func validateToken() {
        guard canValidateToken else { return }

        let trimmedToken = tokenInput.trimmingCharacters(in: .whitespaces)

        Task {
            isValidating = true
            errorMessage = ""
            showError = false

            let result = await tokenValidationService.validateToken(trimmedToken)
            validationResult = result
            currentStep = .validation

            if !result.isValid {
                errorMessage = "Token validation failed. Please check your token and try again."
                showError = true
            }

            isValidating = false
        }
    }

    func saveTokenAndComplete() {
        guard let result = validationResult,
              result.hasMinimumPermissions else {
            errorMessage = "Cannot save token without minimum required permissions."
            showError = true
            return
        }

        let trimmedToken = tokenInput.trimmingCharacters(in: .whitespaces)
        _ = tokenManager.saveToken(trimmedToken)
    }

    func continueWithLimitedPermissions() {
        guard let result = validationResult,
              result.hasMinimumPermissions else {
            errorMessage = "Cannot continue without minimum required permissions."
            showError = true
            return
        }

        saveTokenAndComplete()
    }

    func openGitHubTokenSettings() {
        if let url = URL(string: "https://github.com/settings/tokens/new") {
            NSWorkspace.shared.open(url)
        }
    }

    func openGitHubFineGrainedTokenSettings() {
        if let url = URL(string: "https://github.com/settings/personal-access-tokens/new") {
            NSWorkspace.shared.open(url)
        }
    }

    func resetOnboarding() {
        currentStep = .welcome
        tokenInput = ""
        validationResult = nil
        errorMessage = ""
        showError = false
    }
}

// MARK: - Onboarding Step

enum OnboardingStep {
    case welcome
    case instructions
    case tokenInput
    case validation
}
