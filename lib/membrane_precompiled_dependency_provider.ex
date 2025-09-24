defmodule Membrane.PrecompiledDependencyProvider do
  @moduledoc """
  Module providing URLs for precompiled dependencies used by Membrane plugins.

  Dependencies that are fully located in the repositories of `membraneframework-precompiled` will
  be referred to as generic. Otherwise they will be referred to as non-generic.
  """

  require Logger

  @membrane_precompiled_org_url "https://github.com/membraneframework-precompiled"
  @ffmpeg_builds_url "https://github.com/BtbN/FFmpeg-Builds/releases"

  @type precompiled_dependency() ::
          :ffmpeg
          | :portaudio
          | :"fdk-aac"
          | :srtp
          | :opus
          | :sdl2
          | :portaudio
          | :mad
          | :lame
          | :libvpx
          | :srt
          | atom()

  @doc """
  Get URL of a precompiled build of given dependency for a platform from which this function is being
  called. A specific version of the dependency can also be provided. For generic dependencies this 
  version needs to be the same as a release name from the repository of the precompiled dependency, 
  but without the leading "v". By default the latest version will be taken.
  """
  @spec get_dependency_url(precompiled_dependency(), version :: String.t()) ::
          String.t() | nil
  def get_dependency_url(dependency, version \\ "latest")

  def get_dependency_url(:ffmpeg, version) do
    generic_url_prefix =
      get_generic_dependency_url_prefix(:ffmpeg, version)

    {linux_x86_release, linux_arm_release} = get_linux_ffmpeg_releases(version)

    case Bundlex.get_target() do
      %{abi: "musl"} ->
        nil

      %{architecture: "x86_64", os: "linux"} ->
        "#{@ffmpeg_builds_url}/#{linux_x86_release}"

      %{architecture: "aarch64", os: "linux"} ->
        "#{@ffmpeg_builds_url}/#{linux_arm_release}"

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

  def get_dependency_url(generic_dependency, version) do
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

  @spec get_linux_ffmpeg_releases(String.t()) ::
          {x86_release :: String.t(), arm_release :: String.t()}
  defp get_linux_ffmpeg_releases(version) do
    case version do
      v when v in ["6.0", "6.0.1"] ->
        &"download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-#{&1}-gpl-shared-6.0.tar.xz"

      v when v in ["6.1", "6.1.3"] ->
        &"download/autobuild-2025-08-31-13-00/ffmpeg-n6.1.3-#{&1}-gpl-shared-6.1.tar.xz"

      v when v in ["7.0", "7.0.2"] ->
        &"download/autobuild-2024-08-31-12-50/ffmpeg-n7.0.2-6-g7e69129d2f-#{&1}-gpl-shared-7.0.tar.xz"

      v when v in ["7.1", "7.1.2"] ->
        &"download/autobuild-2025-09-23-13-17/ffmpeg-n7.1.2-2-gab05459692-#{&1}-gpl-shared-7.1.tar.xz"

      "8.0" ->
        &"download/autobuild-2025-09-23-13-17/ffmpeg-n8.0-14-gb9adbf0fcc-#{&1}-gpl-shared-8.0.tar.xz"

      "latest" ->
        &"latest/download/ffmpeg-master-latest-#{&1}-gpl-shared.tar.xz"

      other ->
        Logger.warning("Version #{other} not found, using latest")
        &"latest/download/ffmpeg-master-latest-#{&1}-gpl-shared.tar.xz"
    end
    |> then(&{&1.("linux64"), &1.("linuxarm64")})
  end
end
