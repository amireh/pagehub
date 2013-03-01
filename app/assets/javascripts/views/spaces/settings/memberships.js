define(
'views/spaces/settings/memberships',
[ 'views/spaces/settings/setting_view', 'jquery', 'pagehub', 'hb!spaces/settings/membership_record.hbs' ],
function(SettingView, $, UI, MembershipRecordTmpl) {

  var SpaceMembershipsSettingsView = SettingView.extend({
    el: $("#space_membership_settings"),

    events: {
      // 'keyup #user_search':       'queue_user_lookup',
      'click button':             'consume',
      // 'click #user_listing li':   'add_user',
      'click [data-action=kick]': 'kick_user',
      'change #membership_records input[type=radio][name^=users]': 'rankify'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);
      this._ctx   = {};

      this.lookup_timer = null;
      this.lookup_pulse = 250;

      this.elements = {
        user_search:        this.$el.find('#user_search'),
        user_listing:       this.$el.find('#user_listing'),
        membership_records: this.$el.find('#membership_records')
      }

      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;

      this.elements.user_search.autocomplete({
        delay:    this.lookup_pulse,
        appendTo: this.elements.user_listing,
        focus: function(e) { e.preventDefault(); return false },
        // select:   this.add_user,
        source: function(request, handler) {
          $.ajax({
            url:    "/users/lookup/by_nickname",
            method: "GET",
            data: { nickname: request.term },
            success: function(users) {
              view._ctx.users = users;
              handler(_.collect(users, function(u) {
                return { label: u.nickname, value: u.id, icon: u.gravatar }
              }));
            }
          })
        }
      }).data( "ui-autocomplete" )._renderItem = function( ul, item ) {
        return $( "<li>" )
          .append( "<a><img src=\"" + item.icon + "\" /> " + item.label + "</a>" )
          .appendTo( ul );
      };

      this.elements.user_search.on('autocompleteselect', view, view.add_user);

      return this.space.get('memberships').every(function(user) {
        return this.add_record(user);
      }, this);
    },

    membership_from_id: function(id) {
      return _.select(this.space.get('memberships'), function(m) { return m.id == id; })[0];
    },
    membership_from_nickname: function(id) {
      return _.select(this.space.get('memberships'), function(m) { return m.nickname == id; })[0];
    },

    membership_from_record: function(el) {
      var user_id = el.parents('tr[id]:first').attr("id").replace('user_', '');
      return this.membership_from_id(user_id);
    },

    add_record: function(user) {
      this.elements.membership_records.append(MembershipRecordTmpl(user));
      return this;
    },

    rankify: function(e) {
      var el          = $(e.target),
          membership  = this.membership_from_record(el),
          role        = el.val(),
          view        = this;

      view.trigger('sync', {
        memberships: [{
          user_id: membership.id,
          role:    role
        }]
      }, {
        success: function() {
          UI.status.show(membership.nickname + " is now a " + role.vowelize() + " of this space.", "good");
        },
        error: function() {
          el.parents("tr:first").replaceWith(MembershipRecordTmpl(membership))
          // el.attr("checked", null);
          // el.parents("td:first").find("[value=" + membership.role + "]").attr("checked", true);
        }
      });

      e.preventDefault();
      return false;
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    serialize: function() {
      return {}
    },

    add_user: function(e, ui) {
      var el            = $(e.target),
          user_id       = ui.item.value,
          user_nn       = ui.item.label,
          user_avatar   = ui.item.icon;
          view          = e.data,
          m             = view.membership_from_id(user_id);

      view.elements.user_search.val(ui.item.label);

      e.preventDefault();

      if (m) {
        UI.status.show(m.nickname + " is already a member!", "bad");
        return true;
      }

      view.trigger('sync', {
         memberships: [{
          user_id: user_id,
          role:    'member'
        }]
      }, {
        success: function() {
          UI.status.show(user_nn + " is now a member of this space.", "good");
          view.add_record(view.membership_from_id(user_id));
        }
      })

      return true;
    },

    kick_user: function(e) {
      var el    = $(e.target),
          m     = this.membership_from_record(el),
          view  = this;

      view.trigger('sync', {
        memberships: [{
          user_id: m.id,
          role:    null
        }]
      }, {
        success: function() {
          view.elements.membership_records.find('#user_' + m.id).remove();
          UI.status.show( m.nickname + " is no longer a member of this space.", "good");
        }
      });
    }
  });

  return SpaceMembershipsSettingsView;
});