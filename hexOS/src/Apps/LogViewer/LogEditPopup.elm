module Apps.LogViewer.LogEditPopup exposing (..)

-- TODO: Convert Html to UI

import API.Game as GameAPI
import API.Logs.Json as LogsJD
import API.Types
import Apps.Input as App
import Apps.Manifest as App
import Apps.Popups.ConfirmationPrompt.Types as ConfirmationPrompt
import Effect exposing (Effect)
import Game
import Game.Bus as Game
import Game.Model.Log as Log exposing (Log)
import Game.Model.LogID exposing (LogID)
import Game.Model.NIP as NIP exposing (NIP)
import Game.Model.ProcessOperation as Operation exposing (Operation)
import Html as H exposing (Html)
import Json.Encode as JE
import OS.AppID exposing (AppID)
import OS.Bus
import UI exposing (UI, cl, col, row, text)
import UI.Button
import UI.Dropdown
import UI.Form
import UI.Icon
import UI.Model.FormFields as FormFields exposing (TextField)
import UI.TextInput
import WM


type Msg
    = ToOS OS.Bus.Action
    | DropdownMsg DropdownID (UI.Dropdown.Msg Msg)
    | OnTypeSelected LogEditType
    | OnPerspectiveSelected LogEditPerspective
    | SetFieldIP String String
    | SetFreeFormField String
    | ValidateFieldIP String
    | RequestEditLog
    | EditLog RequestConfig
    | OnEditLogResponse LogID API.Types.LogEditResult
    | FromConfirmationPrompt ConfirmationPrompt.Action


type alias Model =
    { appId : AppID
    , nip : NIP
    , log : Log
    , originalLog : Log
    , previewText : String
    , hasChanged : Bool
    , isValid : Bool
    , isEditing : Bool
    , selectedType : LogEditType
    , typeDropdown : UI.Dropdown.Model
    , selectedPerspective : Maybe LogEditPerspective
    , perspectiveDropdown : UI.Dropdown.Model
    , freeFormText : TextField
    , ip1 : TextField
    , ip2 : TextField
    }


{-| TODO: Figure out iptextfield
-}
type alias IPTextField =
    TextField


type DropdownID
    = DropdownType
    | DropdownPerspective


type LogEditType
    = TypeCustom
    | TypeServerLogin
    | TypeFileTransfer
    | TypeConnectionProxied


type LogEditPerspective
    = PerspectiveSelf
    | PerspectiveGateway
    | PerspectiveEndpoint


type LogEditPerspectiveOptions
    = NoPerspectiveOptions
    | PerspectiveOptionsSelfGatewayRemote
    | PerspectiveOptionsGatewayRemote


{-| Type used by the Elm API to represent the log type, perspective and data
-}
type alias RequestConfig =
    ( String, String, String )



-- Model


updatePreview : ( Model, Effect Msg ) -> ( Model, Effect Msg )
updatePreview ( model, effect ) =
    ( { model | previewText = generatePreview model }, effect )


generatePreview : Model -> String
generatePreview model =
    let
        invalidPerspective =
            "<INVALID PERSPECTIVE>"
    in
    case model.selectedType of
        TypeServerLogin ->
            case Maybe.withDefault PerspectiveSelf model.selectedPerspective of
                PerspectiveSelf ->
                    "localhost logged in"

                PerspectiveGateway ->
                    "localhost logged in to [" ++ model.ip1.value ++ "]"

                PerspectiveEndpoint ->
                    "[" ++ model.ip1.value ++ "] logged in to localhost"

        TypeFileTransfer ->
            let
                fileName =
                    "foo.txt"

                ip =
                    model.ip1.value
            in
            case Maybe.withDefault PerspectiveGateway model.selectedPerspective of
                PerspectiveGateway ->
                    "[localhost] downloaded file " ++ fileName ++ " from [" ++ ip ++ "]"

                PerspectiveEndpoint ->
                    "[" ++ ip ++ "] downloaded file " ++ fileName ++ "from [localhost]"

                _ ->
                    invalidPerspective

        TypeConnectionProxied ->
            let
                ( ip1, ip2 ) =
                    ( model.ip1.value, model.ip2.value )
            in
            "[localhost] proxied connection from [" ++ ip1 ++ "] to [" ++ ip2 ++ "]"

        TypeCustom ->
            model.freeFormText.value



