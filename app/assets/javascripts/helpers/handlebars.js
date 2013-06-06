define('helpers/handlebars', [ 'underscore', 'Handlebars', 'md5', 'underscore.inflection' ], function(_, Handlebars) {
  Handlebars.registerHelper("pluralize", function (word, count) {
    return _(word).pluralize(count, true);
  });

  Handlebars.registerHelper('escape', function(word) {
    return _.escape(word);
  });

  Handlebars.registerHelper('h', function(word) {
    return _.escape(word);
  });

  Handlebars.registerHelper('checkify', function(attribute, values) {
    if (_.indexOf(values.split(' '), attribute) != -1) return 'checked="checked"';
    else return '';
  });

  Handlebars.registerHelper('gravatar_hash', function(email) {
    return md5(email.trim().toLowerCase());
  });

  return {};
});
