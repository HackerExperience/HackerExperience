#!/usr/bin/env elixir

defmodule OpenAPI.Elm.Formatter do
  require Logger

  # TODO: Add comment stating these files are generated and should not be hand-edited
  @files [
    "src/API/Events/Types.elm",
    "src/API/Events/Json.elm"
  ]

  @custom_types [
    :server_id
  ]

  def format do
    Enum.each(@custom_types, fn type ->
      Logger.debug("Formatting custom type: #{type}")

      Enum.each(@files, fn file ->
        handle(type, file)
        elm_format(file)
      end)
    end)
  end

  ##################################################################################################
  # Handlers
  ##################################################################################################

  defp handle(:server_id, file) do
    insert_import("import Game.Model.ServerID as ServerID exposing (ServerID(..))", file)

    # Types
    sed("s/mainframe_id \: Int/mainframe_id \: ServerID/", file)

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

  defp json_dec(elm_type, json_type \\ "int") do
    "(Json\.Decode\.map #{elm_type} Json\.Decode\.#{json_type})"
  end

  defp json_enc(elm_type, json_type \\ "int") do
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
