#
# WKCStrings.pm -- wikiCalc strings
#
# (c) Copyright 2007 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License at the end of this file
#

#
# Define Package
#

   package WKCStrings;

#
# Do uses
#

   use strict;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw($WKCdirectory %WKCStrings @WKCmonthnames
                    @WKCrfc822monthnames @WKCrfc822daynames);
   our $VERSION = '1.0.0';

#
# Define some variables
#

   #
   # Location of "local" files, including image files and default localwkcpath
   #

   our $WKCdirectory = "."; # default is working directory

   #
   # Public ones:
   #

   our @WKCmonthnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   our @WKCrfc822monthnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   our @WKCrfc822daynames = qw(Sun Mon Tue Wed Thu Fri Sat);

   our %WKCStrings = (

#
# wikicalc.pl
#

"wikicalcnolistener" => "Unable to create a listener on local port",
"wikicalcaccessui" => "To access UI, display in browser",
"wikicalcquitpage" => <<"EOF",
<html>
<head>
<title>Quitting</title>
<body>
Quitting.<br><br><b>You may close the browser window.</b>
<br><br>
<a href="">Retry</a>
</body>
</html>
EOF

#
# wikicalcwin.pl
#

"wikicalcwinhelp1" => "Usage:",
"wikicalcwinhelp2" => <<"EOF",
[options]

  --browser, -b
     Launch UI in a browser at start up
  --help, -h
     Show this help info
  --socket=n, -s n
EOF
"wikicalcwinhelp3" => "     Socket to listen to for browser (default:",
"wikicalcwinhelp4" => <<"EOF",

Exit by clicking on icon in tray and selecting "Shutdown".
EOF
"wikicalcwinnolistener1" => "Error: Unable to create a listener on local port",
"wikicalcwinnolistener2" => <<"EOF",
Use the "-s number" command option to specify a
different socket number (1024 < number < 65536).
EOF
"wikicalcwinpopup1" => "Launch UI",
"wikicalcwinpopup2" => "in browser",
"wikicalcwinpopup3" => "Execute",
"wikicalcwinpopup4" => "Shutdown",

#
# wikicalccgi.pl
#

"wikicalccgiquitpage1" => <<"EOF",
<html>
<head>
<title>Quitting</title>
<body>
Quitting.<br><br><b>You may close the browser window.</b>
<br><br>
EOF
"wikicalccgiquitpage2" => <<"EOF",
Restart</a>
</body>
</html>
EOF

#
# WKC.pm
#

"Page" => "Page", "Edit" => "Edit", "Format" => "Format","Preview" => "Publish", 
"Tools" => "Tools", "Quit" => "Quit",

# See WKC.pm for information about "programextratop" and "footerextratext":

"programextratop" => "", # Additional text as part of the program name at the top
#"programextratop" => "Modified", # sample additional top text

"footerextratext" => "", # Additional text in the footer below the copyright notice
#"footerextratext" => <<"EOF", # sample additional footer text
#<br><br>Modification to original:<br>
#Localisation to UK English (c) 2006 ABC Localizers Ltd.
#EOF


"showlicense" => "Show License",

"logintitle" => "Login, please.",
"loginname" => "Name:",
"loginpassword" => "Password:",
"loginlogin" => "Login",
"loginsessioncookie" => "Remember login until browser quits",
"loginlongcookie" => "Remember login after quit",

"savesettingedit" => "Save",
"cancelsettingedit" => "Cancel",

"loginerror" => "User name or password not known.",
"setcellnotloggedin" => "Not logged in.",
"setcellnotfound" => "Page not found.",

"viewlogoutcompleted" => "Logout completed.",
"viewliveviewloggedinasuser" => "Logged in as user",
"viewliveviewsologout" => "Logout",
"viewliveviewnoreadaccess" => "No read access to site",
"viewliveviewforuser" => "for user",
"viewlogin1" => "Login needed to view page",
"viewnotloggedin" => "Error: Not logged in to read",
"viewloggedin" => "Logged in as user",
"viewclicktoview" => "Click to view page",
"viewunabletoload" => "Unable to load",
"viewnosource" => "No source available for",
"viewnotfound1" => "Source file",
"viewnotfound2" => "not found.",
"viewnomodify1" => "Attempt to modify unmodifiable cell",
"viewnomodify2" => "as part of viewing",
"viewunknowntype" => "Unknown view type",

"etpnotfound" => "Page not found.",
"etpeditstartof" => "Edit start of",
"etpcancelled" => "cancelled.",

"choosecondition1" => "Condition found while preparing page",
"choosecondition2" => "for edit:",

"logpublishedby" => "Published by",
"publisherror" => "Error while publishing page",

"choosedelerror" => "Error while deleting page",
"choosedeldeleted" => "Deleted page",

"chooseabandonerror" => "Error while deleting edit information for",
"chooseabandondeleted1" => "Deleted recent editing information for page",
"chooseabandondeleted2" => "returning it to last published state",

"logeditedpageproperties" => "Edited page properties",
"logautorecalset" => "Auto recalculation set to",

"topon" => "on",
"topuser" => "User",
"toplogout" => "LOGOUT",
"toprevert" => "Starting with contents of backup file",

"multiedittitle" => "Already Editing",
"multieditdoyou" => "Do you want to edit page",
"multiediteventhough1" => "even though others have started editing it, too?",
"multiediteventhough2" => "Earlier published versions will be overwritten by later published ones.",
"multieditpage" => "Page",
"multieditonsite" => "on site",
"multieditisopen" => "is open for edit by",
"multiedityes" => "Yes, Edit",
"multieditno" => "No, Don't Edit",

"publishedtitle" => "Page Published: ",
"publisheddescopen" => "This file was published to the web site and will stay open for editing.",
"publisheddescclosed" => "This file was published to the web site and was closed for editing.",
"publishcontinueediting" => "Continue Editing",
"publishviewpagelist" => "View Page List",
"publishviewhtmlpage" => "View HTML Page",
"publishviewlivepage" => "View Live Page",
"publishresume" => "Resume",
"publishresumedesc" => 'Resume viewing the URL of the page that invoked "Edit This Page":',

"previewpublish" => "Publish",
"previewviewonweb" => "View On Web",
"previewhelp" => "Help",
"previewpublishtoserver" => "Publish to the server as",
"previewpublishhtml" => "Publish HTML",
"previewpublishsource" => "Publish Source",
"previewpublishjs" => 'Publish Embeddable ".js"',
"previewpublishnologin" => "Allow live view without login",
"previewcomments" => "<b>Comments:</b> (such as about the edits made to the page since last published)",
"previewcomments2" => <<"EOF",
Choose the appropriate button depending upon whether you want to just save the comments and continue editing, publish and continue editing this page now,
or publish and check it back in so others can edit it:
EOF

"previewsavecomments" => "Save Comments",
"previewpublishcontinue" => "Publish and Continue",
"previewpublishclose" => "Publish and Done Editing",
"previewview1" => "View the most recently published version of this page in the specified browser window:",
"previewlivethis" => "Live View This Window",
"previewlivepopup" => "Live View Popup Window",
"previewnolive" => "This site's \"URL for Editing\" setting is blank.<br>Unable to provide links to view Live View pages.",
"previewplainthis" => "Plain HTML Page This Window",
"previewplainpopup" => "Plain HTML Page Popup Window",
"previewnohtml" => "This site's \"URL for HTML\" setting is blank.<br>Unable to provide links to view published HTML pages.",

"helphelp" => "HELP",
"helphide" => "Hide",
"helpnotloaded" => "Not loaded yet.",

"editloading" => "Loading...",
"editrecalcneeded" => "Recalculation may be needed",
"editrange" => "Range",
"editextendrange" => "[Extend range down and/or right with arrows or by clicking, <b>Esc</b> to return to cell editing]",
"editmoreedit" => "More edit commands",
"editesctoreturn" => "[<b>Esc</b> to return to cell editing]",
"editdatatable" => "Data Table commands",
"editok" => "OK",
"editmultilinereq" => "Multi-line edit required",
"editmultilineedit" => '"Multi-line edit',
"editrange" => ":Range",
"editmore" => "/More",
"editcancel" => "Cancel",
"edithelp" => "Help",
"editrecalconce" => "Recalc Once",
"editblank" => "Blank",
"editlinktopage" => "Link to page",
"editmergecells" => "Merge Cells",
"editunmerge" => "Unmerge",
"editcopy" => "Copy",
"editcut" => "X-Cut",
"editerase" => "Erase",
"editfillright" => "Fill Right",
"editfilldown" => "Fill Down",
"edittable" => "Table",
"editall" => "All",
"editcontents" => "Contents",
"editformats" => "Formats",
"editrange" => ":Range",
"editpasteall" => "Paste All",
"editpastecontents" => "Paste Contents",
"editpasteformats" => "Paste Formats",
"editrecalcmanual" => "Recalc Manual",
"editrecalcauto" => "Recalc Auto",
"editinsertrow" => "Insert Row",
"editinsertcol" => "Insert Column",
"editdeleterow" => "Delete Row",
"editdeletecol" => "Delete Column",
"editsort" => "Sort",
"editsorttitle" => "SORT",
"editmajorsort" => "Major Sort",
"editminorsort" => "Minor Sort",
"editlastsort" => "Last Sort",
"editascending" => "Ascending",
"editdescending" => "Descending",
"editpagetolinkto" => "Page to link to on this site:",
"editempty" => "Empty...",
"editchoose" => "Choose",
"editaddrow" => "Add Row",
"editaddcolumn" => "Add Column",
"editcurrentsheetextent" => "Current sheet extent is",
"editcolsby" => "columns by",
"editrows" => "rows",

"editdebuggingmsg" => "DEBUGGING MESSAGE",

"publishtemplate" => <<"EOF",
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>{{pagetitle}}</title>
<style type="text/css">
body, td, input, textarea {font-family:verdana,helvetica,sans-serif;font-size:small;}
.smaller {font-size: smaller;}
dd {padding: 1pt 0px 2pt 0px;}
dt {font-weight: bold; padding: 1pt 0px 1pt 0px;}
{{sheetstyles}}
</style>
</head>
<body>
{{sheet0}}
<br><hr>
<span class="smaller">{{pagetitle}} ({{pagename}}.html), {{pubdatetime}}
{{line-if-liveview}}{{line-if-editurl}}{{line-if-loggedin}}<br><a href="{{editurl}}?view=logout">Logout {{loggedinuser}}</a>
</span>
{{editthispagehtml}}
</body>
</html>
EOF

"editthispagehtml" => <<"EOF",
<form name="wkcformetp" method="POST" action="{{editurl}}" style="margin:0px;">
 <input type="hidden" name="editthispage" value="{{sitename}}/{{pagename}}">
 <input type="hidden" name="etpurl" value="">
 <a href="" onclick="document.wkcformetp.etpurl.value=location.href;document.wkcformetp.submit();return false;"><span class="smaller">Edit This Page</span></a>
</form>
EOF

"editsub-general" => "General",
"editsub-formula" => "Formula",
"editsub-text" => "Text",

"editcircular1" => "Circular reference at cell ",
"editcircular2" => " to cell ",

"wkcfooterruntime" => "Runtime",
"wkcfootersecondsat" => "seconds at",

"findsheetincacheunabletoload" => "Unable to load page from",

#
# WKCjs.txt
#

"jsdefinestrings" => <<"EOF",
<script>
var jsstrings = {};
jsstrings["ajaxerrnostatus"] = "There was a problem with the request to the server and no status was returned describing the error.\\nClick on Publish to see current state.";
jsstrings["ajaxerrstatus1"] = "There was a problem with the request to the server. Status: ";
jsstrings["ajaxerrstatus2"] = "\\nClick on Publish to see current state.";
jsstrings["ajaxerrtimeout1"] = "There was a problem with the request to the server: Timeout after ";
jsstrings["ajaxerrtimeout2"] = " seconds.";
jsstrings["loading"] = "Loading...";
</script>
EOF

#
# WKCeditjs.txt
#

"editjsdefinestrings" => <<"EOF",
<script>
jsstrings["Editing"] = "Editing";
jsstrings["Loading"] = "Loading...";
jsstrings["Formula"] = "Formula";
jsstrings["Text"] = "Text";
jsstrings["Number"] = "Number";
jsstrings["Multi-line"] = "Multi-line";
jsstrings["slashplain"] = "Keyboard shortcuts: <b>R</b>ange, <b>P</b>aste, <b>G</b>lobal, <b>I</b>nsert row/column, <b>D</b>elete row/column, <b>F</b>ormat";
jsstrings["slashR"] = " &nbsp; /Range: <b>M</b>erge cells, <b>U</b>nmerge cells, <b>C</b>opy, <b>X</b>-Cut, <b>E</b>rase, <b>F</b>ill, <b>D</b>elete row/column, <b>T</b>able";
jsstrings["slashRF"] = " &nbsp; /Range Fill: <b>R</b>ight, <b>D</b>own";
jsstrings["slashRD"] = " &nbsp; /Range Delete: <b>R</b>ows, <b>C</b>olumns";
jsstrings["slashRT"] = " &nbsp; /Range Table: <b>S</b>ort";
jsstrings["slashRTS"] = " &nbsp; /Range Table Sort";
jsstrings["slashP1"] = "/Paste (clipboard from ";
jsstrings["slashP2"] = "): <b>A</b>ll, <b>C</b>ontents, <b>F</b>ormats, <b>E</b>rase clipboard contents";
jsstrings["slashP3"] = "/Paste: Clipboard empty";
jsstrings["slashI"] = "/Insert: <b>R</b>ow, <b>C</b>olumn";
jsstrings["slashD"] = "/Delete: <b>R</b>ow, <b>C</b>olumn";
jsstrings["slashG"] = "/Global: <b>R</b>ecalculation";
jsstrings["slashGR"] = "/Global Recaculation: <b>A</b>uto, <b>M</b>anual, <b>N</b>ow";
jsstrings["Format"] = "Format";
jsstrings["unknowncmd1"] = "Unknown command";
jsstrings["unknowncmd2"] = "press Esc";
jsstrings["nonestr"] = "(none)";
jsstrings["colstr"] = "Column ";
jsstrings["Retrieving"] = "Retrieving list of pages...";
jsstrings["NoPages"] = "*** No Pages To Link To ***";
</script>
EOF

#
# WKCformatjs.txt
#

"formatjsdefinestrings" => <<"EOF", # note: defaultlayout should be same as $WKCStrings{sheetdefaultlayoutstyle}
<script>
var formatjsstrings = {};
formatjsstrings["Currency"] = "Currency";
formatjsstrings["defaultlayout"] = "padding:2px 2px 1px 2px;vertical-align:top;";
formatjsstrings["rowsamplenormal"] = "Row&nbsp;N-1<br><b>Row&nbsp;N</b><br>Row&nbsp;N+1";
formatjsstrings["rowsamplehidden"] = "Row&nbsp;N-1<br>Row&nbsp;N+1";
formatjsstrings["miscsample"] = "A&nbsp;Sample&nbsp;Cell<br>For&nbsp;Style<br>\$1,234.56";
</script>
EOF
   # Also, you can set the text over the preview with something like:
   #    formatjsstrings["previewtext:colors"] = "C O L O R S";
   # Where "colors" is numbers, text, fonts, colors, borders, layout, columns, rows, or misc.

#
# WKCloadsheetjs.txt
#

"loadsheetjsdefinestrings" => <<"EOF",
<script>
var loadsheetjsstrings = {};
loadsheetjsstrings["ajaxerrstatus"] = "There was a problem with the request to the server for a list of pages. Status: ";
loadsheetjsstrings["ajaxerrnostatus"] = "There was a problem with the request to the server for a list of pages and no status was returned describing the error.";
loadsheetjsstrings["ajaxerrtimeout1"] = "There was a problem with the request to the server for a list of pages: Timeout after ";
loadsheetjsstrings["ajaxerrtimeout2"] = " seconds.";
loadsheetjsstrings["ajaxnosuchpagestocopy"] = "*** No Such Pages To Copy ***";
loadsheetjsstrings["ajaxretrieving"] = "Retrieving list of pages...";
</script>
EOF

#
# WKCnewpagejs.txt
#

"newpagejsdefinestrings" => <<"EOF",
<script>
var newpagejsstrings = {};
newpagejsstrings["ajaxerrstatus"] = "There was a problem with the request to the server for a list of pages. Status: ";
newpagejsstrings["ajaxerrnostatus"] = "There was a problem with the request to the server for a list of pages and no status was returned describing the error.";
newpagejsstrings["ajaxerrtimeout1"] = "There was a problem with the request to the server for a list of pages: Timeout after ";
newpagejsstrings["ajaxerrtimeout2"] = " seconds.";
newpagejsstrings["ajaxnosuchpagestocopy"] = "*** No Such Pages To Copy ***";
newpagejsstrings["ajaxretrieving"] = "Retrieving list of pages...";
</script>
EOF

#
# WKCPageCommands.pm
#

"pagemissingpagemode" => "Missing pagemode",
"pagecreatedlocalonly" => "Page may have been created locally but server will not let others know until it is published successfully.",
"pagewelcometitle" => "Welcome to wikiCalc!",
"pagewelcomedesc" => <<"EOF",
It appears that you are running wikiCalc for the first time on this computer.
In order to run, wikiCalc needs certain information to be entered describing your publishing environment.
EOF

"pagedemonstrationsetuptitle" => "Demonstration Setup",
"pagedemonstrationsetupdesc" => <<"EOF",
If you are new to wikiCalc and just want to try it without publishing to the web yet,
you can have it automatically set up with directories already created, settings set, and some sample files to edit.
Just click the "Demo Setup" button below.
You can modify those settings later to use the program normally
using the "Manage Sites" and "Manage Hosts" buttons you will soon find on this Page tab.
EOF

"pagedemosetup" => "Demo Setup",
"pagemanualsetuptitle" => "Manual Setup",
"pagemanualsetupdesc" => <<"EOF",
If you want to set up wikiCalc manually (it will lead you through with prompts), click the "Manual Setup" button.
It will then ask you to create a "site" and a "host", and then finally the first page.
EOF

"pagemanualsetup" => "Manual Setup",

"pagetoppagetitle" => "PAGE SELECTION",
"pagetoppagedesc" => <<"EOF",
This is where you choose which page you want to edit.
You can also change which site you are editing.
Open a page for editing by pressing the appropriate Edit button.
It will be copied from the server and you will be editing that copy.
Modified pages may be published (which updates the copy on the server)
and editing closed by pressing the appropriate Publish button.
EOF

"pagenositesettitle" => "No Site Set",
"pagenositesetdesc" => "You need to choose a site to edit.",
"pagechoose" => "Choose",
"pagelistmultieditprompt1" => "Page '",
"pagelistmultieditprompt2" => "' is being edited by someone else. If you both publish changes one may overwrite the other, losing the edits.\\n\\nClick OK to start editing anyway.",
"pagelisttitle" => "Pages You Can Edit On Site: ",
"pagelistuser" => "Your author name is: ",
"pageeditbuttons" => "Edit Buttons",
"pageviewonwebbuttons" => "View On Web Buttons",
"pagedelabandonbuttons" => "Delete and Abandon Edit Buttons",
"pagelistcolfullname" => 'FULL&nbsp;NAME&nbsp;',
"pagelistcolfilename" => 'FILENAME&nbsp;',
"pagelistcoleditstatus" => 'EDIT&nbsp;STATUS&nbsp;',
"pagelistcolpublishstatus" => 'PUBLISH&nbsp;STATUS&nbsp;',
"pagelistedit" => "Edit",
"pagelistediting" => "Editing",
"pagelistcurrentedit" => "Currently being edited",
"pagelistopenforedit" => "Open for editing",
"pagelistdelete" => "Delete",
"pagelistabandonedit" => "Abandon Edit",
"pagelistpublish" => "Publish",
"pagelistlastmod" => "Last modified:",
"pagelistunchanged" => "Not modified",
"pagelistnotediting" => "Not editing",
"pagelistnotpublished" => "This page has not been published",
"pagelisteditedby" => "Being edited by:",
"pagelistpublished" => "Published:",
"pagelistnotpublishedshort" => "Not Published",
"pagelistlastreconciled" => "Publish Status Last Reconciled</b><br><b>with Server: ",
"pagelistreload" => "Reload",
"pagelistcreatenewpage" => "Create New Page",
"pagelistmanagesites" => "Manage Sites",
"pagelistmanagehosts" => "Manage Hosts",
"pagelisteditingsitetitle" => "Editing Site",
"pagelisteditingsitedesc" => "This is the site you are editing. You can change it, if you want.",
"pagelistchangesite" => "Change",


"pagechangesitebreadcrumbs" => "Page Selection:",
"pagechangesitepagetitle" => "CHANGE SITE BEING EDITED",
"pagechangesitepagedesc" => <<"EOF",
This is where you choose which site you want to edit.
You can also create new sites.
EOF

"pageadd" => "Add",
"pagecancel" => "Cancel",
"pageaddsitechangebreadcrumbs" => "Page Selection &gt; Change Site:",
"pageaddsitemanagebreadcrumbs" => "Page Selection &gt; Manage Sites:",
"pageaddsitepagetitle" => "ADD SITE STEP 1: CHOOSE HOST",
"pageaddsitepagedesc" => <<"EOF",
To add a new site to the list of sites you can edit,
you must first indicate on which host it resides.
EOF

"pageaddhost" => "Add Host",
"pageaddsite2changebreadcrumbs" => "Page Selection &gt; Change Site:",
"pageaddsite2managebreadcrumbs" => "Page Selection &gt; Manage Sites:",
"pageaddsite2pagetitle" => "ADD SITE STEP 2:",
"pageaddsite2pagedesc" => <<"EOF",
To add a new site to the list of sites you can edit you must provide these values
EOF

"pageaddsite2valuestitle" => "SET VALUES FOR SITE ON HOST: ",
"pageaddsite2sitename" => "Site Name",
"pageaddsite2sitenamedesc" => <<"EOF",
Required field. The short name you will use for this site here.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase).
<br>Example: earthlink-main-site
EOF

