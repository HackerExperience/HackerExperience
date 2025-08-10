module Apps.Manifest exposing (..)


type Manifest
    = InvalidApp
    | AppStoreApp
    | FileExplorerApp
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

        FileExplorerApp ->
            "File Explorer"

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

        FileExplorerApp ->
            "folder"

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
