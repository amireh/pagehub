var $;
var jQuery;
if (!$ && !jQuery) {
  throw("jQuery could not be found, dynamism requires it.");
}

dynamism = function(options) {
  var stages      = [ "all", "addition", "removal", "post-removal", "post-injection" ],
      callbacks   = {},
      injections  = [],
      factories   = {},
      options     = $.extend({
        debug: true,
        logging: true,
        log_target: null,
        log_out: null
      }, options);
  
  $.apply_on = function(el, method) {
    $(el).each(function() { method($(this)); });
  }

  /* -------
   * Utility
   * ------- */
  /** Log output function, overridden if options.log_target is given */
  var log_out = function(msg) {
    console.log(msg);
  }

  var log;
  log = function(m, ctx) { 
    ctx = ctx || "D";
    log_out("[" + ctx + "] " + m);
  }

  function setup() {

    // DEBUG log entries will not be logged
    if (!options.debug) {
      log = function(m, ctx) {
        if (!ctx || ctx == "D")
          return false;

        return log_out("[" + ctx + "] " + m);
      }
    }

    // Logs will be inserted as list items in a given container
    if (options.log_target) {
      var list = options.log_target.html("<ol></ol>").find("ol:first");
      log_out = function(m) {
        var ctx = m.substr(1,1);
        list.append("<li class='" + ctx +"'><em>" + ctx + "</em> " + m.substr(4) + "</li>")
      }
    }

    if (!options.logging) {
      log_out = function() { }
    }
  }

  /** For logging objects instead of getting [object Object] */
  var dump;
  if (!dump) {
    dump = function(el) {
      var self = $(el)[0];
      var out = '<' + self.tagName;
      
      if (self.attributes) {
        for (var i = 0; i < self.attributes.length; ++i) {
          var pair = self.attributes[i]
          out += ' ' + pair.name + '="' + pair.value + '"';
        }
      }

      out += ' />';
      return out;
    }
  }
  
  /** Convenient closure-based array iterator */
  var foreach;
  if (!foreach) {
    foreach = function(arr, handler) {
      arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
    }
  }

  // initialize the stage callbacks
  foreach(stages, function(stage) { callbacks[stage] = [] });

  /**
   * Replaces [ and ] with \\\[ and \\\] respectively.
   * This is required for jQuery selectors locating attribute values that
   * contain any bracket
   */
  $.escape = function(str) {
    return str.replace(/\[/g, '\\\[').replace(/\]/g, '\\\]');
  }
  // alias
  var escape_indexes = $.escape;

  /**
   * Joins an array of strings by [].
   * Useful for building a nested ID and usually used with $.escape()
   */
  function indexize(str_arr) {
    if (typeof(str_arr) == "string")
      str_arr = [ str_arr ];
    var str = "";
    for (var i = 0; i < str_arr.length; ++i) {
      if (!str_arr[i] || str_arr[i] == "")
        continue;

      str += '[' + str_arr[i] + ']';
    }
    return $.escape(str);
  } // dynamism::indexize()

  /**
   * Attempts to locate a method by its fully-qualified name, ie
   * `dynamism.foo.bar`.
   */
  function method_from_fqn(fqn) {
    var parts = fqn.split('.');
    if (parts.length == 0 && !window[fqn])
      return null;

    var method = window[parts[0]];
    for (var i = 1; i < parts.length; ++i) {
      if (!method)
        return null

      method = method[parts[i]];
    }

    return method;
  } // dynamism::method_from_fqn()

  /**
   * Attempts to locate a dynamism entity based on the given
   * element's @data-dyn-target attribute, or if not found
   * will traverse the ancestry chain until an element with
   * the @data-dyn-entity attribute is found.
   *
   * @param el if not set, $(this) is assumed
   *
   * @note Used by dynamism.add() and dynamism.remove()
   *
   * @return null if the target could not be found
   * @return $(target)
   */
  function locate_target(el) {
    var target = null;
    var target_name = $(el).attr("data-dyn-target");
    var target_index = $(el).attr("data-dyn-target-index");

    // An implicit relationship with the entity is assumed;
    // we will look for the first data-dyn-entity up the
    // DOM and use it as the target
    if (!target_name) {
      var parent = $(el).parents("[data-dyn-entity]:not([data-dyn-index=-1]):first");
      if (parent.length == 0) {
        log("Unable to find any parent entity for: " + dump(el), "E");
        return null;
      }

      target = parent;
      // log("Target found implicitly:" + dump(target), "N");
    }

    target = target ||
      $("[data-dyn-entity='" + $.escape(target_name) + "']" +
        "[data-dyn-index=" + target_index + "]");

    if (target.length == 0) {
      log("Target could not be located by: " + dump(el), "E");
      return null;
    }

    return target;
  } // dynamism::locate_target()

  /**
   * Substitutes all occurences of the "reference" (see note below)
   * with the injection value, @value. The substitution can either
   * be a full replacement, or a partial one when wildmarks are used.
   *
   * For example, the following node will have its @href attribute 
   * injected with the `id` key's value _only_ where %id is placed.
   * However, its text() node will be emptied and replaced with `label`:
   *
   * @code
   *  <a href="/posts/%id" data-dyn-inject="@href, id, @text, label">
   *    This will be erased.
   *  </a>
   * @endcode
   *
   * @note The reference is built either using the @key, or is composed
   *       of the context (__ctx.join('.')) and suffixed by the @key.
   *
   * @note The substitution is not limited to one node, but will
   *       be performed on all the nodes that match the conditions.
   */
  function substitute(key, value, el, __ctx) {
    // build up the reference that the attribute value must match
    var reference = __ctx.length > 0
      ? __ctx.join('.') + '.' + key
      : key;

    // log("\tInjecting value: " + value + " in context: " + __ctx);

    // We need to locate the target(s) now
    reference = $.escape(reference);
    var targets = el.find('[data-dyn-inject]:visible,input[data-dyn-inject][type=hidden]');
    if (el.attr("data-dyn-inject")) {
      log("Self-object wants to be injected too! " + el.attr("data-dyn-inject"), "N");
      targets = targets.add(el);
    }

    targets = targets.filter(function() {
      return $(this).attr("data-dyn-inject").trim().match(RegExp('@\\\S+,\\\s*' + reference));
    });

    targets.each(function() {
      var target = $(this);

      // Find out whether we're injecting into an attribute or 
      // the target's inner text() node
      var parts = target.attr("data-dyn-inject").trim().split(/,\s*/);

      // assert proper syntax (each node must map to an injection)
      if (parts.length % 2 != 0) {
        // yes, alert, this is a programmer mistake
        alert("Syntax error: " + parts.join(' ') + " are not even!");
        return false;
      }

      // var nr_attrs = parts.length / 2;
      for (var j = 0; j < parts.length; j += 2) {
        
        // Is not interested with the current injection
        if (parts[j+1] != reference) {
          if (target.is(el)) {
            log("Self is not interested in " + parts[j+1]);
          }
          continue;
        }
        // Has already been injected
        else if (is_injected(target, parts[j], reference)) {
          log("this element has already been injected with " + 
              parts[j] + " for " + reference + ", skipping", "N");

          continue;
        }

        // the attribute or text node we will be injecting into
        var node = parts[j].substr(1 /* trailing @ */);

        // log(node + " => " + value + " #" + reference);

        // Now we perform the actual substitution:
        // 1. handle text() nodes
        if (node == 'text') {
          // substitute the wildmark(s)
          if (target.html().search('%' + key) != -1) {
            target.html(target.html().replace(RegExp('%' + key, "g"), value));
          }
          // no wildmarks used, replace the whole value
          else {
            target.html(value);
          }
        }
        // 2. and @attributes
        else {
          var attr_value = target.attr(node);
          // like text() above, substitute wildmarks if any
          if (attr_value && attr_value.search('%' + key) != -1) {
            var replacement = RegExp('%' + key, "g");
            target.attr(node, attr_value.replace(replacement, value));
          }
          // or replace/create the attribute value
          else {
            target.attr(node, value);                      
          }                    
        } // dest is an @attribute

        track_injection(target, '@' + node, reference);
      } // injection parts loop
    }); // targets loop

    if (targets.length == 0) {
      log("Could not find any entity referencing: " + reference, "E");
    }
  } // dynamism::substitute()

  /** Helper used internally by is_injected() and track_injection() */
  function __injection_id(node, reference) { return node + ' ' + reference; }

  /** Returns true if @element has had its @node injected by @reference. */
  function is_injected(element, node, reference) {
    for (var i = 0; i < injections.length; ++i) {
      var entry = injections[i];
      if (element.is(entry.o)) {
        if (entry.injections.search(__injection_id(node, reference)) != -1)
          return true;
      }
    }

    return false;
  } // dynamism::is_injected()

  /** Nodes will not be injected more than once for every @reference and @node pair. */
  function track_injection(element, node, reference) {
    var found = false;
    for (var i = 0; i < injections.length; ++i) {
      var entry = injections[i];
      if (element.is(entry.o)) {
        entry.injections += __injection_id(node, reference);
        found = true;
        break;
      }
    }

    if (!found) {
      injections.push({ o: element, injections: __injection_id(node, reference) });
    }
    // log("Injection: " + reference + " into " + node)
    log("Injection: " + reference + " into " + node + " on " + dump(element))
  } // dynamism::track_injection()

  /** Is the given string a dynamism stage? (see dynamism.stages) */
  function is_stage(str) {
    for (var i = 0; i < stages.length; ++i)
      if (stages[i] == str)
        return true;

    return false;
  } // dynamism::is_stage()

  /**
   * Binds all specified methods to their events which can be either
   * dynamism stage events, or window events (click, hover, etc.).
   *
   * The definition is read from the attribute @data-dyn-hook, syntax:
   *  data-dyn-hook="[,]event_or_stage, method_id"
   *
   * @note In the case of a window event, the element will _not_ be
   *       unbound from its current handlers, if any.
   *
   * @note This is called internally when dynamism.bind() is invoked.
   *
   * Side-effects:
   * => element's [data-dyn-hook] attribute will be removed
   */
  function attach_hooks() {
    var el = $(this);
    if (!el.attr("data-dyn-hook").match(/\s*\S+,\s*\S+/)) {
      log("hooks: invalid syntax, unable to parse event or method in: " + el.attr("data-dyn-hook"), "E");
      return false;   
    }

    var pairs = el.attr("data-dyn-hook").trim().split(/,\s*/);

    if (pairs.length % 2 != 0) {
      log("hooks: invalid syntax, odd number of event<->method pairs in: " + el.attr("data-dyn-hook"), "E");
      return false;
    }

    var hook_factory = function(element, method) {
      return function(el) { if (el.is(element)) { return method.apply(el, arguments); } return true; }
    }

    var pairs_sz = pairs.length;
    for(var i = 0; i < pairs_sz; i += 2) {
      var evt         = pairs[i],
          method_fqn  = pairs[i+1],
          method      = method_from_fqn(method_fqn);

      // log("hooks: checking whether " + evt + " is a dynamism event for " + method_fqn, "N")
      // log("Method: " + method, "N")

      if (typeof method_fqn == "string" && method && typeof method == "function") {
        // is it a dynamism hook or an event hook?
        if (is_stage(evt)) {
          dynamism.add_callback(hook_factory(el, method), evt);
        } // dynamism event

        else {
          log("hooks: binding window event: " + evt + " => " + method_fqn);
          el.bind(evt, method); // TODO: do we have to $.unbind() here?
        } // window event

      } else {
        log("hooks: Invalid event or method: " + evt + " => " + method_fqn, "E");
      }
    } // pair loop

    el.attr("data-dyn-hook", null);
  } // dynamism::attach_hooks()

  return {
    
    configure: function(opts) {
      options = $.extend(options, opts);
      setup();
    },
    callbacks: callbacks,

    add: function(target) {
      var target_name = null,
          target_index = null;

      if (target) {
        try {
          target = $(target);
          target_name = target.attr("data-dyn-entity");
          target_index = target.attr("data-dyn-index");

          if (!target_name || !target_index) {
            throw "Invalid target, has no identity or index";
          }

        } catch(e) {
          log(e);
          target = null;
        }
      }

      if (!target) {
        target_name   = $(this).attr("data-dyn-target");
        target_index  = $(this).attr("data-dyn-target-index") || -1;

        target = $("[data-dyn-entity='" + $.escape(target_name) + "']" +
                   "[data-dyn-index=" + target_index + "]");

        if (target.length == 0) {
          log("Unable to find entity. Invalid reference by: " + dump($(this)));
          return false;
        }

      }

      // determine the next index (based on the last entry's index)
      var last_entry = $("[data-dyn-entity='" + $.escape(target_name) + "']:last");
      var next_index = parseInt(last_entry.attr("data-dyn-index")) + 1;

      // do the actual cloning
      var clone = target.clone();
      clone.attr({  "hidden": null, "data-dyn-index": next_index });

      // Now we need to adjust all references by the children to this entity:
      // the reference will look like [my_name][-1] in any of the attributes.
      // It needs to reflect the actual index (next_index)
      var __orig_parent_name = RegExp(escape_indexes(target_name + '[-1]'), "g");
      var __real_parent_name = target_name + "[" + next_index + "]";
      clone.find("*").each(function() {
        var child = $(this);
        $.each(child.get(0).attributes, function(i, pair) {
          try {
            child.attr(
              pair.name,
              pair.value.replace(__orig_parent_name, __real_parent_name));
          } catch (e) {
            // ignore properties that can't be changed
            // log("Property " + pair.name + " can't be changed!")
          }
        });

        // if the child points to us, adjust the pointing index
        if (child.attr("data-dyn-target") == target_name) {
          // inject the parent index into IMMEDIATE children that ask for it
          if (child.attr("data-dyn-inject") == "index") {
            child.html(next_index);
          }

          child.attr("data-dyn-target-index", next_index);
        }
      });

      clone.find("[data-dyn-inject=index]:not([data-dyn-target])").each(function() {
        var child = $(this);
        if (child.parents("[data-dyn-entity]:first").attr("data-dyn-entity") == clone.attr("data-dyn-entity"))
          child.html(next_index);
      })

      dynamism.bind(clone);

      // target.parent().append(clone);
      $("[data-dyn-entity=" + $.escape(target_name) + "]:last").after(clone);
      // target.after(clone);

      foreach(callbacks["addition"], function(cb) { cb(clone); });
      foreach(callbacks["all"],      function(cb) { cb(clone, "addition"); });

      return clone;
    }, // dynamism.add

    utility: {
      lookup_method: function(fqn) {
        return method_from_fqn(fqn);
      }
    },

    remove: function() {
      var target  = locate_target($(this)),
          btn     = $(this);

      if (!target)
        return false;

      try {
        foreach(callbacks["removal"], function(cb) { cb(target, btn); });
        foreach(callbacks["all"],     function(cb) { cb(target, "removal", btn); });
      } catch(e) {
        log("Removal aborted per requested. Given cause: " + e, "E");
        return false;
      }

      target.remove();

      foreach(callbacks["post-removal"],  function(cb) { cb(null, btn); });
      foreach(callbacks["all"],           function(cb) { cb(null, "post-removal", btn); });
    }, // dynamism.remove
    
    /**
     * Parses the JSON feed @feed, traverses its values and
     * populates nodes found in @el that are interested in
     * the injection data.
     *
     * Nodes can specify the injection using the @data-dyn-inject
     * attribute which has the following syntax:
     * => data-dyn-inject="@node, method_fqn"
     *
     * @node can be the special 'text' node, or any attribute node. Note
     * that the leading @ is required!
     *
     * Each pair of target node and method_fqn is called an injection.
     * Multiple injections can be defined, simply separate
     * them by commas.
     *
     * Example: injecting a text node with a value found in the JSON feed
     * at `feed.page.title`:
     *  @code
     *    <span data-dyn-inject="@text, page.title">%title</span>
     *  @endcode
     *
     * The %wildmark is optional, if it is omitted, then the target
     * node (text() in our example) will be _replaced_ with the feed
     * value if found.
     *
     * For more information, see dynamism::substitute() above.
     */
    inject: function(feed, el, __ctx) {
      var initial = !__ctx,
          __ctx   = __ctx || [],
          key     = null;

      for (key in feed) {
        var value = feed[key];
        // log(typeof(key) + " => " + typeof value);
        // log(key + " => " + value);
        switch(typeof value) {
          case "string":
          case "number":
            substitute(key, value, el, __ctx);
            break;
          case "object":
            // it's an object, not an array, so we update the
            // context and proceed with injection normally
            if (isNaN(parseInt(key))) {
              __ctx.push(key);
              log("Context: " + __ctx);
              dynamism.inject(value, el, __ctx);
              __ctx.pop();
            }
            // it's an array of objects, we will look if there's
            // any factory method registered for this kind of objects
            // and if there is, we create an element and inject that
            else {
              var model = __ctx.join('.'),
                  new_el = null,
                  factory = factories[model];

              log("Looking for a factory for " + model)
              // is there user-defined factory?
              if (factory) {
                log("\tUsing user-defined factory for: " + model);
                new_el = factory(el, feed[key], feed);
              }
              // look for a template node
              else {
                log("\tLooking for a factory for model: " + model);

                // might be more than one node interested in this
                var tmpl = el.find("[data-dyn-spawn-on='" + model +"'][data-dyn-index=-1]");
                if (tmpl.length > 0) {
                  log("\t\tFound " + tmpl.length + "!")
                  new_el = $();
                  // we handle them all
                  tmpl.each(function() {
                    var me = $(this);
                    new_el = new_el.add( dynamism.add(me) );
                  });
                }
              }

              if (new_el && new_el.length > 0) {
                // we inject once for each newly created model
                new_el.each(function() {
                  var me = $(this);
                  dynamism.inject(value, me, __ctx);

                  // invoke any injection hooks attached to this element
                  if (me.attr("data-dyn-hook")) {
                    foreach(callbacks["post-injection"],  function(cb) { cb(me, value); });
                    foreach(callbacks["all"],             function(cb) { cb(me, "post-injection", value); });                  
                  }
                })
              } else {
                log("Unable to create model: " + model + ", no factory found.", "W");
              }
            
            }
            break;
          default:
            log("Unknown value type: " + typeof(value), "E");
        }
      }

      // we're done injecting
      if (initial) {
        log("Invoking all post-injection hooks");
        foreach(callbacks["post-injection"],  function(cb) { cb(el, feed); });
        foreach(callbacks["all"],             function(cb) { cb(el, "post-injection", feed); });
      }
    }, // dynamism.inject

    /**
     * Binds the dynamism addition and removal handlers
     * specified in the given element and its children.
     *
     * Handlers can be bound using the @data-dyn-action
     * attribute which can have the values "add" or "remove".
     *
     * @note This is called automatically for you whenever an entity
     *       is added using dynamism.add().
     */
    bind: function(root) {
      if (!root || $(root).length == 0) {
        root = $("*");
      }

      // addition bindings
      root.find("[data-dyn-target]:not([data-dyn-action]),"
              + "[data-dyn-target][data-dyn-action='add']")
          .unbind('click', dynamism.add)
          .bind('click', dynamism.add);

      // removal bindings
      root.find("[data-dyn-action='remove']")
          .unbind('click', dynamism.remove)
          .bind('click', dynamism.remove);
    }, // dynasmism.bind

    /**
     * 
     * @note Called internally whenever an entity is added.
     */
    hook: function(root) {
      var hooks_group = null;
      try {
        hooks_group = root.find("[data-dyn-hook]:visible");
      } catch (err) {
        return alert("Unable to inject: " + root + ". Cause: " + err)
      }

      if (root.attr("data-dyn-hook")) {
        hooks_group = hooks_group.add(root);
      }

      hooks_group.each(attach_hooks);
    },
    /**
     * @action can be one of "all", "addition", or "removal"
     *
     * All callbacks receive two arguments: the element (if applicable),
     * and the stage (see @dynamism.stages)
     */
    add_callback: function(cb, action) {
      var action = action || "all";
      
      if (!cb) {
        throw "Undefined " + action + " callback: " + cb;
      }
      else if (typeof cb != "function") {
        throw "Bad callback type given: " + typeof cb
      }

      callbacks[action].push(cb);
    }, // dynamism.add_callback

    /**
     * Registers a method to be called when an entity
     * has been cloned and added.
     *
     * This is handy for installing bindings for elements
     * contained in the entity if needed.
     *
     * Callback will receive the element for the first argument.
     */
    on_addition: function(cb) { 
      return dynamism.add_callback(cb, "addition");
    },

    /**
     * Registers a method to be called right *before* an 
     * entity is removed.
     *
     * Callback will receive the element for the first argument.
     */
    on_removal: function(cb) {
      return dynamism.add_callback(cb, "removal");
    },

    /**
     * Callback will receive null for an element!
     */
    after_removal: function(cb) {
      return dynamism.add_callback(cb, "post-removal");
    },

    /**
     * Callback will receive the injected element. Called
     * after an element has been fully injected (its registered
     * feed has been fully parsed.)
     *
     * To validate the identity of a *certain* injected element,
     * use jQuery's is():
     * @code
     *  function my_cb(el) {
     *    if ($("some_selector").is(el)) {
     *      // OK, this is the element that you want
     *    }
     *  }
     * @endcode
     */
    after_injection: function(cb) {
      return dynamism.add_callback(cb, "post-injection");
    },

    register_factory: function(model, factory) {
      if (factories[model]) {
        alert("Seems like you've already registered a factory for: " + model);
        return false;
      }

      if (typeof factory != "function") {
        alert("Factory must be a method that creates an"
            + "object, given was: " + typeof(factory) + " for model: " + model);
        return false;
      }

      factories[model] = factory;
      log("Registered factory for: " + model);
    }
  } // dynamism.return
}();

$(function() {
  // hide all entity templates (ones with [data-dyn-index = -1] or none at all)
  $("[data-dyn-entity]:not([data-dyn-index])").attr({ "data-dyn-index": -1 });
  $("[data-dyn-entity][data-dyn-index=-1]").attr({ "hidden": "true" });

  // Attach the hooks after elements are created & populated
  dynamism.after_injection(dynamism.hook);

  // Remove all the injection attributes from the newly injected nodes.
  // This isn't really "required", it only makes the markup less cluttered
  var __injection_attributes_to_cleanup
  = [ "data-dyn-inject", "data-dyn-spawn-on", "data-dyn-hook" ];
  dynamism.after_injection(function(el) {
    for (var i = 0; i < __injection_attributes_to_cleanup.length; ++i) {
      var attr = __injection_attributes_to_cleanup[i];
      el.find("[" + attr + "]:visible").attr(attr, null);
      el.attr(attr, null);
    }
  });

  // Bind all template buttons
  // dynamism.bind($("*"));
});
