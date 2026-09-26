class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # JSON callers are exempt: this is a machine API, and a voice assistant or a
  # data loader sends no User-Agent worth judging.
  allow_browser versions: :modern, unless: -> { request.format.json? }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # CSRF tokens defend a *browser session* against a cross-site form post. The
  # JSON API has no session and no cookies to ride on — Pika has no
  # authentication at all — so token verification here would reject every
  # legitimate machine caller and protect nothing. HTML forms keep it.
  skip_forgery_protection if: -> { request.format.json? }

  # RFC 8631 and RFC 9727: any response points a client at the API docs and
  # catalog. Asset preload links are appended to this header by Rails, not
  # replaced.
  before_action do
    response.headers["link"] = %(<#{api_catalog_url}>; rel="api-catalog", <#{docs_api_url}>; rel="service-doc")
  end
end