"pageaddsite2sitelongname" => "Site Long Name",
"pageaddsite2sitelongnamedesc" => <<"EOF",
A more descriptive name you will use for this site here.
This is optional.
<br>Example: Main site on my Earthlink web hosting account
EOF

"pageaddsite2sitenameonhost" => "Site Name on Host",
"pageaddsite2sitenameonhostdesc" => <<"EOF",
Required field. The short name for this site used on the host.
If others edit the site, they must use the same name.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase).
<br>Example: main-site
EOF

"pageaddsite2authornameonhost" => "Author Name on Host",
"pageaddsite2authornameonhostdesc" => <<"EOF",
Required field. The short name for you as the author used on this site on this host.
If others edit the site, they must use a different name.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase).
<br>Example: jsmith
EOF

"pageaddsite2authorfromlogin" => "Author From Login",
"pageauthorfromloginyes" => "Yes",
"pageauthorfromloginno" => "No",
"pageaddsite2authorfromlogindesc" => <<"EOF",
If "Yes", then if the author is logged in (see the User Administration on the Tools tab)
the login name will be used as the author name.
If "No" or if logging in is not required, then the "Author Name on Host" will be used.
EOF

"pageaddsite2htmlpath" => "Path for HTML",
"pageaddsite2htmlpathdesc" => <<"EOF",
Required field. This is the path to the directory where the HTML pages are to be stored.
This directory MUST ALREADY EXIST, it is not created automatically.
If doing FTP publishing, this is a directory on the FTP server.
This is sometimes blank when doing FTP publishing if the home FTP directory ("/")
is where you want the file to go.
If not doing FTP publishing, this is a directory on the local computer where this program is running
relative to the directory where this program is run.
<br>Examples: htdocs/, ../../html/spreadsheetpages/
EOF

