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
  An atom representing a dependency.

  Dependency can be non-generic, which is handled in `get_dependency_url/2`, such as `:ffmpeg`, 
  or generic, which has a corresponding repository in 
  https://github.com/membraneframework-precompiled organization, such as `:opus` or `:libvpx`. 
  """
  @type precompiled_dependency() :: atom()

  @typedoc """
  List of desired versions of the precompiled dependencies.

  If an application requires specific versions of used precompiled dependencies, they can be specified
  by passing such list to a `Config.config/3` function with `:membrane_precompiled_dependency_provider`
  root key and `:versions` key, like so 

      config :membrane_precompiled_dependency_provider, :versions,
        ffmpeg: "6.0.1",
        opus: "1.5.2"
  """
  @type version_config() :: [
          {precompiled_dependency(), String.t()}
        ]

  @doc """
  Get URL of a precompiled build of given dependency for a platform from which this function is being
  called. 

  A specific version of the dependency can be provided with `:version` option or through config
  (see `t:version_config/0`). If provided in both ways, the config value will be taken.
  For generic dependencies this version needs to be the same as a release name from the
  repository of the precompiled dependency, but without the leading "v". By default the latest
  version is chosen.

  The target platform can be overridden with the `:target` option (a map in the format returned
  by `Bundlex.get_target/0`). By default the platform from which this function is being called
  is used.
  """
  @spec get_dependency_url(precompiled_dependency(), version: String.t(), target: map()) ::
          String.t() | nil
  def get_dependency_url(dependency, options \\ [])

  def get_dependency_url(:ffmpeg, options) do
    version = resolve_version(:ffmpeg, options)

    generic_url_prefix =
      get_generic_dependency_url_prefix(:ffmpeg, version)

    case resolve_target(options) do
      %{abi: "musl"} ->
        nil

      %{architecture: "x86_64", os: "linux"} ->
        get_linux_ffmpeg_release(version, "linux64")

      %{architecture: "aarch64", os: "linux"} ->
        get_linux_ffmpeg_release(version, "linuxarm64")

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
    version = resolve_version(generic_dependency, options)

    generic_url_prefix =
      get_generic_dependency_url_prefix(generic_dependency, version)

    case resolve_target(options) do
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

  @doc false
  @spec known_ffmpeg_versions() :: [String.t()]
  def known_ffmpeg_versions(), do: ["6.0.1", "6.1.3", "7.1.2", "8.0", "latest"]

  @spec resolve_target(version: String.t(), target: map()) :: map()
  defp resolve_target(opts) do
    Keyword.get_lazy(opts, :target, &Bundlex.get_target/0)
  end

  @spec resolve_version(precompiled_dependency(), version: String.t()) :: String.t()
  defp resolve_version(dependency, opts) do
    opts_version = Keyword.get(opts, :version, "latest")

    Application.get_env(:membrane_precompiled_dependency_provider, :versions, [])
    |> Keyword.get(dependency, opts_version)
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
        "#{@membrane_precompiled_org_url}/precompiled_ffmpeg/releases/download/v6.0.1/ffmpeg_#{platform}.tar.xz"

      version in ["6.1", "6.1.3"] ->
        "#{@ffmpeg_builds_url}/download/autobuild-2025-08-31-13-00/ffmpeg-n6.1.3-#{platform}-gpl-shared-6.1.tar.xz"

      version in ["7.1", "7.1.2"] ->
        "#{@ffmpeg_builds_url}/download/autobuild-2025-09-30-13-19/ffmpeg-n7.1.2-5-g8f77695e65-#{platform}-gpl-shared-7.1.tar.xz"

      version == "8.0" ->
        "#{@ffmpeg_builds_url}/download/autobuild-2025-09-30-13-19/ffmpeg-n8.0-16-gd8605a6b55-#{platform}-gpl-shared-8.0.tar.xz"

      version == "latest" ->
        "#{@ffmpeg_builds_url}/latest/download/ffmpeg-master-latest-#{platform}-gpl-shared.tar.xz"

      true ->
        Logger.warning("Version #{version} not found, using latest")
        "#{@ffmpeg_builds_url}/latest/download/ffmpeg-master-latest-#{platform}-gpl-shared.tar.xz"
    end
  end
end
