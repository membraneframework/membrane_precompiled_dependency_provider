defmodule Membrane.PrecompiledDependencyProvider do
  @moduledoc """
  Module providing URLs for precompiled dependencies used by Membrane plugins.

  Dependencies that are fully located in the repositories of `membraneframework-precompiled` will
  be referred to as generic. Otherwise they will be referred to as non-generic.
  """

  require Logger

  @membrane_precompiled_org_url "https://github.com/membraneframework-precompiled"
  @ffmpeg_builds_url "https://github.com/BtbN/FFmpeg-Builds/releases"

  @typedoc """
  A precompiled_dependency can be an atom representing a name of non-generic dependency which is handled in 
  `get_dependency_url/2`, such as `:ffmpeg`, or a generic dependency which has a corresponding repository 
  in https://github.com/membraneframework-precompiled organization, such as `:opus` or `:libvpx`. 
  """
  @type precompiled_dependency() :: atom()

  @doc """
  Get URL of a precompiled build of given dependency for a platform from which this function is being
  called. A specific version of the dependency can be provided with `:version` option. 
  For generic dependencies this version needs to be the same as a release name from the repository 
  of the precompiled dependency, but without the leading "v". By default the latest version is chosen.
  """
  @spec get_dependency_url(precompiled_dependency(), version: String.t()) ::
          String.t() | nil
  def get_dependency_url(dependency, options \\ [])

  def get_dependency_url(:ffmpeg, options) do
    version = Keyword.get(options, :version, "latest")

    generic_url_prefix =
      get_generic_dependency_url_prefix(:ffmpeg, version)

    case Bundlex.get_target() do
      %{abi: "musl"} ->
        nil

      %{architecture: "x86_64", os: "linux"} ->
        "#{@ffmpeg_builds_url}/#{get_linux_ffmpeg_release(version, "linux64")}"

      %{architecture: "aarch64", os: "linux"} ->
        "#{@ffmpeg_builds_url}/#{get_linux_ffmpeg_release(version, "linuxarm64")}"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{generic_url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{generic_url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end

  # ---------------------------------
  # NEW NON-GENERIC DEPENDENCIES HERE
  # defp get_dependency_url(..., target) do 
  #
  # end
  # ---------------------------------

  def get_dependency_url(generic_dependency, options) do
    version = Keyword.get(options, :version, "latest")

    generic_url_prefix =
      get_generic_dependency_url_prefix(generic_dependency, version)

    case Bundlex.get_target() do
      %{abi: "musl"} ->
        nil

      %{architecture: "aarch64", os: "linux"} ->
        "#{generic_url_prefix}_linux_arm.tar.gz"

      %{architecture: "x86_64", os: "linux"} ->
        "#{generic_url_prefix}_linux_x86.tar.gz"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{generic_url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{generic_url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end

  @spec get_generic_dependency_url_prefix(precompiled_dependency(), String.t()) :: String.t()
  defp get_generic_dependency_url_prefix(dep, version) do
    releases_url = "#{@membrane_precompiled_org_url}/precompiled_#{dep}/releases"

    case version do
      "latest" -> "#{releases_url}/latest/download/#{dep}"
      version -> "#{releases_url}/download/v#{version}/#{dep}"
    end
  end

  @spec get_linux_ffmpeg_release(String.t(), String.t()) :: String.t()
  defp get_linux_ffmpeg_release(version, platform) do
    cond do
      version in ["6.0", "6.0.1"] ->
        "download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-#{platform}-gpl-shared-6.0.tar.xz"

      version in ["6.1", "6.1.3"] ->
        "download/autobuild-2025-08-31-13-00/ffmpeg-n6.1.3-#{platform}-gpl-shared-6.1.tar.xz"

      version in ["7.0", "7.0.2"] ->
        "download/autobuild-2024-08-31-12-50/ffmpeg-n7.0.2-6-g7e69129d2f-#{platform}-gpl-shared-7.0.tar.xz"

      version in ["7.1", "7.1.2"] ->
        "download/autobuild-2025-09-23-13-17/ffmpeg-n7.1.2-2-gab05459692-#{platform}-gpl-shared-7.1.tar.xz"

      version == "8.0" ->
        "download/autobuild-2025-09-23-13-17/ffmpeg-n8.0-14-gb9adbf0fcc-#{platform}-gpl-shared-8.0.tar.xz"

      version == "latest" ->
        "latest/download/ffmpeg-master-latest-#{platform}-gpl-shared.tar.xz"

      true ->
        Logger.warning("Version #{version} not found, using latest")
        "latest/download/ffmpeg-master-latest-#{platform}-gpl-shared.tar.xz"
    end
  end
end
