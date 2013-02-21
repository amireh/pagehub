FlashTypes = [ 'notice', 'error', 'warning' ]

def should_flash(type, keywords)
  page.should have_selector('.flashes.' + type.to_s)
  page.find('.flashes.' + type.to_s).should have_keywords(keywords)
end


def should_only_flash(type, keywords)
  FlashTypes.each { |excluded_type|
    next if excluded_type == type.to_s
    page.should_not have_selector(".flashes.#{excluded_type}")
  }

  should_flash(type, keywords)
end