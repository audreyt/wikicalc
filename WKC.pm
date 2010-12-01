#
# WKC.pl -- Main package wikiCalc
#
# (c) Copyright 2005, 2006, 2007 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License at the end of this file
#

#

#
# Define Package
#

   package WKC;

#
# Do uses
#

   use strict;
   use CGI qw(:standard);
   use utf8;
   use LWP::UserAgent;

   use WKCStrings;
   use WKCSheet;
   use WKCSheetFunctions;
   use WKCPageCommands;
   use WKCDataFiles;
   use WKCFormatCommands;
   use WKCToolsCommands;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(process_request update_hiddenfields site_not_allowed find_in_sheet_cache
                    %config_values $programname);
   our $VERSION = '1.0.0';

#
# Define some variables
#

   #
   # Public ones:
   #

   our %config_values = (socket => 6556);

      #
      # Here are the program name strings for display when executing. See the Note below.
      #

   our $programversion = "1.0"; # The version information string
   our $programmark = "wikiCalc"; # This is the main trademark for the product. Change if required by trademark law.
   our $programmarksymbol = qq!<span style="font-weight:normal;vertical-align:super;">&reg;</span>!; # The HTML for the trademark symbol for $programmark
   our $programname = "$programmark $programversion"; # Change name if required by trademark usage. This is where the version is indicated.
   our $trademark1 = qq!, a Software Garden<span style="font-weight:normal;vertical-align:super;">&reg;</span> product!; # Remove if required by trademark usage (also: \xC2\xAE as UTF-8)
   our $SGIfootertext = <<"EOF";
wikiCalc Program (c) Copyright 2007 Software Garden, Inc.
<br>All Rights Reserved.
<br>Garden, Software Garden, and wikiCalc are registered trademarks or trademarks
<br>of Software Garden, Inc., in the United States and in other countries.
<br>The original version of this program is from <a href="http://www.softwaregarden.com">Software Garden</a>.
EOF

      # *** Note: ***
      #
      # In order to carry a prominent notice stating that you changed the files when distributing
      # works based on this program, you may use the $WKCStrings values "programextratop" and "footerextratext".
      #
      # An example of a "programextratop" value would be "Modified" which would result in
      # a displayed banner of "Modified wikiCalc..." indicating that this is
      # a modification to the original version to which the trademark applied.
      # Another example would be "Foobar&nbsp;1.5&nbsp;modification&nbsp;of&nbsp;" which would
      # result in a displayed banner of "Foobar 1.5 modification of wikiCalc...".
      # (Use of "Foobar 1.5 " without the words "modification of" is a trademark violation.)
      # If you make any modifications to the product you should set programextratop appropriately
      # since it is no longer the Software Garden product alone.
      #
      # An example of a "footerextratext" value would be "<br><br>Modification to original:<br>Localisation to UK English (c) 2007 ABC Localizers Ltd."
      #
      # In both cases, you would also put comments in any source files that were modified indicating
      # the author, date, and nature of the changes.

   #
   # Private ones:
   #

   my $securitycode = "not set!"; # Requests may need a parameter that matches this

   my %initial_datavalues = (     # Used to initialize %datavalues
         );

   my $defaultcookieexpire = "+6M"; # how long do cookies (remembering page being edited and maybe login info) last by default?

   my $template_headertop = <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>$programname</title>
EOF

   my $template_styletop = <<"EOF";
<style type="text/css">
body, td, input, textarea {font-family:verdana,helvetica,sans-serif;font-size:small;}
.smaller {font-size: smaller;}
form {
  margin:0px;
  padding:0px;
}
dd {
  padding: 1pt 0px 2pt 0px;
}
dt {
  font-weight: bold;
  padding: 1pt 0px 1pt 0px;
}
.programtop {
  margin-bottom: 10px;
  }
.programtopdark {
  color: #006600;
  font-size: smaller;
  font-weight: bold;
}
.programtoplight {
  color: #999999;
  font-size: smaller;
}
.programtoplogout, .programtoplogout a {
  color: #999999;
  font-weight: bold;
  font-size: smaller;
  text-decoration: none;
}
.programtoplogout a:hover {
  text-decoration: underline;
}
.programtopname {
  color: #006600;
  font-weight: bold;
  font-size: smaller;
  border: 1px solid #006600;
  padding: 4px;
}
.programtoprevert {
  color: #CC0000;
  font-size: smaller;
  font-weight: bold;
}
.tab {
  border-bottom: 1px solid black;
  padding-bottom: 4px;
  }
.tab input {
  background-color:#CCCC99;
  color:black;
}
.tabselected {
  border-left: 1px solid black;
  border-right: 1px solid black;
  border-top: 1px solid black;
  background-color:#DDFFDD;
  color:black;
  padding: 1px 14px 0px 14px;
  text-align: center;
  font-weight: bold;
  }
.tab1 {
  border-bottom: 1px solid black;
  }
.tab2 {
  background-color:#DDFFDD;
  }
.tab2left {
  border-left: 1px solid black;
  background-color:#DDFFDD;
  padding-left:20px;
  }
.tab2right {
  border-right: 1px solid black;
  background-color:#DDFFDD;
  }
.ttbody {
  background-color:#DDFFDD;
  border-right: 1px solid black;
  border-left: 1px solid black;
  border-bottom: 1px solid black;
  padding: 0px 10px 4px 10px;
}
EOF

   my $template_stylemiddle_verbose = <<"EOF";
