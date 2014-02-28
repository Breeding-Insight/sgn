/*jslint browser: true, devel: true */

/**

=head1 UploadTrial.js

Dialogs for uploading trials


=head1 AUTHOR

Jeremy D. Edwards <jde22@cornell.edu>

=cut

*/


var $j = jQuery.noConflict();

jQuery(document).ready(function ($) {


    function upload_trial_file() {
        var uploadFile = $("#trial_uploaded_file").val();
        $('#upload_trial_form').attr("action", "/ajax/trial/upload_trial_file");
        if (uploadFile === '') {
	    alert("Please select a file");
	    return;
        }
        $("#upload_trial_form").submit();
    }

    function open_upload_trial_dialog() {
	$('#upload_trial_dialog').dialog("open");
	//add a blank line to design method select dropdown that dissappears when dropdown is opened 
	$("#trial_upload_design_method").prepend("<option value=''></option>").val('');
	$("#trial_upload_design_method").one('mousedown', function () {
            $("option:first", this).remove();
            $("#trial_design_more_info").show();
	    //trigger design method change events in case the first one is selected after removal of the first blank select item
	    $("#trial_upload_design_method").change();
	});
	
	//reset previous selections
	$("#trial_upload_design_method").change();
    }

    $('#upload_trial_link').click(function () {
        open_upload_trial_dialog();
    });

    $("#upload_trial_dialog").dialog({
	autoOpen: false,	
	modal: true,
	autoResize:true,
        width: 500,
        position: ['top', 75],
	buttons: {
            "Cancel": function () {
                $('#upload_trial_dialog').dialog("close");
            },
	    "Ok": function () {
		alert("adding trial not yet supported");
		upload_trial_file();
	    },
	}
    });

    $("#trial_upload_spreadsheet_format_info").click( function () { 
	$("#trial_upload_spreadsheet_info_dialog" ).dialog("open");
    });

    $("#trial_upload_spreadsheet_info_dialog").dialog( {
	autoOpen: false,
	buttons: { "OK" :  function() { $("#trial_upload_spreadsheet_info_dialog").dialog("close"); },},
	modal: true,
	width: 900,
	autoResize:true,
    });

    $('#upload_trial_form').iframePostForm({
	json: true,
	post: function () {
            var uploadedTrialLayoutFile = $("#trial_uploaded_file").val();
            if (uploadedTrialLayoutFile === '') {
		alert("No file selected");
            }
	},
	complete: function (response) {
            if (response.error_string) {
		$("#upload_trial_error_display tbody").html('');
		$("#upload_trial_error_display tbody").append(response.error_string);
		$(function () {
                    $("#upload_trial_error_display").dialog({
			modal: true,
			autoResize:true,
			width: 650,
			position: ['top', 250],
			title: "Errors in uploaded file",
			buttons: {
                            Ok: function () {
				$(this).dialog("close");
                            }
			}
                    });
		});
		return;
            }
            if (response.error) {
		alert(response.error);
		return;
            }
            if (response.success) {
		alert("File uploaded successfully");
            }
	}
    });

});
