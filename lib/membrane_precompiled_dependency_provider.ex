defmodule Membrane.PrecompiledDependencyProvider do
  @moduledoc """
  Module providing URLs for precompiled dependencies used by Membrane plugins.

  Dependencies that are fully located in the repositories of `membraneframework-precompiled` will
  be referred to as Generic. Otherwise they will be referred to as Non-generic.
  """
  @membrane_precompiled_org_url "https://github.com/membraneframework-precompiled"

  @generic_precompiled_deps [
    :portaudio,
    :"fdk-aac",
    :srtp,
    :opus,
    :sdl2,
    :portaudio,
    :mad
  ]

  @type precompiled_dependency() ::
          :ffmpeg | :portaudio | :"fdk-aac" | :srtp | :opus | :sdl2 | :portaudio | :mad

  @doc """
  Get url where precompiled build of given dependency for current platform is located.
  """
  @spec get_precompiled_dependency_url(dependency :: precompiled_dependency()) ::
          String.t() | nil
  def get_precompiled_dependency_url(dependency) do
    case dependency do
      generic_dep when generic_dep in @generic_precompiled_deps -> get_generic_url(generic_dep)
      non_generic_dep -> get_non_generic_url(non_generic_dep)
    end
  end

  @spec get_generic_url_prefix(dependency_name :: precompiled_dependency()) :: String.t()
  defp get_generic_url_prefix(dependency_name) do
    "#{@membrane_precompiled_org_url}/precompiled_#{dependency_name}/releases/latest/download/#{dependency_name}"
  end

  @spec get_generic_url(dependency_name :: precompiled_dependency()) :: String.t() | nil
  defp get_generic_url(dependency_name) do
    url_prefix = get_generic_url_prefix(dependency_name)

    case Bundlex.get_target() do
      %{abi: "musl"} ->
        nil

      %{os: "linux"} ->
        "#{url_prefix}_linux.tar.gz"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end

  @spec get_non_generic_url(dependency_name :: precompiled_dependency()) :: String.t() | nil
  defp get_non_generic_url(:ffmpeg) do
    url_prefix = get_generic_url_prefix(:ffmpeg)

    case Bundlex.get_target() do
      %{abi: "musl"} ->
        nil

      %{architecture: "aarch64", os: "linux"} ->
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n6.0-latest-linuxarm64-gpl-shared-6.0.tar.xz"

      %{os: "linux"} ->
        "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n6.0-latest-linux64-gpl-shared-6.0.tar.xz"

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_intel.tar.gz"

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        "#{url_prefix}_macos_arm.tar.gz"

      _other ->
        nil
    end
  end
end
