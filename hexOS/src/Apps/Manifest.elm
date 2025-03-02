module Apps.Manifest exposing (..)


type Manifest
    = InvalidApp
    | LogViewerApp
    | RemoteAccessApp
    | DemoApp
      -- Popups
    | PopupConfirmationDialog
    | PopupDemoSingleton