"pageaddsite2htmlurl" => "URL for HTML",
"pageaddsite2htmlurldesc" => <<"EOF",
This is the URL of the directory where the HTML pages are to be stored.
If doing FTP publishing, this is on the web server at that site, not the FTP server.
If not doing FTP publishing, this is a directory on the local computer where this program is running.
If blank, then there won't be any "View Site" links in this program.
<br>Example: http://www.domain.com
EOF

"pageaddsite2editurl" => "URL for Editing",
"pageaddsite2editurldesc" => <<"EOF",
This is the URL for invoking the editing code for this program.
It is used to allow an "Edit This Page" link on published web pages as well as "Live View".
(For more information on Live View, see the Publish tab help.)
If you are editing locally, this will be on the client computer, such as "http://127.0.0.1:6556".
If editing using a server with CGI, this will be to the Perl program on the server.
This is similar to the URL you see in the browser right now.
<br>Example: http://www.domain.com/cgi-bin/wikicalccgi.pl
EOF

"pageaddsite2publishrss" => "RSS: Publish",
"pageaddsite2publishrsstag" => "Publish RSS feeds",
"pageaddsite2publishrssdesc" => <<"EOF",
If checked, RSS files will be produced for both the site and each individual page.
The files will be put in the same directory as the HTML.
The RSS feed for site "sitename" will be in file "sitename.site.rss.xml"
and for page "pagename" will be in file "pagename.page.rss.xml".
<br>If this is not checked the other RSS values are ignored.
EOF

"pageaddsite2rssmaxitems" => "RSS: Maximum Items",
"pageaddsite2rssmaxitemssite" => "Site",
"pageaddsite2rssmaxitemspage" => "Page",
"pageaddsite2rssmaxitemsdesc" => <<"EOF",
The maximum number of most recently changed items to appear in the RSS feeds.
This is set separately for the site RSS feed and the page RSS feeds.
EOF

"pageaddsite2rsstitle" => "RSS: Feed Title",
"pageaddsite2rsstitledesc" => <<"EOF",
The title of the RSS feed for this site.
It will also be used as the start of the name for the page RSS feeds.
If blank, the site name will be used as the feed title.
EOF

"pageaddsite2rsslink" => "RSS: Feed Link URL",
"pageaddsite2rsslinkdesc" => <<"EOF",
The URL used as the link for the site feed.
This should point to the main page for the site.
This is required if RSS Publish is checked.
<br>Example: http://www.domain.com/index.html
EOF
                     "pageaddsite2rssdescription" => "RSS: Site Feed Description",
                     "pageaddsite2rssdescriptiondesc" => <<"EOF",
The description of this site for the site RSS feed.
If blank, the Site Long Name will be used as the feed description.
EOF

