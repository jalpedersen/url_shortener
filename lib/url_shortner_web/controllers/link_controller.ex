defmodule UrlShortenerWeb.LinkController do
  use UrlShortenerWeb, :controller

  alias UrlShortener.Links
  alias UrlShortener.Links.Link
  alias UrlShortenerWeb.Router.Helpers, as: RouterHelpers

  action_fallback(UrlShortenerWeb.FallbackController)

  def create(conn, %{"url" => url}) do
    url_params = create_params(%{url: url})

    link_result =
      case Links.get_link_by_short_code(url_params.short_code) do
        {:ok, %Link{} = link} -> {:ok, link}
        {:error, :not_found} -> Links.create_link(url_params)
      end

    with {:ok, %Link{} = link} <- link_result do
      link =
        RouterHelpers.link_url(
          UrlShortenerWeb.Endpoint,
          :redirect_url,
          link.short_code
        )

      conn
      |> put_status(:created)
      |> render("show.json", link: link)
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(405)
    |> put_view(UrlShortenerWeb.ErrorView)
    |> render(:"405")
  end

  def redirect_url(conn, %{"short_code" => short_code}) do
    with {:ok, %Link{} = link} <- Links.get_link_by_short_code(short_code) do
      conn
      |> redirect(external: link.url)
    end
  end

  defp create_params(params) do
    params
    |> Map.merge(%{short_code: generate_short_code(params.url)})
  end

  defp generate_short_code(url) do
    hash = :crypto.hash(:md5, url)

    hash
    |> Base.encode64()
    |> binary_part(0, 8)
  end
end