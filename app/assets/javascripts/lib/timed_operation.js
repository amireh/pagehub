define('timed_operation', [ 'underscore', 'backbone' ], function(_, Backbone) {
  return Backbone.Model.extend({

    initialize: function(object, callback, options) {
      if (!callback) {
        throw "[timed_operation]: invalid argument @callback, must be a callable object, got " + typeof(callback);
      }

      this.options = {};

      _.implode(this.options, $.extend({}, {
        pulse: 250,
        with_flag: false,
        autoqueue: false
      }, options));

      this.timer      = null;
      this.__callee   = object; /* for lack of better name, caller and callee are reserved... */
      this.__method   = callback;

    },

    __invoke_with_flag: function() {
      var args = []; for (var i = 0; i < arguments.length; ++i) { args.push(arguments[i]); };
      args.push(true);

      return this.__method.apply(this.__callee, args);
    },

    __invoke: function() {
      return this.__method.apply(this.__callee, arguments);
    },

    __start: function(callback) {
      this.stop();

      if (this.options.autoqueue) {
        this.timer = setInterval(callback, this.options.pulse);
      }
      else {
        this.timer = setTimeout(callback, this.options.pulse);
      }

      return this;
    },

    /**
     * Starts the recurring timer.
     */
    start: function() {
      if (this.options.autoqueue) {
        this.queue();
      }

      return this;
    },

    /**
     * Stops the timer.
     */
    stop: function() {
      if (this.timer) {
        if (this.options.autoqueue) {
          this.timer = clearInterval(this.timer);
        } else {
          this.timer = clearTimeout(this.timer);
        }
      }

      return this;
    },
    // alias to stop
    cancel: function() { return this.stop(); },

    /**
     * Queues an operation invocation.
     *
     * This will restart the timer.
     */
    queue: function() {
      var me    = this,
          args  = arguments;

      if (this.options.with_flag) {
        this.__start(function() { return me.__invoke_with_flag.apply(me, args); });
      } else {
        this.__start(function() { return me.__invoke.apply(me, args); });
      }

      return true;
    }
  })
});