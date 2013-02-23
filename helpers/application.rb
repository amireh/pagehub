helpers do
  def jstemplate(tmpl)
    m = "<script id=\"#{tmpl}_template\" type=\"text/x-handlebars-template\">"
    m << erb("../app/templates/#{tmpl}.hbs", layout: false)
    m << "</script>"
  end
end