-- Model > Perspective


defaultPerspectiveForType : LogEditType -> Maybe LogEditPerspective
defaultPerspectiveForType selectedType =
    case selectedType of
        TypeFileTransfer ->
            Just PerspectiveGateway

        TypeServerLogin ->
            Just PerspectiveSelf

        TypeConnectionProxied ->
            Nothing

        TypeCustom ->
            Nothing


perspectiveToString : LogEditPerspective -> String
perspectiveToString perspective =
    case perspective of
        PerspectiveSelf ->
            "Self"

        PerspectiveGateway ->
            "Gateway"

        PerspectiveEndpoint ->
            "Endpoint"


isPerspectiveValid : LogEditPerspective -> LogEditType -> Bool
isPerspectiveValid perspective selectedType =
    let
        validIfSelfGatewayEndpoint =
            case perspective of
                PerspectiveSelf ->
                    True

                PerspectiveGateway ->
                    True

                PerspectiveEndpoint ->
                    True

        validIfGatewayEndpoint =
            case perspective of
                PerspectiveGateway ->
                    True

                PerspectiveEndpoint ->
                    True

                _ ->
                    False

        validIfNoPerspective =
            False
    in
    case selectedType of
        TypeFileTransfer ->
            validIfGatewayEndpoint

        TypeConnectionProxied ->
            False

        TypeServerLogin ->
            validIfSelfGatewayEndpoint

        TypeCustom ->
            validIfNoPerspective


setPerspectiveOnTypeSelection : Maybe LogEditPerspective -> LogEditType -> Maybe LogEditPerspective
setPerspectiveOnTypeSelection currentPerspective newSelectedType =
    case currentPerspective of
        Nothing ->
            defaultPerspectiveForType newSelectedType

        Just perspective ->
            if isPerspectiveValid perspective newSelectedType then
                currentPerspective

            else
                defaultPerspectiveForType newSelectedType


setPerspectiveDropdown : UI.Dropdown.Model -> Maybe LogEditPerspective -> UI.Dropdown.Model
setPerspectiveDropdown dropdown maybePerspective =
    case maybePerspective of
        Just perspective ->
            { dropdown | selected = Just <| perspectiveToString perspective }

        Nothing ->
            dropdown



-- Model > Fields


onFieldIPSet : Model -> String -> String -> Model
onFieldIPSet model identifier value =
    let
        newIp =
            FormFields.setValue FormFields.text value
    in
    case identifier of
        "ip2" ->
            { model | ip2 = newIp }

        _ ->
            { model | ip1 = newIp }


onFieldFreeFormSet : Model -> String -> Model
onFieldFreeFormSet model value =
    { model | freeFormText = FormFields.setValue FormFields.text value }


onValidateFieldIP : Model -> String -> Model
onValidateFieldIP model identifier =
    let
        validateField =
            \ipField ->
                if ipValid ipField.value then
                    ipField

                else
                    FormFields.setError ipField "Invalid IP"
    in
    case identifier of
        "ip2" ->
            { model | ip2 = validateField model.ip2 }

        _ ->
            { model | ip1 = validateField model.ip1 }



-- Model > Misc


logEditTypeToBackendType : LogEditType -> String
logEditTypeToBackendType logEditType =
    case logEditType of
        TypeCustom ->
            "custom"

        TypeServerLogin ->
            "server_login"

        TypeFileTransfer ->
            -- TODO: This is not "TypeFileTransfer"
            "file_downloaded"

        TypeConnectionProxied ->
            "connection_proxied"


logEditPerspectiveToBackendType : LogEditPerspective -> String
logEditPerspectiveToBackendType perspective =
    case perspective of
        PerspectiveSelf ->
            "self"

        PerspectiveGateway ->
            "to_ap"

        PerspectiveEndpoint ->
            "from_en"


