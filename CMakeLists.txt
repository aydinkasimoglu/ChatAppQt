cmake_minimum_required(VERSION 3.16)

project(ChatApp VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS Quick WebSockets)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appChatApp
    src/main.cpp
)

set(qml_singletons
    Theme.qml
    ToastManager.qml
)
set_source_files_properties(${qml_singletons}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

file(GLOB_RECURSE IMAGE_FILES 
    RELATIVE "${PROJECT_SOURCE_DIR}" 
    "assets/*.png" 
    "assets/*.svg" 
    "assets/*.jpg"
)

qt_add_qml_module(appChatApp
    URI ChatApp
    VERSION 1.0
    RESOURCE_PREFIX "/"
    SOURCES
        src/core/authClient.cpp
        src/core/authClient.h
        src/core/networkClient.cpp
        src/core/networkClient.h
        src/core/serverManager.cpp
        src/core/serverManager.h
        src/core/friendshipManager.cpp
        src/core/friendshipManager.h
        src/core/presenceManager.cpp
        src/core/presenceManager.h
        src/models/friendListModel.cpp
        src/models/friendListModel.h
        src/models/pendingRequestModel.cpp
        src/models/pendingRequestModel.h
        src/models/blockListModel.cpp
        src/models/blockListModel.h
        src/models/serverListModel.cpp
        src/models/serverListModel.h
    QML_FILES
        Main.qml
        components/AddServerButton.qml
        components/BlurOverlay.qml
        components/ServerIcon.qml
        components/Toast.qml
        components/ThemedSwitch.qml
        components/PopupMenuItem.qml
        components/auth/AuthButton.qml
        components/auth/AuthForm.qml
        components/auth/AuthHeader.qml
        components/auth/AuthTextField.qml
        components/dialogs/CreateServerDialog.qml
        views/AuthView.qml
        views/FriendsView.qml
        views/LoadingScreen.qml
        views/MainView.qml
        views/MidPanel.qml
        views/SidePanel.qml
        ${qml_singletons}
)

qt_add_resources(appChatApp PRIVATE
    PREFIX "/"
    FILES ${IMAGE_FILES}
)

target_include_directories(appChatApp PRIVATE
    src/core
    src/models
)

set_target_properties(appChatApp PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE $<IF:$<CONFIG:Release>,TRUE,FALSE>
)

target_link_libraries(appChatApp
    PRIVATE Qt6::Quick Qt6::WebSockets
)

include(GNUInstallDirs)
install(TARGETS appChatApp
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