"pageaddsite2rsschannelxml" => "RSS: Channel Additional XML",
"pageaddsite2rsschannelxmldesc" => <<"EOF",
This text will be added to the XML that makes up the &lt;channel&gt; part of the feeds.
It is an advanced feature that should only be used by people who understand how to write XML.
It is used to add elements, such as &lt;copyright&gt; and &lt;image&gt;, that are not
currently supported by this program.
EOF

"pageaddsite2save" => "Save",
"pagemanagesitebreadcrumbs" => "Page Selection:",
"pagemanagesitepagetitle" => "MANAGE SITES",
"pagemanagesitepagedesc" => <<"EOF",
This is a list of defined sites.
You can select one to make changes to its settings.
EOF

"pagedone" => "Done",

"pagemanagesitecolhead" => "SITE",
"pagemanagesitecurrentsettingscolhead" => "CURRENT&nbsp;SETTINGS",
"pagemanagesiteyes" => "Yes",
"pagemanagesiteno" => "No",
"pagemanagesitepages" => "Pages",
"pagemanagesitetotal" => "total",
"pagemanagesitepublished" => "published",
"pagemanagesitenopagesyet" => "No pages yet",
"pagemanagesitestatuslastrec" => "Status last reconciled",
"pagemanagesitestatusnotrec" => "Status not reconciled yet",
"pagemanagesitelongname" => "Long Name:",
"pagemanagesitehost" => "Host:",
"pagemanagesitesitenameonhost" => "Site Name On Host:",
"pagemanagesiteauthornameonhost" => "Author Name On Host:",
"pagemanagesiteauthorfromlogin" => "Author From Login:",
"pagemanagesitepathforhtml" => "Path For HTML:",
"pagemanagesiteurlforhtml" => "URL For HTML:",
"pagemanagesiteurlforediting" => "URL For Editing:",
"pagemanagesitepublishrss" => "Publish RSS:",
"pagemanagesitepubrssyes" => "Yes",
"pagemanagesiterssmaxitems" => "RSS Max Items:",
"pagemanagesiterssfeedtitle" => "RSS Feed Title:",
"pagemanagesitersssitefeedlinkurl" => "RSS Site Feed Link URL:",
"pagemanagesitersssitefeeddesc" => "RSS Site Feed Description:",
"pagemanagesiterssaddlxml" => "RSS Channel Additional XML:",
"pagemanagesitepubrssno" => "No",
"pagemanagesitehostchecked" => "Host Checked:",
"pagemanagesiteloaded" => "Loaded:",
"pagemanagesiteedit" => "Edit",
"pagemanagesitecopy" => "Copy",
"pagemanagesitedelete" => "Delete",
"pagemanagesiteadd" => "Add",
"pagemanagesitedeleteprompt1" => "Do you really want to delete definitions and edit information about site '",
"pagemanagesitedeleteprompt2" => "'? Click OK to delete.\\n\\nThis operation cannot be undone.",

"pagesitecopypagetitle" => "COPY OF SITE: ",
"pagesitecopypagedesc" => <<"EOF",
Define a new site.
The values here start out with those of the site being copied.
The pages of the site being copied are not copied, just these settings.
A different site name must be given.
EOF

"pagesiteeditpagetitle" => "EDIT SITE: ",
"pagesiteeditpagedesc" => <<"EOF",
View and make changes to a particular site's settings.
The short name of the site may not be changed.
Changes here (such as changing hosts or paths) do not remove existing files on the host
- those must be done manually directly on the host or with FTP.
EOF

"pagesiteeditbreadcrumbs" => "Page Selection: Manage Site:",
"pagesiteedithost" => "Host",
"pagesiteedithostdesc" => <<"EOF",
The host where the site resides.
This must be one of the hosts already defined in this system.
Add a new host by going back to the Page Selection screen and choosing Manage Hosts.
EOF

"pagesiteeditsave" => "Save",

"pageaddhostchangesitebreadcrumbs" => "Page Selection &gt; Change Site &gt; Add Site:",
"pageaddhostmanagesitebreadcrumbs" => "Page Selection &gt; Manage Sites &gt; Add Site:",
"pageaddhostmanagehostbreadcrumbs" => "Page Selection &gt; Manage Hosts:",
"pageaddhostpagetitle" => "ADD HOST",
"pageaddhostpagedesc" => <<"EOF",
To add a new host to the list of host you must provide these values
EOF

"pagehostcopypagetitle" => "COPY OF HOST: ",
"pagehostcopypagedesc" => <<"EOF",
Define a new host.
The values here start out with those of the host being copied.
The sites and pages on the host being copied are not copied, just these settings.
A different host name must be given.
EOF

"pageaddhosthostname" => "Host Name",
"pageaddhosthostnamedesc" => <<"EOF",
The short name you will use for this host here.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase).
<br>Example: earthlink-host
EOF

"pagehosteditpagetitle" => "EDIT HOST: ",
"pagehosteditpagedesc" => <<"EOF",
View and make changes to a particular host's settings.
The short name of the host may not be changed.
Changes here (such as changing URLs or paths) do not remove existing files on the host
- those must be done manually directly on the host or with FTP.
EOF

"pageedithostlongnametitle" => "Host Long Name",
"pageedithostlongnamedesc" => <<"EOF",
A more descriptive name you will use for this host here.
This is optional.
<br>Example: Sites on my Earthlink web hosting account
EOF

"pageedithostftpurltitle" => "FTP URL",
"pageedithostftpurldesc" => <<"EOF",
The URL of the FTP host to hold the published files (HTML, RSS, data files, etc.).
LEAVE BLANK if not doing "FTP publishing".
That is, leave blank if running the program with server-based processing and only browsers on the client (local publishing);
provide a value if running the main program on a personal computer with web storage elsewhere (FTP publishing).
<br>Example: ftp.domain.com
EOF

"pageedithostftploginnametitle" => "FTP Login Name",
"pageedithostftploginnamedesc" => <<"EOF",
The user name to use when logging into the FTP server (or nothing if not doing FTP publishing and the FTP URL is blank).
<br>Example: jsmith
EOF

"pageedithostftploginpasswordtitle" => "FTP Login Password",
"pageedithostftploginpassworddesc" => <<"EOF",
The password to use when logging into the FTP server (or nothing if not doing FTP publishing and the FTP URL is blank).
EOF

"pageedithostdatafilepathtitle" => "Data File Path",
"pageedithostdatafilepathdesc" => <<"EOF",
This is the path to the directory where editing and other data about sites
on this host are to be stored on a remote host.
The program will create a directory called "wkcdata" in this directory.
If doing FTP publishing, this is a directory on the FTP server.
If not doing FTP publishing, this value is ignored and may be blank.
<br>Examples: cgi-data, cgi-bin/wikicalc
EOF

"pageedithostsave" => "Save",

"pagemanagehostbreadcrumbs" => "Page Selection:",
"pagemanagehostpagetitle" => "MANAGE HOSTS",
"pagemanagehostpagedesc" => <<"EOF",
This is a list of defined hosts.
You can select one to make changes to its settings.
If you copy a host, it only copies the settings, it doesn't copy any sites or pages.
You may only delete hosts that are not referred to by any site definitions.
EOF

"pagemanagehosthostcolhead" => "HOST",
"pagemanagehostcurrentsettingscolhead" => "CURRENT&nbsp;SETTINGS",
"pagemanagehostnone" => "None",
"pagemanagehostdelete" => "Delete",
"pagemanagehostremote" => "Remote",
"pagemanagehostlocal" => "Local",
"pagemanagehostignored" => " <i>(Ignored)</i>",
"pagemanagehostlongname" => "Long Name:",
"pagemanagehostusedbysite" => "Used by Site(s):",
"pagemanagehosttype" => "Type:",
"pagemanagehosturl" => "URL:",
"pagemanagehostloginname" => "Login Name:",
"pagemanagehostdatafilepath" => "Data File Path:",
"pagemanagehostedit" => "Edit",
"pagemanagehostcopy" => "Copy",
"pagemanagehostadd" => "Add",
"pagemanagehostdeleteprompt1" => "Do you really want to delete definitions and edit information about host '",
"pagemanagehostdeleteprompt2" => "'? Click OK to delete.\\n\\nThis operation cannot be undone.",

"pageaddpagesitespecific" => "site-specific",
"pageaddpageshared" => "shared",
"pageaddpagebreadcrumbs" => "Page Selection:",
"pageaddpagepagetitle" => "ADD NEW PAGE",
"pageaddpagepagedesc" => <<"EOF",
Here's where you add a new page.
EOF

"pageaddpagepagenametitle" => "Page Name",
"pageaddpagepagenamedesc" => <<"EOF",
The short name you will use for this page here and as the main part of the filename
on the website (".html" will be added - <b>do not include the ".html"</b>).
The names "index" and "default" are special on the website:
They are the default (usually in that order) if no name is given to the browser.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase).
This must be unique within a site, but may be the same as on other sites.
<br>Example: testresults
EOF

"pageaddpagelongpagenametitle" => "Long Page Name",
"pageaddpagelongpagenamedesc" => <<"EOF",
A more descriptive name than the filename that you use for this page here and in some links to it and in some templates.
This is optional but recommended. It does not need to be unique.
<br>Example: Latest Test Results
EOF

