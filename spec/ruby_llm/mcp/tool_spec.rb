# frozen_string_literal: true

RSpec.describe RubyLLM::MCP::Tool do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    ClientRunner.build_client_runners(CLIENT_OPTIONS)
    ClientRunner.start_all
  end

  after(:all) do # rubocop:disable RSpec/BeforeAfterAll
    ClientRunner.stop_all
  end

  describe "tool_list" do
    CLIENT_OPTIONS.each do |options|
      let(:client) do
        ClientRunner.client_runners[options[:name]].client
      end

      context "with #{options[:name]}" do
        it "returns a list of tools" do
          tools = client.tools
          expect(tools).to be_a(Array)
          expect(tools.first.name).to eq("add")
        end
      end
    end
  end

  # describe "tool_call" do
  # end
end
