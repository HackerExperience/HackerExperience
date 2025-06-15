#!/usr/bin/env elixir

defmodule OpenAPI.Elm.Formatter do
  require Logger

  @common_file "src/OpenApi/Common.elm"

  @files [
    "src/API/Events/Types.elm",
    "src/API/Events/Json.elm",
    "src/API/Game/Types.elm",
    "src/API/Game/Json.elm",
    "src/API/Game/Api.elm",
    "src/API/Processes/Types.elm",
    "src/API/Processes/Json.elm",
    "src/API/Logs/Types.elm",
    "src/API/Logs/Json.elm"
  ]

  @custom_types [
    :nip,
    :log_id,
    :process_id,
    :tunnel_id
  ]

  def format do
    handle_common_file()

    Enum.each(@custom_types, fn type ->
      Logger.debug("Formatting custom type: #{type}")
      Enum.each(@files, &handle(type, &1))
    end)

    Enum.each(@files ++ [@common_file], &add_warning_comment/1)
    Enum.each(@files ++ [@common_file], &elm_format/1)
  end

  ##################################################################################################
  # Handlers
  ##################################################################################################

  defp handle(:nip, file) do
    replace("nip", "String", "NIP", file)
    replace("source_nip", "String", "NIP", file)
    replace("target_nip", "String", "NIP", file)
    replace("from_nip", "String", "NIP", file)
    replace("to_nip", "String", "NIP", file)
    replace("mainframe_nip", "String", "NIP", file)
  end

  defp handle(:log_id, file) do
    replace("log_id", "String", "LogID", file)
  end

  defp handle(:process_id, file) do
    replace("process_id", "String", "ProcessID", file)
  end

  defp handle(:tunnel_id, file) do
    replace("tunnel_id", "String", "TunnelID", file)
  end

  defp handle_common_file do
    # Remove Bytes resolver: we have no plans on using it and it's not supported by elm-program-test
    sed("/expectBytesCustom \:/,/decodeOptionalField \:/{/decodeOptionalField \:/!d}", @common_file)
    sed("s/expectBytesCustom, //", @common_file)
    sed("s/bytesResolverCustom, //", @common_file)
    sed("/import Bytes$/d", @common_file)
    sed("/import Bytes\.Decode$/d", @common_file)
  end

  ##################################################################################################
  # Replacers
  ##################################################################################################

  defp replace(name, oas_type, elm_type, file) do
    oas_decoder_type = String.downcase(oas_type)

    # Make sure file has necessary imports
    insert_import(elm_type, file)

    # Replace type
    sed("s/, #{name} \: #{oas_type}/, #{name} \: #{elm_type}/", file)
    sed("s/{ #{name} \: #{oas_type}/{ #{name} \: #{elm_type}/", file)
    sed("s/, #{name} \: Maybe #{oas_type}/, #{name} \: Maybe #{elm_type}/", file)
    sed("s/{ #{name} \: Maybe #{oas_type}/{ #{name} \: Maybe #{elm_type}/", file)

    # Replace Decoder (without line break)
    sed(
      "s/(Json\.Decode\.field \"#{name}\" Json\.Decode\.#{oas_decoder_type})/" <>
        "(Json\.Decode\.field \"#{name}\" #{json_dec(elm_type, oas_decoder_type)})/",
      file
    )

    # Replace decoder (with line break)
    sed(
      "/\"#{name}\"/!b;n;s/Json\.Decode\.#{oas_decoder_type}/" <>
        "#{json_dec(elm_type, oas_decoder_type)}/",
      file
    )

    # Replace Encoder
    sed(
      "s/\"#{name}\", Json\.Encode\.#{oas_decoder_type} rec\.#{name}/" <>
        "\"#{name}\", #{json_enc(elm_type, oas_decoder_type)} rec\.#{name})/",
      file
    )

    # Replace Encoder (Maybe variant)
    sed(
      "s/\"#{name}\", Json\.Encode\.#{oas_decoder_type} mapUnpack/" <>
        "\"#{name}\", #{json_enc(elm_type, oas_decoder_type)} mapUnpack)/",
      file
    )

    # Replace path parameters
    # TODO: This will cause issues when path parameter is, say, LogRevisionID
    sed("s/, config\.params\.#{name}/, #{elm_type}\.toString config\.params\.#{name}/", file)
  end

  ##################################################################################################
  # Utils
  ##################################################################################################

  defp json_dec("NIP", _) do
    "(Json\.Decode\.map (\\\\nip -> NIP\.fromString nip) Json\.Decode\.string)"
  end

  defp json_dec(elm_type, json_type) do
    "(Json\.Decode\.map #{elm_type} Json\.Decode\.#{json_type})"
  end

  defp json_enc("NIP", _) do
    "Json\.Encode\.string (NIP\.toString "
  end

  defp json_enc(elm_type, json_type) do
    "Json\.Encode\.#{json_type} (#{elm_type}\.toValue "
  end

  defp insert_import(name, file) do
    line = "import Game.Model.#{name} as #{name} exposing (#{name}(..))"

    if not exists_in_file?(line, file) do
      if exists_in_file?("^import", file) do
        # Since this file already have imports, just add the import before the first one
        sed("0,/^import/!b;//i#{line}", file)
      else
        # This file does not have any imports, so just add it after the first blank line
        sed("0,/^$/!b;/^$/a#{line}", file)
      end
    end
  end

  defp exists_in_file?(pattern, file) do
    {_, ec} = System.cmd("grep", [pattern, file])
    ec == 0
  end

  defp sed(pattern, file) do
    # NOTE: This entire script assumes GNU Sed
    Logger.debug("sed -i '#{pattern}' #{file}")
    {"", 0} = System.cmd("sed", ["-i", pattern, file])
  end

  defp elm_format(file) do
    {_, 0} = System.cmd("elm-format", ["--yes", file])
  end

  defp add_warning_comment(file) do
    comment = "-- This is an auto-generated file; manual changes will be overwritten!"
    sed("1s/^/#{comment}\\n/", file)
  end
end

# s/none/debug/ for debugging
Logger.configure(level: :none)
OpenAPI.Elm.Formatter.format()
