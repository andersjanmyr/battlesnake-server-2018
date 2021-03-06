defmodule Bs.HTTPMock do
  alias HTTPoison.Response
  alias HTTPoison.Error
  import Poison
  require Logger

  @econnrefused %Error{id: nil, reason: :econnrefused}

  def post!(url, _, _, _) do
    Logger.debug("[http_mock] called: #{url}")

    try do
      case url do
        "invalid.mock/move" ->
          %Response{body: encode!(%{move: "UP"}), status_code: 200}

        "up.mock/move" ->
          %Response{body: encode!(%{move: "up"}), status_code: 200}

        "right.mock/move" ->
          %Response{body: encode!(%{move: "right"}), status_code: 200}

        "left.mock/move" ->
          %Response{body: encode!(%{move: "left"}), status_code: 200}

        "down.mock/move" ->
          %Response{body: encode!(%{move: "down"}), status_code: 200}

        _ ->
          cond do
            url =~ ~r{econnrefused.mock} ->
              raise @econnrefused

            url =~ ~r{fail.mock} ->
              raise %Error{}

            url =~ ~r{html.mock} ->
              %Response{
                status_code: 200,
                body: "<html><body>text</body></html>"
              }

            url =~ ~r{/start} ->
              %Response{
                status_code: 200,
                body:
                  encode!(%{
                    name: "mock snake",
                    taunt: "mock taunt"
                  })
              }
          end
      end
    rescue
      err ->
        Logger.debug("[http_mock] raised: #{inspect(err)}")
        raise err
    end
    |> case do
      response ->
        Logger.debug("[http_mock] returned: #{inspect(response)}")
        response
    end
  end
end