"pageaddpagepagetemplatetitle" => "Page Template",
"pageaddpageusedefaulttemplate" => "Use default template",
"pageaddpageusesharedtemplate" => "Use shared template",
"pageaddpagecopypublished" => "Copy published version of a page",
"pageaddpagecopyedited" => "Copy edited version of a page",
"pageaddpagecopyfromurl" => "Copy from URL",
"pageaddpagepagetemplatedesc" => <<"EOF",
The template provides predefined content, attributes, etc.
You can choose predefined ones shared among all sites you can edit or shared just among this particular site.
You can also load a template provided elsewhere on the Internet by providing the appropriate URL.
EOF

"pageaddpagelistoftemplates" => "List of templates to choose from",
"pageaddpagesitetolist" => "Site from which to list pages",
"pageaddpagecurrentsite" => "Current Site",
"pageaddpagepagetocopy" => "Page to copy from that site",
"pageaddpageempty" => "Empty...",
"pageaddpageloadfromthisurl" => "Load the template from this URL. (It must be in the correct format and accessible by HTTP.)",
"pageaddpagecreate" => "Create",

"pageaddedithosterr1" => "Host",
"pageaddedithosterr2" => "already exists. Choose another name.",

"pagedeletehosterr1" => "Host",
"pagedeletehosterr2" => "does not exist. Cannot delete.",

"pagedeletesiteerr1" => "Site",
"pagedeletesiteerr2" => "does not exist. Cannot delete.",

"pagedeletesiteerr3" => "Unable to fully delete site:",

"pageaddpagenonamegiven" => "No page name given. You must provide one to create a new page.",
"pageaddpagetypesite" => "New page from site template:",
"pageaddpagetypeshared" => "New page from shared template:",
"pageaddpagecannotcopy" => "Cannot copy that page.",
"pageaddpagenocopypub" => "Could not find page to copy: published",
"pageaddpagetypepublished" => "New page from published page:",
"pageaddpagenocopyediting" => "Could not find page to copy: editing",
"pageaddpagetypeediting" => "New page from page being edited:",
"pageaddpageunabletoloadurl" => "Unable to load template from URL.",
"pageaddpagetypeurl" => "New page from:",
"pageaddpagetypedefault" => "New page from default template",

"pagesiteediterr1" => "Site",
"pagesiteediterr2" => "already exists. Choose another name.",
"pagesiteediterr3" => "The Site Name On Host and Author Name on Host fields must both be filled in.",
"pagesiteediterr4" => "Unable to check existence of site on host:",

"pagedemosetupcreatingdir" => "Creating directory",
"pagedemosetupcreatingdirerr1" => "Directory",
"pagedemosetupcreatingdirerr2" => "already exists",
"pagedemosetupcreatingdirerr3" => "Unable to create directory",
"pagedemosetupcreatingfile" => "Creating file",
"pagedemosetupcreatingfileexists" => "File already exists. Not modifying existing",
"pagedemosetupcreatingfileerr1" => "Unable to create file",
"pagedemosetupcompletetitle" => "Demo Setup Complete",
"pagedemosetupcompletedesc" => "Demo setup complete",
"pagedemosetupactionlist" => "The following actions were taken to setup wikiCalc:",
"pagedemosetupcontinue" => "Continue",

#
# WKCBackupCommands.pm
#

"backupkeepall" => "Keep all",
"backupnomin" => "No minimum",
"backupprefstitle" => "BACKUP PREFERENCES",
"backupprefsdesc" => <<"EOF",
Settings used to determine when to delete old backup files, if at all.
The actual deleting of the backup files for a particular page occurs when a page is published.
Archive files are not automatically deleted no matter what is set here
and are not included in the count of files to keep.
<br><br>
These settings affects all pages on a site.
The site being edited is:
EOF

"backupprefsmaxfiles" => "Maximum Backup Files Per Page",
"backupprefskeepall" => "Keep All",
"backupprefsmaxfilesdesc" => <<"EOF",
The maximum number of most recent backup files to save for each page for this site.
Each time a page is published a backup is created.
Older files than the most recent number set here will be deleted when new backups are created.
To prevent a particular backup from being deleted convert it into an "archive" file
using the "Archive" button associated with that backup file on the "List Backups For One Page" list.
EOF

"backupprefsmindays" => "Minimum Days Of Backup To Keep",
"backupprefsnomin" => "No minimum",
"backupprefsday" => "day",
"backupprefsdays" => "days",
"backupprefsmindaysdesc" => <<"EOF",
This setting specifies the minimum number of days
(counting from the time when publishing is done)
to prevent a backup file from being deleted no matter what the Maximum Backup Files setting.
This will prevent a flurry of edits from prematurely deleting recent backups
but can result in the number of files kept growing large.
EOF

"backupprefssave" => "Save",
"backupprefscancel" => "Cancel",

"backupclickoktoedit" => "Click OK to start editing.",

"backupdone" => "Done",
"backuphelp" => "Help",
"backuppreferences" => "Preferences",

"backupnewer" => "Newer",
"backupolder" => "Older",
"backupnewest" => "Newest",
"backupoldest" => "Oldest",

"backupshowprefs1" => "Preference settings for this site:<br>Maximum number of backup files saved for each page",
"backupshowprefs2" => "minimum number of days kept",

"backupunpubopen" => "Unpublished data open for edit by current author",

"backupbreadcrumbs" => "Tools:",
"backuppagedesc" => "Commands to list backup copies of pages, revert to old versions, etc.",

"backupdetailsbreadcrumb" => "Backup File Details",
"backupdetailspagetitle" => "BACKUP FILE DETAILS:",
"backupdetailspagedesc" => "Details about a specific backup file for a page",

"backupdetailssite" => "Site",
"backupdetailsbackupfilename" => "Backup Filename",
"backupdetailstype" => "Type",
"backupdetailspage" => "Page",
"backuplastauthor" => "Last Author",
"backupcomments" => "Comments",
"backupstartedwith" => "Started With File",
"backupedits" => "Edits",
"backuplistallbreadcrumb" => "List All Backup Pages",
"backuplistallpagetitle" => "LIST ALL BACKUP PAGES:",
"backuplistallsite" => "SITE",
"backuplistallpagename" => "PAGE&nbsp;NAME&nbsp;",
"backuplistallfullname" => "FULL&nbsp;NAME&nbsp;",
"backuplistallwhenpub" => "MOST&nbsp;RECENT&nbsp;PUBLISH&nbsp;",
"backuplistallnfiles" => "FILES&nbsp;IN&nbsp;GROUP&nbsp;",
"backuplistalllist" => "List",

"backuplistonebreadcrumb" => "List Backups For One Page",
"backuplistonepagetitle" => "LIST BACKUPS FOR ONE PAGE:",
"backuplistonesite" => "SITE",
"backuplistonelistall" => "List All Backup Pages",
"backuplistonewhenpub" => "When&nbsp;Published&nbsp;",
"backuplistoneauthor" => "Author&nbsp;",
"backuplistoneedit" => "Edits&nbsp;",
"backuplistonecomments" => "Comments&nbsp;",
"backuplistonetype" => "Type&nbsp;",
"backuplistonenotpub" => "Not published yet",
"backuplistonecurrentedits" => "Current edits for this page",
"backuplistonecurrent" => "current",
"backuplistonedetails" => "Details",
"backuplistonearchive" => "Archive",
"backuplistonedelete" => "Delete",
"backuplistoneonserver" => "On server only. Download to see details.",
"backuplistonedownload" => "Download",

"backupwarning1" => "You are already editing the lastest version of page",
"backupwarning2" => "Are you sure you want to abandon those edits and start editing with",
"backupwarning3a" => "You had started editing the lastest version of page",
"backupwarning3b" => "but did not modify it",
"backupwarning4" => "Are you sure you want to abandon that version and start editing with",
"backupwarning5" => "Someone else has started editing page",
"backupwarning6" => "If you both publish changes one may overwrite the other, losing the edits.",
"backupwarning7" => "Are you sure you want to start editing with",
"backupwarning8a" => "Are you sure you want to ignore the lastest version of page",
"backupwarning8b" => "and start editing with",

#
# WKCDataFiles.pm
#

"datafilesnotfound" => "File not found.",
"datafilesunknownlocation" => "Unknown location, so no directory returned",
"datafilesunableftperrorstatus" => "Unable to access information by FTP. Error status",
"datafilesunableftperrorstatusis" => "Error while accessing information by FTP. Error status is",
"datafilesunablehtml" => "Unable to access Path For HTML",
"datafilesunableftp" => "Unable to access information by FTP",
"datafilesunableftpok1" => "Unable to access information by FTP. OK is",
"datafilesunableftpok2" => "Error status is",
"datafilesunabledelete" => "Unable to find directories and files to delete on host",
"datafilesfile" => "File",
"datafilesnotfound2" => "not found",
"datafilespage" => "Page",
"datafilesonsite" => "on site",
"datafilescannotedit" => "cannot be found to edit",
"datafilesattemptedit" => "Will attempt to edit from last local copy of a published version...",
"datafilesfoundlocal" => <<"EOF",
Found a local copy of a previously published version and will open for editing from there.<br>
Click the Edit button again to edit, or abandon editing if this is not correct.
EOF

