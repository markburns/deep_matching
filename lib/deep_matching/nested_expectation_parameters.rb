module DeepMatching
  class NestedExpectationParameters
    include ActiveModel::Model
    attr_accessor :evaluation_context, :obj, :expected_obj, :nesting, :ignore_list, :failure_message_extra_context
  end
end
