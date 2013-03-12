# require 'capybara/node/matchers'

# module Capybara
#   module Node
#     module Matchers
#       # This matcher that will perform a scan of the given keywords
#       # in the specified order across the node's content, regardless
#       # of what's in between the keywords.
#       #
#       # Usage example: some HTML node might have the following inner text:
#       # => 'The payment method "Cash" has been removed.'
#       #
#       # That content can be matched by:
#       #
#       # => has_keywords?('method removed')          # => true
#       # => has_keywords?('method payment removed')  # => false
#       def has_keywords?(*keywords)
#         if keywords.size == 1
#           keywords = keywords.first.split(/\s/)
#         end
#         if self.respond_to?(:has_text?)
#           has_text?(Regexp.new(keywords.join('.*')))
#         else
#           normalize_whitespace(text).match(Regexp.new(keywords.join('.*')))
#         end
#       end

#       alias_method :have_keywords, :has_keywords?
#     end
#   end
# end