"datafilesnolocal" => "There is no local copy of a previously published version to edit from.",
"datafilesunableaccessbackupftp" => "Unable to access information by FTP to download backup file.",
"datafilesbackuperroraccessing" => "Error while accessing backup copy by FTP. Error status is",
"datafilesattemptfrombackup" => "Will attempt to edit from last local copy of backup file...",
"datafilesnolocalbackup" => "There is no local copy of the backup file to edit from.",
"datafilesrevertedtobackup" => "Reverted to backup",
"datafilesrevertedby" => "by",
"datafilesunablepubftp" => "Unable to access FTP to publish.",
"datafileserrorpubftp" => "Error publishing by FTP. OK is",
"datafileserrorpubftpstatus" => "Error status is",
"datafilescontinueopen" => "File will continue to be open for edit so you can try publishing again.",
"datafilesunableftpdownloadrename" => "Unable to access FTP to rename. Local files may have been renamed successfully.",
"datafileserrorrename" => "Error renaming by FTP. Error status is",
"datafilespossbilerename" => "It is possible that some files were renamed successfully.",
"datafilesunableftplocalpossible" => "Unable to access FTP to rename. Local files may have been renamed successfully.",
"datafilesrenamed" => "Renamed",
"datafilesrenamedto" => "to",
"datafilesunableftpdownload" => "Unable to access FTP to download.",
"datafileserrordownloadingftpis" => "Error downloading by FTP. Error status is",
"datafilesmaybecorrupt" => "It is possible that some data was downloaded but it might be corrupt.",
"datafileshost" => "Host",
"datafilesnotsetup" => "not set up for FTP. Nothing to download.",
"datafilesunableftpdelete" => "Unable to access FTP to delete.",
"datafileserrordeletingstatusis" => "Error deleting by FTP. Error status is",
"datafilesunableftpdeletelocalmaybe" => "Unable to access FTP to delete. Local files may have been deleted successfully.",
"datafileserrorftpdeletestatusis" => "Error deleting by FTP. Error status is",
"datafilesunableftpdeleteedit" => "Unable to access FTP to delete edit file.",
"datafileserrorftpdeleteeditstatusis" => "Error deleting edit file by FTP. Error status is",
"datafilesunableftplistbackup" => "Unable to access FTP to list backup files.",
"datafileserrorftplistbackupstatusis" => "Error accessing site data by FTP to list backup files. Error status is",
"datafilesunableftplistremotetodelete" => "Unable to access FTP to list remote backup files.",
"datafileserrorftplistremotetodelete" => "Error accessing site data by FTP trying to list remote backup files. Error status is",
"datafilesbackupsdeleted1" => "Deleted",
"datafilesbackupsdeleted2" => "backup files",
"datafilesrsspage" => "Page",
"datafilesrssonsite" => "on site",
"datafilesrssby" => "by",
"datafilesrsswith" => "with",
"datafilesrssedit" => "edit",
"datafilesrsseditpluralending" => "s",
"datafilesrssunknown" => "unknown",

#
# WKCFormatCommands.pm
#

# The list of font families:

"formatfontfamilies" => <<"EOF", # css value|display value
default|Default
Verdana,Arial,Helvetica,sans-serif|Verdana
arial,helvetica,sans-serif|Arial
'Courier New',Courier,monospace|Courier
EOF

# The list of font sizes:

"formatfontsizes" => <<"EOF", # css value|display value
default|Default
xx-small|XX-Small
x-small|X-Small
small|Small
medium|Medium
large|Large
x-large|X-Large
xx-large|XX-Large
6pt|6pt
7pt|7pt
8pt|8pt
9pt|9pt
10pt|10pt
11pt|11pt
12pt|12pt
14pt|14pt
16pt|16pt
18pt|18pt
20pt|20pt
22pt|22pt
24pt|24pt
28pt|28pt
36pt|36pt
48pt|48pt
72pt|72pt
8px|8 pixels
9px|9 pixels
10px|10 pixels
11px|11 pixels
12px|12 pixels
13px|13 pixels
14px|14 pixels
16px|16 pixels
18px|18 pixels
20px|20 pixels
22px|22 pixels
24px|24 pixels
28px|28 pixels
36px|36 pixels
EOF

"formatborderwidthoptions" => <<"EOF",
<option value="1px" selected>1 pixel<option value="2px">2 pixels<option value="3px">3 pixels<option value="4px">4 pixels
<option value="1pt">1 pt<option value="2pt">2 pt<option value="3pt">3 pt
<option value="4pt">4 pt<option value="5pt">5 pt<option value="6pt">6 pt
EOF

"formatborderstyleoptions" => <<"EOF",
<option selected value="solid">Solid<option value="dotted">Dotted
<option value="dashed">Dashed<option value="double">Double
EOF

# The list of padding sizes:

"formatpaddingsizes" => <<"EOF", # css value|display value
0px|0 pixels
1px|1 pixels
2px|2 pixels
3px|3 pixels
4px|4 pixels
5px|5 pixels
6px|6 pixels
7px|7 pixels
8px|8 pixels
9px|9 pixels
10px|10 pixels
11px|11 pixels
12px|12 pixels
13px|13 pixels
14px|14 pixels
16px|16 pixels
18px|18 pixels
20px|20 pixels
22px|22 pixels
24px|24 pixels
28px|28 pixels
36px|36 pixels
1pt|1 pt
2pt|2 pt
3pt|3 pt
4pt|4 pt
6pt|6 pt
12pt|12 pt
18pt|18 pt
24pt|24 pt
36pt|36 pt
48pt|48 pt
54pt|54 pt
60pt|60 pt
72pt|72 pt
EOF

"formatloading" => "Loading...",
"formatnumbers" => "Numbers",
"formattext" => "Text",
"formatfonts" => "Fonts",
"formatcolors" => "Colors",
"formatborders" => "Borders",
"formatlayout" => "Layout",
"formatcolumns" => "Columns",
"formatrows" => "Rows",
"formatmisc" => "Misc",
"formatalignment" => "Alignment",
"formatformat" => "Format",
"formatallcells" => "All Cells",
"formatdefault" => "Default",
"formatleft" => "Left",
"formatcenter" => "Center",
"formatright" => "Right",
"formateditdefault" => "Edit default",
"formatfontfamily" => "Font Family",
"formatfontsize" => "Font Size",
"formatfontweightandstyle" => "Font Weight and Style",
"formatbold" => "Bold",
"formatitalic" => "Italic",
"formattextcolor" => "Text Color",
"formatbackgroundcolor" => "Background Color",
"formatcolordefault" => "Default",
"formatcolorcancel" => "Cancel",
"formatcolorok" => "OK",
"formatvisibility" => "Visibility",
"formatthickness" => "Thickness",
"formatstyle" => "Style",
"formatcolor" => "Color",
"formatallborders" => "All&nbsp;borders",
"formattopborder" => "Top&nbsp;border",
"formatrightborder" => "Right&nbsp;border",
"formatbottomborder" => "Bottom&nbsp;border",
"formatleftborder" => "Left&nbsp;border",
"formatoutlinecellrangeonly" => "Outline cell range only",
"formatsetsidesseparately" => "Set sides separately",
"formatwidth" => "Width",
"formatcolvisibility" => "Visibility",
"formatcelllayout" => "Cell Layout",
"formatvalignment" => "Alignment",
"formatpadding" => "Padding",
"formatlusedefault" => "Use default",
"formatlsetexplicitly" => "Set explicitly",
"formataligntop" => "Top",
"formatalignmiddle" => "Middle",
"formatalignbottom" => "Bottom",
"formatpaddingtop" => "Top",
"formatpaddingleft" => "Left",
"formatpaddingright" => "Right",
"formatpaddingbottom" => "Bottom",
"formatauto" => "Auto",
"formatsetcol" => "Set:",
"formathidewhenpublished" => "Hide when published",
"formateditdefaultwidth" => "Edit default width",
"formatrowvisibility" => "Visibility",
"formathiderowwhenpublished" => "Hide row when published",
"formatcellcssclass" => "Cell CSS Class",
"formatcellcssstyle" => "Cell CSS Style",
"formatliveviewmodifiable" => "Live View Modifiable",
"formatcssclassdesc" => "This is an advanced feature that replaces many of the other formatting settings for a cell when published.",
"formatcssstyledesc" => 'This is an advanced feature that adds an explicit "style" attribute to a cell.',
"formatyes" => "Yes",
"formatmodifiabledesc" => "Allow modification to cell value during live view for duration of single recalculation. See Help for more information.",
"formatsavenumbersettings" => "Save Number Settings",
"formatsavetextsettings" => "Save Text Settings",
"formatsavefontsettings" => "Save Font Settings",
"formatsavecolorsettings" => "Save Color Settings",
"formatsavebordersettings" => "Save Border Settings",
"formatsavelayoutsettings" => "Save Layout Settings",
"formatsavecolumnsettings" => "Save Column Settings",
"formatsaverowsettings" => "Save Row Settings",
"formatsavemiscsettings" => "Save Misc Settings",
"formatrange" => ":Range",
"formatmaincancel" => "Cancel",
"formathelp" => "Help",
"formatinitialfptext" => "A&nbsp;Sample&nbsp;Cell<br>\$1,234.56",
"formatinitialfpfonts" => "A&nbsp;Sample&nbsp;Cell<br>\$1,234.56",
"formatinitialfpcolors" => "<b>A&nbsp;Sample&nbsp;Cell<br>\$1,234.56</b>",
"formatinitialfpborders" => "A&nbsp;Sample&nbsp;Cell<br>\$1,234.56",
"formatinitialfplayout" => <<"EOF",
<table cellspacing="0" cellpadding="0" style="border-collapse:collapse;">
 <tr>
  <td id="layoutsample1" style="border:1px solid black;text-align:right;">\$1,234<br>57<br>102<br>abcdefg</td>
  <td id="layoutsample2" style="border:1px solid black;">Sample Text</td>
 </tr>