logDataNipToConfig : Model -> String -> String -> Maybe RequestConfig
logDataNipToConfig model cfgType cfgDirection =
    if not (FormFields.isTextEmpty model.ip1 || FormFields.hasError model.ip1) then
        let
            nip =
                NIP.new "0" model.ip1.value

            data =
                LogsJD.encodeLogDataNIP { nip = nip }
        in
        Just ( cfgType, cfgDirection, JE.encode 0 data )

    else
        Nothing


getRequestConfig : Model -> Maybe RequestConfig
getRequestConfig model =
    let
        withLogDataEmpty =
            \( cfgType, cfgDirection ) ->
                Just ( cfgType, cfgDirection, "" )
    in
    case model.selectedType of
        TypeServerLogin ->
            case model.selectedPerspective of
                Just PerspectiveSelf ->
                    Just ( "server_login", "self", "" )

                Just PerspectiveGateway ->
                    logDataNipToConfig model "server_login" "to_ap"

                Just PerspectiveEndpoint ->
                    logDataNipToConfig model "server_login" "from_en"

                _ ->
                    Nothing

        TypeCustom ->
            -- TODO: The data is not actually empty
            ( "custom", "self" )
                |> withLogDataEmpty

        _ ->
            -- TODO
            Nothing


update : Game.Model -> Msg -> Model -> ( Model, Effect Msg )
update game msg model =
    case msg of
        OnTypeSelected logEditType ->
            let
                updatedPerspective =
                    setPerspectiveOnTypeSelection model.selectedPerspective logEditType

                updatedPerspectiveDropdown =
                    setPerspectiveDropdown model.perspectiveDropdown updatedPerspective

                newModel =
                    { model
                        | selectedType = logEditType
                        , selectedPerspective = updatedPerspective
                        , perspectiveDropdown = updatedPerspectiveDropdown
                    }
            in
            ( newModel, Effect.none )
                |> updatePreview

        OnPerspectiveSelected perspective ->
            ( { model | selectedPerspective = Just perspective }, Effect.none )
                |> updatePreview

        SetFieldIP identifier value ->
            ( onFieldIPSet model identifier value, Effect.none )
                |> updatePreview

        SetFreeFormField value ->
            ( onFieldFreeFormSet model value, Effect.none )
                |> updatePreview

        ValidateFieldIP identifier ->
            ( onValidateFieldIP model identifier, Effect.none )

        RequestEditLog ->
            case getRequestConfig model of
                Just requestConfig ->
                    ( model, Effect.msgToCmd (EditLog requestConfig) )

                Nothing ->
                    let
                        msg_ =
                            ToOS <|
                                OS.Bus.RequestOpenApp
                                    App.PopupConfirmationPrompt
                                    (Just ( App.PopupLogEdit, model.appId ))
                                    (App.PopupConfirmationPromptInput <| invalidLogPrompt model)
                    in
                    ( model, Effect.msgToCmd msg_ )

        -- `EditLog` is called either from RequestEditLog directly (when the data is valid) or
        -- from the Confirmation prompt after the user decided to proceed with a custom log
        EditLog ( cfgLogType, cfgLogDirection, cfgLogData ) ->
            let
                server =
                    Game.getServer game model.nip

                config =
                    GameAPI.logEditConfig
                        game.apiCtx
                        model.nip
                        model.log.id
                        cfgLogType
                        cfgLogDirection
                        cfgLogData
                        server.tunnelId

                toGameMsg =
                    Game.ProcessOperation
                        model.nip
                        (Operation.Starting <| Operation.LogEdit model.log.id)
            in
            ( { model | isEditing = True }
            , Effect.batch
                [ Effect.logEdit (OnEditLogResponse model.log.id) config
                , Effect.msgToCmd <| ToOS <| OS.Bus.ToGame toGameMsg
                , Effect.msgToCmd <| ToOS <| OS.Bus.CloseApp model.appId
                ]
            )

        OnEditLogResponse _ _ ->
            ( { model | isEditing = False }, Effect.none )

        DropdownMsg _ (UI.Dropdown.OnSelected msg_) ->
            ( model, Effect.msgToCmd msg_ )

        DropdownMsg ddId ddMsg ->
            let
                ddModel =
                    case ddId of
                        DropdownType ->
                            model.typeDropdown

                        DropdownPerspective ->
                            model.perspectiveDropdown

                updateModel =
                    \newDdModel ->
                        case ddId of
                            DropdownType ->
                                { model | typeDropdown = newDdModel }

                            DropdownPerspective ->
                                { model | perspectiveDropdown = newDdModel }

                ( newDd, ddEffect ) =
                    UI.Dropdown.update ddMsg ddModel
            in
            ( updateModel newDd, Effect.map (DropdownMsg ddId) ddEffect )

        FromConfirmationPrompt action ->
            case action of
                ConfirmationPrompt.Confirm ->
                    let
                        requestConfig =
                            ( "custom", "self", "" )
                    in
                    ( model, Effect.msgToCmd (EditLog requestConfig) )

                ConfirmationPrompt.Cancel ->
                    ( model, Effect.none )

        ToOS _ ->
            -- Handled by OS
            ( model, Effect.none )


