module PageHub
  module Helpers

    def password_salt()
      rand(36**16).to_s(32)[0..6]
    end

    def tiny_salt(r = 3)
      Base64.urlsafe_encode64 Random.rand(1234 * (10**r)).to_s(8)
    end

    def sane_salt(pepper)
      Base64.urlsafe_encode64( pepper + Time.now.to_s)
    end

    def salt(pepper = "")
      pepper = Random.rand(12345 * 1000).to_s if pepper.empty?
      pepper = pepper + Random.rand(1234).to_s
      sane_salt(pepper)
    end

    def md(content)
      content.to_s.to_markdown
    end

    def __host
      request.referer.scan(/http:\/\/[^\/]*\//).first[0..-2]
    end

    def pretty_time(datetime)
      datetime.strftime("%D")
    end

    def pluralize(number, word)
      number == 1 ? "#{number} #{word}" : "#{number} #{word}s"
    end

    def vowelize(word)
      word.to_s.vowelize
    end

    def ordinalized_date(date)
      month = date.strftime('%B')
      day   = DataMapper::Inflector.ordinalize(date.day)
      year  = date.year

      "the #{day} of #{month}., #{year}"
    end
  end
end

class String
  Vowels = ['a','o','u','i','e']
  def vowelize
    Vowels.include?(self[0]) ? "an #{self}" : "a #{self}"
  end

  def to_plural
    DataMapper::Inflector.pluralize(self)
  end

  def pluralize(n = nil, with_adverb = false)
    plural = to_plural
    n && n != 1 ? "#{with_adverb ? 'are ' : ''}#{n} #{plural}" : "#{with_adverb ? 'is ' : ''}1 #{self}"
  end
end

helpers do
  include PageHub::Helpers

  def h(*args)
    ERB::Util.h(*args)
  end

  def title(*args)
    args << (h @space.title)   if @space
    args << (h @user.nickname) if @user
    args.reject { |s| !s || s.empty? }.join(' | ')
  end
end