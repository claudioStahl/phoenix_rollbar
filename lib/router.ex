defmodule PhoenixRollbar.Router do
  defmacro __using__(_) do
    quote location: :keep do
      @before_compile PhoenixRollbar.Router
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable call: 2

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          e in Plug.Conn.WrapperError ->
            %{conn: conn, kind: kind, reason: reason, stack: stack} = e
            PhoenixRollbar.Router.__catch__(conn, kind, reason, stack)
        catch
          kind, reason ->
            stack = System.stacktrace()
            PhoenixRollbar.Router.__catch__(conn, kind, reason, stack)
        end
      end
    end
  end

  @doc false
  def __catch__(conn, kind, reason, stack) do
    normalized_reason = Exception.normalize(kind, reason, stack)

    wrapper_error = %PhoenixRollbar.WrapperError{
      conn: conn,
      kind: :error,
      reason: normalized_reason,
      stack: stack
    }

    :erlang.raise(kind, wrapper_error, stack)
  end
end
