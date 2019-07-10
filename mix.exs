defmodule PhoenixRollbar.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_rollbar,
      version: "0.1.2",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rollbax, ">= 0.0.0"}
    ]
  end
end
