Handlebars.registerHelper("pluralize", function (word, count) {
  return _(word).pluralize(count, true);
});

Handlebars.registerHelper('if', function(conditional, options) {
  if(conditional) {
    return options.fn(this);
  }
});