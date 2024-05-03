# frozen_string_literal: true

require "minitest/smartdiff/version"
require "minitest/assertions"
require "xxhash"
require "openai"
require "forwardable"
require "erb"

module Minitest
  module Smartdiff
    class Error < StandardError; end

    extend Forwardable

    def self.included(base)
      base.extend ClassMethods
    end

    def smart_diff_off
      @smart_diff = false
    end

    def smart_diff_on
      @smart_diff = true
    end

    def smart_diff
      raise ArgumentError, "Expected a block but none was given" unless block_given?
      smart_diff_on
      yield
    ensure
      smart_diff_off
    end

    def_delegators :"self.class", :openai, :prompt, :model, :valid_json?, :smart_diffable?

    module ClassMethods
      def openai(config = {})
        @openai ||= OpenAI::Client.new(
          {
            organization_id: "",
            log_errors: true,
            access_token: ENV['OPENAI_KEY'],
            uri_base: ENV['OPENAI_URI_BASE'],
          }.merge(config)
        )
      end

      def prompt(string = nil)
        @prompt = string if string
        @prompt ||= ERB.new <<~DEFAULT
          You are Minitest::Smartdiff - the smartest differ that ever existed.
          Your task is to find subtle but important differences in two pieces of data,
          the expected, and the actual.  When you find the difference describe the
          difference as precisely as possible, and provide samples from the provided
          input.

          Be as succinct as possible, only point out the differences in the two strings.

          Example Output
          <% if mode == :json || mode == :object %>
            Make sure to provide JSONPath to the location of the differences.

            Expected:
              {
                usage: {
                  prompt_tokens: 9
                }
              }

            Actual:
              {
                usage: {
                  prompt_tokens: 11
                }
              }

            1. In the usage object, the number of tokens used is different:
              - JSONPath: $.usage.prompt_tokens
              - Expected: 9
              - Actual: 11
          <% else %>
            Make sure to provide a concise description of the surrounding context for the differences.

            Expected:
              The quick brown dog jumped over the lazy red fox.

            Actual:
              The quick red dog jumped over the lazy brown fox.

            1. The word "brown" in the expected text describes the dog, but in the actual text the word "red" is used.
            2. The word "red" in the expected text describes the fox,  is in the actual text the word "brown" is used.
          <% end %>

          This is very important to my career, I've got children to feed and a
          mortgage to pay - so be very careful to only show differences.

          Expected:
            <%= expected %>

          Actual
            <%= actual %>
        DEFAULT
      end

      def model(model = nil)
        @model = model if model
        @model ||= "gpt-3.5-turbo"
      end

      def valid_json?(str)
        rep = JSON.parse(str)
        rep.is_a?(Hash) || rep.is_a?(Array)
      rescue JSON::ParserError
        false
      end

      def smart_diffable?(exp, act)
        return false if exp.class != act.class
        return false unless [Hash, String, Array].include?(exp.class)

        if exp.is_a?(String)
          if valid_json?(exp) && valid_json?(act)
            :json
          else
            :text
          end
        else
          :object
        end
      end
    end
  end

  module Assertions
    alias_method :old_diff, :diff

    def smart_diff(exp, act)
      return old_diff(exp,act) unless @smart_diff

      mode = smart_diffable?(exp, act)

      return old_diff(exp, act) unless mode

      expected, actual = if mode == :object
        [exp.to_json, act.to_json]
      else
        [exp, act]
      end

      params = {
        parameters: {
          messages: [
            {
              role: "user",
              content: prompt.result_with_hash({
                expected:,
                actual:,
                mode:
              }),
            },
          ],
          model: model,
          temperature: 0.00000000000001,
          seed: XXhash.xxh32(expected, actual)
        }
      }

      completion = openai.chat(**params)
      completion.dig("choices",0,"message","content") + "\n"
    rescue => e
      warn "Error talking to OpenAI: #{e.message} will fallback to basic diff"
      old_diff(exp,act)
    end

    alias_method :diff, :smart_diff
  end
end
