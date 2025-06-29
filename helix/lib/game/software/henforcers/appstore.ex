defmodule Game.Henforcers.AppStore do
  alias Game.{Software}

  @doc """
  Determines whether the provided `file_type` can be AppStore-installed in the target server.

  It can be AppStore-installed if:

  - `file_type` is installable.
  - One of the following conditions is true:
    a. "AppStore software" is not already present and installed in the server; or
    b. "AppStore software" is present in the server but not installed; or
    c. "AppStore software" is not present in the server but installed.
  - In the event of the File being added to the server, the server must have sufficient storage.
  - In the event of the File being installed, the server must have sufficient memory.

  Notes:

  By "AppStore software" we mean the exact combination between file type and version.

  It is at this moment (Henforcer check) that we determine if the resulting process should:
  - Download & install software; or
  - Only download software; or
  - Only install software.
  """
  def can_install?(_server, _entity, _file_type) do
    # TODO
    software = Software.get(:cracker)
    {true, %{software: software, action: :download_and_install}}
  end
end
