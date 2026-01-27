import Foundation

struct PermissionsState {
    var canReadPullRequests: Bool = true
    var canReadCommitStatuses: Bool = true
    var canReadReviews: Bool = true
    var canReadComments: Bool = true

    var hasAllPermissions: Bool {
        canReadPullRequests && canReadCommitStatuses && canReadReviews && canReadComments
    }

    var missingPermissions: [String] {
        var missing: [String] = []
        if !canReadPullRequests { missing.append("Pull Requests") }
        if !canReadCommitStatuses { missing.append("CI/CD Status") }
        if !canReadReviews { missing.append("Reviews") }
        if !canReadComments { missing.append("Comments") }
        return missing
    }

    static func from(validationResult: TokenValidationService.TokenValidationResult) -> PermissionsState {
        PermissionsState(
            canReadPullRequests: validationResult.canReadPullRequests.status == .granted,
            canReadCommitStatuses: validationResult.canReadCommitStatuses.status == .granted,
            canReadReviews: validationResult.canReadReviews.status == .granted,
            canReadComments: validationResult.canReadComments.status == .granted
        )
    }
}
