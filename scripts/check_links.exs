# Verifies that all URLs emitted by Membrane.PrecompiledDependencyProvider point to
# existing artifacts. Run with: mix run scripts/check_links.exs

defmodule CheckLinks do
  @generic_dependencies [
    :dav1d,
    :"fdk-aac",
    :lame,
    :libnice,
    :libvpx,
    :mad,
    :opus,
    :portaudio,
    :sdl2,
    :srt,
    :srtp,
    :"svt-av1"
  ]

  @targets [
    %{architecture: "x86_64", os: "linux", abi: "gnu"},
    %{architecture: "aarch64", os: "linux", abi: "gnu"},
    %{architecture: "x86_64", os: "darwin22.6.0", abi: "gnu"},
    %{architecture: "aarch64", os: "darwin22.6.0", abi: "gnu"}
  ]

  # Artifacts that were never published; remove entries once they are.
  @known_broken [
    {:ffmpeg, "6.1.3", "x86_64", "darwin"},
    {:ffmpeg, "6.1.3", "aarch64", "darwin"},
    {:ffmpeg, "7.1.2", "x86_64", "darwin"},
    {:ffmpeg, "7.1.2", "aarch64", "darwin"},
    {:ffmpeg, "8.0", "x86_64", "darwin"}
  ]

  # No generic dependency publishes a macos_intel artifact.
  defp known_broken?(dep, _version, %{architecture: "x86_64", os: "darwin" <> _rest})
       when dep != :ffmpeg,
       do: true

  defp known_broken?(dep, version, target) do
    {dep, version, target.architecture, os_family(target)} in @known_broken
  end

  def run() do
    ffmpeg_cases =
      for version <- Membrane.PrecompiledDependencyProvider.known_ffmpeg_versions(),
          target <- @targets,
          do: {:ffmpeg, version, target}

    generic_cases =
      for dep <- @generic_dependencies, target <- @targets, do: {dep, "latest", target}

    cases =
      (ffmpeg_cases ++ generic_cases)
      |> Enum.reject(fn {dep, version, target} -> known_broken?(dep, version, target) end)

    urls =
      cases
      |> Enum.map(fn {dep, version, target} ->
        Membrane.PrecompiledDependencyProvider.get_dependency_url(dep,
          version: version,
          target: target
        )
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    IO.puts("Checking #{length(urls)} URLs...")

    results =
      urls
      |> Task.async_stream(fn url -> {url, check(url)} end,
        max_concurrency: 10,
        timeout: 300_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    # Only a confirmed 404/410 fails the job - transient errors (timeouts, 5xx etc.)
    # would create false-positive issues on CI.
    broken = for {url, :broken} <- results, do: url
    transient = for {url, {:transient, reason}} <- results, do: {url, reason}

    Enum.each(transient, fn {url, reason} ->
      IO.puts("WARNING: could not verify (#{reason}): #{url}")
    end)

    if broken == [] do
      IO.puts("No broken links found")
    else
      Enum.each(broken, &IO.puts("BROKEN: #{&1}"))
      System.halt(1)
    end
  end

  # Req retries transient errors (timeouts, 5xx etc.) on its own before we classify.
  defp check(url) do
    case Req.head(url, receive_timeout: 30_000, redirect_log_level: false) do
      {:ok, %Req.Response{status: status}} when status in 200..399 -> :ok
      {:ok, %Req.Response{status: status}} when status in [404, 410] -> :broken
      {:ok, %Req.Response{status: status}} -> {:transient, status}
      {:error, error} -> {:transient, inspect(error)}
    end
  end

  defp os_family(%{os: "darwin" <> _rest}), do: "darwin"
  defp os_family(%{os: os}), do: os
end

CheckLinks.run()
