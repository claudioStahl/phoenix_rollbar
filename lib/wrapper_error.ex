defmodule PhoenixRollbar.WrapperError do
  defexception [:conn, :kind, :reason, :stack]
end
