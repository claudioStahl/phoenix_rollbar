defmodule PhoenixRollbar.Endpoint do
  require Logger

  import Plug.Conn

  defmacro __using__(_opts) do
    quote location: :keep do
      @before_compile PhoenixRollbar.Endpoint
    end
  end

  defmacro __before_compile__(_) do
    quote location: :keep do
      defoverridable call: 2

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          e in Plug.Conn.WrapperError ->
            %{conn: conn, kind: kind, reason: reason, stack: stack} = e
            PhoenixRollbar.Endpoint.__catch__(conn, kind, reason, stack)

          e in PhoenixRollbar.WrapperError ->
            %{conn: conn, kind: kind, reason: reason, stack: stack} = e
            PhoenixRollbar.Endpoint.__catch__(conn, kind, reason, stack)
        catch
          kind, reason ->
            stack = System.stacktrace()
            PhoenixRollbar.Endpoint.__catch__(conn, kind, reason, stack)
        end
      end
    end
  end

  def __catch__(conn, kind, reason, stack) do
    stack = System.stacktrace()
    metadata = Logger.metadata() |> Enum.into(%{})

    log(conn, kind, reason, stack, metadata)
    report(conn, kind, reason, stack, metadata)

    :erlang.raise(kind, reason, stack)
  end

  defp log(conn, kind, reason, stack, metadata) do
    conn_json = conn_to_request(conn) |> Poison.encode!()
    Logger.info("Conn: #{conn_json}")

    Exception.format(kind, reason, stack)
    |> String.split("\n")
    |> Enum.each(&Logger.bare_log(kind, &1))
  end

  defp report(
         conn,
         kind,
         %Phoenix.Router.NoRouteError{message: _} = reason,
         stack,
         metadata
       ) do
    metadata = Map.put(metadata, "request", conn_to_request(conn))
    {class, message} = Rollbax.Item.exception_class_and_message(kind, reason)
    body = Rollbax.Item.exception_body(class, message, stack)
    Rollbax.Client.emit(:warning, System.system_time(:second), body, %{}, metadata)
  end

  defp report(conn, kind, reason, stack, metadata) do
    metadata = Map.put(metadata, "request", conn_to_request(conn))
    {class, message} = Rollbax.Item.exception_class_and_message(kind, reason)
    body = Rollbax.Item.exception_body(class, message, stack)
    Rollbax.Client.emit(:error, System.system_time(:second), body, %{}, metadata)
  end

  defp conn_to_request(conn) do
    %{
      "cookies" => clear_unfetched(conn.req_cookies),
      "url" => "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
      "user_ip" => List.to_string(:inet.ntoa(conn.remote_ip)),
      "headers" => clear_unfetched(conn.req_headers),
      "method" => conn.method,
      "params" => clear_unfetched(conn.params)
    }
  end

  defp clear_unfetched(value) do
    case value do
      %{__struct__: Plug.Conn.Unfetched} -> "unfetched"
      other -> other |> Enum.into(%{})
    end
  end
end