ipValid : String -> Bool
ipValid _ =
    -- TODO: Move elsewhere; also used on RemoteAccess
    True



-- View


view : Model -> UI Msg
view model =
    col [ cl "app-logeditpopup" ]
        [ vEditor model
        , vActionRow model
        ]


vEditor : Model -> UI Msg
vEditor model =
    col [ cl "a-lep-editor" ]
        [ vPreview model
        , vPreviewSeparator
        , vSelector model
        ]


vPreview : Model -> UI Msg
vPreview model =
    let
        inner =
            H.fieldset
                []
                [ H.legend [] [ H.text "Preview" ]
                , UI.row [ cl "a-lep-e-p-text" ]
                    [ text model.previewText
                    ]
                ]
    in
    row [ cl "a-lep-e-preview" ]
        [ inner ]


vPreviewSeparator : UI Msg
vPreviewSeparator =
    row [ cl "a-lep-e-preview-separator" ]
        []


vSelector : Model -> UI Msg
vSelector model =
    let
        typeSelector =
            dropdownEntries
                |> UI.Dropdown.new
                |> UI.Dropdown.withMaxHeight 200
                |> UI.Dropdown.toUI model.typeDropdown
                |> H.map (DropdownMsg DropdownType)
    in
    col [ cl "a-lep-e-selector" ]
        [ typeSelector
        , vFieldSelector model
        ]


vFieldSelector : Model -> UI Msg
vFieldSelector model =
    let
        perspective =
            getLogEditPerspectiveOptions model.selectedType

        typeSpecificFields =
            renderEditFields model
    in
    col [ cl "a-lep-e-fields" ]
        (vPerspectiveSelector model :: typeSpecificFields)


renderEditFields : Model -> List (UI Msg)
renderEditFields model =
    let
        selectedPerspective =
            Maybe.withDefault PerspectiveSelf model.selectedPerspective
    in
    case model.selectedType of
        TypeServerLogin ->
            case selectedPerspective of
                PerspectiveSelf ->
                    []

                _ ->
                    [ renderFieldIP model.ip1 "ip" ]

        TypeCustom ->
            [ renderTextArea model.freeFormText ]

        _ ->
            [ text "Todoo" ]


renderTextArea : TextField -> UI Msg
renderTextArea textField =
    -- TODO: Actual textarea
    UI.TextInput.new "" textField
        |> UI.TextInput.withOnChange SetFreeFormField
        -- |> UI.TextInput.withOnBlur (ValidateFieldIP changeIdentifier)
        |> UI.TextInput.toUI


