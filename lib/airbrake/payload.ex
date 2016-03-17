defmodule Airbrake.Payload do
  @notifier_info %{
    name: "Airbrake Elixir",
    version: Airbrake.Mixfile.project[:version],
    url: Airbrake.Mixfile.project[:package][:links][:github],
  }

  @mix_env Mix.env

  defstruct apiKey: nil, notifier: @notifier_info, errors: nil

  def new(exception, stacktrace, options \\ []) do
    %__MODULE__{}
    |> add_error(exception,
                 stacktrace,
                 Keyword.get(options, :context),
                 Keyword.get(options, :env),
                 Keyword.get(options, :params),
                 Keyword.get(options, :session))
  end

  defp add_error(payload, exception, stacktrace, context, env, params, session) do
    payload
    |> add_exception_info(exception, stacktrace)
    |> add_context(context)
    |> add_env(env)
    |> add_params(params)
    |> add_session(session)
  end

  defp add_exception_info(payload, exception, stacktrace) do
    error = %{
      type: exception.__struct__,
      message: Exception.message(exception),
      backtrace: format_stacktrace(stacktrace)
    }
    Map.put payload, :errors, [error]
  end

  defp add_context(payload, nil), do: Map.put(payload, :context, %{environment: @mix_env})
  defp add_context(payload, context) do
    if !context[:environment] do
      context = Map.put(context, :environment, @mix_env)
    end
    Map.put(payload, :context, context)
  end

  defp add_env(payload, nil), do: payload
  defp add_env(payload, env), do: Map.put(payload, :environment, env)

  defp add_params(payload, nil), do: payload
  defp add_params(payload, params), do: Map.put(payload, :params, params)

  defp add_session(payload, nil), do: payload
  defp add_session(payload, session), do: Map.put(payload, :session, session)

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, args, [] }) ->
        %{
          file: "unknown",
          line: 0,
          function: "#{ module }.#{ function }#{ format_args(args) }"
        }
      ({ module, function, args, [file: file, line: line_number] }) ->
        %{
          file: file |> List.to_string,
          line: line_number,
          function: "#{ module }.#{ function }#{ format_args(args) }"
        }
    end
  end

  defp format_args(args) when is_integer(args) do
    "/#{args}"
  end
  defp format_args(args) when is_list(args) do
    "(#{args
        |> Enum.map(&(inspect(&1)))
        |> Enum.join(", ")})"
  end
end
