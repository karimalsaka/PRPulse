import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
    }

    func configure() {
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            self.center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    func fetchNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in
            completion(settings)
        }
    }

    func processUpdates(pullRequests: [PullRequest], currentUserLogin: String?) {
        let normalizedLogin = currentUserLogin?.lowercased() ?? ""
        if !NotificationPreferences.baselineEstablished {
            establishBaseline(for: pullRequests)
            NotificationPreferences.baselineEstablished = true
            return
        }

        for pr in pullRequests {
            let prKey = makePRKey(for: pr)

            handleCommentNotifications(for: pr, prKey: prKey, currentUserLogin: normalizedLogin)
            handleReviewNotifications(for: pr, prKey: prKey, currentUserLogin: normalizedLogin)

            updateLastSeenMarkers(for: pr, prKey: prKey)
        }
    }

    private func establishBaseline(for pullRequests: [PullRequest]) {
        for pr in pullRequests {
            let prKey = makePRKey(for: pr)
            updateLastSeenMarkers(for: pr, prKey: prKey)
        }
    }

    private func handleCommentNotifications(for pr: PullRequest, prKey: String, currentUserLogin: String) {
        guard hasLastSeen(prefix: NotificationPreferences.Keys.lastSeenCommentPrefix, prKey: prKey) else { return }
        let lastSeen = lastSeenDate(prefix: NotificationPreferences.Keys.lastSeenCommentPrefix, prKey: prKey)
        let newComments = pr.recentComments
            .filter { $0.createdAt > lastSeen }
            .filter { !isFromSelf(author: $0.author, currentUserLogin: currentUserLogin) }

        guard NotificationPreferences.notifyComments, !newComments.isEmpty else { return }

        let latest = newComments.max(by: { $0.createdAt < $1.createdAt }) ?? newComments[0]
        let count = newComments.count
        let body: String
        if count == 1 {
            body = "New comment by \(latest.author): \(latest.preview)"
        } else {
            body = "\(count) new comments. Latest by \(latest.author): \(latest.preview)"
        }
        scheduleNotification(
            id: "comment-\(prKey)-\(latest.id)",
            title: "\(pr.repoName) #\(pr.number)",
            body: body
        )
    }

    private func handleReviewNotifications(for pr: PullRequest, prKey: String, currentUserLogin: String) {
        guard hasLastSeen(prefix: NotificationPreferences.Keys.lastSeenReviewPrefix, prKey: prKey) else { return }
        let lastSeen = lastSeenDate(prefix: NotificationPreferences.Keys.lastSeenReviewPrefix, prKey: prKey)
        let newReviews = pr.recentReviews
            .filter { $0.createdAt > lastSeen }
            .filter { !isFromSelf(author: $0.author, currentUserLogin: currentUserLogin) }

        guard NotificationPreferences.notifyReviews, !newReviews.isEmpty else { return }

        let latest = newReviews.max(by: { $0.createdAt < $1.createdAt }) ?? newReviews[0]
        let count = newReviews.count
        let body: String
        if count == 1 {
            body = "\(latest.label) review by \(latest.author)"
        } else {
            body = "\(count) new reviews. Latest: \(latest.label) by \(latest.author)"
        }
        scheduleNotification(
            id: "review-\(prKey)-\(latest.id)",
            title: "\(pr.repoName) #\(pr.number)",
            body: body
        )
    }

    private func updateLastSeenMarkers(for pr: PullRequest, prKey: String) {
        if pr.recentComments.isEmpty && !hasLastSeen(prefix: NotificationPreferences.Keys.lastSeenCommentPrefix, prKey: prKey) {
            setLastSeenDate(prefix: NotificationPreferences.Keys.lastSeenCommentPrefix, prKey: prKey, date: Date())
        }
        if let latestComment = pr.recentComments.max(by: { $0.createdAt < $1.createdAt }) {
            setLastSeenDate(prefix: NotificationPreferences.Keys.lastSeenCommentPrefix, prKey: prKey, date: latestComment.createdAt)
        }

        if pr.recentReviews.isEmpty && !hasLastSeen(prefix: NotificationPreferences.Keys.lastSeenReviewPrefix, prKey: prKey) {
            setLastSeenDate(prefix: NotificationPreferences.Keys.lastSeenReviewPrefix, prKey: prKey, date: Date())
        }
        if let latestReview = pr.recentReviews.max(by: { $0.createdAt < $1.createdAt }) {
            setLastSeenDate(prefix: NotificationPreferences.Keys.lastSeenReviewPrefix, prKey: prKey, date: latestReview.createdAt)
        }
    }

    private func makePRKey(for pr: PullRequest) -> String {
        let repoKey = pr.repoFullName.replacingOccurrences(of: "/", with: "-")
        return "\(repoKey)-\(pr.number)"
    }

    private func isFromSelf(author: String, currentUserLogin: String) -> Bool {
        guard !currentUserLogin.isEmpty else { return false }
        return author.lowercased() == currentUserLogin
    }

    private func lastSeenDate(prefix: String, prKey: String) -> Date {
        let key = prefix + prKey
        let stored = UserDefaults.standard.double(forKey: key)
        return Date(timeIntervalSince1970: stored)
    }

    private func hasLastSeen(prefix: String, prKey: String) -> Bool {
        let key = prefix + prKey
        return UserDefaults.standard.object(forKey: key) != nil
    }

    private func setLastSeenDate(prefix: String, prKey: String, date: Date) {
        let key = prefix + prKey
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: key)
    }

    private func scheduleNotification(id: String, title: String, body: String, delay: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Notification scheduling failed: \(error.localizedDescription)")
            }
        }
    }

    func scheduleTestNotification() {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound]) { _, _ in
                    self.scheduleNotification(
                        id: "debug-test-\(UUID().uuidString)",
                        title: "PRPulse Test Notification",
                        body: "This is a test notification.",
                        delay: 3
                    )
                }
                return
            }

            self.scheduleNotification(
                id: "debug-test-\(UUID().uuidString)",
                title: "PRPulse Test Notification",
                body: "This is a test notification.",
                delay: 3
            )
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