renderFieldIP : IPTextField -> String -> UI Msg
renderFieldIP ipTextField changeIdentifier =
    let
        fieldLabel =
            UI.Form.newFieldLabel "IP Address"
                |> UI.Form.fieldLabelToUI

        textInput =
            UI.TextInput.new "IP" ipTextField
                |> UI.TextInput.withOnChange (SetFieldIP changeIdentifier)
                |> UI.TextInput.withOnBlur (ValidateFieldIP changeIdentifier)
                |> UI.TextInput.toUI
    in
    UI.Form.newFieldPair fieldLabel textInput
        |> UI.Form.fieldPairWithClass "a-lep-e-fields-perspective"
        |> UI.Form.fieldPairToUI


vPerspectiveSelector : Model -> UI Msg
vPerspectiveSelector model =
    let
        perspective =
            getLogEditPerspectiveOptions model.selectedType

        perspectiveSelector =
            perspectiveEntries perspective
                |> UI.Dropdown.new
                |> UI.Dropdown.withWidth 200
                |> UI.Dropdown.toUI model.perspectiveDropdown
                |> H.map (DropdownMsg DropdownPerspective)

        fieldLabel =
            UI.Form.newFieldLabel "Perspective"
                |> UI.Form.fieldLabelToUI
    in
    case perspective of
        NoPerspectiveOptions ->
            UI.emptyEl

        _ ->
            UI.Form.newFieldPair fieldLabel perspectiveSelector
                |> UI.Form.fieldPairWithClass "a-lep-e-fields-perspective"
                |> UI.Form.fieldPairToUI


getLogEditPerspectiveOptions : LogEditType -> LogEditPerspectiveOptions
getLogEditPerspectiveOptions logEditType =
    case logEditType of
        TypeCustom ->
            NoPerspectiveOptions

        TypeServerLogin ->
            PerspectiveOptionsSelfGatewayRemote

        TypeFileTransfer ->
            PerspectiveOptionsGatewayRemote

        TypeConnectionProxied ->
            NoPerspectiveOptions


vActionRow : Model -> UI Msg
vActionRow model =
    row [ cl "a-lep-actionrow" ]
        [ text "[X]"
        , vActionButtonArea model
        ]


vActionButtonArea : Model -> UI Msg
vActionButtonArea model =
    let
        -- TODO: Better UX, show spinner etc
        editButton =
            UI.Button.new (Just "Edit")
                |> UI.Button.withClass "a-lep-ar-ba-editbtn"
                |> UI.Button.withOnClick RequestEditLog
                |> UI.Button.toUI
    in
    row [ cl "a-lep-ar-buttonarea" ]
        [ editButton ]



-- Thoughts: Maybe the "direction" could be translated to "Perspective"
-- With these values: "Self" (or "Self-inflicted"); "Gateway" and "Endpoint"


perspectiveEntries : LogEditPerspectiveOptions -> List (UI.Dropdown.ConfigEntry Msg)
perspectiveEntries perspectiveOptions =
    let
        self =
            UI.Dropdown.SelectableEntry
                { label = perspectiveToString PerspectiveSelf
                , onSelect = Just (OnPerspectiveSelected PerspectiveSelf)
                , opts = Nothing
                }

        gateway =
            UI.Dropdown.SelectableEntry
                { label = perspectiveToString PerspectiveGateway
                , onSelect = Just (OnPerspectiveSelected PerspectiveGateway)
                , opts = Nothing
                }

        endpoint =
            UI.Dropdown.SelectableEntry
                { label = perspectiveToString PerspectiveEndpoint
                , onSelect = Just (OnPerspectiveSelected PerspectiveEndpoint)
                , opts = Nothing
                }
    in
    case perspectiveOptions of
        NoPerspectiveOptions ->
            []

        PerspectiveOptionsSelfGatewayRemote ->
            [ self, gateway, endpoint ]

        PerspectiveOptionsGatewayRemote ->
            [ gateway, endpoint ]


