#!/usr/bin/env elixir

defmodule OpenAPI.Elm.Formatter do
  require Logger

  # TODO: Add comment stating these files are generated and should not be hand-edited
  @files [
    "src/API/Events/Types.elm",
    "src/API/Events/Json.elm",
    "src/API/Game/Api.elm"
  ]

  @custom_types [
    :server_id,
    :nip
  ]

  def format do
    Enum.each(@custom_types, fn type ->
      Logger.debug("Formatting custom type: #{type}")

      Enum.each(@files, fn file ->
        handle(type, file)
      end)
    end)

    Enum.each(@files, &elm_format/1)
  end

  ##################################################################################################
  # Handlers
  ##################################################################################################

  # TODO: I may be able to simplify some of these operations
  defp handle(:nip, file) do
    insert_import("import Game.Model.NIP as NIP exposing (NIP(..))", file)

    # Types
    sed("s/{ nip \: String/{ nip \: NIP/", file)
    sed("s/, nip \: String/, nip \: NIP/", file)
    sed("s/, source_nip \: String/, source_nip \: NIP/", file)
    sed("s/, target_nip \: String/, target_nip \: NIP/", file)

    # Json parsing
    sed("/\"nip\"/!b;n;s/Json\.Decode\.string/#{json_dec(:nip)}/", file)
    sed("/\"source_nip\"/!b;n;s/Json\.Decode\.string/#{json_dec(:nip)}/", file)
    sed("/\"target_nip\"/!b;n;s/Json\.Decode\.string/#{json_dec(:nip)}/", file)

    sed(
      "s/\"nip\", Json\.Encode\.string rec\.nip/" <>
        "\"nip\", #{json_enc(:nip)} rec\.nip)/",
      file
    )

    sed(
      "s/\"source_nip\", Json\.Encode\.string rec\.source_nip/" <>
        "\"source_nip\", #{json_enc(:nip)} rec\.source_nip)/",
      file
    )

    sed(
      "s/\"target_nip\", Json\.Encode\.string rec\.target_nip/" <>
        "\"target_nip\", #{json_enc(:nip)} rec\.target_nip)/",
      file
    )

    # Path parameters
    sed("s/, config\.params\.nip/, NIP\.toString config\.params\.nip/", file)
    sed("s/, config\.params\.target_nip/, NIP\.toString config\.params\.target_nip/", file)
  end

  defp handle(:server_id, file) do
    insert_import("import Game.Model.ServerID as ServerID exposing (ServerID(..))", file)

    # Types
    sed("s/, mainframe_id \: Int/, mainframe_id \: ServerID/", file)

    # Json parsing
    sed("/\"mainframe_id\"/!b;n;s/Json\.Decode\.int/#{json_dec("ServerID", "int")}/", file)

    sed(
      "s/\"mainframe_id\", Json\.Encode\.int rec\.mainframe_id/" <>
        "\"mainframe_id\", #{json_enc("ServerID", "int")} rec\.mainframe_id)/",
      file
    )
  end

  ##################################################################################################
  # Utils
  ##################################################################################################

  defp json_dec(elm_type, json_type \\ "int")

  defp json_dec(:nip, _) do
    "(Json\.Decode\.map (\\\\nip -> NIP\.fromString nip) Json\.Decode\.string)"
  end

  defp json_dec(elm_type, json_type) do
    "(Json\.Decode\.map #{elm_type} Json\.Decode\.#{json_type})"
  end

  defp json_enc(elm_type, json_type \\ "int")

  defp json_enc(:nip, _) do
    "Json\.Encode\.string (NIP\.toString "
  end

  defp json_enc(elm_type, json_type) do
    "Json\.Encode\.#{json_type} (#{elm_type}\.toValue "
  end

  defp insert_import(line, file) do
    if not exists_in_file?(line, file) do
      if exists_in_file?("^import", file) do
        # Since this file already have imports, just add the import before the first one
        # sed("0,/^import/s/#{line}\n//", file)

        sed("0,/^import/!b;//i#{line}", file)
      else
        # This file does not have any imports, so just add it at the second line (after module)
        sed("1 a #{line}\n", file)
      end
    end
  end

  defp exists_in_file?(pattern, file) do
    {_, ec} = System.cmd("grep", [pattern, file])
    ec == 0
  end

  defp sed(pattern, file) do
    # NOTE: This entire script assumes GNU Sed
    {"", 0} = System.cmd("sed", ["-i", pattern, file] |> IO.inspect())
  end

  defp elm_format(file) do
    {_, 0} = System.cmd("elm-format", ["--yes", file])
  end
end

OpenAPI.Elm.Formatter.format()
