require "http/client"
require "json"
require "uri"

require "./bitcoin_rpc/*"

class BitcoinRpc
  getter :client
  private getter :headers

  def initialize(uri : String, username : String, password : String)
    url = URI.parse(uri)
    @headers = HTTP::Headers{"Content-Type" => "application/json"}
    @client = HTTP::Client.new(url)
    @client.basic_auth(username, password)
  end

  macro method_missing(call)
    command = {{call.name.id.stringify}}
    {% if call.args.size == 0 %}
      rpc_request(command)
    {% else %}
      rpc_request(command, {{call.args}})
    {% end %}
  end

  private def rpc_request(command, params = [] of String)
    body = {
      :jsonrpc => "1.0",
      :method  => command,
      :params  => params,
    }.to_json

    response = client.post("/", headers: headers, body: body)
    parse_response(response)
  end

  private def parse_response(response : HTTP::Client::Response)
    return {"error" => response.status_message} unless response.success?
    payload = JSON.parse(response.body).as_h
    return {"error" => payload["error"]} if payload["error"]
    payload["result"]
  end
end