.sectionoutlined {
  border: 1px solid #99CC99;
  padding: 8px;
}
.sectionoutlineddark {
  border-left: 20px solid #99CC99;
  padding: 8px 8px 0px 8px;
  margin-bottom: 8px; /* IE bug work-around with padding-bottom and border-left (?!!) */
}
.sectionplain {
  padding: 10px;
}
.sectionerror {
  padding: 10px;
  color: red;
  font-weight: bold;
}
.title {
  color: #006600;
  font-weight:bold;
  margin: 0em 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.title2 {
  border-top: 1px solid #006600;
  color: #006600;
  font-weight:bold;
  margin: .5em 0px 0px 0px;
  padding: 0px 0px 0px 0px;
}
.pagetitle {
  color: #006600;
  font-weight:bold;
  margin: 0em 0px 0px 0px;
  padding: 0px 0px 0px 0px;
}
.pagebreadcrumbs {
  color: #006600;
  font-weight:bold;
  font-size:smaller;
  margin: 0em 0px 6pt 0px;
  padding: 0px 0px 0px 0px;
}
.pagefilename {
  color: #006600;
  font-size: smaller;
  font-weight: bold;
  margin: 1pt 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.pagetitledesc {
  color: black;
  font-size: smaller;
  margin: 1pt 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.desc {
  font-size:smaller;
  padding: 0px 0px .75em 0px;
}
.warning {
  font-size:smaller;
  font-weight:bold;
  color:red;
}
.footer {
  border: 1px dashed #006600;
  padding: 6px;
  color: #006600;
  font-size: smaller;
  margin: 1em 0px .5em 0px;
}
EOF

   my $template_stylemiddle_concise = <<"EOF";
.sectionoutlined {
  padding: 0px 8px 6px 8px;
}
.sectionoutlineddark {
  border-left: 20px solid #99CC99;
  padding: 8px;
  margin-bottom: 8px;
  margin-left: 10px;
}
.sectionplain {
  padding: 10px;
}
.sectionerror {
  padding: 10px;
  color: red;
  font-weight: bold;
}
.title {
  color: #006600;
  font-weight:bold;
  margin: 0em 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.title2 {
  border-top: 1px solid #006600;
  color: #006600;
  font-weight:bold;
  margin: .5em 0px 0px 0px;
  padding: 0px 0px 0px 0px;
}
.pagebreadcrumbs {
  color: #006600;
  font-weight:bold;
  font-size:smaller;
  margin: 0em 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.pagetitle {
  color: #006600;
  font-weight:bold;
  margin: 0em 0px 0px 0px;
  padding: 0px 0px 0px 0px;
}
.pagefilename {
  color: #006600;
  font-size: smaller;
  font-weight: bold;
  margin: 1pt 0px 2pt 0px;
  padding: 0px 0px 0px 0px;
}
.pagetitledesc {
  visibility:hidden;
  height:0px;
}
.desc {
  visibility:hidden;
  height:0px;
}
.warning {
  font-size:smaller;
  font-weight:bold;
  color:red;
}
.footer {
  visibility:hidden;
  height:0px;
}
EOF

   my $template_stylebottom = <<"EOF";
.browsepageavailable {
  font-size: smaller;
  font-weight: bold;
  background-color: white;
  padding-left: 4pt;
  padding-right: 4pt;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepageavailable1 {
  background-color: white;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepageavailable2 {
  font-size: smaller;
  background-color: white;
  padding-left: 4pt;
  padding-right: 4pt;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepageavailable3 {
  font-size: smaller;
  font-weight: bold;
  color: #999999;
  background-color: white;
  padding-left: 4pt;
  padding-right: 0px;
  vertical-align: top;
  text-align: right;
}
.browsepageediting {
  font-size: smaller;
  color: white;
  font-weight: bold;
  background-color: #339933;
  padding-left: 4pt;
  padding-right: 4pt;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepageediting2 {
  font-size: smaller;
  color: white;
  background-color: #339933;
  padding-left: 4pt;
  padding-right: 4pt;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepageediting3 {
  font-size: smaller;
  font-weight: bold;
  color: white;
  background-color: #339933;
  padding-left: 4pt;
  padding-right: 4pt;
  padding-bottom: 1pt;
  vertical-align: top;
}
.browsepagemedium {
  font-size: smaller;
  font-weight: bold;
  padding-left: 4pt;
  vertical-align: top;
  color: black;
}
.browsepagedim {
  font-size: smaller;
  padding-left: 4pt;
  vertical-align: top;
  color: #999999;
}
.browsepagename {
  font-size: smaller;
  padding-left: 4pt;
  padding-right: 4pt;
  vertical-align: top;
  color: black;
}
.browseusername {
  font-weight: bold;
  padding-left: 4pt;
  padding-right: 4pt;
  vertical-align: top;
  color: black;
}
.browseusersite {
  text-align:center;
}
.browseuseradd {
  font-size: smaller;
  font-style: italic;
  padding-left: 4pt;
  text-align: center;
  color: #999999;
}
.browsebuttons {
  padding-left: 4pt;
  vertical-align: top;
}
.browsenormal {
  font-size: smaller;
  padding-left: 4pt;
  vertical-align: top;
}
.browsetablehead {
  background-color: #339933;
  color: white;
  font-size: smaller;
  font-weight: bold;
  padding: 4pt 0 4pt 4pt;
  text-align: center;
}
.browsegrouphead {
  background-color: #99CC99;
  color: black;
  font-size: smaller;
  font-weight: bold;
  padding: 4pt 0 4pt 4pt;
  text-align: center;
}
.browsecolumnhead {
  background-color: #99CC99;
  color: white;
  font-size: smaller;
  font-weight: bold;
  padding: 4pt 0 4pt 4pt;
}
.browsebuttoncell {
  vertical-align: top;
  white-space: nowrap;
}
.browsebuttoncellediting {
  text-align: left;
  white-space: nowrap;
  background-color: #339933;
}
.browseselectedtext {
  font-size: smaller;
  font-weight: bold;
  color: black;
  background-color: white;
  margin: 0px 4px 4px 4px;
  padding: 0px 3px 2px 0px;
}
.browsereconcile {
  background-color: white;
  padding: 6pt;
  vertical-align: top;
  text-align: center;
}
.colsample1 {
  border-top:2px solid black;
  border-left:1px solid black;
  padding:10px 0px 0px 8px;
  font-size:1pt;
}
.colsample2 {
  border-left:1px solid black;
  font-size:x-small;
  padding-left:1pt;
}
.cellnormal {
 }
.cellcursor {
 margin:1px;
 padding:1px;
 border:3px solid #666633;
 }
.cellcorner {
 margin:1px;
 padding:1px;
 border:1px solid #99CC99;
 }
.colorbox {
 border:1px solid black;
 padding:5px;
 height:1px;
 width:1px;
}
.defaultbox {
 border:1px solid black;
 padding:0px;
 background-color:white;
 background-image:url('?getfile=hatchbg');
 height:16px;
 width:16px;
}
.previewlisttitle {
 font-size:smaller;
 font-weight:bold;
 text-align:right;
}
</style>
EOF

   my $template_headerscripts = <<"EOF"; # start with do nothing for setf and remove end of URL for setf0
<script>
<!--
var setf = function() {1;}
function setactions() {
if (document.f0) document.f0.action=location.protocol+"//"+location.host+location.pathname;
if (document.ftabs) document.ftabs.action=location.protocol+"//"+location.host+location.pathname;
}
// -->
</script>
EOF

#
# * * * * *
#
# PRE-LOAD special strings (WKCStrings overrides)
#
# * * * * *
#

   load_special_strings(); # loaded at first parse... (in WKCSheet.pm)

   my @tablist = ($WKCStrings{"Page"}, $WKCStrings{"Edit"},
                  $WKCStrings{"Format"},  $WKCStrings{"Preview"},
                  $WKCStrings{"Tools"}, $WKCStrings{"Quit"},);


#
# * * * * *
#
# process_request($querystring, $cookievalue, \%responsedata, $security, $noquittab)
#
# Process the HTTP request
#
# Responds to browser request and does all the work
# Returns data in %responsedata:
#    $responsedata{content} - a string with the HTML response
#    $responsedata{contenttype} - the HTTP response header content MIME type or null for default text/html UTF-8
#    $responsedata{contentexpires} - expire string or null for default (-1d)
#    $responsedata{cookie} - a string with the cookie value to set, if any
#    $responsedata{cookieexpires} - expire value for cookie (e.g., "+1yr" or "" for session only)
#
# The $querystring is the raw query from the browser.
# $cookievalue is the value of any cookie.
# If $security is present and true, a "security"
# parameter is used in each request to guard against
# URLs on web sites that guess we are running locally.
# $noquittab suppresses the Quit tab if true (for CGI and other cases where you always have a running system)
#

sub process_request {

   my ($querystring, $cookievalue, $responsedata, $security, $noquittab) = @_;
   my ($response, $rhead, $rbody1, $rbodytabs, $rbodytabs2, $inlinescripts);

   my %sheetdata;
   my @sheetlines;
   my %headerdata;
   my @headerlines;

   # Initialize timers

   my $start_clock_time = scalar localtime;
   my $start_cpu_time = times();

   # Get CGI object to get parameters:

   $querystring ||= ""; # make sure has something
   my $q = new CGI($querystring);
   my %params = $q->Vars;

   # Parse cookie

   my %cookievalues;

   foreach my $cookie (split /;/, $cookievalue) {
      if ($cookie) {
         my ($n, $v) = split /:/, $cookie;
         $cookievalues{$n} = $v;
         }
      }

   # If Quit tab is chosen, then return nothing:

   if ($params{newtab} eq $WKCStrings{"Quit"}) {
      return unless $noquittab;
      }

   #
   # Check security code
   #
   # If not the same as ours, set it and wipe out parameters.
   # This is to prevent malicious web sites from linking
   # to a "known" local address and affect this app.
   #

   $securitycode = "" if !$security; # Don't use if running through a web server

   if ($params{securitycode} ne $securitycode) {
      %params = ();
      $querystring = "";
      $securitycode = sprintf("%.14f", rand); # assign a random security code
      }

   my %datavalues = %initial_datavalues; # start with default values
                                         # before reading in
   my $dvchanged; # if true, then need to write out

   #
   # *** Declarations
   #

   my ($editmode, $editcoords);
   my $published = 0;
   my $ok;
   my $responsecookie;

   #
   # *** Retrieve initial values from params
   #

   $params{localwkcpath} = $WKCdirectory;

   $editmode = $params{editmode};
   $editcoords = $params{editcoords};

   my $hostinfo = get_hostinfo(\%params); # input hostinfo data

   #
   # *** Check if login is necessary
   #

   $params{loggedinusername} ||= $cookievalues{loggedinusername}; # get from cookie if not in params
   $params{loggedinuserpassword} ||= $cookievalues{loggedinuserpassword};

   if ($params{dologin}) {
      $params{loggedinusername} = $params{editusername};
      }
   elsif ($params{dologout}) {
      %params = (); # forget everything
      %cookievalues = ();
      }

   my %userinfo; # information about current user to be filled in when checking password
   $userinfo{HOSTrequirelogin} = $hostinfo->{requirelogin}; # remember whether this host requires login here, too

   my $loggedinuser = $params{loggedinusername};
   my $needlogin; # if true, need to login a user
   my $loginerrtext;
   $params{loggedinadmin} = "yes"; # if true, have wikiCalc admin privileges
   if ($hostinfo->{requirelogin} eq "yes") { # global setting
      my $password = $params{loggedinuserpassword};
      $needlogin = 1; # assume need to login
      $params{loggedinadmin} = ""; # assume not admin
#print "logged in user: $loggedinuser/$password (cookies:$cookievalues{loggedinusername}/$cookievalues{loggedinuserpassword})\n";
      if ($loggedinuser || $params{dologin}) { # is someone already logged in or logging in?
         my $errtext = get_userinfofileinfo(\%params, \%userinfo, $loggedinuser);
         if (!$errtext) {
            if ($params{dologin}) {
               $params{loggedinuserpassword} = substr(crypt($params{edituserpassword}, $userinfo{$params{editusername}}->{password}), 2);
               $password = $params{loggedinuserpassword};
               }
            if ($password eq substr($userinfo{$loggedinuser}->{password}, 2)) { # password is OK (salt is not passed back to browser)
               if ($userinfo{$loggedinuser}->{admin} eq "yes") {
                  $params{loggedinadmin} = "yes"; # turn on
                  }
               $needlogin = 0; # don't need to login
               if ($params{dologin}) {
                  if ($params{editusercookies}) { # if the user says to save login info in cookie
                     $responsecookie .= "loggedinusername:$params{loggedinusername};loggedinuserpassword:$params{loggedinuserpassword};";
                     $cookievalues{expires} = $params{editusercookies};
                     }
                  }
               elsif ($cookievalues{loggedinusername} && $params{loggedinusername}) { # if have been saving login info, continue to
                  $responsecookie .= "loggedinusername:$params{loggedinusername};loggedinuserpassword:$params{loggedinuserpassword};";
                  }
               }
            else {
               sleep 4; # if bad password, wait a bit so can't power through many easily
               $loginerrtext = $WKCStrings{"loginerror"};
               }
            }
         else {
            sleep 4; # if bad password, wait a bit so can't power through many easily
            $loginerrtext = $WKCStrings{"loginerror"};
            }
         }
      }

   #
   # *** Look for special calls
   #

   #
   # ?getfile=type for downloading special files, such as 1x1.gif
   #

   if ($params{getfile}) {
      if ($params{getfile} eq "1x1" || $params{getfile} eq "hatchbg" || $params{getfile} eq "colsizehandle" || $params{getfile} eq "colsizescale") {
         open IMAGEFILE, "$WKCdirectory/$params{getfile}.gif";
         binmode IMAGEFILE;
         my @imagelines = <IMAGEFILE>;
         close IMAGEFILE;
         $response = join "", @imagelines;
         $responsedata->{content} = $response;
         $responsedata->{contenttype} = "image/gif";
         $responsedata->{contentexpires} = "+1h";
         return;
         }
      }

   #
   # ?ajaxsetcell=sitename:pagename:coord:newvalue for new cell value
   #
   # Returns XML with <root>new cell data in a CDATA</root>.
   #
   # The cell data is in the form of one or more text lines, each one of the following:
   #    coord:type:displayvalue:editvalue:align:colspan:rowspan:skip:csss\n
   #    error:Error message to display
   #    needsrecalc:yes/no
   #    footer:New runtime message for page footer
   # Where:
   #    coord - A1, B7, etc.
   #    newvalue - what was typed in, including "=", etc., if present
   #    type - t is explicit text, tw is wikitext, n is number,
   #           f is formula without "=", and "e" is empty
   #    displayvalue - rendered HTML
   #    align - left/right/center
   #    colspan/rowspan - 1 or more
   #    skip - blank if normal cell, else coord of cell to move cursor to if it lands here
   #    csss - optional explicit style
   #

   if ($params{ajaxsetcell}) {
      my ($psite, $pname, $coord, $value) = split(/:/, $params{ajaxsetcell}, 4);
      $value = decode_from_ajax($value);

      ($params{sitename}, $params{datafilename}) = ("", ""); # not used, but do this just in case

      if ($needlogin || site_not_allowed(\%userinfo, $loggedinuser, $psite)) { # Not logged in or not allowed
         my $msg = $needlogin ? $WKCStrings{"ajxnotloggedin"} : $WKCStrings{"ajaxnotfound"};
         my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[
error:$msg
]]></root>
EOF
         $responsedata->{content} = $xmlresponse;
         $responsedata->{contenttype} = "text/xml";
         return;
         }

      my ($type, $v1, $aep, @aheaderlines, @asheetlines, %aheaderdata, %asheetdata, %asheetdata, $aerrtext);

      $aep = get_page_edit_path(\%params, $hostinfo, $psite, $pname);
      $ok = load_page($aep, \@aheaderlines, \@asheetlines);

      $ok = parse_header_save(\@aheaderlines, \%aheaderdata);
      $ok = parse_sheet_save(\@asheetlines, \%asheetdata);
      init_sheet_cache(\%asheetdata, \%params, $hostinfo, $psite); # remember in case have references to other worksheets

      my %celldatabefore;
      my $linkstyle = "?view=$psite/[[pagename]]";
      render_values_only(\%asheetdata, \%celldatabefore, $linkstyle);

      # Determine value type and do appropriate command to set it

      $type = "text tw";
      my $fch = substr($value, 0, 1);
      if ($fch eq "=" && $value !~ m/\n/) {
         $type = "formula";
         $value = substr($value, 1);
         }
      elsif ($fch eq "'") {
         $type = "text tw";
         $value = substr($value, 1);
         }
      elsif (length $value == 0) {
         $type = "empty";
         }
      else {
         $v1 = determine_value_type($value, \$type);
         if ($type eq 'n' && $v1 == $value) { # check that we don't need "constant"
            $type = "value n";
            }
         elsif ($type eq 't') {
            $type = "text tw";
            }
         else { # handle all the special types
            $type = "constant $type $v1";
            }
         }

      my $cmdline = "set $coord $type $value"; # create and execute command to set the cell
      $ok = execute_sheet_command_and_log(\%asheetdata, $cmdline, \%aheaderdata);
      if ($ok) {
         if ($asheetdata{sheetattribs}->{recalc} ne "off") {
            $aerrtext = recalc_sheet(\%asheetdata);
            }
         else {
            $asheetdata{sheetattribs}->{needsrecalc} = "yes";
            }
         }
      else {
         $aerrtext = "Failed: $ok"; # should not get here, so use English...
         }
      my %celldataafter;
      render_values_only(\%asheetdata, \%celldataafter, $linkstyle);

      my $asheetcontents = create_sheet_save(\%asheetdata);

      $aheaderdata{lastmodified} = $start_clock_time; # remember it in header

      my $sitedata = $hostinfo->{sites}->{$psite};
      my $thisauthor = $sitedata->{authoronhost}; # Get author name
      if ($sitedata->{authorfromlogin} eq "yes" && $params{loggedinusername}) {
         $thisauthor = $params{loggedinusername};
         $thisauthor =~ s/[^a-z0-9\-]//g;
         }
      $aheaderdata{lastauthor} = $thisauthor;

      my $aheadercontents = create_header_save(\%aheaderdata);

      $ok = save_page($aep, $aheadercontents, $asheetcontents);

      foreach my $cr (sort keys %celldataafter) { # construct output
         my $cdbefore = $celldatabefore{$cr};
         my $cdafter = $celldataafter{$cr};
         next
          if $cdbefore->{type} eq $cdafter->{type}
          && $cdbefore->{display} eq $cdafter->{display}
          && $cdbefore->{align} eq $cdafter->{align}
          && $cr ne $coord; # only stuff that has changed unknown to client (but send at least one -- the one with "loading")

         my $displayvalue = encode_for_ajax($cdafter->{display});
         $displayvalue = "" if $displayvalue eq "&nbsp;"; # this is the default
         my $csssvalue = encode_for_save($asheetdata{cellattribs}->{$cr}->{csss}); # need this to scroll back
         my $editvalue;
         if ($asheetdata{datatypes}->{$cr} eq 'f' || $asheetdata{datatypes}->{$cr} eq 'c') { # formula or constant
            $editvalue = encode_for_ajax($asheetdata{formulas}->{$cr});
            }
         else {
            $editvalue = encode_for_ajax($asheetdata{datavalues}->{$cr});
            }
         $response .= "$cr:$cdafter->{type}:$displayvalue:$editvalue:$cdafter->{align}:$cdafter->{colspan}:$cdafter->{rowspan}:$cdafter->{skip}:$csssvalue\n";
         }
      if ($asheetdata{sheetattribs}->{circularreferencecell}) { # include some error information
         my ($from, $to) = split(/\|/, $asheetdata{sheetattribs}->{circularreferencecell});
         my $str = "$WKCStrings{editcircular1}$from$WKCStrings{editcircular2}$to";
         $response .= "error:$str\n";
         }
      $response .= "needsrecalc:$asheetdata{sheetattribs}->{needsrecalc}\n";
      $response .= sprintf ("footer:$WKCStrings{wkcfooterruntime} %.2f $WKCStrings{wkcfootersecondsat} $start_clock_time\n",
                              times() - $start_cpu_time);

      my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[
$response
]]></root>
EOF
      $responsedata->{content} = $xmlresponse;
      $responsedata->{contenttype} = "text/xml";
      return;
      }

   #
   # ?ajaxgetpagelist=sitename
   #
   # Returns XML with <root>page data in a CDATA</root>
   #
   # The page data is in one of the following forms:
   #    pages:pagename1:longname1:type1:pagename2:longname2:type2...
   # or:
   #    error:Error message to display
   # Where:
   #    pagename - the name, without the .html
   #    longname - longname, with \ and : converted to \b and \c
   #    type - e (editing locally), r (editing remotely), or p (published)
   #

   if ($params{ajaxgetpagelist}) {
      my $currentsite = $params{sitename}; # temporarily switch to other site
      $params{sitename} = $params{ajaxgetpagelist};

      if ($needlogin || site_not_allowed(\%userinfo, $loggedinuser, $params{sitename})) { # Not logged in or not allowed
         my $msg = $needlogin ? $WKCStrings{"ajaxnotloggedin"} : $WKCStrings{"ajaxnotfound"};
         my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[error:$msg]]></root>
EOF
         $responsedata->{content} = $xmlresponse;
         $responsedata->{contenttype} = "text/xml";
         return;
         }

      my $siteinfo = get_siteinfo(\%params); # get site information
      my $ok = update_siteinfo(\%params, $hostinfo, $siteinfo); # update it
      if ($siteinfo->{updates}) {
         $ok = save_siteinfo(\%params, $siteinfo);
         }
      my $currentauthor = $hostinfo->{sites}->{$params{sitename}}->{authoronhost};
      if ($hostinfo->{sites}->{$params{sitename}}->{authorfromlogin} eq "yes" && $params{loggedinusername}) {
         $currentauthor = $params{loggedinusername};
         }
      $params{sitename} = $currentsite;

      $response = "pages";

      foreach my $name (sort keys %{$siteinfo->{files}}) { # List each file, depending on edit/pub status
         my $fileinfo = $siteinfo->{files}->{$name};
         my $longname = encode_for_ajax($fileinfo->{fullnamepublished});
         my $editstatus = $fileinfo->{authors}->{$currentauthor}->{editstatus}; # is current author editing?
         my $pubstatus = $fileinfo->{pubstatus}; # has it been published?
         if ($pubstatus) {
            $response .= ":$name:$longname:p";
            }
         if ($editstatus) {
            if ($editstatus eq "remote") {
               $response .= ":$name:$longname:r";
               }
            else {
               $response .= ":$name:$longname:e";
               }
            }
         }

      my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[$response]]></root>
EOF
      $responsedata->{content} = $xmlresponse;
      $responsedata->{contenttype} = "text/xml";
      return;
      }

   #
   # ?ajaxgetnamedtext=textname
   #
   # Returns XML with <root>text data in a CDATA</root>
   # The text data is in WKCtextdata.txt. That file is in the following format:
   #  *** WKCtexdataname: textname1 ***
   #  Lines of text to be returned...
   #  *** WKCtexdataname: textname2 ***
   #  Lines of text to be returned...
   # textname is alphanumerics plus -

   if ($params{ajaxgetnamedtext}) {
      my $textname = $params{ajaxgetnamedtext};
      $textname =~ s/[^A-Za-z0-9\-]//g;
      my ($returnstr, $line);

      open(TEXTFILEIN, "$WKCdirectory/WKCtextdata.txt");

      while ($line = <TEXTFILEIN>) { # find start of desired text
         last if $line =~ m/^\*\*\* WKCtextdataname\: $textname \*\*\*/;
         }

      while ($line = <TEXTFILEIN>) { # copy lines
         last if $line =~ m/^\*\*\* WKCtextdataname\: [A-Za-z0-9\-]+ \*\*\*/;
         $returnstr .= $line;
         }

      close TEXTFILEIN;

      my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[$returnstr]]></root>
EOF
      $responsedata->{content} = $xmlresponse;
      $responsedata->{contenttype} = "text/xml";
      return;
      }

   #
   # *** Process CGI-access to view pages
   #
   # Use with:
   #    ?view=sitename/pagename (assumes type=page)
   #    ?view=sitename/pagename&type=outputtype (page, html, js, cdata, and source are the allowed types)
   #    optional: &recalc=no (anything else or no &recalc means "yes, do a recalc first"
   #    The saved page is not modified by viewing it, even if a recalc is done
   #    ?view=logout (logs user out)
   #    ?view=sitename/pagename&cell:coord:type=value (type is n, t, or e:na)
   #

   if ($params{view}) { # "wikicalc.pl?view=sitename/pagename" invocation
      if ($params{view} eq "logout") { # logout user
         $responsedata->{content} = <<"EOF";
<html>
<head>
</head>
<body style="background-color:gray;">
<table cellspacing="0" cellpadding="0" border="0" align="center">
<tr><td style="border:1px solid black;background-color:white;padding:1em;">
$WKCStrings{"viewlogoutcompleted"}
</td></tr></table>
</body>
</html>
EOF
         $responsedata->{contenttype} = "text/html";
         $responsedata->{cookie} = "datafilename:;sitename:";
         $responsedata->{cookieexpires} = "";
         return;
         }

      my ($vsitename, $vpagename) = split(/\//, lc $params{view}, 2);
      $vsitename =~ s/[^a-z0-9\-]//g;
      my $viewerrstr;
      $vpagename =~ s/[^a-z0-9\-]//g;
      $responsedata->{contenttype} = "text/plain"; # default

      $params{sitename} = $vsitename;
      $params{datafilename} = $vpagename;

      my (@vheaderlines, %vheaderdata, @vsheetlines, %vsheetdata);

      my $vstr;
      my $linkstyle;

      # Load page (even if this user doesn't have permission) and then parse header

      my $vpath = get_page_published_datafile_path(\%params, $hostinfo, $vsitename, $vpagename);

      my $loaderr = load_page($vpath, \@vheaderlines, \@vsheetlines);

      my $pareseok = parse_header_save(\@vheaderlines, \%vheaderdata); # Get data from header

      # Determine access

      if ($vheaderdata{viewwithoutlogin} ne "yes" && $needlogin) {
         my $temp1 = $params{view};
         my $temp2 = $params{type};
         my $temp3 = $params{etpurl};
         %params = (); # need login -- wipe out all parameters (for now...)
         $params{view} = $temp1 if $temp1;
         $params{type} = $temp2 if $temp2;
         $params{etpurl} = $temp3 if $temp3;
         $loggedinuser = "";
         }

      if ($vheaderdata{viewwithoutlogin} ne "yes" && readsite_not_allowed(\%userinfo, $loggedinuser, $vsitename)) {
         if (!$params{type} || lc($params{type}) eq "page") {
            if ($loginerrtext) { # error logging in
               $loginerrtext = qq!<span style="color:red;">$loginerrtext</span><br><br>!;
               }
            elsif ($params{viewlogin}) { # probably site not allowed
               $loginerrtext = <<"EOF";
$WKCStrings{"viewliveviewloggedinasuser"} "$loggedinuser" (<a href="$hostinfo->{sites}->{$vsitename}->{editurl}?view=logout">$WKCStrings{"viewliveviewsologout"}</a>)<br><br>
<span style="color:red;">$WKCStrings{"viewliveviewnoreadaccess"} "$vsitename" $WKCStrings{"viewliveviewforuser"} "$loggedinuser"</span><br><br>
EOF
               }
            $responsedata->{content} = <<"EOF"; # need POST to keep password out of URL
<html>
<head>
</head>
<body style="background-color:gray;" onload="setf();">
<form name="f0" method="POST">
<table cellspacing="0" cellpadding="0" border="0" align="center">
<tr><td style="border:1px solid black;background-color:white;padding:1em;">
$loginerrtext
$WKCStrings{"viewlogin1"} '$vsitename/$vpagename'
<br><br>
$WKCStrings{"loginname"}&nbsp;<input type="text" name="editusername" size="15" value="">
&nbsp;$WKCStrings{"loginpassword"}&nbsp;<input type="password" name="edituserpassword" size="10" value="">
&nbsp;<input type="submit" name="dologin" value="$WKCStrings{"loginlogin"}">
<br><br>
<input type="radio" name="editusercookies" value="session" CHECKED>$WKCStrings{"loginsessioncookie"}&nbsp;
<input type="radio" name="editusercookies" value="$defaultcookieexpire">$WKCStrings{"loginlongcookie"}
<input type="hidden" name="view" value="$params{view}">
<input type="hidden" name="type" value="$params{type}">
<input type="hidden" name="viewlogin" value="1">
</td></tr></table>
</form>
<script>
var setf = function() {document.f0.editusername.focus();}
</script>
</body>
</html>
EOF
            $responsedata->{contenttype} = "text/html";
            }

         elsif (lc($params{type}) eq "js") {
            $responsedata->{content} = "document.write('$WKCStrings{viewnotloggedin} \\'$params{view}\\'');";
            $responsedata->{contenttype} = "text/javascript";
            }
         elsif (lc($params{type}) eq "cdata") {
            $responsedata->{content} = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[$WKCStrings{"viewnotloggedin"} '$params{view}']]></root>
EOF
            $responsedata->{contenttype} = "text/xml";
            }
         else {
            $responsedata->{content} = "$WKCStrings{viewnotloggedin} '$params{view}'";
            }
         return;
         }

      if ($params{viewlogin}) { # successful login
         # This makes sure the page is accessed with a GET and works with or without Javascript
         $responsedata->{content} = <<"EOF";
<html>
<head>
</head>
<body style="background-color:gray;" onload="setf();">
<form name="f0" method="GET">
<table cellspacing="0" cellpadding="0" border="0" align="center">
<tr><td style="border:1px solid black;background-color:white;padding:1em;">
$WKCStrings{"viewloggedin"} "$loggedinuser"<br>
<br>$WKCStrings{"viewclicktoview"} "$vsitename/$vpagename":<br><br>
<input type="submit" name="view" value="$params{view}" onclick="location.href=location.href;return false;">
</td></tr></table>
</form>
<script>
var setf = function() {document.f0.view.focus();}
</script>
</body>
</html>
EOF
            $responsedata->{contenttype} = "text/html";
            $responsecookie .= "datafilename:;sitename:;expires:$cookievalues{expires}";
            $responsedata->{cookie} = $responsecookie;
            $responsedata->{cookieexpires} = $cookievalues{expires} eq "session" ? "" : ($cookievalues{expires} || $defaultcookieexpire);
            return;
            }

      if (lc($params{type}) eq "source") {
         if ($loaderr) {
            $responsedata->{content} = "$WKCStrings{viewunabletoload} '$params{view}'";
            return;
            }
         if ($vheaderdata{publishsource} ne "yes") { # not allowed
            $responsedata->{content} = "$WKCStrings{viewnosource} '$params{view}'.";
            return;
            }
         my $ok = open (DATAFILEIN, $vpath);
         if (!$ok) {
            $responsedata->{content} = "$WKCStrings{notfound1} '$vpath' $WKCStrings{notfound2}";
            return;
            }
         my $line;
         while ($line = <DATAFILEIN>) {
            $vstr .= $line;
            }
         close DATAFILEIN;
         $responsedata->{content} = $vstr;
         return;
         }

      $pareseok = parse_sheet_save(\@vsheetlines, \%vsheetdata); # Get data from sheet

      $loaderr = $WKCStrings{"viewunabletoload"} if $loaderr;

      if (lc($params{recalc}) ne "no") { # do a recalc
         foreach my $param (keys %params) { # see if any cell value overrides
            next unless $param =~ /^cell\:([a-z]{1,2}\d+)\:(n|t|e\:na)$/i;
            if ($vsheetdata{cellattribs}->{uc $1}->{mod} ne "y") {
               $loaderr = "$WKCStrings{viewnomodify1} $1 $WKCStrings{viewnomodify2}";
               last;
               }
            if (lc($2) eq "n") { # numeric value
               $vsheetdata{datavalues}->{uc($1)} = $params{$param};
               $vsheetdata{datatypes}->{uc($1)} = "v";
               $vsheetdata{valuetypes}->{uc($1)} = "n";
               }
            elsif (lc($2) eq "t") { # text value
               $vsheetdata{datavalues}->{uc($1)} = $params{$param};
               $vsheetdata{datatypes}->{uc($1)} = "t";
               $vsheetdata{valuetypes}->{uc($1)} = "t";
               }
            if (lc($2) eq "e:na") { # error value
               $vsheetdata{datavalues}->{uc($1)} = $params{$param};
               $vsheetdata{datatypes}->{uc($1)} = "v";
               $vsheetdata{valuetypes}->{uc($1)} = "e#N/A";
               $vsheetdata{cellerrors}->{uc($1)} = "#N/A";
               }
            }
         init_sheet_cache(\%vsheetdata, \%params, $hostinfo, $vsitename); # remember in case have references to other worksheets
         my $aerrtext = recalc_sheet(\%vsheetdata); # do the recalc
         }

      my $vstr;

      if (!$params{type} || lc($params{type}) eq "page") {
         if ($loaderr) {
            $responsedata->{content} = "$loaderr '$params{view}'";
            return;
            }
         my $sitedata = $hostinfo->{sites}->{$vsitename};
         my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

         $linkstyle = "$sitedata->{editurl}?view=$vsitename/[[pagename]]";
         my ($stylestr, $sheetstr) = render_sheet(\%vsheetdata, 'class="wkcsheet"', "", "s", "a", "publish", "", "", $linkstyle);

         my $author = $vheaderdata{lastauthor} || $sitedata->{authoronhost}; # Get author name

         $vstr = $vheaderdata{templatetext}
                   || get_template(\%params, "htmltemplate", $vheaderdata{templatefile})
                   || get_template(\%params, "htmltemplate", "site:default")
                   || get_template(\%params, "htmltemplate", "shared:default")
                   || get_template(\%params, "htmltemplate", "system:default")
                   || $WKCStrings{"publishtemplate"};

         $vstr = fill_in_HTML_template($vstr, $sitedata, \%vheaderdata, $vsitename, $vpagename, $start_clock_time, $author, $loggedinuser, $stylestr, $sheetstr, 1);
         $responsedata->{content} = $vstr;
         $responsedata->{contenttype} = "text/html; charset=UTF-8";
         }

      elsif (lc($params{type}) eq "js") {
         if ($loaderr) {
            $responsedata->{content} = "document.write('$loaderr \\'$params{view}\\'');";
            $responsedata->{contenttype} = "text/javascript";
            return;
            }
         my ($stylestr, $sheetstr) = render_sheet(\%vsheetdata, 'class="wkcsheet"', "", "s", "a", "embed", "", "", $linkstyle);
         $vstr = create_embeddable_JS_sheet($stylestr, $sheetstr);
         $responsedata->{content} = $vstr;
         $responsedata->{contenttype} = "text/javascript; charset=UTF-8";
         }

      elsif (lc($params{type}) eq "html") {
         if ($loaderr) {
            $responsedata->{content} = "$loaderr '$params{view}'";
            $responsedata->{contenttype} = "text/plain";
            return;
            }
         my ($stylestr, $sheetstr) = render_sheet(\%vsheetdata, 'class="wkcsheet"', "", "s", "a", "inline", "", "", $linkstyle);
         $responsedata->{content} = $sheetstr;
         $responsedata->{contenttype} = "text/plain; charset=UTF-8";
         }

      elsif (lc($params{type}) eq "cdata") {
         if ($loaderr) {
            $responsedata->{content} = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[Error: $loaderr '$params{view}']]></root>
EOF
            $responsedata->{contenttype} = "text/xml";
            return;
            }
         my ($stylestr, $sheetstr) = render_sheet(\%vsheetdata, 'class="wkcsheet"', "", "s", "a", "inline", "", "", $linkstyle);
         my $xmlresponse = <<"EOF";
<?xml version="1.0" ?>
<root><![CDATA[$sheetstr]]></root>
EOF
         $responsedata->{content} = $xmlresponse;
         $responsedata->{contenttype} = "text/xml";
         return;
         }

      else {
         $responsedata->{content} = "$WKCStrings{viewunknowntype} '$params{type}'.";
         }

      $responsedata->{contenttype} = "text/html; charset=UTF-8";

      # (leave cookies as they were)

      return;
      }

   #
   # *** Protect from not being logged in
   #

   if ($needlogin) {
      my $temp1 = $params{editthispage};
      my $temp2 = $params{etpurl};
      %params = (); # need login -- wipe out all parameters (for now...)
      $params{logineditthispage} = $temp1 if $temp1;
      $params{etpurl} = $temp2 if $temp2;
      }

   #
   # *** Process Edit This Page call (do a POST with editthispage=sitename/pagename)
   #

   my $checkmultiedit; # if non-blank, list of others editing already

   if ($params{editthispage}) { # "Edit this page" invocation
      my ($etpsavesitename, $etpsavedatafilename) = ($params{sitename}, $params{datafilename});
      ($params{sitename}, $params{datafilename}) = split(/\//, $params{editthispage}, 2);
      $params{sitename} =~ s/[^a-z0-9\-]//g; # get new sitename and pagename
      my $etperrstr;
      if (site_not_allowed(\%userinfo, $loggedinuser, $params{sitename})) {
         $params{sitename} = "";
         $params{datafilename} = "";
         $params{etpurl} = ""; # if wipe out name, wipe out back to where we started when editing
         $etperrstr = $WKCStrings{"etpnotfound"};
         }
      if ($params{cancelmultieditthispage}) { # someone else editing and decided not to override
         $etperrstr = qq!$WKCStrings{"etpeditstartof"} "$params{datafilename}" $WKCStrings{"etpcancelled"}!;
         $params{datafilename} = "";
         $params{etpurl} = "";
         $params{newtab} = $WKCStrings{"Page"};
         }
      $params{datafilename} =~ s/[^a-z0-9\-]//g;
      $editcoords = "";
      delete $params{scrollrow};

      # See if anybody else is editing this

      if (!$params{editthispageokmulti} && !$etperrstr) {
         my $siteinfo = get_siteinfo(\%params);

         my $currentauthor = $hostinfo->{sites}->{$params{sitename}}->{authoronhost};
           if ($hostinfo->{sites}->{$params{sitename}}->{authorfromlogin} eq "yes" && $params{loggedinusername}) {
            $currentauthor = $params{loggedinusername};
            }

         my $ok = update_siteinfo(\%params, $hostinfo, $siteinfo);

         if ($siteinfo->{updates}) {
            $ok = save_siteinfo(\%params, $siteinfo);
            }
         my $fileinfo = $siteinfo->{files}->{$params{datafilename}};
         my $editstatus = $fileinfo->{authors}->{$currentauthor}->{editstatus};

         foreach my $author (sort keys %{$fileinfo->{authors}}) {
            if ($author ne $currentauthor) { # not us
               $checkmultiedit .= "$author, ";
               }
            }
         }

      if ($checkmultiedit) { # others editing - check if that's OK first
         $checkmultiedit =~ s/, $//; # make readable
         ($params{sitename}, $params{datafilename}) = ($etpsavesitename, $etpsavedatafilename); # restore
         $params{checkmultiediteditthispage} = $params{editthispage};
         }

      elsif (!$etperrstr) { # all ready for us
         delete $params{scrollrow};
         $etperrstr = edit_published_page(\%params, $hostinfo, $params{sitename}, $params{datafilename}) unless $etperrstr;
         if ($etperrstr && !$needlogin) {
            $params{newtab} = $WKCStrings{"Page"};
            $params{etpurl} = "";
            $params{debugmessage} = $etperrstr;
            }
         else {
            $params{newtab} =  $WKCStrings{"Edit"};
            }
         }
      }

   #
   # *** If nothing set, see if anything remembered in cookie
   #

   if (!$params{datafilename} && !$params{sitename}) {
      if ($cookievalues{datafilename}) {
         $params{datafilename} = $cookievalues{datafilename};
         delete $params{scrollrow};
         }
      if ($cookievalues{sitename}) {
         $params{sitename} = $cookievalues{sitename};
         }
      }

   #
   # *** Check OK to edit this site
   #

   if (site_not_allowed(\%userinfo, $loggedinuser, $params{sitename})) {
      $params{sitename} = "";
      $params{datafilename} = "";
      $params{etpurl} = "" unless $params{logineditthispage};
      }

   #
   # *** Process buttons
   #

   foreach my $p (keys %params) {  # go through all the parameters

      #
      # Change which page we are editing
      #

      if ($p =~ /^choosepage(local|pub|backup):(.*)/) {
         my $newname = $2;
         my $editerrstr;
         if ($1 eq "pub") { # if editing from published page, copy the contents to an edit file
            $editerrstr = edit_published_page(\%params, $hostinfo, $params{sitename}, $2);
            }
         elsif ($1 eq "backup") {
            my $basefile = $2;
            $basefile =~ m/([a-z0-9\-]+?)\.\w+?\.[0-9\-]+?\.txt$/;
            $newname = $1;
            $editerrstr = edit_backup_page(\%params, $hostinfo, $params{sitename}, $basefile);
            }
         elsif ($1 ne "local") {
            $editerrstr = qq!Got command "$p"!; # debugging, shouldn't get here
            $params{"oktools:backup"} = 1;
            }
         if ($editerrstr) {
            $params{pagemessage} = qq!$WKCStrings{"choosecondition1"} "$2" $WKCStrings{"choosecondition2"}<br>$editerrstr!;
            }
         else {
            $params{datafilename} = $newname;
            $params{etpurl} = ""; # don't go back to last one from Edit This Page invocation
            $editcoords = "";
            delete $params{scrollrow};
            $params{newtab} =  $WKCStrings{"Edit"};
            }
         }

      #
      # Publish page
      #

      elsif ($p =~ /^publish(preview):(.*)/) {
         $params{pagemessage} = qq!Old code: $p!; # debugging
         }

      elsif ($p =~ /^publish(continue|page|frompage):(.*)/) {
         my $continuepage = $1; # which invocation
         my $name = $2;

         my (@pubheaderlines, %pubheaderdata, @pubsheetlines, %pubsheetdata);

         my $pubpath = get_page_edit_path(\%params, $hostinfo, $params{sitename}, $name);
         my $loaderr = load_page($pubpath, \@pubheaderlines, \@pubsheetlines);

         my $pareseok = parse_header_save(\@pubheaderlines, \%pubheaderdata); # Get data from header
         $pareseok = parse_sheet_save(\@pubsheetlines, \%pubsheetdata); # Get data from sheet

         my ($stylestr, $sheetstr) = render_sheet(\%pubsheetdata, 'class="wkcsheet"', "", "s", "a", "publish", "", "");

         my $sitedata = $hostinfo->{sites}->{$params{sitename}};
         my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

         my $thisauthor = $sitedata->{authoronhost}; # Get author name
         if ($sitedata->{authorfromlogin} eq "yes" && $params{loggedinusername}) {
            $thisauthor = $params{loggedinusername};
            $thisauthor =~ s/[^a-z0-9\-]//g;
            }

         my $pubstr;
         if ($continuepage ne "frompage") { # invoked from view tab -- check updates to what to publish
            $pubheaderdata{publishhtml} = $params{editpublishhtml} ? "yes" : "no";
            $pubheaderdata{publishsource} = $params{editpublishsource} ? "yes" : "";
            $pubheaderdata{publishjs} = $params{editpublishjs} ? "yes" : "";
            $pubheaderdata{viewwithoutlogin} = $params{editviewwithoutlogin} ? "yes" : "";
            }
         $pubstr = $pubheaderdata{templatetext}
                   || get_template(\%params, "htmltemplate", $pubheaderdata{templatefile})
                   || get_template(\%params, "htmltemplate", "site:default")
                   || get_template(\%params, "htmltemplate", "shared:default")
                   || get_template(\%params, "htmltemplate", "system:default")
                   || $WKCStrings{"publishtemplate"};

         if ($params{editcomments}) { # New comment content to go with this publish - saved when published
            $pubheaderdata{editcomments} = $params{editcomments}; # do here so available to HTML
            }
 
         add_to_editlog(\%pubheaderdata, "# $WKCStrings{logpublishedby} $thisauthor") if $thisauthor ne $pubheaderdata{lastauthor}; # if unmodified may have last author

         $pubstr = fill_in_HTML_template($pubstr, $sitedata, \%pubheaderdata, $params{sitename}, $name, $start_clock_time, $thisauthor, $loggedinuser, $stylestr, $sheetstr, 0);

         my $continueediting = $continuepage eq "continue" ? 1 : 0; # Continue editing if requested

         my $jsstr;
         if ($pubheaderdata{publishjs} eq "yes") {
            ($stylestr, $sheetstr) = render_sheet(\%pubsheetdata, 'class="wkcsheet"', "", "s", "a", "embed", "", "");
            $jsstr = create_embeddable_JS_sheet($stylestr, $sheetstr);
            }

         my $puberrstr = publish_page(\%params, $hostinfo, $params{sitename}, $name, $pubstr, $jsstr, \%pubheaderdata, \%pubsheetdata, $continueediting);
         if ($puberrstr) {
            $params{pagemessage} = qq!$WKCStrings{"publisherror"} "$name":<br>$puberrstr!;
            }

         if (!$continueediting && $name eq $params{datafilename}) { # reset if were editing page just published
            $params{datafilename} = "";
            delete $params{scrollrow};
            $params{etpurl} = "" if $continuepage eq "frompage";
            }

         $published = $name;
         }

      #
      # Delete page
      #

      elsif ($p =~ /^choosepagedel:(.*)/) {
         my $deletepage = $1;
         my $errstr = delete_page(\%params, $hostinfo, $params{sitename}, $deletepage);
         if ($errstr) {
            $params{pagemessage} = qq!$WKCStrings{"choosedelerror"} "$deletepage":<br>$errstr!;
            }
         else {
            $params{pagemessage} = qq!$WKCStrings{"choosedeldeleted"} "$deletepage"!;
            }
         if ($deletepage eq $params{datafilename}) {
            delete $params{datafilename}; # if deleted current page, make it not the current page
            delete $params{scrollrow};
            $params{etpurl} = "";
            }
         delete $params{pagebuttons}; # go back to normal editing state
         }

      #
      # Abandon editing page
      #

      elsif ($p =~ /^choosepageabandon:(.*)/) { # Abandon editing page
         my $abandonpage = $1;
         my $errstr = abandon_page_edit(\%params, $hostinfo, $params{sitename}, $abandonpage);
         if ($errstr) {
            $params{pagemessage} = qq!$WKCStrings{"chooseabandonerror"} "$abandonpage":<br>$errstr!;
            }
         else {
            $params{pagemessage} = qq!$WKCStrings{"chooseabandondeleted1"} "$abandonpage" $WKCStrings{"chooseabandondeleted2"}!;
            }
         if ($abandonpage eq $params{datafilename}) {
            delete $params{datafilename}; # if abandoned current page, make it not the current page
            delete $params{scrollrow};
            $params{etpurl} = "";
            }
         delete $params{pagebuttons}; # go back to normal editing state
         }

      #
      # Set a new range
      #

      elsif ($p =~ /^okeditrange:(.+)/) { # Range edit command
         $params{okeditrange} = $1; # Remember which particular command
         }

      #
      # Backup subcommand
      #

      elsif ($p =~ /^backup:(details|archive|delete|download|preferences|savepreferences|all|list):(.+)/) { # Backup sub-command
         $params{backupsubcommand} = $1; # Remember which particular command
         $params{backupfilename} = $2; # Remember which file and/or other information
         if ($1 eq "list" || $1 eq "all") { # List and All may have paging info
            ($params{backupfilename}, $params{startitem}) = split(/:/, $params{backupfilename});
            } 
         $params{"oktools:backup"} = 1; # Invoke backup command to process
         }

      }

   if ($params{okeditpreview}) {
      $params{newtab} = $WKCStrings{"Preview"};
      }

   if (!$params{datafilename}) { # If no page chosen, go to Page tab in most cases
      if ($params{newtab}) {
         if ($params{newtab} ne $WKCStrings{"showlicense"} && $params{newtab} ne $WKCStrings{"Tools"}) {
            $params{newtab} = $WKCStrings{"Page"};
            }
         }
      elsif ($params{currenttab} ne $WKCStrings{"Tools"}) {
         $params{newtab} = $WKCStrings{"Page"};
         }
      }

   if ($params{newtab}) {
      if ($params{newtab} eq $WKCStrings{"Page"}) {
         $params{currenttab} = $params{newtab};
         $editmode = "";
         }
      elsif ($params{newtab} eq $WKCStrings{"Preview"}) {
         $params{currenttab} = $params{newtab};
         $editmode = "";
         }
      elsif ($params{newtab} eq $WKCStrings{"Edit"}) {
         $params{currenttab} = $params{newtab};
         $editmode = $WKCStrings{"editsub-general"};
         $editcoords =~ s/:.*$//; # start with only upper left
         $editcoords ||= "A1";
         $params{editcoords} = $editcoords;
         }
      elsif ($params{newtab} eq $WKCStrings{"Format"}) {
         $params{currenttab} = $params{newtab};
         $editmode = $WKCStrings{"formatsub-range"};
         $editcoords ||= "A1";
         $params{editcoords} = $editcoords;
         }
      elsif ($params{newtab} eq $WKCStrings{"Tools"}) {
         $params{currenttab} = $params{newtab};
         $editcoords ||= "A1";
         $params{editcoords} = $editcoords;
         }
      elsif ($params{newtab} eq $WKCStrings{"showlicense"}) {
         $params{currenttab} = $params{newtab};
         $editmode = "";
         }
      }

   if ($params{editsub}) {
      $editmode = $params{editsub};
      }

   #
   # Get current tab and switch if necessary
   #

   my $currenttab = $params{currenttab} || $WKCStrings{"Page"};
   my $lineheight;
   if ($currenttab eq $WKCStrings{"Edit"} || $currenttab eq $WKCStrings{"Format"}) {
      $lineheight = qq! style="font-size:1pt;"!;
      }

   #
   # Display tabs and other top stuff
   #

   $rbodytabs = <<"EOF";
<form name="ftabs" action="" method="POST">
<table cellpadding="0" cellspacing="0">
<tr>
EOF

   foreach my $tab (@tablist) {
      next if ($tab eq $WKCStrings{"Quit"} && $noquittab); # CGI version doesn't show Quit tab
      if ($currenttab eq $tab && !$needlogin) {
         $rbodytabs .= <<"EOF";
<td class="tab1">&nbsp;</td>
<td class="tabselected">$tab</td>
EOF
         }
      else {
         $rbodytabs .= <<"EOF";
<td class="tab1">&nbsp;</td>
<td class="tab"><input type="submit" name="newtab" value="$tab"></td>
EOF
         }
      }

   $rbodytabs .= <<"EOF";
<td class="tab1" width="100%">&nbsp;</td>
</tr>
<tr>
<td class="tab2left" width="1"$lineheight>&nbsp;</td>
EOF

   my $ncols = @tablist - ($noquittab ? 1 : 0);
   $ncols = $ncols * 2 + 1;
   for (my $i=0; $i<$ncols-2; $i++) {
      $rbodytabs .= <<"EOF";
<td class="tab2"$lineheight>&nbsp;</td>
EOF
      }

   $rbodytabs .= <<"EOF";
<td class="tab2right"$lineheight>&nbsp;</td>
</tr>
</table>
EOF

   # # # # # # # # # #
   #
   # *** Read in data and do things
   #
   # # # # # # # # # #


   my $sheetmodified;

   my $editpath;

   if ($params{datafilename} && $params{sitename}) {
      $editpath = get_page_edit_path(\%params, $hostinfo, $params{sitename}, $params{datafilename});
      my $loaderr = load_page($editpath, \@headerlines, \@sheetlines);

      if ($loaderr) { # deselect if can't load -- don't let us edit an inappropriate blank page
         $params{datafilename} = "";
         }

      $ok = parse_header_save(\@headerlines, \%headerdata);
      $ok = parse_sheet_save(\@sheetlines, \%sheetdata);
      $sheetmodified = 0;
      }
   else { # No file -- use null sheet
      $sheetlines[0] = "";
      $ok = parse_sheet_save(\@sheetlines, \%sheetdata);
      $sheetmodified = 0;
      }
   init_sheet_cache(\%sheetdata, \%params, $hostinfo, $params{sitename}); # remember in case have references to other worksheets

   #
   # *** See if there are edits to do
   #

   if ($params{okeditcoord}) {
      $editcoords = $params{editeditcoords};
      }

   elsif ($params{editaddrow} || $params{editaddcol}) { # extend sheet by a row or column
      my $newsize;
      if ($params{editaddrow}) {
         $newsize = $sheetdata{sheetattribs}->{lastrow} + 1;
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet lastrow $newsize", \%headerdata);
         }
      elsif ($params{editaddcol}) {
         $newsize = $sheetdata{sheetattribs}->{lastcol} + 1;
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet lastcol $newsize", \%headerdata);
         }
      $sheetmodified += 1;
      }

   elsif ($params{okcolumns}) {
      my $value = $params{colwidthvalue};
      $value = "" if $params{colwidthtype} eq "default";
      $value = "auto" if $params{colwidthtype} eq "auto";
      if ($params{colwidthpercent}) {
          $value = $value > 100 ? 100 : ($value < 1 ? 1 : $value);
          $value .= "%";
          }
      my $ok;
      if ($params{columnsedefault}) {
         my $cmdline = "set sheet defaultcolwidth $value";
         $ok = execute_sheet_command_and_log(\%sheetdata, $cmdline, \%headerdata);
         }
      else {
         my $colname = $editcoords;
         $colname =~ s/\d//g;
         my $cmdline = "set $colname width $value";
         $ok = execute_sheet_command_and_log(\%sheetdata, $cmdline, \%headerdata);
         $value = $params{colhidevalue} ? "yes" : ""; # set hide value to yes or blank
         $cmdline = "set $colname hide $value";
         $ok = execute_sheet_command_and_log(\%sheetdata, $cmdline, \%headerdata);
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okrows}) {
      my $rowname = $editcoords;
      $rowname =~ s/[A-Za-z]//g;
      my $value = $params{rowhidevalue} ? "yes" : ""; # set hide value to yes or blank
      my $cmdline = "set $rowname hide $value";
      $ok = execute_sheet_command_and_log(\%sheetdata, $cmdline, \%headerdata);
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okborders}) {
      my ($crd, $ok);
      $ok = 1;
      if ($params{borderoutline}) {
         my ($coord1, $coord2) = split(/:/, $editcoords);
         my ($c1, $r1) = coord_to_cr($coord1);
         my $c2 = $c1;
         my $r2 = $r1;
         ($c2, $r2) = coord_to_cr($coord2) if $coord2;
         for (my $c = $c1; $c <= $c2; $c++) {
            $crd = cr_to_coord($c, $r1);
            $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $crd bt $params{editborder1}", \%headerdata);
            $crd = cr_to_coord($c, $r2);
            $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $crd bb $params{editborder3}", \%headerdata);
            }
         for (my $r = $r1; $r <= $r2; $r++) {
            $crd = cr_to_coord($c1, $r);
            $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $crd bl $params{editborder4}", \%headerdata);
            $crd = cr_to_coord($c2, $r);
            $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $crd br $params{editborder2}", \%headerdata);
            }
         }
      else {
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $editcoords bt $params{editborder1}", \%headerdata);
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $editcoords br $params{editborder2}", \%headerdata);
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $editcoords bb $params{editborder3}", \%headerdata);
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $editcoords bl $params{editborder4}", \%headerdata);
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{oklayout}) {
      my $ok;
      my $layoutstr; # default to blank, which is "use default"
      if ($params{explicitlayout} eq "yes") { # set explicitly
         #
         # layout format is: padding:top right bottom left;vertical-align:style
         #
         $layoutstr = "padding:$params{layoutpaddingtop} $params{layoutpaddingright} $params{layoutpaddingbottom} $params{layoutpaddingleft};";
         $layoutstr .= "vertical-align:$params{verticalalign};";
         }
      if ($params{layoutdefault}) {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaultlayout $layoutstr", \%headerdata);
         }
      else {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords layout $layoutstr", \%headerdata);
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okcolors}) {
      my $ok;
      if ($params{colorsedefault}) {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaultcolor $params{edittextcolor}", \%headerdata);
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set sheet defaultbgcolor $params{editbackgroundcolor}", \%headerdata);
         }
      else {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords color $params{edittextcolor}", \%headerdata);
         $ok &&= execute_sheet_command_and_log(\%sheetdata, "set $editcoords bgcolor $params{editbackgroundcolor}", \%headerdata);
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okfonts}) {
      my $ok;
      my $fontstyleweight;
      if ($params{fontdefault}) {
         $fontstyleweight = "*";
         }
      else {
         $fontstyleweight = $params{fontitalic} ? "italic " : "normal ";
         $fontstyleweight .= $params{fontbold} ? "bold" : "normal";
         }
      $params{fontsize} = "*" if $params{fontsize} eq "default";
      $params{fontfamily} = "*" if $params{fontfamily} eq "default";
      if ($params{fontedefault}) {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaultfont $fontstyleweight $params{fontsize} $params{fontfamily}", \%headerdata);
         }
      else {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords font $fontstyleweight $params{fontsize} $params{fontfamily}", \%headerdata);
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{oktext}) {
      my $ok;
      $params{textalign} = "" if $params{textalign} eq "default";
      $params{textvalueformat} = "" if $params{textvalueformat} eq "default";
      if ($params{textedefault}) {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaulttextformat $params{textalign}", \%headerdata);
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaulttextvalueformat $params{textvalueformat}", \%headerdata);
         }
      else {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords cellformat $params{textalign}", \%headerdata);
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords textvalueformat $params{textvalueformat}", \%headerdata) if $ok;
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okmisc}) {
      my $ok;
      $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords cssc $params{miscclassvalue}", \%headerdata);
      $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords csss $params{miscstylevalue}", \%headerdata) if $ok;
      $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords mod $params{miscmodvalue}", \%headerdata) if $ok;
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{oknumeric}) {
      my $ok;
      $params{numbersalign} = "" if $params{numbersalign} eq "default";
      $params{numbersvalueformat} = "" if $params{numbersvalueformat} eq "default";
      if ($params{numbersedefault}) {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaultnontextformat $params{numbersalign}", \%headerdata);
         $ok = execute_sheet_command_and_log(\%sheetdata, "set sheet defaultnontextvalueformat $params{numbersvalueformat}", \%headerdata) if $ok;
         }
      else {
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords cellformat $params{numbersalign}", \%headerdata);
         $ok = execute_sheet_command_and_log(\%sheetdata, "set $editcoords nontextvalueformat $params{numbersvalueformat}", \%headerdata) if $ok;
         }
      if ($ok) {
         $sheetmodified += 1;
         }
      else {
         $params{debugmessage} = "Failed: $ok\n";
         }
      }

   elsif ($params{okeditrange}) {
      my $errtxt = execute_edit_command(\%params, \%sheetdata, $editcoords, \%headerdata);
      if ($errtxt) {
         $params{debugmessage} = "Failed: $errtxt\n";
         }
      else {
         if ($params{recalc} ne "off" && $params{okeditrange}!~/merge|copy/) {
            my $errtext = recalc_sheet(\%sheetdata);
            }
         else {
            if ($params{okeditrange}!~/merge|copy|recalc/) {
               $sheetdata{sheetattribs}->{needsrecalc} = "yes" if $params{okeditrange}!~/merge|copy/;
               }
            }
         $editcoords = $params{editcoords};
         $sheetmodified += 1;
         }
      }

   elsif ($params{dorecalc}) {
      my $errtext = recalc_sheet(\%sheetdata);
      $sheetmodified += 1;
      }

   elsif ($params{oktoolspageproperties}) {
      $headerdata{fullname} = $params{editlongname};
      if ($params{edittemplatetype} eq "default") {
         $headerdata{templatefile} = "";
         $headerdata{templatetext} = "";
         }
      if ($params{edittemplatetype} eq "shared") {
         $headerdata{templatefile} = $params{edittemplatelist};
         $headerdata{templatetext} = "";
         }
      if ($params{edittemplatetype} eq "explicit") {
         $headerdata{templatefile} = "";
         $headerdata{templatetext} = $params{edittemplatetext};
         }
      $headerdata{publishhtml} = $params{editpublishhtml} ? "yes" : "no";
      $headerdata{publishsource} = $params{editpublishsource};
      $headerdata{publishjs} = $params{editpublishjs};
      $headerdata{viewwithoutlogin} = $params{editviewwithoutlogin};
      add_to_editlog(\%headerdata, "# $WKCStrings{logeditedpageproperties}");
      $sheetmodified += 1;
      }

   elsif ($params{okeditcomments}) {
      $headerdata{editcomments} = $params{editcomments}; # no need to log -- this is different for each backup
      $sheetmodified += 1;
      }

   elsif ($params{oktoolsloadfromtext} || $params{oktoolsloadfromsheet}) {
      my $errtxt = execute_tools_command(\%params, \%sheetdata, $editcoords, \%headerdata);
      if ($errtxt) {
         $params{debugmessage} = "Failed: $errtxt\n";
         }
      else {
         if ($params{recalc} ne "off") {
            my $errtext = recalc_sheet(\%sheetdata);
            }
         else {
            $sheetdata{sheetattribs}->{needsrecalc} = "yes";
            }
         $editcoords = $params{editcoords};
         $sheetmodified += 1;
         }
      }

   elsif ($params{oktoolsuseradmin}) {
      if ($params{loggedinadmin} eq "yes") { # must be admin
         my $errtxt = execute_tools_useradmincommand(\%params);
         }
      }

   #
   # *** Save sheet if modifications
   #

   if ($sheetmodified && $params{sitename}) {
      my $sheetcontents = create_sheet_save(\%sheetdata);

      $headerdata{lastmodified} = $start_clock_time; # remember it in header

      my $sitedata = $hostinfo->{sites}->{$params{sitename}};
      my $thisauthor = $sitedata->{authoronhost}; # Get author name
      if ($sitedata->{authorfromlogin} eq "yes" && $params{loggedinusername}) {
         $thisauthor = $params{loggedinusername};
         $thisauthor =~ s/[^a-z0-9\-]//g;
         }
      $headerdata{lastauthor} = $thisauthor;
      my $headercontents = create_header_save(\%headerdata);

      $ok = save_page($editpath, $headercontents, $sheetcontents);

      }

   #
   # *** See if need to rename page
   #

   if ($params{oktoolspageproperties} && $params{editpagename} ne $params{datafilename} && $params{sitename}) {
      my $newname = $params{editpagename};
      $newname =~ s/[^a-z0-9\-]//g;
      $params{toolsmessage} = rename_existing_page(\%params, $hostinfo, $params{sitename}, $params{datafilename}, $newname);
      $params{etpurl} = "";
      }

   # # # # # # # # # #
   #
   # Output command section (if necessary) and data depending upon mode
   #
   # # # # # # # # # #

   my $template_stylemiddle = $template_stylemiddle_verbose;
   $params{promptlevelspacing} = "<br>";


   my $fullname = special_chars($headerdata{fullname}); # used in some places
   my $fullsitename = special_chars($hostinfo->{sites}->{$params{sitename}}->{longname});

   my $programnametop = $WKCStrings{programextratop} ? "$WKCStrings{programextratop}&nbsp;" : "";
   $programnametop .= "$programmark&nbsp;$programversion";

   #
   # Top line of screen with page name and login/logout stuff
   #

   $rbody1 = <<"EOF"; # Top line of screen
</head>
<body onload="setactions();setf()">
<div class="programtop">
<form name="flo" method="POST">
<table cellspacing="0" cellpadding="0"><tr><td width="100%" valign="top">
EOF
   $rbody1 .= <<"EOF" if $params{datafilename} && $currenttab ne $WKCStrings{"Page"};
<span class="programtopdark">$fullname</span>
<span class="programtoplight">($params{datafilename}.html $WKCStrings{"topon"} $fullsitename)</span>
EOF
   $rbody1 .= <<"EOF" if $params{loggedinusername}; # stay with POST
<span class="programtoplight">$WKCStrings{"topuser"}: $params{loggedinusername}</span>
<span class="programtoplogout">[<a href="" onClick="document.flo.submit();return false;">$WKCStrings{"toplogout"}</a>]</span>
<input name="dologout" type="hidden" value="1">
EOF
   if ($headerdata{reverted} && $currenttab ne $WKCStrings{"Page"}) {
      $headerdata{reverted} =~ m/^.+?\.\w+?\.([0-9\-]+)\.txt/;
      $rbody1 .= <<"EOF"
<br>
<span class="programtoprevert">$WKCStrings{"toprevert"} $1</span>
EOF
      }
   $rbody1 .= <<"EOF";
</td><td valign="top"><div class="programtopname">$programnametop</div></td></tr></table></form>
</div>
EOF

   my $etpurlencoded = url_encode_plain($params{etpurl});
   my $hiddenfields = <<"EOF";
<input type="hidden" name="editcoords" value="$editcoords">
<input type="hidden" name="editmode" value="$editmode">
<input type="hidden" name="scrollrow" value="$params{scrollrow}">
<input type="hidden" name="formatmode" value="$params{formatmode}">
<input type="hidden" name="securitycode" value="$securitycode">
<input type="hidden" name="currenttab" value="$currenttab">
<input type="hidden" name="datafilename" value="$params{datafilename}">
<input type="hidden" name="sitename" value="$params{sitename}">
<input type="hidden" name="loggedinusername" value="$params{loggedinusername}">
<input type="hidden" name="loggedinuserpassword" value="$params{loggedinuserpassword}">
<input type="hidden" name="etpurl" value="$etpurlencoded">
EOF

   $rbodytabs2 .= <<"EOF";
</form>
EOF

   # # # # # # # # # #
   #
   # Do login
   #
   # # # # # # # # # #

   if ($needlogin) {
      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2;

      my $descstring = $loginerrtext;

      my $etpstr;
      $etpstr = <<"EOF" if $params{logineditthispage};
<input name="editthispage" type="hidden" value="$params{logineditthispage}">
EOF

      $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
<td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"logintitle"}</div>
<div class="pagetitledesc">$descstring</div>
</div>
<form name="f0" method="POST">
<div class="sectionplain">
<table cellpadding="0" cellspacing="0">
<tr>
<td><div class="title">$WKCStrings{"loginname"}&nbsp;</div></td>
<td><div style="margin-bottom:2pt;"><input type="text" name="editusername" size="15" value=""></div></td>
<td><div class="title">&nbsp;$WKCStrings{"loginpassword"}&nbsp;</div></td>
<td><div style="margin-bottom:2pt;"><input type="password" name="edituserpassword" size="10" value=""></div></td>
<td>&nbsp;<input type="submit" name="dologin" value="$WKCStrings{"loginlogin"}"></td>
</tr>
</table>
<input type="radio" name="editusercookies" value="session" CHECKED><span class="smaller">$WKCStrings{"loginsessioncookie"}</span>&nbsp;
<input type="radio" name="editusercookies" value="$defaultcookieexpire"><span class="smaller">$WKCStrings{"loginlongcookie"}</span>
<br>
</div>
$etpstr
$hiddenfields
</form>
</td></tr>
</table>
<script>
var setf = function() {document.f0.editusername.focus();}
</script>
EOF
      }

   # # # # # # # # # #
   #
   # Do you want to edit this page when others are already editing it?
   #
   # # # # # # # # # #

   elsif ($checkmultiedit) {
      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2;

      my $descstring = $loginerrtext;

      $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
<td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"multiedittitle"}</div>
<div class="pagetitledesc">$WKCStrings{"multieditdoyou"} "$params{datafilename}" $WKCStrings{""}
$WKCStrings{"multiediteventhough2"}
</div>
</div>
<form name="f0" method="POST">
<div class="sectionplain">
$WKCStrings{"multieditpage"} "$params{datafilename}" $WKCStrings{"multieditonsite"} "$params{sitename}" $WKCStrings{"multieditisopen"}: $checkmultiedit<br><br>
<input type="submit" name="okmultieditthispage" value="$WKCStrings{"multiedityes"}">
<input type="submit" name="cancelmultieditthispage" value="$WKCStrings{"multieditno"}">
</div>
<input name="editthispage" type="hidden" value="$params{checkmultiediteditthispage}">
<input name="editthispageokmulti" type="hidden" value="1">
$hiddenfields
</form>
</td></tr>
</table>
EOF
      }

   # # # # # # # # # #
   #
   # Just published
   #
   # # # # # # # # # #

   elsif ($published) {
      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2;

      my $descstring = $params{datafilename} ? $WKCStrings{"publisheddescopen"} : $WKCStrings{"publisheddescclosed"};

      my $pagemessage;
      if ($params{pagemessage}) { # Publish info
         $pagemessage = <<"EOF";
<div class="sectionerror">
$params{pagemessage}
</div>
EOF
         }

      $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
<td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"publishedtitle"}$published</div>
<div class="pagetitledesc">$descstring</div>
</div>
$pagemessage
<form name="f0" method="POST">
<div class="sectionplain">
EOF
      if ($params{datafilename}) { # continue
         $response .= <<"EOF";
<input type="submit" name="publishcontinue" value="$WKCStrings{"publishcontinueediting"}">
EOF
         }
      else {
         $response .= <<"EOF";
<input type="submit" name="publishcontinue" value="$WKCStrings{"publishviewpagelist"}">
EOF
         }

      if ($params{editpublishhtml} eq "yes" && $hostinfo->{sites}->{$params{sitename}}->{htmlurl}) { # HTML accessible
         $response .= <<"EOF";
<input type="submit" value="$WKCStrings{"publishviewhtmlpage"}" onclick="location.href='$hostinfo->{sites}->{$params{sitename}}->{htmlurl}/$published.html';return false;">
EOF
         }
      my $editurl = $hostinfo->{sites}->{$params{sitename}}->{editurl};
      if ($editurl) {
         $response .= <<"EOF";
<input type="submit" value="$WKCStrings{"publishviewlivepage"}" onclick="location.href='$editurl?view=$params{sitename}/$published';return false;">
EOF
        }
      $response .= <<"EOF";
</div>
EOF
      if ($params{etpurl}) {
         my $etpurlencode = url_encode_plain($params{etpurl});
         $response .= <<"EOF";
<br>
<div class="sectionoutlined">
<div style="padding-bottom:4pt;"><input type="submit" value="$WKCStrings{"publishresume"}" onclick="location.href='$etpurlencode';return false;"></div>
<div class="pagetitledesc">$WKCStrings{"publishresumedesc"}<br>
$params{etpurl}
</div>
</div>
<br>
EOF
         }
      $response .= <<"EOF";
$hiddenfields
</form>
</td></tr>
</table>
EOF
      }

   # # # # # # # # # #
   #
   # Page mode
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"Page"}) {
      my $pcstr = do_page_command(\%params, $loggedinuser, \%userinfo, $hiddenfields);

      $hiddenfields = update_hiddenfields(\%params, $hiddenfields);

      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2 . $pcstr;

      }

   # # # # # # # # # #
   #
   # Preview mode (Publish tab)
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"Preview"}) {

      my $editcommentsnl = special_chars_nl($headerdata{editcomments});

      # Load scripts from a file

      $inlinescripts .= $WKCStrings{"jsdefinestrings"};
      open JSFILE, "$WKCdirectory/WKCjs.txt";
      while (my $line = <JSFILE>) {
         $inlinescripts .= $line;
         }
      close JSFILE;

      open JSFILE, "$WKCdirectory/WKCpreviewjs.txt";
      while (my $line = <JSFILE>) {
         $inlinescripts .= $line;
         }
      close JSFILE;
 
      my $onclickstr = q! onclick="rcc('$coord');"!;
      my $linkstyle = "?view=$params{sitename}/[[pagename]]";
      my ($stylestr, $outstr) = render_sheet(\%sheetdata, 'class="wkcsheet"', "", "s", "a", $editmode, $editcoords, $onclickstr, $linkstyle);

      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $stylestr . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2;

      my ($publishhtmlchecked, $publishsourcechecked, $publishjschecked, $viewwithoutloginchecked);
      $publishhtmlchecked = " CHECKED" if $headerdata{publishhtml} ne "no";
      $publishsourcechecked = " CHECKED" if $headerdata{publishsource} eq "yes";
      $publishjschecked = " CHECKED" if $headerdata{publishjs} eq "yes";
      $viewwithoutloginchecked = " CHECKED" if $headerdata{viewwithoutlogin} eq "yes";

      $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td class="ttbody" width="100%"><form name="f0" method="POST">
<div style="margin:4px 0px 4px 0px;">
 <table class="buttonbar" cellspacing="0" cellpadding="0"><tr>
  <td id="publishbutton"><input class="smaller" type="submit" name="bpublish" value="$WKCStrings{"previewpublish"}" onclick="this.blur();return switchto('publish');">
  </td><td id="viewbutton"><input class="smaller" type="submit" name="bview" value="$WKCStrings{"previewviewonweb"}" onclick="this.blur();return switchto('view');">
  </td><td id="helpbutton"><input class="smaller" type="submit" name="bhelp" value="$WKCStrings{"previewhelp"}" onclick="toggle_help('previewhelptext');this.blur();return false;">
  </td>
 </tr></table>
</div>

<div id="c1publish" style="display:none;">
<span class="smaller">
<b>$WKCStrings{"previewpublishtoserver"}:</b> $hostinfo->{sites}->{$params{sitename}}->{htmlurl}/$params{datafilename}.html
</span>
<br>
<span class="smaller"><b>Options:</b></span>
<input type="checkbox" name="editpublishhtml" value="yes"$publishhtmlchecked><span class="smaller">$WKCStrings{"previewpublishhtml"}</span>
<input type="checkbox" name="editpublishsource" value="yes"$publishsourcechecked><span class="smaller">$WKCStrings{"previewpublishsource"}</span>
<input type="checkbox" name="editpublishjs" value="yes"$publishjschecked><span class="smaller">$WKCStrings{"previewpublishjs"}</span>
<input type="checkbox" name="editviewwithoutlogin" value="yes"$viewwithoutloginchecked><span class="smaller">$WKCStrings{"previewpublishnologin"}</span>
<br>
<span class="smaller">$WKCStrings{"previewcomments"}</span>
<br>
<textarea cols="60" rows="3" name="editcomments">
$editcommentsnl</textarea>
<br>
<div class="smaller" style="margin:6px 0px;">
$WKCStrings{"previewcomments2"}
</div>
<input type="submit" class="smaller" name="okeditcomments" value="$WKCStrings{"previewsavecomments"}">
<input type="submit" class="smaller" name="publishcontinue:$params{datafilename}" value="$WKCStrings{"previewpublishcontinue"}">
<input type="submit" class="smaller" name="publishpage:$params{datafilename}" value="$WKCStrings{"previewpublishclose"}">
</div>

<div id="c1view" style="display:none;">
<div class="smaller" style="margin-bottom:6px;">
$WKCStrings{"previewview1"}
</div>
<table cellspacing="0" cellpadding="0">
EOF

      my $editurl = $hostinfo->{sites}->{$params{sitename}}->{editurl};
      if ($editurl) {
         $response .= <<"EOF";
<tr>
<td align="center" style="padding:0px 2pt 2pt 0px;"><input type="submit" class="smaller" value="$WKCStrings{"previewlivethis"}" onclick="location.href='$editurl?view=$params{sitename}/$params{datafilename}';return false;"></td>
<td align="center" style="padding:0px 2pt 2pt 0px;"><input type="submit" class="smaller" value="$WKCStrings{"previewlivepopup"}" onclick="window.open('$editurl?view=$params{sitename}/$params{datafilename}');return false;"></td>
</tr>
EOF
         }
      else {
         $response .= <<"EOF";
<tr>
<td colspan="2"><span class="warning">
$WKCStrings{"previewnolive"}
</span>
</td>
</tr>
EOF
         }

      if ($hostinfo->{sites}->{$params{sitename}}->{htmlurl}) {
         $response .= <<"EOF";
<tr>
<td align="center" style="padding:0px 2pt 2pt 0px;"><input type="submit" class="smaller" value="$WKCStrings{"previewplainthis"}" onclick="location.href='$hostinfo->{sites}->{$params{sitename}}->{htmlurl}/$params{datafilename}.html';return false;"></td>
<td align="center" style="padding:0px 2pt 2pt 0px;"><input type="submit" class="smaller" value="$WKCStrings{"previewplainpopup"}" onclick="window.open('$hostinfo->{sites}->{$params{sitename}}->{htmlurl}/$params{datafilename}.html');return false;"></td>
</tr>
EOF
         }
      else {
         $response .= <<"EOF";
<tr>
<td colspan="2"><span class="warning">
$WKCStrings{"previewnohtml"}
</span>
</td>
</tr>
EOF
         }

      $response .= <<"EOF";
</table>
</div>

<div id="helptext" style="width:500px;padding:10px 0px 10px 0px;display:none;">
 <div style="border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;color:white;background-color:#66CC66;">
 <table cellspacing="0" cellpadding="0"><tr><td align="center" width="100%" class="smaller"><b>$WKCStrings{"helphelp"}</b></td>
 </td><td align="right"><input class="smaller" type="submit" name="hidehelp" value="$WKCStrings{"helphide"}" onClick="toggle_help('');this.blur();return false;"></td>
 </tr></table></div>
 <div id="helpbody" class="smaller" style="height:200px;overflow:auto;background-color:white;padding:4px;border:1px solid black;">
  $WKCStrings{"helpnotloaded"}
 </div>
</div>

<br>
$hiddenfields
$inlinescripts
</form>
</td></tr></table>
<br>
<script>
<!--
function rcc(c) {document.ftabs.editcoords.value=c;document.ftabs.newtab[1].click();1;}
var setf = function() {switchto("publish");}
// -->
</script>
EOF

      $response .= <<"EOF";
$outstr
<br>
EOF

      }

   # # # # # # # # # #
   #
   # Edit mode
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"Edit"}) {

      # Load scripts from a file

      $inlinescripts .= $WKCStrings{"jsdefinestrings"};
      open JSFILE, "$WKCdirectory/WKCjs.txt";
      while (my $line = <JSFILE>) {
         $inlinescripts .= $line;
         }
      close JSFILE;

      $inlinescripts .= $WKCStrings{"editjsdefinestrings"};
      open JSFILE, "$WKCdirectory/WKCeditjs.txt";
      while (my $line = <JSFILE>) {
         $inlinescripts .= $line;
         }
      close JSFILE;
 
      my $coord = $editcoords;
      $coord =~ s/:.*$//; # only first cell
      my $cellcontents;
      if ($sheetdata{datatypes}->{$coord} eq "f" || $sheetdata{datatypes}->{$coord} eq "c") {
         $cellcontents = $sheetdata{formulas}->{$coord} if $sheetdata{datatypes}->{$coord} eq "f";
         }
      else {
         $cellcontents = $sheetdata{datavalues}->{$coord};
         }
      my $cellcontentsnl = special_chars_nl($cellcontents);

      my $onclickstr = q! onclick="rc0('$coord');"!;

      my $linkstyle = "?view=$params{sitename}/[[pagename]]";
      my ($stylestr, $outstr) = render_sheet(\%sheetdata, 'id="sheet0" class="wkcsheet"', "", "s", "a", "ajax", $coord, q! onclick="rc0('$coord');"!, , $linkstyle);

      $rbody1 =~ s/<body /<body onKeydown="return ev1(event);" onKeypress="return ev2(event);" onLoad="save_initial_sheet_data();move_cursor(ecell,ecell,true);" /;

      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $stylestr . $template_stylebottom . 
                   $template_headerscripts . $rbody1;

      $response .= <<"EOF";
$rbodytabs
$hiddenfields
$rbodytabs2
<table cellspacing="0" cellpadding="0" width="100%">
<tr><td class="ttbody" width="100%">
<form name="f0" method="POST">
<table cellpadding="0" cellspacing="0">
EOF

      my %afterentercheck;
      if ($params{afterenter}) {
         $afterentercheck{$params{afterenter}} = " CHECKED";
         }
      else {
         $afterentercheck{same} = " CHECKED";
         }

      my %celldata;
      my ($lcol, $lrow) = render_values_only(\%sheetdata, \%celldata, $linkstyle);
      my $jsdata = qq!var isheet="";\nisheet="!;

      foreach my $cr (sort keys %celldata) { # construct output
         my $cellspecifics = $celldata{$cr};
         my $displayvalue = encode_for_save($cellspecifics->{display});
         $displayvalue = "" if $displayvalue eq "&nbsp;"; # this is the default
         my $csssvalue = encode_for_save($sheetdata{cellattribs}->{$cr}->{csss}); # need this to scroll back
         my $editvalue;
         if ($sheetdata{datatypes}->{$cr} eq 'f' || $sheetdata{datatypes}->{$cr} eq 'c') { # formula or constant
            $editvalue = encode_for_save($sheetdata{formulas}->{$cr});
            }
         else {
            $editvalue = encode_for_save($sheetdata{datavalues}->{$cr});
            }
         my $str = "$cr:$cellspecifics->{type}:$displayvalue:$editvalue:$cellspecifics->{align}:$cellspecifics->{colspan}:$cellspecifics->{rowspan}:$cellspecifics->{skip}:$csssvalue";
         $str =~ s/\\/\\\\/g;
         $str =~ s/"/\\x22/g;
         $str =~ s/</\\x3C/g;
         $jsdata .= "$str\\n";
         }
      $jsdata .= qq!"\n!;

      if ($sheetdata{sheetattribs}->{circularreferencecell}) {
         my ($from, $to) = split(/\|/, $sheetdata{sheetattribs}->{circularreferencecell});
         my $str = "$WKCStrings{editcircular1}$from$WKCStrings{editcircular2}$to";
         $jsdata .= qq!isheet=isheet+"error:$str\\n";\n!;
         }

      $response .= <<"EOF";
<tr>
 <td class="smaller">&nbsp;</td>
 <td valign="bottom">
  <div id="mode1"><span class="smaller" id="valuetype">$WKCStrings{"editloading"}</span>&nbsp;<span id="warning" class="warning">&nbsp;</span>
   <span id="recalcmsg" class="smaller" style="font-style:italic;display:none">&nbsp;$WKCStrings{"editrecalcneeded"}</span></div>
  <div id="mode4" style="display:none;"><span class="smaller">$WKCStrings{"editrange"}</span>
   <span class="smaller" style="font-style:italic;color:gray;">$WKCStrings{"editextendrange"}</span></div>
  <div id="mode5" class="smaller" style="display:none;">$WKCStrings{"editmoreedit"}
   <span style="font-style:italic;color:gray;">$WKCStrings{"editesctoreturn"}</span></div>
  <div id="mode6" class="smaller" style="display:none;">$WKCStrings{"editdatatable"}
   <span style="font-style:italic;color:gray;">$WKCStrings{"editesctoreturn"}</span></div>
 </td>
</tr>
<tr>
 <td valign="top" width="1">
  <span id="coordtext">$editcoords</span>&nbsp;
 </td>
 <td valign="bottom" width="100%" nowrap><span id="config1a">
   <input class="smaller" type="text" size="80" name="valueedit" value="" autocomplete="off" onFocus="ve_focus()">
    <input class="smaller" type="submit" name="okedit" id="okeditve" value="$WKCStrings{"editok"}" onClick="this.blur();return process_OK();">
   </span><span id="config2a" style="display:none;">
   <input class="smaller" style="font-style:italic;" type="text" size="80" value="$WKCStrings{"editmultilinereq"}" disabled>
   </span><span id="config45a" style="display:none;"><span id="rangeend"></span><span id="kbdprompt" class="smaller"></span></span><span id="config3a" style="display:none;">
    <textarea cols="80" rows="10" name="valueedittext" onFocus="vet_focus()">
$cellcontentsnl</textarea>
   </span>
 </td>
</tr>
<tr>
 <td></td>
 <td valign="top"><div id="config1c">
  <input class="smaller" type="submit" name="switcheditvet" id="switcheditvet" value='$WKCStrings{"editmultilineedit"}' onClick="set_editconfig(3);document.f0.valueedittext.focus();return false;">
  <input class="smaller" type="submit" name="range" value="$WKCStrings{"editrange"}" onClick="this.blur();range_button();return false;">
  <input class="smaller" type="submit" name="range" value="$WKCStrings{"editmore"}" onClick="this.blur();more_button();return false;">
  <input class="smaller" type="submit" name="canceledit" value="$WKCStrings{"editcancel"}" onClick="this.blur();process_typed_char('[esc]');return false;">
  <input class="smaller" type="submit" name="help" value="$WKCStrings{"edithelp"}" onClick="toggle_help('edithelptext');this.blur();return false;">
  <input id="dorecalcbutton" class="smaller" type="submit" name="dorecalcbutton" value="$WKCStrings{"editrecalconce"}" style="display:none;" onClick="document.f0.dorecalc.value=1;">
  </div><div id="config3c" style="display:none;">
  <input class="smaller" type="submit" name="okeditvet" value="$WKCStrings{"editok"}" onClick="this.blur();return process_OK();">
  <input class="smaller" type="submit" name="blankvet" value="$WKCStrings{"editblank"}" onClick="document.f0.valueedittext.value='';val='';document.f0.valueedittext.focus();return false;">
  <input class="smaller" type="submit" name="pagelink" value="$WKCStrings{"editlinktopage"}" onClick="this.blur();update_page_list();return false;">
  <input class="smaller" type="submit" name="canceleditvet" value="$WKCStrings{"editcancel"}" onClick="this.blur();process_typed_char('[esc]');return false;">
  <input class="smaller" type="submit" name="helpvet" value="$WKCStrings{"edithelp"}" onClick="toggle_help('edithelptext');this.blur();return false;">
  </div>
 </td>
</tr>
<tr>
 <td></td>
 <td>
  <div id="config4d" style="display:none;">
   <input id="mergebutton" class="smaller" type="submit" name="okeditrange:merge" value="$WKCStrings{"editmergecells"}" onClick="set_range('all');document.f0.okeditrange.value='merge';">
   <input id="unmergebutton" class="smaller" type="submit" name="okeditrange:unmerge" value="$WKCStrings{"editunmerge"}" onClick="set_more('all');document.f0.okeditrange.value='unmerge';">
   <input class="smaller" type="submit" name="okeditrange:copy" value="$WKCStrings{"editcopy"}" onClick="set_range('all');">
   <input class="smaller" type="submit" name="okeditrange:cut" value="$WKCStrings{"editcut"}">
   <input class="smaller" type="submit" name="okeditrange:erase" value="$WKCStrings{"editerase"}">
   <input class="smaller" type="submit" name="okeditrange:fillright" value="$WKCStrings{"editfillright"}" onClick="set_range('all');">
   <input class="smaller" type="submit" name="okeditrange:filldown" value="$WKCStrings{"editfilldown"}" onClick="set_range('all');">
   <input class="smaller" type="submit" name="tables" value="$WKCStrings{"edittable"}" onClick="this.blur();table_button();return false;">
   <input class="smaller" type="submit" name="cancelrange" value="$WKCStrings{"editcancel"}" onClick="this.blur();cancel_range();return false;">
   <input class="smaller" type="submit" name="rangehelp" value="$WKCStrings{"edithelp"}" onClick="toggle_help('rangehelptext');this.blur();return false;">
   <span class="smaller">
    <input type="radio" name="editparts" value="all" CHECKED>$WKCStrings{"editall"}
    <input type="radio" name="editparts" value="formulas">$WKCStrings{"editcontents"}
    <input type="radio" name="editparts" value="formats">$WKCStrings{"editformats"}
   </span>
  </div><div id="config5d" style="display:none;">
   <div style="margin:6px 0px 6px 0px;">
    <input class="smaller" type="submit" name="range" value="$WKCStrings{"editrange"}" onClick="this.blur();range_button();return false;">
    <input class="smaller" type="submit" name="okeditrange:paste" value="$WKCStrings{"editpasteall"}" onClick="set_more('all');">
    <input class="smaller" type="submit" name="okeditrange:paste" value="$WKCStrings{"editpastecontents"}" onClick="set_more('formulas');">
    <input class="smaller" type="submit" name="okeditrange:paste" value="$WKCStrings{"editpasteformats"}" onClick="set_more('formats');">
    <input id="recalcmanualbutton" class="smaller" type="submit" name="okeditrange:recalcmanual" value="$WKCStrings{"editrecalcmanual"}">
    <input id="recalcautobutton" class="smaller" type="submit" name="okeditrange:recalcauto" value="$WKCStrings{"editrecalcauto"}" style="display:none;">
   </div>
   <input class="smaller" type="submit" name="okeditrange:insertrow" value="$WKCStrings{"editinsertrow"}" onClick="set_more('all');">
   <input class="smaller" type="submit" name="okeditrange:insertcol" value="$WKCStrings{"editinsertcol"}" onClick="set_more('all');">
   <input class="smaller" type="submit" name="okeditrange:deleterow" value="$WKCStrings{"editdeleterow"}" onClick="set_more('all');">
   <input class="smaller" type="submit" name="okeditrange:deletecol" value="$WKCStrings{"editdeletecol"}" onClick="set_more('all');">
   <input class="smaller" type="submit" name="cancelrange2" value="$WKCStrings{"editcancel"}" onClick="this.blur();cancel_more();return false;">
   <input class="smaller" type="submit" name="rangehelp2" value="$WKCStrings{"edithelp"}" onClick="toggle_help('editmorehelptext');this.blur();return false;">
  </div><div id="config6d" style="display:none;"><div id="config6d1">
    <input class="smaller" type="submit" name="tablesort" value="$WKCStrings{"editsort"}" onClick="this.blur();set_kbdprompt('/RTS');return false;">
    <input class="smaller" type="submit" name="canceltable" value="$WKCStrings{"editcancel"}" onClick="this.blur();cancel_table();return false;">
    <input class="smaller" type="submit" name="canceltable" value="$WKCStrings{"edithelp"}" onClick="toggle_help('edittablehelptext');this.blur();return false;">
   </div><div id="config6d2">
    <table cellspacing="0" cellpadding="0" style="border:1px solid black;background-color:white;margin:6px 0px 4px 0px;">
     <tr><td colspan="13" style="background-color:gray;color:white;font-weight:bold;text-align:center;">$WKCStrings{"editsorttitle"}</td></tr><tr>
      <td>&nbsp;</td>
      <td style="font-size:smaller;font-weight:bold;color:black">$WKCStrings{"editmajorsort"}</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;&nbsp;</td>
      <td style="font-size:smaller;font-weight:bold;color:black">$WKCStrings{"editminorsort"}</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;&nbsp;</td>
      <td style="font-size:smaller;font-weight:bold;color:black">$WKCStrings{"editlastsort"}</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;&nbsp;</td>
     </tr><tr>
      <td>&nbsp;</td>
      <td valign="top"><select name="sort1" size="1"><option value="" selected><option value="B">Column B<option value="C">Column C</select></td><td>&nbsp;</td>
      <td>
       <input name="sortorder1" type="radio" value="up" checked><span class="smaller">$WKCStrings{"editascending"}</span><br>
       <input name="sortorder1" type="radio" value="down"><span class="smaller">$WKCStrings{"editdescending"}</span><br>
      </td><td>&nbsp;</td>
      <td valign="top"><select name="sort2" size="1"><option value="" selected><option value="B">Column B<option value="C">Column C</select></td><td>&nbsp;</td>
      <td>
       <input name="sortorder2" type="radio" value="up" checked><span class="smaller">$WKCStrings{"editascending"}</span><br>
       <input name="sortorder2" type="radio" value="down"><span class="smaller">$WKCStrings{"editdescending"}</span><br>
      </td><td>&nbsp;</td>
      <td valign="top"><select name="sort3" size="1"><option value="" selected><option value="B">Column B<option value="C">Column C</select></td><td>&nbsp;</td>
      <td>
       <input name="sortorder3" type="radio" value="up" checked><span class="smaller">$WKCStrings{"editascending"}</span><br>
       <input name="sortorder3" type="radio" value="down"><span class="smaller">$WKCStrings{"editdescending"}</span><br></td><td>&nbsp;</td>
     </tr><tr><td>&nbsp;</td><td colspan="12" style="padding:6px 0px 6px 0px;">
      <input class="smaller" type="submit" name="okeditrange:sort" value="$WKCStrings{"editok"}">
      <input class="smaller" type="submit" name="cancelsort" value="$WKCStrings{"editcancel"}" onClick="this.blur();set_kbdprompt('/RT');return false;">
      <input class="smaller" type="submit" name="sorthelp" value="$WKCStrings{"edithelp"}" onClick="toggle_help('edittablesorthelptext');this.blur();return false;">
      </td>
     </tr>
    </table>
   </div>
  </div><div id="linkpagelist" style="padding-top:10px;display:none;">
   <span class="smaller">$WKCStrings{"editpagetolinkto"}</span><br>
   <select name="pagelist" size="10">
   <option value="">$WKCStrings{"editempty"}
   </select><br>
   <input class="smaller" type="submit" value="$WKCStrings{"editchoose"}" onClick="choose_pagelink(true);return false;">
   <input class="smaller" type="submit" value="$WKCStrings{"editcancel"}" onClick="choose_pagelink(false);return false;">
  </div><div id="helptext" style="width:500px;padding:10px 0px 10px 0px;display:none;">
   <div style="border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;color:white;background-color:#66CC66;">
   <table cellspacing="0" cellpadding="0"><tr><td align="center" width="100%" class="smaller"><b>$WKCStrings{"helphelp"}</b></td>
   </td><td align="right"><input class="smaller" type="submit" name="hidehelp" value="$WKCStrings{"helphide"}" onClick="toggle_help('');this.blur();return false;"></td>
   </tr></table></div>
   <div id="helpbody" class="smaller" style="height:200px;overflow:auto;background-color:white;padding:4px;border:1px solid black;">
    $WKCStrings{"helpnotloaded"}
   </div>
  </div>
 </td>
</tr>
EOF
      $inlinescripts .= <<"EOF";
<script>

$jsdata

sheetlastcol=$lcol;
sheetlastrow=$lrow;
parse_sheet(isheet);
ecell="$coord";
cliprange="$sheetdata{clipboard}->{range}";
needsrecalc="$sheetdata{sheetattribs}->{needsrecalc}";
check_error();
</script>
EOF

      $response .= <<"EOF";
</table>
$inlinescripts
$hiddenfields
<input type="hidden" name="okeditrange" value="">
<input type="hidden" name="newtab" value="">
<input type="hidden" name="recalc" value="$sheetdata{sheetattribs}->{recalc}">
<input type="hidden" name="dorecalc" value="">
<input type="hidden" name="mergetype" value="">
</form>
</td></tr></table>
<br>
EOF

      $response .= <<"EOF";
<table cellspacing="0" cellpadding="0"><tr>
<td valign="top">
$outstr
</td>
<td valign="top">
<div style="border:4px solid #CCCC99;background-color: #CCCC99;" unselectable="on">
<div class="smaller" style="text-align:center;color:#666633;" id="statusthing" unselectable="on" onmousedown="scroll_to_home();">&nbsp;</div>
<div id="draghandle" style="margin:0 auto 0 auto;width:14px;height:6px;border:1px solid #666633;background-color:#DDFFDD;position:relative;top:17px;left:0;z-index:1" onmousedown="begindrag(event);" unselectable="on"><img src="?getfile=1x1" width="1" height="1" unselectable="on"></div>
<div id="scrollup" style="margin:0 auto 0 auto;width:12px;height:8px;border:1px solid #666633;background-color:white;" onmousedown="begin_scroll(-1,this);" unselectable="on"><img  src="?getfile=1x1" width="1" height="1" unselectable="on"></div>
<div id="slider" style="margin:0 auto 0 auto;width:20px;position:relative;top:0px;left:0;" onmousedown="slider_page(event);" unselectable="on"><div style="margin:0 auto 0 auto;width:4px;height:150px;background-color:white;border-left:1px solid #666633;border-right:1px solid #666633;"></div></div>
<div id="scrolldown" style="margin:0 auto 0 auto;width:12px;height:8px;border:1px solid #666633;background-color:white;" onmousedown="begin_scroll(1,this);" unselectable="on"><img src="?getfile=1x1" width="1" height="1" unselectable="on"></div>
<img src="?getfile=1x1" width="24" height="10" unselectable="on">
</div>
</td>
</tr>
</table>
<div style="margin:6px 0px 6px 0px;">
<form name="f1" method="POST">
<input name="editaddrow" type="submit" value="$WKCStrings{"editaddrow"}" class="smaller" onclick="document.f1.editcoords.value=ecell;">
<input name="editaddcol" type="submit" value="$WKCStrings{"editaddcolumn"}" class="smaller" onclick="document.f1.editcoords.value=ecell;">
<span class="smaller" style="color:#999999;">$WKCStrings{"editcurrentsheetextent"} $sheetdata{sheetattribs}->{lastcol} $WKCStrings{"editcolsby"} $sheetdata{sheetattribs}->{lastrow} $WKCStrings{"editrows"}</span>
$hiddenfields
</form>
</div>
EOF
      }

   # # # # # # # # # #
   #
   # Format mode
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"Format"}) {

      my ($fcstylestr, $fcbodystr) = do_format_command(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $editmode);

      $hiddenfields = update_hiddenfields(\%params, $hiddenfields);

      $rbody1 =~ s/<body /<body onKeydown="return ev1(event);" onKeypress="return ev2(event);" /;
 
      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $fcstylestr . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2 . $fcbodystr;

      }

   # # # # # # # # # #
   #
   # Tools mode
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"Tools"}) {

      my ($tcstylestr, $tcbodystr) = do_tools_command(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, \%userinfo);

      $hiddenfields = update_hiddenfields(\%params, $hiddenfields);

      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $tcstylestr . $template_stylebottom . 
                   $template_headerscripts . $rbody1 . $rbodytabs . $hiddenfields . $rbodytabs2 . $tcbodystr;

      }

   # # # # # # # # # #
   #
   # Show License mode
   #
   # # # # # # # # # #

   elsif ($currenttab eq $WKCStrings{"showlicense"}) {

      use WKCLicense;

      $response .= $template_headertop . $template_styletop . $template_stylemiddle . $template_stylebottom . 
                   $template_headerscripts . $rbody1;

      $response .= <<"EOF";
$rbodytabs
$hiddenfields
$rbodytabs2
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td class="ttbody" width="100%">
<div class="sectiondark">
$sgilicensetext
</div>
<br>
<div class="sectiondark">
$gpllicensetext
</div>
</td></tr>
</table>
EOF
      }

   # # # # # # # # # #
   #
   # ? mode
   #
   # # # # # # # # # #

   else {
      $response .= <<"EOF";
UNKNOWN MODE<br>
EOF
      }

   # # # # # # # # # #
   #
   # Output footer
   #
   # # # # # # # # # #

   my $end_time = times();
   my $time_string = sprintf ("$WKCStrings{wkcfooterruntime} %.2f $WKCStrings{wkcfootersecondsat} $start_clock_time",
                              $end_time - $start_cpu_time);

   if ($params{debugmessage}) { # Message to display -- would print, but that would mess up CGI-based version
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"editdebuggingmsg"}: $params{debugmessage}<br><br>
</div>
EOF
      }

   my $programnamebottom;
   if ($WKCStrings{programextratop}) { # if extra program name material, don't add SGI stuff
      $programnamebottom = "$WKCStrings{programextratop}&nbsp;$programmark$programmarksymbol&nbsp;$programversion";
      }
   else {
      $programnamebottom .= "$programmark$programmarksymbol&nbsp;$programversion$trademark1";
      }

   $response .= <<"EOF";
