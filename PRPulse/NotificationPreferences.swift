import Foundation

enum NotificationPreferences {
    enum Keys {
        static let notifyComments = "notify.comments"
        static let notifyReviews = "notify.reviews"
        static let baselineEstablished = "notify.baselineEstablished"
        static let lastSeenCommentPrefix = "notify.lastSeen.comment."
        static let lastSeenReviewPrefix = "notify.lastSeen.review."
    }

    static var notifyComments: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notifyComments) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notifyComments) }
    }

    static var notifyReviews: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.notifyReviews) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.notifyReviews) }
    }

    static var baselineEstablished: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.baselineEstablished) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.baselineEstablished) }
    }
}
