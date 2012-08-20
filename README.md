## PageHub

An online service for composing documents using [Markdown](http://daringfireball.net/projects/markdown/) syntax.

The application is built using Ruby, it runs on a MySQL backend, and has the following gem dependencies:

* `gem 'sinatra'`
* `gem 'sinatra-content-for'`
* `gem 'sinatra-flash'`
* `gem "data_mapper", ">=1.2.0"`
* `gem 'redcarpet'`
* `gem 'albino'`
* `gem 'nokogiri'`

[CodeMirror](http://codemirror.net) is used for the Markdown JavaScript editor.

PageHub extends the RedCarpet Markdown renderer to add support for the following:

### Table of Contents generation

See [this article](http://www.mxvt.net/articles/toying-with-markdown-smart-table-of-content-generation-and-document-embedding) for more information about the usage of this feature. The code lies in `lib/toc.rb`.

### Document embedding

I'm tired of having to maintain multiple versions of documents that contain the very same information, so I added an embedding facility that allows you to get content out of a page and insert it into a page on PageHub.

The embedding module allows for the definition of *content processors* that handle the data extraction from certain sources; for example, I have many documents on GitHub Wikis and I wanted to use some of them, so I was able to define a processor that extracts (using `nokogiri`) the content of wiki articles and embed them in my PageHub ones.

## Compatibility

I've tested PageHub only on the latest Chrome, Firefox, and Opera under Linux. I'm not sure if it works on IE.

## Bugs, feature requests, etc.

You can either use the GitHub issue tracking system or email me directly, I'll be happy to hear any feedback.

## License

The thing is open and free. Host it yourself if you want to, and the license is public domain; do whatever you want with it.