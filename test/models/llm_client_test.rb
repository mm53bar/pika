require "test_helper"
require "net/http"

class LlmClientTest < ActiveSupport::TestCase
  # A local HTTP server would be heavier than this seam: Net::HTTP.start is the
  # one call that leaves the process, so it is swapped for the duration.
  def answering(content, code: "200")
    response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code).new("1.1", code, "")
    body = { choices: [ { message: { content: content } } ] }.to_json
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    fake = Object.new
    fake.define_singleton_method(:request) { |_| response }

    original = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) { |*, **, &block| block.call(fake) }
    yield LlmClient.new(base_url: "http://llm.test/v1", model: "some-model")
  ensure
    Net::HTTP.define_singleton_method(:start, original)
  end

  test "parses a plain JSON answer" do
    answering('{"ok": true}') { |client| assert_equal({ "ok" => true }, client.complete_json(system: "s", user: "u")) }
  end

  test "parses an answer wrapped in a Markdown fence" do
    answering("```json\n{\"ok\": true}\n```") { |client| assert_equal({ "ok" => true }, client.complete_json(system: "s", user: "u")) }
    answering("```\n{\"ok\": true}\n```\n") { |client| assert_equal({ "ok" => true }, client.complete_json(system: "s", user: "u")) }
  end

  test "an unparseable answer is nil, not an error" do
    answering("not json at all") { |client| assert_nil client.complete_json(system: "s", user: "u") }
  end

  test "a server error is Unavailable, so it is retried" do
    answering("{}", code: "503") do |client|
      assert_raises(LlmClient::Unavailable) { client.complete_json(system: "s", user: "u") }
    end
  end

  test "an unconfigured client answers nothing" do
    assert_nil LlmClient.new(base_url: nil, model: nil).complete_json(system: "s", user: "u")
  end
end
