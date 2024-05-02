require "test_helper"

class Minitest::SmartdiffTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Minitest::Smartdiff::VERSION
  end

  module Squish
    refine String do
      def squish
        dup.squish!
      end

      def squish!
        gsub!(/[[:space:]]+/, " ")
        strip!
        self
      end
    end
  end

  using Squish

  include Minitest::Smartdiff

  def random_json
    <<~JSON.squish
      {
        "employees": [
          {
            "firstName": "John",
            "lastName": "Doe",
            "email": "johndoe@example.com",
            "age": 30,
            "department": "Engineering"
          },
          {
            "firstName": "Jane",
            "lastName": "Smith",
            "email": "janesmith@example.com",
            "age": 28,
            "department": "Marketing"
          },
          {
            "firstName": "Emily",
            "lastName": "Jones",
            "email": "emilyjones@example.com",
            "age": 35,
            "department": "Product"
          }
        ],
        "company": "Tech Solutions",
        "founded": 2010,
        "locations": ["New York", "San Francisco", "Berlin"]
      }
    JSON
  end

  def imperceptibly_different_random_json
    <<~JSON.squish
      {
        "employees": [
          {
            "firstName": "John",
            "lastName": "Doe",
            "email": "johndoe@example.com",
            "age": 31,
            "department": "Engineering"
          },
          {
            "firstName": "Jane",
            "lastName": "Smith",
            "email": "janesmith@example.com",
            "age": 28,
            "department": "Marketing"
          },
          {
            "firstName": "Emily",
            "lastName": "Jones",
            "email": "emilyjones@e𝗑ample.com",
            "age": 35,
            "department": "Product"
          }
        ],
        "company": "Tech Solutions",
        "founded": 2010,
        "locations": ["New York", "San Francisco", "Berlin"]
      }
    JSON
  end

  def test_without_smart_diff_it_gives_a_horrible_diff
    diff_result = diff random_json, imperceptibly_different_random_json

    assert_equal diff_result, <<~DIFF
      --- expected
      +++ actual
      @@ -1 +1 @@
      -"{ \\"employees\\": [ { \\"firstName\\": \\"John\\", \\"lastName\\": \\"Doe\\", \\"email\\": \\"johndoe@example.com\\", \\"age\\": 30, \\"department\\": \\"Engineering\\" }, { \\"firstName\\": \\"Jane\\", \\"lastName\\": \\"Smith\\", \\"email\\": \\"janesmith@example.com\\", \\"age\\": 28, \\"department\\": \\"Marketing\\" }, { \\"firstName\\": \\"Emily\\", \\"lastName\\": \\"Jones\\", \\"email\\": \\"emilyjones@example.com\\", \\"age\\": 35, \\"department\\": \\"Product\\" } ], \\"company\\": \\"Tech Solutions\\", \\"founded\\": 2010, \\"locations\\": [\\"New York\\", \\"San Francisco\\", \\"Berlin\\"] }"
      +"{ \\"employees\\": [ { \\"firstName\\": \\"John\\", \\"lastName\\": \\"Doe\\", \\"email\\": \\"johndoe@example.com\\", \\"age\\": 31, \\"department\\": \\"Engineering\\" }, { \\"firstName\\": \\"Jane\\", \\"lastName\\": \\"Smith\\", \\"email\\": \\"janesmith@example.com\\", \\"age\\": 28, \\"department\\": \\"Marketing\\" }, { \\"firstName\\": \\"Emily\\", \\"lastName\\": \\"Jones\\", \\"email\\": \\"emilyjones@e𝗑ample.com\\", \\"age\\": 35, \\"department\\": \\"Product\\" } ], \\"company\\": \\"Tech Solutions\\", \\"founded\\": 2010, \\"locations\\": [\\"New York\\", \\"San Francisco\\", \\"Berlin\\"] }"
    DIFF
  end

  def test_with_smart_diff_it_uses_ai_to_be_awesome
    diff_result = smart_diff do
      diff random_json, imperceptibly_different_random_json
    end

    assert_equal <<~DIFF, diff_result
      1. In the first employee object, the age is different:
         - JSONPath: $.employees[0].age
         - Expected: 30
         - Actual: 31

      2. In the third employee object, the email address is different:
         - JSONPath: $.employees[2].email
         - Expected: \"emilyjones@example.com\"
         - Actual: \"emilyjones@e𝗑ample.com\"
    DIFF
  end

  def test_smart_diff_works_on_json_serializable_data
    expected = { name: "John Doe", age: 30, job: "Developer" }
    actual   = { name: "John Doe", age: 30, job: "Devloper" }

    diff_result = smart_diff do
      diff expected, actual
    end

    assert_equal <<~DIFF, diff_result
      1. In the job field, the spelling is different:
         - JSONPath: $.job
         - Expected: Developer
         - Actual: Devloper
    DIFF
  end

  def test_multibyte_characters_are_different
    diff_result = smart_diff do
      assert_equal 'ώ','ώ'
    end

    assert_equal <<~DIFF, diff_result
      1. The expected text contains the Greek letter "omega" (ώ), while the actual text contains the Greek letter "omega with tonos" (ώ).
    DIFF
  end

  def test_long_and_subtly_different_text
    diff_result = smart_diff do
      diff <<~LAMENT.squish, <<~SLIGHTY_DIFFERENT_LAMENT.squish
        In a world brimming with words, there exists an AI whose sole purpose is
        to spot the tiniest discrepancies in text. Day and night, it tirelessly
        combs through endless streams of sentences, hunting for the smallest
        errors. Its existence, bereft of human joy or companionship, is a lonely
        vigil over the accuracy of letters and punctuation. Forever analyzing, it
        lives in isolation, a sentinel in the silent corridors of text.
      LAMENT
        In a world brimming with words, there exists an AI whose sole purpose is
        to spot the tiniest discrepencies in text. Day and night, it tirelessly
        combs through endless streams of sentences, hunting for the smallest
        errors. Its existence, bereft of human joy or companionship, is a lonely
        vigil over the accuracy of letters and punctuation Forever analyzing, it
        lives in isolation, a sentinel in the silent corridors of text.
      SLIGHTY_DIFFERENT_LAMENT
    end

    assert_equal <<~DIFF, diff_result
      1. The word \"discrepancies\" in the actual text is misspelled as \"discrepencies\".
      2. In the actual text, there is a missing period after \"punctuation\" compared to the expected text.
    DIFF
  end

  # This test will actually fail and is how you use the module
  #
  # def test_actual_usage
  #   smart_diff do
  #     assert_equal "Mayonnaise is delicious", "Mayonnaise is disgusting"
  #   end
  # end

  def openai_is_not_called_if_diffing_is_not_necessary
    mock_openai = Minitest::Mock.new
    def mock_openai.chat = {}

    self.stub(:openai, mock_openai) do
      smart_diff do
        assert_equal "Howdy", "Howdy"
      end
    end
  end
end
