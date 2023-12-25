# frozen_string_literal: true

RSpec.describe DeepMatching do
  include described_class

  it 'matches idential hashes' do
    a = {a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7}

    expect_deep_matching(a, a)
  end

  it 'does not match non identical hashes but ignores extra keys' do
    expected = {bar: 1}
    actual = {foo: 1, bar: 2}

    expect_failure(
      actual, expected,
      {path: 'bar', expected_value: 1, got: 2}
    )
  end

  it 'supports subhashes' do
    a = {a: 1, b: {c: 2}}

    expect_success(a, a)

    a = {a: 1, b: {c: 2, d: [{c: 2}, {c: 2, d: {e: 3}}]}}
    expect_success(a, a)
  end

  it 'fails with mismatching subhashes' do
    actual = {a: 1, b: {c: 2}}
    expected = {a: 1, b: {c: 3}}

    expect_failure(actual, expected, path: 'b.c', expected_value: 3, got: 2)
  end

  it 'fails with mismatching heavily nested in hashes and arrays' do
    actual   = {a: 1, b: {c: [1, 2, {d: 'actual'  }]}}
    expected = {a: 1, b: {c: [1, 2, {d: 'expected'}]}}

    expect_failure(actual, expected, path: 'b.c.2.d', expected_value: '"expected"', got: '"actual"')
  end

  it 'produces multiple failure messages' do
    actual   = {a: 1, b: {c: [1, 2, {d: 'actual'  }]}}
    expected = {a: 2, b: {c: [1, 2, {d: 'expected'}]}}

    expect_multiple_failures(
      actual,
      expected
    )

    message = @raised_messages[0].gsub(/^\s+/, '')

    expect_in_message(message, <<~FAILURE)
      Got 3 failures from failure aggregation block "multiple failures":
    FAILURE

    expect_in_message(message, <<~FAILURE)
      1) Expected hash key at 'a'
        to eq
        2,
        but got
        1
    FAILURE

    expect_in_message(message, <<~FAILURE)
      2) Expected nested hash key at 'b.c.2.d'
         to eq
         "expected",
         but got
         "actual"
    FAILURE
  end

  def expect_in_message(message, expected)
    expect(message).to include(expected.chomp.gsub(/^\s+/, ''))
  end

  def expect_success(actual, expected)
    expect_deep_matching(actual, expected)
  end

  def expect_multiple_failures(actual, expected)
    @raised_messages = []

    aggregate_failures('multiple failures') do
      with_failure_expectation(actual, expected) do |failure|
        @raised_messages << failure.message
      end
    end
  rescue RSpec::Expectations::ExpectationNotMetError => e
    @raised_messages << e.message
  end

  def expect_failure(actual, expected, expected_failure)
    expected_value = expected_failure[:expected_value]
    got = expected_failure[:got]
    path = expected_failure[:path]

    nested = path.match(/^(.*)\.(.*)$/) ? 'nested ' : ''

    with_failure_expectation(actual, expected) do |failure|
      expect(failure.message).to eq  <<~FAILURE.chomp
        Expected #{nested}hash key at '#{path}'
        to eq
        #{expected_value},
        but got
        #{got}
      FAILURE
    end
  end

  def with_failure_expectation(actual, expected, &block)
    expect { expect_deep_matching(actual, expected) }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError, &block)
  end
end
