require "test_helper"

class DiscoveryTest < ActionDispatch::IntegrationTest
  API_DOC = Rails.root.join("docs/api.md").read

  test "llms.txt is the API doc, verbatim" do
    get "/llms.txt"

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_equal API_DOC, response.body
  end

  test "the API doc is served as Markdown and as a page" do
    get "/docs/api.md"
    assert_equal "text/markdown", response.media_type
    assert_equal API_DOC, response.body

    get "/docs/api"
    assert_response :success
    assert_select "pre", text: /Pika JSON API/
  end

  test "the API catalog follows RFC 9727" do
    get "/.well-known/api-catalog"

    assert_response :success
    assert_equal 'application/linkset+json; profile="https://www.rfc-editor.org/info/rfc9727"',
                 response.headers["content-type"].sub(/; charset=utf-8\z/, "")

    linkset = JSON.parse(response.body).fetch("linkset")
    catalog = linkset.find { |context| context["anchor"] == "http://www.example.com/.well-known/api-catalog" }
    assert_equal [ "http://www.example.com/" ], catalog["item"].map { |link| link["href"] }

    docs = linkset.find { |context| context["anchor"] == "http://www.example.com/" }["service-doc"]
    assert_equal %w[ text/html text/markdown text/plain ], docs.map { |link| link["type"] }
    docs.each do |link|
      get link["href"]
      assert_response :success, "#{link["href"]} is advertised but does not resolve"
    end
  end

  test "HEAD on the catalog answers with a Link header" do
    head "/.well-known/api-catalog"

    assert_response :success
    assert_includes response.headers["link"], '<http://www.example.com/.well-known/api-catalog>; rel="api-catalog"'
  end

  test "every page and JSON response points at the docs" do
    [ root_path, trips_path(format: :json) ].each do |path|
      get path
      assert_includes response.headers["link"], '<http://www.example.com/docs/api>; rel="service-doc"', path
    end
  end

  test "asset preload links are added to the Link header, not replaced" do
    get root_path

    assert_includes response.headers["link"], 'rel="api-catalog"'
    assert_includes response.headers["link"], "rel=preload"
  end

  test "a client that is not a browser can read the docs" do
    get "/llms.txt", headers: { "User-Agent" => "curl/8.7.1" }
    assert_response :success

    get "/llms.txt", headers: { "User-Agent" => "" }
    assert_response :success
  end
end
