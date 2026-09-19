-- Unit test for the Amazon Bedrock provider request shape

local info = debug.getinfo(1, "S")
local unit_dir = info.source:match("@?(.*)"):match("(.+)/[^/]+$") or "."
local tests_dir = unit_dir:match("(.+)/[^/]+$") or "."
local plugin_dir = tests_dir:match("(.+)/[^/]+$") or "."
package.path = plugin_dir .. "/?.lua;" .. tests_dir .. "/?.lua;" ..
    tests_dir .. "/lib/?.lua;" .. package.path

require("mock_koreader")

local handler = require("koassistant_api.bedrock")
local built = handler:buildRequestBody({ { role = "user", content = "Hello" } }, {
    api_key = "test-key",
    system = { text = "Be brief." },
})

assert(built.provider == "bedrock")
assert(built.url == "https://bedrock-runtime.us-east-1.amazonaws.com/model/deepseek.v3.2/converse")
assert(built.headers.Authorization == "Bearer test-key")
assert(built.body.model == nil)
assert(built.body.system[1].text == "Be brief.")
assert(built.body.messages[1].role == "user")
assert(built.body.messages[1].content[1].text == "Hello")
assert(built.body.inferenceConfig.maxTokens == 16384)

local ResponseParser = require("koassistant_api.response_parser")
local ModelLists = require("koassistant_model_lists")
assert(ModelLists._docs.bedrock.api_list ==
    "https://bedrock.us-east-1.amazonaws.com/foundation-models?byOutputModality=TEXT&byInferenceType=ON_DEMAND")
assert(handler:getModelsUrl("https://bedrock-runtime.eu-west-1.amazonaws.com") ==
    "https://bedrock.eu-west-1.amazonaws.com/foundation-models?byOutputModality=TEXT&byInferenceType=ON_DEMAND")
local bedrock_models, seen = ModelLists.bedrock, {}
for _, model in ipairs(bedrock_models) do
    assert(not seen[model], "duplicate Bedrock model: " .. model)
    seen[model] = true
end
assert(seen["amazon.nova-2-lite-v1:0"])
assert(seen["global.anthropic.claude-fable-5-1"])
assert(seen["openai.gpt-oss-120b-1:0"])
assert(seen["qwen.qwen3-coder-next"])
assert(not seen["amazon.nova-sonic-v1:0"])
local ok, text = ResponseParser:parseResponse({
    output = { message = { content = { { text = "Hello back" } } } },
    stopReason = "end_turn",
}, "bedrock")
assert(ok and text == "Hello back")

print("Amazon Bedrock provider test passed")
return true
