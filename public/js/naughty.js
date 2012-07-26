/* Overriding Javascript's Confirm Dialog */

// NOTE; A callback must be passed. It is executed on "cotinue". 
//  This differs from the standard confirm() function, which returns
//   only true or false!

// If the callback is a string, it will be considered a "URL", and
//  followed.

// If the callback is a function, it will be executed.

function confirm(msg,callback) {
  $('#confirm')
    .jqmShow()
    .find('p.jqmConfirmMsg')
      .html(msg)
    .end()
    .find(':submit:visible')
      .click(function(){
        if(this.value == 'Yes')
          (typeof callback == 'string') ?
            window.location.href = callback :
            callback();
        $('#confirm').jqmHide();
      });
}

$(function() {
  $('#confirm').jqm({overlay: 88, modal: true, trigger: false});
  
  // trigger a confirm whenever links of class alert are pressed.
  $('a.confirm').click(function() { 
    // confirm('About to visit: '+this.href+' !',this.href);
    var a = $(this);
    confirm(a.attr("data-confirmation"), function() {
      console.log("modal was accepted...");
      ui[a.attr("data-confirmation-cb")]();
    });

    return false;
  });
})

ui.delete_page = function() {
  console.log("DELETING")
  var entry = $("li.selected");
  var page_id = entry.attr("id").replace("page_", "");
  var page_title = entry.html();

  $.ajax({
    type: "DELETE",
    url: "/pages/" + page_id,
    success: function() {
      ui.status("Page " + page_title + " is now dead :(", "good");
      entry.remove();
      ui.editor.setValue("");
      ui.actions.addClass("disabled");
    }
  });
}