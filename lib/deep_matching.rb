# frozen_string_literal: true

require 'active_model'

require 'deep_matching/deep_matcher'
require 'deep_matching/nested_expectation_parameters'

module DeepMatching
  # I tried writing this as an RSpec matcher, but couldn't easily make it
  # find all nested failures with aggregate_failures, rather than just the
  # first one
  def expect_deep_matching(actual_object, expected_object, ignore_list: [], nested_expectation_parameters: nil,
                           failure_message_extra_context: '')
    nested_expectation_parameters ||= NestedExpectationParameters.new(
      nesting: [],
      ignore_list: ignore_list,
      evaluation_context: self,
      failure_message_extra_context: failure_message_extra_context
    )

    return true if deep_matches?(
      actual_object, expected_object,
      nested_expectation_parameters: nested_expectation_parameters
    )

    failure_message = deep_matching_failure_message_for(
      actual_object,
      nested_expectation_parameters.nesting,
      nested_expectation_parameters.failure_message_extra_context
    )

    make_assertion_about!(actual_object, expected_object, failure_message, nested_expectation_parameters.evaluation_context)
  end

  def deep_matches?(actual_object, expected_object, nested_expectation_parameters:)
    DeepMatcher.new(
      actual_object:,
      expected_object:,
      nested_expectation_parameters:
    ).matches?
  end

  private

  def make_assertion_about!(actual_object, expected_object, failure_message, evaluation_context)
    evaluation_context.instance_eval do
      case expected_object
      when RSpec::Mocks::ArgumentMatchers::KindOf
        make_assertion_about_kind_of(actual_object, expected_object, failure_message)
      when Regexp
        expect(actual_object).to match(expected_object), failure_message.call(:match, expected_object)
      else
        expect(actual_object).to eq(expected_object), failure_message.call(:eq, expected_object)
      end
    end
  end

  def make_assertion_about_kind_of(actual_object, expected, _failured_message)
    expected = expected.instance_eval { @klass }
    expect(actual_object).to be_a(expected), failure_message.call(:be_a, expected)
  end

  def deep_matching_failure_message_for(actual_object, nesting, failure_message_extra_context)
    lambda do |comparison, expected|
      nesting_message = nesting.length > 1 ? 'Expected nested hash key at' : 'Expected hash key at'
      [failure_message_extra_context.presence,
       "#{nesting_message} '#{nesting.join('.')}'",
       "to #{comparison}",
       "#{expected.inspect},",
       'but got',
       actual_object.inspect].compact.join("\n")
    end
  end
end
