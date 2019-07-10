defmodule PhoenixRollbar.WrapperError do
  defexception [:conn, :kind, :reason, :stack]

  def message(%{kind: kind, reason: reason, stack: stack}) do
    Exception.format_banner(kind, reason, stack)
  end
end
