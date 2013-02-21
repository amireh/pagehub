object @page

node do |p|
  {
    url:  p.url,
    href: p.href,
    revisions: {
      url:  p.revisions_url,
      href: p.revisions_url
    }
  }
end