</table>
EOF
"formatinitialfpcolumns" => "Browser&nbsp;may&nbsp;make<br>actual&nbsp;column&nbsp;width<br>larger&nbsp;than&nbsp;specified<br>to&nbsp;fit&nbsp;content.",
"formatinitialfpmisc" => "A&nbsp;Sample&nbsp;Cell<br>For&nbsp;Style<br>\$1,234.56",
#
# WKCSheet.pm
#

"decimalchar" => ".",
"separatorchar" => ",",
"currencychar" => '$',
"daynames" => "Sunday Monday Tuesday Wednesday Thursday Friday Saturday",
"daynames3" => "Sun Mon Tue Wed Thu Fri Sat ",
"monthnames3" => "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec",
"monthnames" => "January February March April May June July August September October November December",
"sheetdefaultlayoutstyle" => "padding:2px 2px 1px 2px;vertical-align:top;",
"sheetdefaultfontfamily" => "Verdana,Arial,Helvetica,sans-serif",
"linkformatstring" => "Link", # you could make this an img tag if desired:
#"linkformatstring" => '<img border="0" src="http://www.domain.com/link.gif">',
"defaultformatdt" => 'd-mmm-yyyy h:mm:ss',
"defaultformatd" => 'd-mmm-yyyy',
"defaultformatt" => '[h]:mm:ss',
"displaytrue" => 'TRUE', # how TRUE shows when rendered
"displayfalse" => 'FALSE',
"parseerrexponent" => "Improperly formed number exponent",
"parseerrtwoops" => "Error in formula (two operators inappropriately in a row)",
"parseerrmissingopenparen" => "Missing open parenthesis in list with comma(s). ",
"parseerrcloseparennoopen" => "Closing parenthesis without open parenthesis. ",
"parseerrmissingcloseparen" => "Missing close parenthesis. ",
"parseerrmissingoperand" => "Missing operand. ",
"parseerrerrorinformula" => "Error in formula.",
"calcerrerrorvalueinformula" => "Error value in formula",
"parseerrerrorinformulabadval" => "Error in formula resulting in bad value.",
"calcerrnumericoverflow" => "Numeric overflow",
"calcerrcellrefmissing" => "Cell reference missing when expected.",
"calcerrsheetnamemissing" => "Sheet name missing when expected.",
"calcerrunknownname" => "Unknown name",
"calcerrincorrectargstofunction" => "Incorrect arguments to function",

#
# WKCSheetFunctions.pm
#

"sheetfuncunknownfunction" => "Unknown function",
"sheetfunclnarg" => "LN argument must be greater than 0",
"sheetfunclog10arg" => "LOG10 argument must be greater than 0",
"sheetfunclogsecondarg" => "LOG second argument must be numeric greater than 0",
"sheetfunclogfirstarg" => "LOG first argument must be greater than 0",
"sheetfuncroundsecondarg" => "ROUND second argument must be numeric",
"sheetfuncddblife" => "DDB life must be greater than 1",
"sheetfuncslnlife" => "SLN life must be greater than 1",
"sheetfuncwkchttperr" => "returned error",

#
# WKCToolsCommands.pm
#

"toolspagetitle" => "TOOLS OPTIONS:",
"toolspagedesc" => "General page settings, special operations, program settings.",

"toolspagepagepropertiesbutton" => "Page Properties",
"toolspagepagepropertiesbuttondesc" => "Edit general page settings: host name, HTML template",
"toolspageloadfromsheetbutton" => "Load From Sheet",
"toolspageloadfromsheetbuttondesc" => <<"EOF",
Load the clipboard from another sheet created by this program, either one from the current site or from elsewhere.
EOF

"toolspageloadfromtextbutton" => "Load From Text",
"toolspageloadfromtextbuttondesc" => <<"EOF",
Load the clipboard from typed in or pasted text.
This lets you take lines of text and numbers for other programs and place them in a series of cells.
It can also convert from comma separated (CSV)
and tab separated (what Microsoft Excel puts on the clipboard) format.
EOF

"toolspagesaveastextbutton" => "Save As Text",
"toolspagesaveastextbuttondesc" => <<"EOF",
Save the contents of the clipboard.
This lets you take the contents of a series of cells and get them in a variety of formats including CSV and XML.
EOF

"toolspagebackupsbutton" => "Backups",
"toolspagebackupsbuttondesc" => <<"EOF",
List backup copies of pages, revert to old versions, etc.
EOF

"toolspagelogoutbutton" => "Logout",
"toolspagelogoutbuttondesc" => "Logout current user",
"toolspageuseradminbutton" => "User Administration",
"toolspageuseradminbuttondesc" => <<"EOF",
Administer users to control who may edit files or make changes to the environment.
EOF

"toolspagepropsitespecific" => "site-specific",
"toolspagepropshared" => "shared",
"toolspagepropertiesbreadcrumbs" => "Tools:",
"toolspagepropertiespagetitle" => "PAGE PROPERTIES:",
"toolspagepropertiespagedesc" => "General page settings.",


"toolspagepgproppagename" => "Page Name",
"toolspagepgproppagenamedesc" => <<"EOF",
The short name you use for this page here and as the main part of the filename
on the website (".html" is added - <b>do not include the ".html"</b> here).
The names "index" and "default" are special on the website:
They are the default (usually in that order) if no name is given to the browser.
The name should be 32 or fewer characters in length,
and all characters other than letters, numbers, and the dash ("-") character
will be ignored.
Case is ignored (it is stored as lowercase) and only one page may have any given name on a site.
<br>
<b>Changing the name here will change the name for all instances of the page,
including published versions, published HTML, editing versions, and backup versions.</b>
<br>Example: testresults
EOF

"toolspagepgproplongpgnm" => "Long Page Name",
"toolspagepgproplongpgnmdesc" => <<"EOF",
A more descriptive name than the filename that you use for this page here and in some links to it and in some templates.
This is optional but recommended.
<br>Example: Latest Test Results
EOF

"toolspagepgprophtmltmplt" => "HTML Template",
"toolspagepgpropusedeftmplt" => "Use the default template",
"toolspagepgpropuseshared" => "Use a shared template",
"toolspagepgpropeditcopy" => "Edit a copy for just this page",
"toolspagepgprophtmltmpltdesc" => <<"EOF",
The template used to create the published HTML page.
You can choose predefined ones shared among all sites you can edit, shared just among this particular site,
or you can edit a template just associated with this page.
EOF

"toolspagepgpropeditcopydesc" => <<"EOF",
This is the page-specific template used to create the published HTML page which you can edit.
If this is blank, then the default template will be used (and appear here when next edited).
This starts out with the contents of the last shared template applied to this page.<br>
<br>The following special symbols may be used:<br><br>
<div style="padding-left:1em;">
{{pagetitle}} - Replaced by the page's Host Page Name set above<br>
{{pagename}} - Page's filename without the ".html"<br>
{{sitename}} - The site name value<br>
{{pubdatetime}} - Time string at publish time<br>
{{author}} - The name of the most recent author<br>
{{loggedinuser}} - The currently logged in user name<br>
{{editurl}} - The site URL for Editing value<br>
{{htmlurl}} - The site URL for HTML value<br>
{{sheetstyles}} - The styles definitions for the sheet to go within &lt;style&gt; section in page header<br>
{{sheet0}} - The HTML of the sheet itself<br>
<br>
{{templatedescriptionline}} - Optional description.
Must start first line of file. All text after it on the line
is used as template description when listed.<br>
{{line-if-editurl}} - Text after this on the line is output
if URL for Editing is set, ignored otherwise<br>
{{line-if-htmlurl}} - Text after this on the line is output
if URL for HTML is set, ignored otherwise<br>
{{line-if-loggedin}} - Text after this on the line is output
if the user is logged in, ignored otherwise<br>
{{line-if-liveview}} - Text after this on the line is output
if the template is being used to render during Live View, ignored otherwise<br>
{{editthispagehtml}} - Replaced by the default HTML to create an Edit This Page link if URL for Editing is set<br>
EOF

