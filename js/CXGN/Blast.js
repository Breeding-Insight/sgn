
function run_blast(database_types, input_option_types) { 
    clear_status();
    update_status("Initializing run... ");

    jQuery('#prereqs').html('');
    jQuery('#blast_report').html('');

    var program  = jQuery('#program_select').val();
    //    var sequence_tag = document.getElementById('sequence');
    //var sequence = sequence_tag.value;

    
    var sequence = jQuery('#sequence').val();
    
    if (jQuery.browser.msie) {
//	var serializer = new XMLSerializer;
//	alert('created serializer');
//	sequence = serializer.serialize(document.getElementById('sequence'));
//	alert(sequence);
					     
	sequence = sequence.replace(/\s+/g, "\n");	
    }

    var database = jQuery('#database').val();
    var evalue   = jQuery('#evalue').val();
    var matrix   = jQuery('#matrix').val();
    var graphics = jQuery('#graphics').val();
    var maxhits  = jQuery('#maxhits').val();
    var filterq  = jQuery('#filterq').val();
    var input_option = jQuery('#input_options').val();
    
    if (sequence === '') { 
	alert("Please enter a sequence :-)"); 
	
	return; 
    }
    
    if (!blast_program_ok(program,  input_option_types[input_option], database_types[database])) { 
	alert("The BLAST program does not match the selected database and query.");
	return;
    }
    
    update_status("Submitting job... ");
    
    var jobid ="";
    var seq_count = 0;
    disable_ui(); 

    jQuery.ajax( { 
		//async: false,
		url:     '/tools/blast/run/',

		method:  'POST',
		data:    { 'sequence': sequence, 'matrix': matrix, 'evalue': evalue, 'maxhits': maxhits, 
			'filterq': filterq, 'database': database, 'program': program, 
			'input_options': input_option, 'db_type': database_types[database]
		},
		success: function(response) { 
			if (response.error) { 
				enable_ui();
				alert(response.error);
				return;
			}
			else{
				jobid = response.jobid; 
				seq_count = response.seq_count;
				//alert("SEQ COUNT = "+seq_count);
				wait_result(jobid, seq_count);
			}
		},
		error: function(response) {
			alert("An error occurred. The service may not be available right now.");
			enable_ui();
			return;
		}
    });
}

function wait_result(jobid, seq_count) { 
    update_status('id='+jobid+' ');
    var done = false;
    var error = false;
    
    while (done == false) { 
	jQuery.ajax( { 
	    async: false,
	    url: '/tools/blast/check/'+jobid,
	    success: function(response) { 
		if (response.status === "complete") { 
		    //alert("DONE!!!!");
		    done = true;
		    finish_blast(jobid, seq_count);
		}
		else { 
		    update_status('.');
		    
		    //alert("Status "+response.status);
		}
	    },
	    error: function(response) { 
		alert("An  error occurred. "); 
		enable_ui(); 
		done=true; 
		error=true; 
		
	    }
	});
	
    }
}

function finish_blast(jobid, seq_count) { 	

    update_status('Run complete.<br />');
    
    var format   =  jQuery('#parse_options').val() || [ 'Basic' ];
    
    //alert("FORMAT IS: "+format + " seqcount ="+ seq_count + "jobid = "+jobid);

    var blast_reports = new Array();
    var prereqs = new Array();

    if (seq_count > 1) { 
	format = [ "Basic" ];
	alert("Multiple sequences were detected. The output will be shown in the basic format");
    }

    var database = jQuery('#database').val();

    for (var n in format) { 
	update_status('Formatting output ('+format[n]+')<br />');

	jQuery.ajax( { 
	    url: '/tools/blast/result/'+jobid,
	    data: { 'format': format[n], 'db_id': database },
	    
	    success: function(response) { 
		if (response.blast_report) { 
		    blast_reports.push(response.blast_report);
		    //alert("BLAST report: "+response.blast_report);
		}
		if (response.prereqs) { 
		    prereqs.push(response.prereqs);
		    jQuery('#prereqs').html(prereqs.join("\n\n<br />\n\n"));
		}
		jQuery('#blast_report').html(blast_reports.join("<hr />\n"));
		
		jQuery('#jobid').html(jobid);
		
		Effects.swapElements('input_parameter_section_offswitch', 'input_parameter_section_onswitch'); 
		Effects.hideElement('input_parameter_section_content');
		
		enable_ui();
		
	    },
	    error: function(response) { alert("Parse BLAST: An error occurred. "+response.error); }
	});
    }
}

function disable_ui() { 
    jQuery('#working').dialog("open");
}

function enable_ui() { 
    jQuery('#working').dialog("close");
}

function clear_input_sequence() { 
   jQuery('#sequence').val('');
}

function blast_program_ok(program, query_type, database_type) { 
   var ok = new Array();
   // query database program
   
   ok = { 'protein': { nucleotide : { tblastn: 1 }, protein : { blastp: 1 } }, 
          'nucleotide' : { nucleotide : { blastn: 1, tblastx: 1}, protein: { blastx: 1 } },
          'autodetect' : { nucleotide : { blastn: 1, tblastx: 1, tblastn: 1}, protein: { blastx: 1, blastp: 1 } } };

   return ok[query_type][database_type][program];
}

function download() { 
   var jobid = jQuery('#jobid').html();

   if (jobid === '') { alert("No BLAST has been run yet. Please run BLAST before downloading."); return; }

   window.location.href= '/documents/tempfiles/blast/'+jobid+'.out';

}

function update_status(message) { 
    var status = jQuery('#blast_status').html();
    status += message;
    jQuery('#blast_status').html(status);
}

function clear_status() { 
    jQuery('#blast_status').html('');
}