<div class="footer">
$programnamebottom<br><br>
<div id="footertimemsg">$time_string</div>
<br>
$SGIfootertext
$WKCStrings{"footerextratext"}
EOF

   $response .= <<"EOF";
<br><br>
<form name="fsl" action="" method="POST">
$hiddenfields
<input style="font-size:xx-small;" type="submit" name="newtab" value="$WKCStrings{"showlicense"}">
</form>
</div> 
</body>
</html>
EOF

   $responsecookie .= "datafilename:$params{datafilename};sitename:$params{sitename};expires:$cookievalues{expires}";

   $responsedata->{content} = $response;
   $responsedata->{contenttype} = "text/html; charset=UTF-8";
   $responsedata->{cookie} = $responsecookie;
   $responsedata->{cookieexpires} = $cookievalues{expires} eq "session" ? "" : ($cookievalues{expires} || $defaultcookieexpire);
   return;
}


   # # # # # # # # # #
   #
   # $hiddenfields = update_hiddenfields(\$params, $hiddenfields)
   #
   # Updates the values for editmode, datafilename, sitename, etc., from params
   # 

sub update_hiddenfields {

   my ($params, $hiddenfields) = @_;

   $hiddenfields =~ s/(name="editmode" value=").*?"/$1$params->{editmode}"/;
   $hiddenfields =~ s/(name="datafilename" value=").*?"/$1$params->{datafilename}"/;
   $hiddenfields =~ s/(name="sitename" value=").*?"/$1$params->{sitename}"/;
   $hiddenfields =~ s/(name="editcoords" value=").*?"/$1$params->{editcoords}"/;
   $hiddenfields =~ s/(name="etpurl" value=").*?"/$1$params->{etpurl}"/;
   $hiddenfields =~ s/(name="scrollrow" value=").*?"/$1$params->{scrollrow}"/;

   return $hiddenfields;

}


# # # # # # # # # #
#
# $notok = site_not_allowed(\%userinfo, $user, $sitename)
#
# Checks to see if $user is allowed to edit $sitename, returning 0 (yes) or 1 (no)
#
# # # # # # # # # #

sub site_not_allowed {

   my ($userinfo, $user, $sitename) = @_;

   return 0 if $userinfo->{HOSTrequirelogin} ne "yes";

   return 0 if $userinfo->{$user}->{allsites} eq "yes";

   my $sitestr = ",$userinfo->{$user}->{sites},"; # comma separated list of allowed sites

   return 0 if ($sitestr =~ m/,$sitename,/ && $userinfo->{$user}->{sites});

   return 1;

}


# # # # # # # # # #
#
# $notok = readsite_not_allowed(\%userinfo, $user, $sitename)
#
# Checks to see if $user is allowed to read $sitename, returning 0 (yes) or 1 (no)
#
# # # # # # # # # #

sub readsite_not_allowed {

   my ($userinfo, $user, $sitename) = @_;

   return 0 if $userinfo->{HOSTrequirelogin} ne "yes";

   return 0 if ($userinfo->{$user}->{allsites} eq "yes" || $userinfo->{$user}->{allreadsites} eq "yes");

   my $sitestr = ",$userinfo->{$user}->{sites},"; # comma separated list of allowed read/write sites
   return 0 if ($sitestr =~ m/,$sitename,/ && $userinfo->{$user}->{sites});

   my $readsitestr = ",$userinfo->{$user}->{readsites},"; # comma separated list of allowed read sites
   return 0 if ($readsitestr =~ m/,$sitename,/ && $userinfo->{$user}->{readsites});

   return 1;

}


# # # # # # # #
#
# $tstr = fill_in_HTML_template($inputstr, $sitedata, \%headerdata, $sitename, $pagename, $clock_time, $author, $loggedinusername, $stylestr, $sheetstr, $renderingliveview)
#
# Fill in the HTML template variables
#
# # # # # # # #

sub fill_in_HTML_template {

   my ($inputstr, $sitedata, $headerdata, $sitename, $pagename, $clock_time, $author, $loggedinusername, $stylestr, $sheetstr, $renderingliveview) = @_;

   my $tstr = $inputstr;

   # Remove description line if it's there

   $tstr =~ s/^{{templatedescriptionline}}.*?(\n|\r\n)//;

   # Process directives

   while ($tstr =~ m/{{line-if-editurl}}/) {
      if ($sitedata->{editurl}) { # if a URL for editing is provided leave rest of line
         $tstr =~ s/{{line-if-editurl}}(.*?)(\n|\r\n)/$1$2/;
         }
      else { # no URL so remove line
         $tstr =~ s/{{line-if-editurl}}.*?(\n|\r\n)/$1/;
         }
      }

   while ($tstr =~ m/{{line-if-htmlurl}}/) {
      if ($sitedata->{htmlurl}) { # if a URL for the directory with HTML is provided leave rest of line
         $tstr =~ s/{{line-if-htmlurl}}(.*?)(\n|\r\n)/$1$2/;
         }
      else { # no URL so remove line
         $tstr =~ s/{{line-if-htmlurl}}.*?(\n|\r\n)/$1/;
         }
      }

   while ($tstr =~ m/{{line-if-loggedin}}/) {
      if ($loggedinusername) { # have the name of logged in user leave rest of line
         $tstr =~ s/{{line-if-loggedin}}(.*?)(\n|\r\n)/$1$2/;
         }
      else { # no URL so remove line
         $tstr =~ s/{{line-if-loggedin}}.*?(\n|\r\n)/$1/;
         }
      }

   while ($tstr =~ m/{{line-if-liveview}}/) {
      if ($renderingliveview) { # if doing live view rendering leave rest of line
         $tstr =~ s/{{line-if-liveview}}(.*?)(\n|\r\n)/$1$2/;
         }
      else { # no URL so remove line
         $tstr =~ s/{{line-if-liveview}}.*?(\n|\r\n)/$1/;
         }
      }

   # Do all the substitutions

   $tstr =~ s/{{editthispagehtml}}/$sitedata->{editurl}?$WKCStrings{"editthispagehtml"}:""/ge; # must preceed others
   $tstr =~ s/{{pagetitle}}/$headerdata->{fullname}/ge;
   $tstr =~ s/{{pagename}}/$pagename/ge;
   $tstr =~ s/{{sitename}}/$sitename/ge;
   $tstr =~ s/{{pubdatetime}}/$clock_time/ge;
   $tstr =~ s/{{author}}/$author/ge;
   $tstr =~ s/{{loggedinuser}}/$loggedinusername/ge;
   $tstr =~ s/{{editurl}}/$sitedata->{editurl}/ge;
   $tstr =~ s/{{htmlurl}}/$sitedata->{htmlurl}/ge;

   $tstr =~ s/{{sheetstyles}}/$stylestr/e;
   $tstr =~ s/{{sheet0}}/$sheetstr/e;

   return $tstr;

   }


# # # # # # # #
#
# $jsstr = create_embeddable_JS_sheet($stylestr, $sheetstr)
#
# Turn the output of rendering into embeddable Javascript
# Uses WKCembeddablejs.txt, replacing {{stylestr}} and {{sheetstr}}
#
# # # # # # # #

sub create_embeddable_JS_sheet {

   my ($stylestr, $sheetstr) = @_;

   my $jsstr;
   $sheetstr =~ s/^(.*?)$/ str+=pl('$1',styles);/gm;
   $stylestr =~ s/^/ /gm;

   open JSFILE, "$WKCdirectory/WKCembeddablejs.txt";
   while (my $line = <JSFILE>) {
      $jsstr .= $line;
      }
   close JSFILE;

   $jsstr =~ s/{{stylestr}}/$stylestr/e;
   $jsstr =~ s/{{sheetstr}}/$sheetstr/e;

   return $jsstr;

   }


# # # # # # # #
#
# $errortext = execute_edit_command(\%params, \%sheetdata, $editcoords, \%headerdata)
#
# Modify the sheet in response to an edit command
#
# # # # # # # #

sub execute_edit_command {

   my ($params, $sheetdata, $editcoords, $headerdata) = @_;

   my ($ok, $errortext);

   if ($params->{okeditrange} eq "erase") {
      $ok = execute_sheet_command_and_log($sheetdata, "erase $editcoords $params->{editparts}", $headerdata);
      }

   elsif ($params->{okeditrange} eq "copy" || $params->{okeditrange} eq "cut") {
      $ok = execute_sheet_command_and_log($sheetdata, "$params->{okeditrange} $editcoords $params->{editparts}", $headerdata);
      }

   elsif ($params->{okeditrange} eq "clearclipboard") {
      $ok = execute_sheet_command_and_log($sheetdata, "clearclipboard", $headerdata);
      }

   elsif ($params->{okeditrange} eq "paste") {
      $ok = execute_sheet_command_and_log($sheetdata, "paste $editcoords $params->{editparts}", $headerdata);
      delete $params->{doingrangesetting};
      }

   elsif ($params->{okeditrange} eq "fillright" || $params->{okeditrange} eq "filldown") {
      $ok = execute_sheet_command_and_log($sheetdata, "$params->{okeditrange} $editcoords $params->{editparts}", $headerdata);
      }

   elsif ($params->{okeditrange} eq "insertrow" || $params->{okeditrange} eq "insertcol") {
      $ok = execute_sheet_command_and_log($sheetdata, "$params->{okeditrange} $editcoords", $headerdata);
      delete $params->{doingrangesetting};
      }

   elsif ($params->{okeditrange} eq "deleterow" || $params->{okeditrange} eq "deletecol") {
      $ok = execute_sheet_command_and_log($sheetdata, "$params->{okeditrange} $editcoords", $headerdata);
      $editcoords =~ s/:(.+)//; # switch to just one cell
      my ($c, $r) = coord_to_cr($editcoords);
      if ($c > $sheetdata->{sheetattribs}->{lastcol}) {
         $c = $sheetdata->{sheetattribs}->{lastcol};
         }
      if ($r > $sheetdata->{sheetattribs}->{lastrow}) {
         $r = $sheetdata->{sheetattribs}->{lastrow};
         }
      $params->{editcoords} = cr_to_coord($c, $r);
      }

   elsif ($params->{okeditrange} eq "merge" || $params->{okeditrange} eq "unmerge") {
      $ok = execute_sheet_command_and_log($sheetdata, "$params->{okeditrange} $editcoords", $headerdata);
      $editcoords =~ s/:(.+)//; # switch to just one cell
      $params->{editcoords} = $editcoords;
      }

   elsif ($params->{okeditrange} eq "recalcauto" || $params->{okeditrange} eq "recalcmanual") {
      $sheetdata->{sheetattribs}->{recalc} = $params->{okeditrange} eq "recalcauto" ? "on" : "off";
      $params->{recalc} = $sheetdata->{sheetattribs}->{recalc};
      add_to_editlog($headerdata, "# $WKCStrings{logautorecalset}: $params->{recalc}");
      }

   elsif ($params->{okeditrange} eq "sort") {
      my $cstr = "sort $editcoords";
      $cstr .= " $params->{sort1} $params->{sortorder1}" if $params->{sort1} ne "none";
      $cstr .= " $params->{sort2} $params->{sortorder2}" if $params->{sort2} ne "none";
      $cstr .= " $params->{sort3} $params->{sortorder3}" if $params->{sort3} ne "none";
      $ok = execute_sheet_command_and_log($sheetdata, $cstr, $headerdata);
      }

   return $errortext;
}


# # # # # # # # # #
#
# decode_from_ajax($string)
#
# Returns a string with \n, \b, \c, and \e escaped to \n, \, :, and ]]> 
# 

sub decode_from_ajax {
   my $string = shift @_;

   $string =~ s/\\n/\n/g;
   $string =~ s/\\c/:/g;
   $string =~ s/\\b/\\/g;

   return $string;
}


# # # # # # # # # #
#
# encode_for_ajax($string)
#
# Returns a string with \n, \, :, and ]]> escaped to \n, \b, \c, and \e
# 

sub encode_for_ajax {
   my $string = shift @_;

   $string =~ s/\\/\\b/g;
   $string =~ s/\n/\\n/g;
   $string =~ s/\r//g;
   $string =~ s/:/\\c/g;
   $string =~ s/]]>/\\e/g;

   return $string;
}


# # # # # # # # # #
#
# $ok = execute_sheet_command_and_log($sheetdata, $command, \%headerdata)
#
# Passes the first two arguments to execute_sheet_command and then logs the command if ok
# 

sub execute_sheet_command_and_log {

   my ($sheetdata, $command, $headerdata) = @_;

   my $ok = execute_sheet_command($sheetdata, $command);

   if ($ok) {
      add_to_editlog($headerdata, $command)
      }

   return $ok;

}


# # # # # # # # # #
#
# init_sheet_cache(\%sheetdata, \%params, \%hostinfo, $sitename)
#
# Stores enough information in the sheetdata to load additional sheets' information for worksheet references
# 

sub init_sheet_cache {

   my ($sheetdata, $params, $hostinfo, $sitename) = @_;

   $sheetdata->{sheetcache} = {};
   $sheetdata->{sheetcache}->{params} = $params;
   $sheetdata->{sheetcache}->{hostinfo} = $hostinfo;
   $sheetdata->{sheetcache}->{sitename} = $sitename;
   $sheetdata->{sheetcache}->{sheets} = {}; # see find_in_sheet_cache

   return;

}


# # # # # # # # # #
#
# $othersheet_sheetdata = find_in_sheet_cache(\%sheetdata, $datafilename)
#
# Load additional sheet's information for worksheet references as a sheetdata structure
# stored in $sheetdata->{sheetcache}->{sheets}->{$datafilename} if necessary.
# Return that structure as \%othersheet_sheetdata
#
# If $datafilename starts with "http:" it is assumed to be a URL and an HTTP GET is done to retrieve
# the file. Otherwise it is assumed to be a pagename and the file is loaded from the current site.
# 

sub find_in_sheet_cache {

   my ($sheetdata, $datafilename) = @_;

   my $sdsc = $sheetdata->{sheetcache};

   if ($datafilename !~ m/^http:/i) { # not URL
      $datafilename = lc $datafilename; # lower case for consistency
      }

   if ($sdsc->{sheets}->{$datafilename}) { # already in cache
      return $sdsc->{sheets}->{$datafilename};
      }

   my (@headerlines, @sheetlines, $loaderror);

   if ($datafilename =~ m/^http:/i) { # URL - use HTTP GET
      my $ua = LWP::UserAgent->new; 
      $ua->agent($programname);
      $ua->timeout(30);
      my $req = HTTP::Request->new("GET", $datafilename);
      $req->header('Accept' => '*/*');
      my $res = $ua->request($req);
      if ($res->is_success) {
         $loaderror = load_page_from_array($res->content, \@headerlines, \@sheetlines);
         }
      else {
         $loaderror = "$WKCStrings{findsheetincacheunabletoload} '$datafilename'";
         }
      }
   else { # assume local pagename
      my $editpath = get_page_published_datafile_path($sdsc->{params}, $sdsc->{hostinfo}, $sdsc->{sitename}, $datafilename);
      $loaderror = load_page($editpath, \@headerlines, \@sheetlines);
      }

   $sdsc->{sheets}->{$datafilename} = {}; # start fresh
   my $ok = parse_sheet_save(\@sheetlines, $sdsc->{sheets}->{$datafilename});

   $sdsc->{sheets}->{$datafilename}->{loaderror} = $loaderror if $loaderror;

   return $sdsc->{sheets}->{$datafilename};

}


1;

=begin license

SOFTWARE LICENSE

This software and documentation is
Copyright (c) 2007 Software Garden, Inc.
All rights reserved. 

1. The source code of this program is made available as free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License, version 2, as published by the Free Software
Foundation.

2. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details. You should have received a
copy of the GNU General Public License along with this program; if not,
write to the Free Software Foundation, Inc., 51 Franklin Street,
Fifth Floor, Boston, MA  02110-1301, USA.

3. If the GNU General Public License is restrictive in a way that does
not meet your needs, contact the copyright holder (Software Garden,
Inc.) to inquire about the availability of other licenses, such as
traditional commercial licenses. 

4. The right to distribute this software or to use it for any purpose
does not give you the right to use Servicemarks or Trademarks of
Software Garden, Inc., including Garden, Software Garden, ListGarden, 
and wikiCalc.

5. An appropriate copyright notice will include the Software Garden,
Inc., copyright, and a prominent change notice will include a
reference to Software Garden, Inc., as the originator of the code
to which the changes were made.

Exception for Executable Bundle 

In some cases this program is distributed together with programs and
libraries of ActiveState Corporation as a single executable file (an
"Executable Bundle") produced using ActiveState Corporation's "Perl Dev
Kit" PerlTray program ("PDK PerlTray"). This free software license does
not apply to those programs and libraries of ActiveState Corporation
that are part of the Executable Bundle. You only have a license to use
those programs and libraries of ActiveState Corporation for runtime
purposes in order to execute this software of Software Garden, Inc. In
order to create and distribute similar executable files from modified
source files, you will need to license your own copy of PDK PerlTray. 

As a specific exception for this product to the terms and conditions of
the GNU General Public License version 2, you are free to distribute
this software (modified or unmodified) in an Executable Bundle created
with PDK PerlTray as long as you adhere to the GNU General Public
License in all respects for all software components except for those of
PDK PerlTray added by that program when used to create the Executable
Bundle. 

Disclaimer 

THIS SOFTWARE IS PROVIDED BY SOFTWARE GARDEN, INC., "AS IS" AND ANY
EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
WARRANTIES OF INFRINGEMENT AND THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL SOFTWARE GARDEN, INC. NOR ITS EMPLOYEES AND OFFICERS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE DISTRIBUTION OR USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 

Software Garden, Inc.
PO Box 610369
Newton Highlands, MA 02461 USA
www.softwaregarden.com

License version: 1.4/2007-01-02

=end

=cut
