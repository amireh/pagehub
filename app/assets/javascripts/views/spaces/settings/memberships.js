define(
'views/spaces/settings/memberships',
[ 'backbone', 'jquery', 'pagehub', 'hb!spaces/settings/membership_record.hbs' ],
function(Backbone, $, UI, MembershipRecordTmpl) {

  var SpaceMembershipsSettingsView = Backbone.View.extend({
    el: $("#space_membership_settings"),

    events: {
      // 'keyup #user_search':       'queue_user_lookup',
      'click button':             'consume',
      // 'click #user_listing li':   'add_user',
      'click [data-action=kick]': 'kick_user',
      'change #membership_records input[type=radio][name^=users]': 'rankify'
    },

    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx;
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

      this.space.save({
        memberships: [{
          user_id: membership.id,
          role:    role
        }]
      }, {
        patch: true,
        wait: true,
        success: function() {
          UI.status.show("Member role updated.", "good");
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

    add_user: function(e, ui) {
      var el            = $(e.target),
          user_nn       = ui.item.value,
          user_avatar   = ui.item.icon;
          view          = e.data,
          m             = view.membership_from_id(user_nn);

      view.elements.user_search.val(ui.item.label);

      e.preventDefault();

      if (m) {
        UI.status.show(m.nickname + " is already a member!", "bad");
        return true;
      }

      // var user_id = _.where(view._ctx.users, { nickname: user_nn })[0].id;
      var user_id = user_nn;

      view.space.save({
        memberships: [{
          user_id: user_id,
          role:    'member'
        }]
      }, {
        patch: true,
        wait: true,
        success: function() {
          UI.status.show("Member added.", "good");
          view.add_record(view.membership_from_id(user_id));
        }
      });

      return true;
    },

    kick_user: function(e) {
      var el    = $(e.target),
          m     = this.membership_from_record(el),
          view  = this;

      this.space.save({
        memberships: [{
          user_id: m.id,
          role:    null
        }]
      }, {
        patch: true,
        wait: true,
        success: function() {
          view.elements.membership_records.find('#user_' + m.id).remove();
          UI.status.show( m.nickname + " is no longer a member of this space.", "good");
        }
      });
    }
  });

  return SpaceMembershipsSettingsView;
});