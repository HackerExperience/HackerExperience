module OS.CtxMenu.Menus exposing (..)


type OSMenu
    = OSRootMenu


type LogViewerMenu
    = LVRootMenu
    | LVEntryMenu


type Menu
    = OS OSMenu
    | LogViewer LogViewerMenu