"toolspagepgproppuboptions" => "Publish Options",
"toolspagepgproppuboptionhtml" => "Publish HTML",
"toolspagepgproppuboptionsource" => "Publish Source",
"toolspagepgproppuboptionjs" => 'Publish Embeddable ".js" Version',
"toolspagepgproppuboptionnologin" => "Allow Live View Without Login",
"toolspagepgproppuboptionsdesc" => <<"EOF",
If Publish HTML is checked, at publish time a copy of the current sheet is converted to static
HTML along with the specified template and stored in the HTML directory for serving by
a web server.
Leave this unchecked if you only want the page viewable using the live viewing facility.<br>
<br>
See the help on the Publish tab for more information about live viewing.
<br>
<br>If Publish Source is checked, at publish time a copy of the page data file will also be put on the web in the same directory
as the newly published HTML file, but with the extension ".txt" instead of ".html".
That published data file may be copied when creating a new page (using the Add New Page's "Copy from URL" option).
It may also be used to access the sheet from pages on other sites and other purposes.
<br>
<br>If Publish Embeddable ".js" Version is checked, at publish time a copy of the newly published HTML
will be saved along with the HTML, but with the extension ".js" instead of ".html".
Only the HTML of the sheet itself is saved in this version, not the surrounding template.
This file may be dynamically included in any other HTML page by using HTML code such as:
&lt;script type="text/javascript" src="http://www.domain.com/pagename.js">&lt;/script>.
The result is static and is not recalculated when accessed the way that it is
with live viewing.
<br>
<br>If Allow Live View Without Login is checked, viewing the page through
the "live" interface will be allowed even if the user is not logged in or
is logged in as a user without permission to access this site.
EOF

"toolspagesave" => "Save",

"toolsuseradminbreadcrumbs" => "Tools:",
"toolsuseradminpagetitle" => "USER ADMINISTRATION:",
"toolsuseradminpagedesc" => <<"EOF",
Set whether to have users or not, and if so, manage their settings.
EOF

"toolspageuseradminmustbeloggedin" => "You must be logged in as an admin user to access this command.",
"toolspageuseradminlastsaved" => "Information about hosts last saved",
"toolspageuseradminrequirelogin" => "Require Login",
"toolspageuseradminreqadminyes" => "Yes",
"toolspageuseradminreqadminno" => "No",
"toolspageuseradminreqadmindesc" => "Do you require a logged in user in order to use the system?",
"toolspageuausername" => "User Name",
"toolspageuadisplayname" => "Display Name",
"toolspageuanewpassword" => "New Password",
"toolspageuaadmin" => "Admin",
"toolspageuaregisteredsites" => "Registered Sites",
"toolspageuadelete" => "Delete",
"toolspageuaallsites" => "ALL&nbsp;SITES",
"toolspageuareadreadwrite" => "&nbsp;R&nbsp;|&nbsp;RW",
"toolspageuareadreadwrite2" => "&nbsp;R&nbsp;|&nbsp;RW",
"toolspageuaaddnew" => "Add New",

"toolsloadfromsheetbreadcrumbs" => "Tools:",
"toolsloadfromsheetpagetitle" => "LOAD FROM SHEET:",
"toolsloadfromsheetclipboarddesc" => <<"EOF",
This command loads the clipboard of the current page from the clipboard contents of another page.
You can choose a page on this site or other sites to which you have access, either the most recently published
copy of the page or the most recently edited or published copy.
You can also load the clipboard contents from a sheet datafile elsewhere on the Internet by providing the appropriate URL.
EOF

"toolsloadfromsheetsheettoload" => "Sheet From Which To Load Clipboard",
"toolsloadfromsheetsheettoloaddesc" => "Choose the sheet from which you want to load the clipboard:",
"toolsloadfromsheetusepublished" => "Use published version of a page",
"toolsloadfromsheetuseedited" => "Use latest edited version of a page",
"toolsloadfromsheetusefromurl" => "Use page datafile from URL",

"toolsloadfromsheetsitetolist" => "Site from which to list pages",
"toolsloadfromsheetcurrentsite" => "Current Site",
"toolsloadfromsheetpagetouse" => "Page to use from that site",
"toolsloadfromsheetempty" => "Empty...",
"toolsloadfromsheetloadfromthisurl" => "Load the clipboard from the sheet datafile at this URL. (It must be in the correct format and accessible by HTTP.)",
"toolsloadfromsheetcommenttitle" => "Comment",
"toolsloadfromsheetcommentdesc" => "An optional comment to be added to the backup edit log.",

"toolsloadfromtextbreadcrumbs" => "Tools:",
"toolsloadfromtextpagetitle" => "LOAD FROM TEXT:",
"toolsloadfromtextpagedesc" => <<"EOF",
Load the clipboard from typed in or pasted text.
This lets you take lines of text and numbers for other programs and place them in a series of cells.
It can also convert from CSV format.
EOF

"toolsloadfromtexttexttoload" => "Text To Load",
"toolsloadfromtextinterpreteachline" => "Interpret each line of text as:",
"toolsloadfromtextsingledown" => "Single cells in succeeding rows as a column",
"toolsloadfromtextsingleacross" => "Single cells in columns across a row",
"toolsloadfromtextcsv" => "Comma-delimited CSV-format data separated by commas with each cell across a row",
"toolsloadfromtexttab" => "Tab-delimited with single cell data separated by tabs across a row (Microsoft Excel puts this on the clipboard)",
"toolsloadfromtextdatadesc" => <<"EOF",
The data as text. Fields that look like numbers (only +, - , ., and numbers -- not $, commas, etc.) will be loaded as numeric values.
Everything else will be loaded as text.
EOF
"toolsloadfromtextcommenttitle" => "Comment",
"toolsloadfromtextcommentdesc" => "An optional comment to be added to the backup edit log.",

"toolspageload" => "Load",

"toolssavetotextbreadcrumbs" => "Tools:",
"toolssavetotextpagetitle" => "SAVE TO TEXT:",
"toolssavetotextpagedesc" => <<"EOF",
Get the contents of the sheet or clipboard in other formats.
The results will be presented in a text field for copying.
EOF

"toolssavetotextsource" => "Source",
"toolssavetotextsourcedesc" => <<"EOF",
Which cells are to be saved.
The sheet extent includes A1 through the furthest cells with data.
EOF

"toolssavetotextsheetcurrently" => "Sheet (currently",
"toolssavetotextclipboardcontains" => "Clipboard (contains contents that came from",
"toolssavetotextformattoproduce" => "Format To Produce",
"toolssavetotextformattoproducedesc" => "Create output with the cells translated as follows:",
"toolssavetotextoneperline" => "The value of each cell going left to right and then down rows output as separate lines",
"toolssavetotextoneperlineformula" => 'The contents (text, number, or formula) of each cell going left to right and then down rows output as separate lines in the format similar to "B7:=1.1*B6"',
"toolssavetotextcsv" => "Comma-delimited CSV-format of the cell values separated by commas with each cell across a row",
"toolssavetotexttab" => "Tab-delimited format with lines of cell values separated by tabs between each cell across a row (Microsoft Excel can paste this into multiple cells)",
"toolspagesave" => "Save",

"toolsdosavetotextempty" => "Clipboard is empty!",
"toolsdosavetotextbreadcrumbs" => "Tools:",
"toolsdosavetotextpagetitle" => "SAVE TO TEXT RESULTS:",
"toolsdosavetotextpagedesc" => <<"EOF",
You can select the contents of the text area below to copy it to another application.
EOF

"toolsexectoolsloadclipboardstart" => "Start loading clipboard from text",
"toolsexectoolsloadclipboardend" => "Finished loading clipboard from text",

"toolsexectoolsloadclipboardsheetstart" => "Start loading clipboard from sheet",
"toolsexectoolsloadsheetclipboardsheetend" => "Finished loading clipboard from sheet",
"toolspagetoolssheetunabletoload" => "Unable to load sheet from",
"toolsexecsheetcannotload" => "Cannot load clipboard from that sheet.",
"toolsexecsheetnoloadpub" => "Could not find page to load clipboard from: published",
"toolsexecsheetnoloadediting" => "Could not find page to load clipboard from: editing",
"toolsexecsheetunabletoloadurl" => "Unable to load sheet from URL.",
"toolsexecsheetemptyclipboard" => "Empty clipboard",

                    );

   1;

=begin license

SOFTWARE LICENSE

This software and documentation is
Copyright (c) 2006 Software Garden, Inc.
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
write to the Free Software Foundation, Inc., 59 Temple Place - Suite
330, Boston, MA  02111-1307, USA.

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

License version: 1.3/2005-09-05

=end

=cut

