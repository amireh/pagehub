helpers do
  def current_nav_section
    content_for?(:nav_section) ? yield_content(:nav_section) : ''
  end

  def current_nav_section?(section)
    current_nav_section == section
  end

  def highlight_if(cnd)
    res = cnd
    res = cnd.call if cnd.respond_to?(:call)
    res ? 'selected' : ''
  end

  def nav_highlight(section)
    highlight_if current_nav_section?(section)
  end
end