# Serves docs/api.md itself, so what an agent reads is the file in the repo and
# cannot drift from it.
class DocsController < ApplicationController
  API_DOC = Rails.root.join("docs/api.md")
  CATALOG_TYPE = 'application/linkset+json; profile="https://www.rfc-editor.org/info/rfc9727"'

  # The llms.txt convention: a Markdown overview at the site root for LLMs.
  def llms
    render plain: API_DOC.read, content_type: "text/plain"
  end

  def api
    respond_to do |format|
      format.html { @markdown = API_DOC.read }
      format.md { render plain: API_DOC.read, content_type: "text/markdown" }
    end
  end

  # RFC 9727. HEAD is answered by Rails as GET without a body, and carries the
  # Link header every response gets from ApplicationController.
  def api_catalog
    render content_type: CATALOG_TYPE, json: {
      linkset: [
        { anchor: api_catalog_url, item: [ { href: root_url } ] },
        {
          anchor: root_url,
          "service-doc": [
            { href: docs_api_url, type: "text/html" },
            { href: docs_api_url(format: :md), type: "text/markdown" },
            { href: llms_txt_url, type: "text/plain" }
          ]
        }
      ]
    }
  end
end
