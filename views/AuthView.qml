import QtQuick

Item {
    id: root

    property bool loading: false
    property bool isLogin: true

    Connections {
        target: AuthClient

        function onLoginSucceeded() {
            ToastManager.showSuccess("Successfully logged in")
            root.loading = false
        }

        function onLoginFailed(message) {
            ToastManager.showError(message)
            root.loading = false
        }

        function onSignupSucceeded() {
            ToastManager.showSuccess("Account created")
            root.loading = false
        }

        function onSignupFailed(message) {
            ToastManager.showError(message)
            root.loading = false
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#EEF2F6" }
            GradientStop { position: 1; color: "#E0E7EE" }
        }
    }

    AuthForm {
        anchors.centerIn: parent
        width: 380

        loading: root.loading

        isLogin: root.isLogin

        onLoginRequested: (email, pass) => {
            root.loading = true
            AuthClient.login(email, pass)
        }

        onSignupRequested: (email, username, pass) => {
            root.loading = true
            AuthClient.signup(email, username, pass)
        }

        onModeChanged: root.isLogin = !root.isLogin
    }
}
