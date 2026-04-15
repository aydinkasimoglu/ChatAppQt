pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic

ApplicationWindow {
    id: appWindow

    width: 1280
    height: 720
    minimumWidth: 500
    minimumHeight: 300
    visible: true
    title: "ChatApp"

    Toast {
        id: globalToast
    }

    Connections {
        target: ToastManager

        function onTriggerToast(message, isError) {
            globalToast.show(message, isError)
        }
    }

    Connections {
        target: AuthClient

        function onAuthenticationChanged() {
            console.log("Authentication state changed. Is authenticated:", AuthClient.isAuthenticated)
            if (!AuthClient.isAuthenticated) {
                PresenceManager.disconnectFromServer()
                DmManager.resetState()
            }
        }

        function onUserLoaded() {
            PresenceManager.connectToServer()
        }

        function onUserLoadFailed(message) {
            ToastManager.showError(message)
        }
    }

    Connections {
        target: PresenceManager

        function onDmMessageReceived(conversationId, message) {
            DmManager.handleIncomingMessage(conversationId, message)
        }
    }

    // Show MainMenu if authenticated AND user data loaded
    // Show LoadingScreen if authenticated but data still loading
    // Show AuthView if not authenticated
    Loader {
        anchors.fill: parent
        sourceComponent: {
            if (AuthClient.isAuthenticated && AuthClient.isUserLoaded) {
                return mainMenuComponent
            } else if (AuthClient.isAuthenticated || AuthClient.isRestoringSession) {
                return loadingScreenComponent
            } else {
                return authViewComponent
            }
        }
    }

    Component {
        id: authViewComponent
        AuthView {
            anchors.fill: parent
        }
    }

    Component {
        id: loadingScreenComponent
        LoadingScreen {
            anchors.fill: parent
        }
    }

    Component {
        id: mainMenuComponent
        MainView {
            anchors.fill: parent
            windowActive: appWindow.active
        }
    }
}
