module Apps.Manifest exposing (..)


type Manifest
    = InvalidApp
    | LogViewerApp
    | RemoteAccessApp
    | DemoApp
      -- Popups
    | PopupConfirmationDialog
    | PopupDemoSingleton


getName : Manifest -> String
getName app =
    case app of
        LogViewerApp ->
            "Log Viewer"

        RemoteAccessApp ->
            "Remote Access"

        DemoApp ->
            "Demo App"

        InvalidApp ->
            "Invalid App"

        PopupConfirmationDialog ->
            "Popup"

        PopupDemoSingleton ->
            "Popup"


getIcon : Manifest -> String
getIcon app =
    case app of
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