dropdownEntries : List (UI.Dropdown.ConfigEntry Msg)
dropdownEntries =
    [ UI.Dropdown.GroupEntry { label = "File Operations" }
    , UI.Dropdown.SelectableEntry
        { label = "File Transfer"
        , onSelect = Just (OnTypeSelected <| TypeFileTransfer)
        , opts = Nothing
        }
    , UI.Dropdown.SelectableEntry
        { label = "File Delete"
        , onSelect = Nothing
        , opts = Nothing
        }
    , UI.Dropdown.GroupEntry { label = "Misc" }
    , UI.Dropdown.SelectableEntry
        { label = "Server Login"
        , onSelect = Just (OnTypeSelected <| TypeServerLogin)
        , opts = Nothing
        }
    , UI.Dropdown.SelectableEntry
        { label = "Connection Proxied"
        , onSelect = Just (OnTypeSelected <| TypeConnectionProxied)
        , opts = Nothing
        }
    , UI.Dropdown.SelectableEntry
        { label = "Custom Log (Free-form)"
        , onSelect = Just (OnTypeSelected <| TypeCustom)
        , opts = Nothing
        }
    ]


invalidLogPrompt : Model -> ( UI ConfirmationPrompt.Msg, ConfirmationPrompt.ActionOption )
invalidLogPrompt model =
    let
        body =
            col [ cl "a-lep-invalid-log" ]
                [ UI.text "The log you are trying to edit has an invalid structure or contains invalid fields:"
                , UI.text model.previewText
                , UI.text "It will be displayed as a Custom Log. Would you like to proceed?"
                ]

        action =
            ConfirmationPrompt.ActionConfirmCancel "Cancel" "Proceed"
    in
    ( body, action )



-- OS.Dispatcher callbacks


getWindowConfig : WM.WindowInfo -> WM.WindowConfig
getWindowConfig _ =
    { lenX = 500
    , lenY = 520
    , title = "Log Edit"
    , childBehavior = Nothing
    , misc = Nothing
    }


willOpen : WM.WindowInfo -> App.InitialInput -> OS.Bus.Action
willOpen window input =
    OS.Bus.OpenApp App.PopupLogEdit window.parent input


didOpen : WM.WindowInfo -> App.InitialInput -> ( Model, Effect Msg )
didOpen { appId } input =
    let
        ( nip, log ) =
            case input of
                App.PopupLogEditInput nip_ log_ ->
                    ( nip_, log_ )

                _ ->
                    ( NIP.invalidNip, Log.invalidLog )

        revision =
            Log.getNewestRevision log
    in
    ( { appId = appId
      , nip = nip
      , log = log
      , originalLog = log
      , previewText = revision.rawText
      , hasChanged = False
      , isValid = True
      , isEditing = False
      , selectedType = TypeCustom
      , typeDropdown = UI.Dropdown.init (Just "TODO")
      , perspectiveDropdown = UI.Dropdown.init Nothing
      , selectedPerspective = Nothing
      , ip1 = FormFields.text
      , ip2 = FormFields.text
      , freeFormText = FormFields.text
      }
    , Effect.none
    )


willClose : AppID -> Model -> WM.Window -> OS.Bus.Action
willClose appId _ _ =
    OS.Bus.CloseApp appId


willFocus : AppID -> WM.Window -> OS.Bus.Action
willFocus appId _ =
    OS.Bus.FocusApp appId



-- Children
-- TODO: Singleton logic can (and probably should) be delegated to the OS/WM


willOpenChild :
    Model
    -> App.Manifest
    -> WM.Window
    -> WM.WindowInfo
    -> App.InitialInput
    -> OS.Bus.Action
willOpenChild _ child parentWindow _ input =
    OS.Bus.OpenApp child (Just ( App.PopupLogEdit, parentWindow.appId )) input


didOpenChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.WindowInfo
    -> App.InitialInput
    -> ( Model, Effect Msg, OS.Bus.Action )
didOpenChild model _ _ _ =
    ( model, Effect.none, OS.Bus.NoOp )


didCloseChild :
    Model
    -> ( App.Manifest, AppID )
    -> WM.Window
    -> ( Model, Effect Msg, OS.Bus.Action )
didCloseChild model _ _ =
    -- TODO: Make defaults for these
    ( model, Effect.none, OS.Bus.NoOp )
