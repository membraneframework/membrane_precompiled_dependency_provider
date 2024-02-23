defmodule Membrane.PrecompiledDependencyProvider do
  @moduledoc """
  Module providing URLs for precompiled dependencies used by Membrane plugins.

  Dependencies that are fully located in the repositories of `membraneframework-precompiled` will
  be referred to as Generic. Otherwise they will be referred to as Non-generic.
  """
  @membrane_precompiled_org_url "https://github.com/membraneframework-precompiled"

  @type precompiled_dependency() ::
          :ffmpeg | :portaudio | :"fdk-aac" | :srtp | :opus | :sdl2 | :portaudio | :mad | :lame

  @doc """
  Get URL of a precompiled build of given dependency for appropriate target.
  """
  @spec get_dependency_url(dependency :: precompiled_dependency()) ::
          String.t() | nil
  def get_dependency_url(dependency) do
    get_dep_url(dependency, Bundlex.get_target())
  end

  @spec get_generic_dep_url_prefix(dep :: precompiled_dependency()) :: String.t()
  defp get_generic_dep_url_prefix(dep) do
    "#{@membrane_precompiled_org_url}/precompiled_#{dep}/releases/latest/download/#{dep}"
  end

  @spec get_dep_url(dep :: precompiled_dependency(), target :: Bundlex.target()) ::
          String.t() | nil
  defp get_dep_url(:ffmpeg, target) do
    url_prefix = get_generic_dep_url_prefix(:ffmpeg)

    case target do
      %{abi: "musl"} ->
        nil

      %{architecture: "aarch64", os: "linux"} ->
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-linuxarm64-gpl-shared-6.0.tar.xz"

      %{architecture: "x86_64", os: "linux"} ->
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-linux64-gpl-shared-6.0.tar.xz"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end

  # ---------------------------------
  # NEW NON-GENERIC DEPENDENCIES HERE

  # ---------------------------------

  defp get_dep_url(generic_dep, target) do
    url_prefix = get_generic_dep_url_prefix(generic_dep)

    case target do
      %{abi: "musl"} ->
        nil

      %{architecture: "x86_64", os: "linux"} ->
        "#{url_prefix}_linux.tar.gz"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end
end
