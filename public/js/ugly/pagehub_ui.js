pagehub_ui=function(){function g(){return $(this).parent("[disabled],:disabled,.disabled").length>0?!1:(b($("a.listlike.selected")),$(this).next("ol").show(),$(this).addClass("selected"),$(this).unbind("click",g),$(this).add($(window)).bind("click",y),!1)}function y(e){return e.preventDefault(),b($(".listlike.selected:visible")),!1}function b(e){$(e).removeClass("selected"),$(e).next("ol").hide(),$(e).add($(window)).unbind("click",y),$(e).bind("click",g)}function w(){return ui.is_page_selected()?ui.current_page().attr("id").replace(/\w+_/,""):null}function E(){return ui.is_folder_selected()?ui.current_folder().parent().attr("id").replace("folder_",""):null}var e={on_entry:[]},t=null,n={autosave:null,sync:null},r="",i=!1,s=250,o=!1,u=null,a=[],f=!1,l=2500,c={autosave:30,sync:5},h={status:1},p={},d={},v={pages:{on_load:[]}},m=[function(){Modernizr.draganddrop||ui.modal.as_alert($("#html5_compatibility_notice"))},function(){dynamism.configure({debug:!1,logging:!1}),$("a[title]").tooltip({placement:"bottom"})},function(){$("[data-collapsible]").each(function(){$(this).append($("#collapser").clone().attr({id:null,hidden:null}))})},function(){$("#resource_editor input[type=text]").keyup(function(e){e.which==13?(e.preventDefault(),ui.resource_editor.save()):e.which==27&&(e.preventDefault(),ui.resource_editor.hide())}).click(function(e){e.preventDefault()}),$("#update_title").click(function(){return ui.resource_editor.save()}),$("#cancel_title_editing").click(function(){return ui.resource_editor.hide()})},function(){pagehub!==undefined&&pagehub.settings.editing.autosave&&(n.autosave=setInterval("ui.pages.save(true)",c.autosave*1e3),n.sync=setInterval("pagehub.sync()",c.sync*1e3))},function(){$("a[data-disabled], a.disabled").click(function(e){return e.preventDefault(),!1})},function(){$("#flashes button").click(function(){$(this).parent().next("hr:first").remove(),$(this).parent().addClass("hidden"),$(".flash_wrap").addClass("hidden")})},function(){$("a.listlike:not(.selected)").bind("click",g),$("ol.listlike li:not(.sticky), ol.listlike li:not(.sticky) *").click(function(){var e=$(this).parent().prev("a.listlike");return e.hasClass("selected")&&b(e),!0})}];return{hooks:m,theme:r,action_hooks:v,reset_autosave_timer:function(){clearInterval(n.autosave),n.autosave=setInterval("ui.pages.save(true)",c.autosave*1e3)},current_page:function(){return $("#page_listing li.selected:not(.folder) a")},current_folder:function(){return $("#page_listing .folder > .selected")},is_page_selected:function(){return ui.current_page().length!=0},is_folder_selected:function(){return ui.current_folder().length!=0},create_editor:function(e,t){t=t||{},mxvt.markdown.setup_bindings();var n=CodeMirror.fromTextArea(document.getElementById(e),$.extend({mode:"markdown",lineNumbers:!1,matchBrackets:!0,theme:"neat",tabSize:2,gutter:!1,autoClearEmptyLines:!1,lineWrapping:!0,keyMap:"mxvt",onChange:function(){pagehub.content_changed=!0},onKeyEvent:function(e,t){return f?(t.preventDefault(),t.stopPropagation(),!0):!1}},t));return n},collapse:function(){var e=$(this);if(e.attr("data-collapse")==null)return e.siblings("[data-collapse]:first").click();e.attr("data-collapsed")?(e.siblings(":not(span.folder_title)").show(),e.attr("data-collapsed",null).html("&minus;"),e.parent().removeClass("collapsed"),pagehub.settings.runtime.cf.pop_value(parseInt(e.attr("data-folder"))),pagehub.settings_changed=!0):(e.siblings(":not(span.folder_title)").hide(),e.attr("data-collapsed",!0).html("&plus;"),e.parent().addClass("collapsed"),pagehub.settings.runtime.cf.push(parseInt(e.attr("data-folder"))),pagehub.settings_changed=!0)},modal:{as_alert:function(e,t){if(typeof e!="string"&&typeof e=="object"){var e=$(e);e.show()}}},status:{clear:function(e){if(!$("#status").is(":visible"))return(e||function(){})();$("#status").addClass("hidden").removeClass("visible"),o=!1,e&&e();if(a.length>0){var t=a.pop();return ui.status.show(t[0],t[1],t[2])}},show:function(e,n,r){n||(n="notice"),r||(r=h.status);if(o&&u!="pending")return a.push([e,n,r]);t&&clearTimeout(t),t=setTimeout("ui.status.clear()",n=="bad"?l*2:l),$("#status").removeClass("pending good bad").addClass(n+" visible").html(e),o=!0,u=n},mark_pending:function(){$(".loader").show()},mark_ready:function(){$(".loader").hide()}},is_editing:function(){return ui.is_page_selected()&&!$("#page_actions").hasClass("disabled")},on_action:function(e,t,n){var r={is_editor_action:!0},n=$.extend(r,n||{});p[e]||(p[e]={props:n,handlers:[]}),p[e].handlers.push(t)},action:function(e){var t=p[e];if(!t)return!0;if(!ui.is_editing()&&t.props.is_editor_action)return!1;for(var n=0;n<t.handlers.length;++n)t.handlers[n]();return!1},resource_editor:{show:function(){if(!ui.is_folder_selected()&&!ui.is_page_selected()){console.log("ERROR: nothing is selected, can't show resource editor");return}var e=ui.is_folder_selected()?ui.current_folder():ui.current_page(),t=$("#resource_editor"),n=t.find("input[type=text][name=title]");e.hide(),t.show(),e.after(t),n.attr("value",e.html().trim()).focus();if(ui.is_folder_selected()){var r=e.parent().attr("data-parent");r||(r="0"),t.find("select :selected").attr("selected",null),t.find("select option[value=folder_"+r+"]").attr("selected","selected"),e.parent().find("li.folder").add(e.parent()).each(function(){t.find("select option[value="+$(this).attr("id")+"]").hide()})}return!0},hide:function(e){if(!ui.is_folder_selected()&&!ui.is_page_selected())return;var t=ui.is_folder_selected()?ui.current_folder():ui.current_page(),n=$("#resource_editor"),r=n.find("input[type=text][name=title]");$("body").append(n.hide()),t.show(),ui.is_folder_selected()&&(t.siblings("button:hidden").show(),ui.dehighlight("folder"),n.find("option:hidden").show(),$("#parent_folder_selection").hide())},save:function(){var e=null;if(!ui.is_folder_selected()&&!ui.is_page_selected()){console.log("ERROR: nothing is selected, can't show resource editor");return}var t=$("#resource_editor input[type=text][name=title]").attr("value");ui.is_folder_selected()?(e=E(),$("#parent_folder_selection select :selected").length==0&&$("#parent_folder_selection select option:first").attr("selected","selected"),parent_folder=$("#parent_folder_selection select :selected").attr("value").replace("folder_",""),ui.status.show("Updating folder...","pending"),pagehub.folders.update(e,{title:t,folder_id:parent_folder},function(e){var e=JSON.parse(e);ui.folders.on_update(e)},function(e){ui.status.show("Unable to update folder: "+e.responseText,"bad")})):(e=w(),ui.status.show("Saving page title...","pending"),pagehub.pages.update(e,{title:t},{success:ui.pages.on_update,error:function(e){ui.status.show("Unable to update page: "+e.responseText,"bad")}})),ui.resource_editor.hide(!0)}},dialogs:{destroy_group:function(e){return window.location.href=$(e).attr("href"),!1},destroy_page:function(){if(!ui.is_page_selected())return!1;$("a.confirm#destroy_page").click()}},report_error:function(e){ui.status.show("A script error has occured, please try to reproduce the bug and report it.","bad"),console.log(e)},highlight:function(e){e=e||$(this),ui.dehighlight(e.hasClass("folder_title")?"folder":"page"),e.addClass("selected"),ui.is_folder_selected()||e.append($("#indicator").show())},dehighlight:function(e){e=="folder"?ui.current_folder().removeClass("selected"):ui.current_page().parent().removeClass("selected")},resources:{on_drag_start:function(e){var t=e.originalEvent;return $("#page_listing .drag-src").removeClass("drag-src"),$(this).addClass("drag-src"),t.dataTransfer.setData("ignore_me","fubar"),i=!0,!0},on_drop:function(e){e.preventDefault(),e.stopPropagation();if(!i)return $("#indicator").hide(),$("#drag_indicator").hide(),!1;var t=$("#page_listing .drag-src");console.log(t),i=!1;if(t.hasClass("folder_title")){var n=t.parent().attr("id").replace("folder_",""),r=$(this).hasClass("general-folder")?$(this).attr("id").replace("folder_",""):$(this).parent().attr("id").replace("folder_","");pagehub.folders.update(n,{folder_id:r},function(e){ui.folders.on_update(JSON.parse(e))},function(e){ui.status.show("Unable to move folder: "+e.responseText,"bad")})}else{var s=$("#page_listing .drag-src a").attr("id").replace("page_",""),o=$(this).hasClass("general-folder")?$(this).attr("id").replace("folder_",""):$(this).parent().attr("id").replace("folder_",""),u=$("#page_listing .drag-src a"),a=$("a[data-action=move][data-folder="+o+"]");w()!=s?(v.pages.on_load.push(function(){a.click(),v.pages.on_load.pop()}),u.click()):a.click()}return $("#page_listing .drag-src, #page_listing .drop-target").removeClass("drag-src drop-target"),$("#indicator").hide(),$("#drag_indicator").hide(),!1},consume_dragevent:function(e){return e.preventDefault(),!1},on_dragenter:function(){$("#page_listing").find(".drop-target").removeClass("drop-target"),$(this).is("li")?$(this).addClass("drop-target"):$(this).parent().addClass("drop-target"),$(this).append($("#indicator").show()),$(this).append($("#drag_indicator").show())},make_draggable:function(e){e.addEventListener("dragenter",ui.resources.on_dragenter),e.addEventListener("drop",ui.resources.on_drop),e.addEventListener("dragend",ui.resources.on_drop),e.addEventListener("dragleave",ui.resources.consume_dragevent),e.addEventListener("dragover",ui.resources.consume_dragevent)}},folders:{create:function(){try{$.ajax({url:pagehub.namespace+"/folders/new",success:function(e){pagehub.confirm(e,"Create a new folder",function(e){ui.status.show("Creating a new folder...","pending"),pagehub.folders.create($("#confirm form#folder_form").serialize(),{success:function(e){var e=JSON.parse(e);console.log(e),dynamism.inject({folders:[e]},$("#page_listing")),ui.status.show("Folder "+e.title+" has been created.","good")},error:function(e){ui.status.show(e.responseText,"bad")}})})}})}catch(e){log(e)}return $("a.listlike.selected").click(),!1},on_update:function(e){ui.status.show("Folder updated!","good"),console.log(e);var t=$("#folder_"+e.id);e.parent?t.attr("data-parent",e.parent):t.attr("data-parent",null),t.find("> span:first").html(e.title),ui.folders.arrange($("#page_listing")),$("a[data-action=move][data-folder="+e.id+"]").html(e.title),$("#resource_editor option[value=folder_"+e.id+"]").html(e.title)},on_injection:function(e){var t=parseInt(e.attr("id").replace("folder_","")),n=t==0;e.find("> ol > li[data-dyn-index][data-dyn-index!=-1]").length>0?e.find("> ol > li:first").hide():e.find("> ol > li:first").show();if(n)e.addClass("general-folder"),e.find("> a[data-action=move]").remove(),e.find("> select").remove(),e.find("> button").remove();else{var r=e.find("a[data-action=move]");r.length==1&&$("#movement_listing").append("<li></li>").find("li:last").append(r),$("#parent_folder_selection select").append('<option value="'+e.attr("id")+'">'+e.find("> span").html()+"</option>"),pagehub.settings.runtime.cf.has_value(parseInt(t))&&e.find("button[data-collapse]").click()}if(Modernizr.draganddrop){var i=n?e.get(0):e.find("> span.folder_title:first").get(0);e.find("[draggable=true]").bind("dragstart",ui.resources.on_drag_start),ui.resources.make_draggable(i)}},arrange:function(e){ui.status.mark_pending(),e.prepend(e.find("li.folder:not([data-parent]):visible")),e.find("li.folder[data-parent]:visible").each(function(){var e=parseInt($(this).attr("data-parent")||"0"),t=$("#folder_"+e);t.length==1?t.find("> ol").append($(this)):(console.log("[ERROR]: Unknown parent "+e+"!"),console.log($(this)))});var t=function(e){e.find("> li.folder:visible").sort(function(e,t){var n=$(e).find("> span:first-child").html().trim().toUpperCase(),r=$(t).find("> span:first-child").html().trim().toUpperCase();return n<r?-1:n>r?1:0}).each(function(t,n){e.append(n)})};t(e),e.find("ol > li.folder:visible").each(function(){t($(this).parent())});var n=$("#page_listing").find(".folder.general-folder");$("#page_listing").append(n),ui.status.mark_ready()},edit_title:function(){return $("#resource_editor").is(":visible")&&ui.resource_editor.hide(),ui.highlight($(this).prev(".folder_title:first")),$(this).siblings("button[data-dyn-action=remove]:visible").hide(),$(this).hide(),$("#parent_folder_selection").show(),ui.resource_editor.show()},on_removal:function(e,t){var n=e.attr("id").replace("folder_","");if(!d[e.attr("id")])throw pagehub.folders.destroy(n,function(n){var n=JSON.parse(n);ui.status.show("Re-building the entire page listing,this could take a while...","pending"),d[e.attr("id")]=!0,e.find("li[data-dyn-entity=folder]").add(e).each(function(){var e=$(this).attr("id").replace("folder_","");$("a[data-action=move][data-folder="+e+"]").parent().remove(),$("#resource_editor option[value=folder_"+e+"]").remove()}),t.click(),dynamism.inject(n,$("#page_listing")),ui.status.show("Folder deleted.","good")},function(e){ui.status.show("Unable to delete folder: "+e.responseText,"bad")}),"Halting."},highlight:function(){var e=$(this);$(this).hasClass("highlighted")?$("span.folder_title.highlighted").removeClass("highlighted"):($(this).addClass("highlighted"),$(this).parents(".folder").find("> span.folder_title").addClass("highlighted"))}},disable_editor:function(){f=!0,$(ui.editor.getWrapperElement()).addClass("disabled")},enable_editor:function(){$(ui.editor.getWrapperElement()).removeClass("disabled"),f=!1},pages:{create:function(){return ui.status.show("Creating a new page...","pending"),pagehub.pages.create({success:function(e){var e=JSON.parse(e);dynamism.inject({folders:[{id:0,pages:[e]}]},$("#page_listing")),$("#page_"+e.id).click(),$(".general-folder li:not([data-dyn-entity]):first").hide(),ui.editor.setValue("Preparing newly created page... hold on.");if(Modernizr.draganddrop){var t=$("#page_"+e.id).parent();t.bind("dragstart",ui.resources.on_drag_start),ui.resources.make_draggable(t)}},error:function(e){ui.status.show("Could not create a new page: "+e.responseText,"bad"),console.log("smth bad happened"),console.log(e)}}),$("a.listlike.selected").click(),!0},load:function(){if($(this).parent().hasClass("selected"))return ui.resource_editor.show(),!1;$("#page_actions").removeClass("disabled"),ui.resource_editor.hide(),ui.highlight($(this).parent()),ui.status.mark_pending(),ui.editor.save();var e=$(this).attr("id").replace("page_","");return $.ajax({type:"GET",url:pagehub.namespace+"/pages/"+e+".json",success:function(t){var t=JSON.parse(t),n=t.content,r=t.groups;ui.editor.clearHistory(),ui.editor.setValue(n),pagehub.content_changed=!1,$("#preview").attr("href",pagehub.namespace+"/pages/"+e+"/pretty"),$("#share_everybody").attr("href",pagehub.namespace+"/pages/"+e+"/share"),$("#history").attr("href",pagehub.namespace+"/pages/"+t.id+"/revisions").html($("#history").html().replace(/\d+/,t.nr_revisions)),t.nr_revisions==0?$("#history").attr("disabled","true").addClass("disabled"):$("#history").attr("disabled",null).removeClass("disabled"),$("a[data-action=share][data-group]").each(function(){var t=$(this).attr("data-group"),n=!1;for(var i=0;i<r.length;++i)if(r[i]==t){$(this).attr("data-disabled",!0),n=!0;break}n?($(this).attr("href",null),$(this).attr("data-disabled",!0)):($(this).attr("href",pagehub.namespace+"/pages/"+e+"/share/"+t),$(this).attr("data-disabled",null))}),$("a[data-action=move]").attr("data-disabled",null),$("a[data-action=move][data-folder="+t.folder+"]").attr({"data-disabled":!0}),$("a[data-action=move]").each(function(){$(this).attr("href",pagehub.namespace+"/folders/"+$(this).attr("data-folder")+"/add/"+t.id)});for(var i=0;i<v.pages.on_load.length;++i)v.pages.on_load[i](t);ui.editor.focus()},complete:function(){ui.status.mark_ready()}}),!1},save:function(e){if(!ui.is_page_selected()||!pagehub.content_changed)return;pagehub.content_changed=!0;var t=w(),n=ui.editor.getValue(),r={};e||(ui.reset_autosave_timer(),ui.disable_editor(),r={success:function(e){var e=JSON.parse(e);ui.status.show("Page updated.","good"),e.nr_revisions==0?$("#history").attr("disabled","true").addClass("disabled"):$("#history").attr("disabled",null).removeClass("disabled"),e.content&&(ui.editor.setValue(e.content),pagehub.content_changed=!1),ui.enable_editor()},error:function(e){ui.status.show("Unable to update page: "+e.responseText,"bad"),ui.enable_editor()}}),pagehub.pages.update(t,{content:n,autosave:e},r),pagehub.sync()},on_update:function(e){var e=JSON.parse(e);ui.status.show("Page updated!","good");var t=$("#page_"+e.id);t.html(e.title)},destroy:function(){if(!ui.is_page_selected())return;var e=ui.current_page(),t=w(),n=e.html();ui.resource_editor.hide(),pagehub.pages.destroy(t,function(){ui.status.show("Page "+n+" has been deleted.","good"),e.parent().remove(),ui.editor.setValue(""),ui.actions.addClass("disabled"),ui.resource_editor.hide(),$(".general-folder > ol > li:visible").length==0&&$(".general-folder > ol > li:hidden:first").show()},function(e){ui.status.show("Page could not be destroyed: "+e.responseText,"bad")})},move:function(){if($(this).attr("data-disabled"))return!1;var e=$(this).attr("href"),t=ui.current_page().parent(),n=t.parents("li.folder:first"),r=$(this).attr("data-folder");return $.ajax({url:e,type:"PUT",success:function(e){var e=JSON.parse(e),r=$("#folder_"+e.folder),i=t.parent();r.find("> ol > li:not(.folder):last").after(t),r.find("> ol > li:first").hide(),i.find("> li:not(.folder):visible").length==0&&i.find("> li:first:hidden").show(),$("a[data-action=move][data-folder="+n.attr("id").replace("folder_","")+"]").attr("data-disabled",null),$("a[data-action=move][data-folder="+e.folder+"]").attr({"data-disabled":!0})},error:function(e){last_error=e,ui.status.show(e.responseText,"bad")}}),!1},preview:function(){if(!ui.is_page_selected())return!0;window.open(pagehub.namespace+"/pages/"+w()+"/pretty","_pretty")}}}},ui=new pagehub_ui,$(function(){for(var e=0;e<ui.hooks.length;++e)ui.hooks[e]()});