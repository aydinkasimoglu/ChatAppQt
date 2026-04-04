pragma Singleton
import QtQuick

QtObject {
    // The main signal that will trigger the UI
    signal triggerToast(string message, bool isError)

    // Helper functions to make your code cleaner in other files
    function showSuccess(message) {
        triggerToast(message, false)
    }

    function showError(message) {
        triggerToast(message, true)
    }
}
