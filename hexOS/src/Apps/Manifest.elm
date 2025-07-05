module Apps.Manifest exposing (..)


type Manifest
    = InvalidApp
    | AppStoreApp
    | LogViewerApp
    | RemoteAccessApp
    | DemoApp
      -- Popups
    | PopupLogEdit
    | PopupConfirmationPrompt
    | PopupDemoSingleton


getName : Manifest -> String
getName app =
    case app of
        AppStoreApp ->
            "AppStore"

        LogViewerApp ->
            "Log Viewer"

        RemoteAccessApp ->
            "Remote Access"

        DemoApp ->
            "Demo App"

        InvalidApp ->
            "Invalid App"

        PopupLogEdit ->
            "Log Edit"

        PopupConfirmationPrompt ->
            "Popup"

        PopupDemoSingleton ->
            "Popup"


getIcon : Manifest -> String
getIcon app =
    case app of
        AppStoreApp ->
            "install_desktop"

        LogViewerApp ->
            "list_alt"

        RemoteAccessApp ->
            "lan"

        DemoApp ->
            "science"

        InvalidApp ->
            "error"

        _ ->
            ""
