import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    width: 380
    height: layout.implicitHeight + 80

    property bool isLogin
    property bool loading

    signal loginRequested(string email, string password)
    signal signupRequested(string email, string username, string password)
    signal modeChanged()

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuart
        }
    }

    function processSubmit() {
        if (root.loading) return;

        // Extract and sanitize
        const email = emailField.text.trim();
        const username = usernameField.text;
        const password = passwordField.text;
        const confirmPass = confirmPassword.text;

        if (email === "" || password === "") {
            ToastManager.showError("Please fill in all fields.");
            return;
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            ToastManager.showError("Please enter a valid email address.");
            return;
        }

        if (root.isLogin)
        {
            root.loginRequested(email, password);
        }
        else
        {
            if (username === "") {
                ToastManager.showError("Please fill in your user name.");
                return;
            }

            if (password.length < 8) {
                ToastManager.showError("Password must be at least 8 characters long.");
                return;
            }

            if (confirmPass === "") {
                ToastManager.showError("Please confirm your password.");
                return;
            }

            if (password !== confirmPass) {
                ToastManager.showError("Passwords do not match.");
                return;
            }

            root.signupRequested(email, username, password);
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent

        radius: 20
        color: "white"

        ColumnLayout {
            id: layout
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 20

            AuthHeader {
                isLogin: root.isLogin
            }

            AuthTextField {
                id: emailField
                placeholderText: "Email address"
                loading: root.loading

                onAccepted: {
                    if (root.isLogin)
                        passwordField.forceActiveFocus()
                    else
                        usernameField.forceActiveFocus()
                }
            }

            AuthTextField {
                id: usernameField
                placeholderText: "User name"
                visible: opacity > 0
                opacity: root.isLogin ? 0 : 1
                loading: root.loading

                Layout.preferredHeight: root.isLogin ? 0 : implicitHeight

                onAccepted: {
                    passwordField.forceActiveFocus()
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            AuthTextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
                loading: root.loading

                onAccepted: {
                    if (root.isLogin)
                        root.processSubmit()
                    else
                        confirmPassword.forceActiveFocus()
                }
            }

            AuthTextField {
                id: confirmPassword
                placeholderText: "Confirm Password"
                visible: opacity > 0
                opacity: root.isLogin ? 0 : 1
                loading: root.loading

                echoMode: TextInput.Password

                Layout.preferredHeight: root.isLogin ? 0 : implicitHeight

                onAccepted: {
                    root.processSubmit()
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            AuthButton {
                isLogin: root.isLogin
                loading: root.loading

                onClicked: {
                    root.processSubmit()
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: root.isLogin ? "Don't have an account?" : "Already have an account?"
                }

                Text {
                    text: root.isLogin ? "Sign up" : "Log in"
                    color: "#6366F1"

                    font.weight: Font.Bold

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeChanged()
                    }
                }
            }
        }
    }

    MultiEffect {
        source: card
        anchors.fill: card
        shadowEnabled: true
        shadowColor: "#1A000000"
        shadowBlur: 1.5
        shadowVerticalOffset: 10
    }
}
