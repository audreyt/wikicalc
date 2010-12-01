#
# WKCBackupCommands.pl -- Commands and other code to deal with backups, revision control, RSS, etc.
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCBackupCommands;

   use strict;
   use CGI qw(:standard);
   use utf8;

   use WKCStrings;
   use WKC;
   use WKCSheet;
   use WKCDataFiles;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(do_backup_command);
   our $VERSION = '1.0.0';

#
# Locals
#

   my $backuplistonepagesize = 50; # Max items when listing backups for one page
   my $backuplistallpagesize = 50; # Max items when listing backups for all pages

# Return something

   1;

# # # # # # # #
#
# $response = do_backup_command(\%params, $hiddenfields, $hostinfo)
#
# Do the stuff for the Backup command
#
# # # # # # # #

sub do_backup_command {

   my ($params, $hiddenfields, $hostinfo) = @_;


   my ($response, $inlinescripts, $errstr);
   my ($donetarget, $donetree, $donecommand, $donecrumbs);

   my $sitename = $params->{sitename};
   my $sitedata = $hostinfo->{sites}->{$sitename};

   my $maxfilesstr = $sitedata->{backupmaxfiles} || $WKCStrings{"backupkeepall"};
   my $mindaysstr = $sitedata->{backupmindays} || $WKCStrings{"backupnomin"};

   my $longsitename = special_chars($hostinfo->{sites}->{$sitename}->{longname});

   my $siteinfo = get_siteinfo($params);

   if (!$params->{backupsubcommand}) { # only do this once when starting a run of using the backup command
      $siteinfo->{ftpdatetime} = ""; # get latest information everywhere for Edit buttons

      my $currentauthor = $hostinfo->{sites}->{$sitename}->{authoronhost};
      if ($hostinfo->{sites}->{$sitename}->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
         $currentauthor = $params->{loggedinusername};
         }

      my $siok = update_siteinfo($params, $hostinfo, $siteinfo);

      if ($siteinfo->{updates}) {
         $siok = save_siteinfo($params, $siteinfo);
         }
      }

   my $ok;

   # Load scripts from a file

   $inlinescripts .= $WKCStrings{"jsdefinestrings"};
   open JSFILE, "$WKCdirectory/WKCjs.txt";
   while (my $line = <JSFILE>) {
      $inlinescripts .= $line;
      }
   close JSFILE;

   # # # # # # # # # # #
   #
   # Check for commands to execute before displaying other info
   #
   # # # # # # # # # # #

   if ($params->{backupsubcommand} eq "archive") { # Archive command
      my ($filename, $pagename) = split(/:/, $params->{backupfilename}); # file to rename from backup to archive
      my $newfilename = $filename;
      $newfilename =~ s/^(\w+?)\.backup/$1.archive/;
      $errstr = rename_specific_file($params, $hostinfo, $sitename, $filename, $newfilename);
      $params->{backupfilename} = $pagename; # set up for info display
      $params->{backupsubcommand} = "list";
      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # pop call tree
      $params->{backupcalltree} = $donetree;
      }

   elsif ($params->{backupsubcommand} eq "delete") { # Delete specific backup/archive file command
      my ($filename, $pagename) = split(/:/, $params->{backupfilename}); # file to delete
      $errstr = delete_specific_file($params, $hostinfo, $sitename, $filename);
      $errstr ||= "Deleted $filename";
      $params->{backupfilename} = $pagename; # set up for info display
      $params->{backupsubcommand} = "list";
      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # pop call tree
      $params->{backupcalltree} = $donetree;
      }

   elsif ($params->{backupsubcommand} eq "download") { # Download backup/archive file from remote server
      my ($filename, $pagename) = split(/:/, $params->{backupfilename}); # file to download
      $errstr = download_specific_file($params, $hostinfo, $sitename, $filename);
      $errstr ||= "Downloaded $filename";
      $params->{backupfilename} = $pagename; # set up for info display
      $params->{backupsubcommand} = "list";
      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # pop call tree
      $params->{backupcalltree} = $donetree;
      }

   elsif ($params->{backupsubcommand} eq "savepreferences") { # Save preference values and then pop back
      $sitedata->{backupmaxfiles} = $params->{editbackupmaxfiles};
      $sitedata->{backupmindays} = $params->{editbackupmindays};
      $ok = save_hostinfo($params, $hostinfo);
      # Parse backupfilename which has old "donecommand" information to go back one
      ($ok, $params->{backupsubcommand}, $params->{backupfilename}) = split(/:/, $params->{backupfilename}, 3);
      if ($params->{backupsubcommand} eq "list" || $params->{backupsubcommand} eq "all") {
         ($params->{backupfilename}, $params->{startitem}) = split(/:/, $params->{backupfilename});
         } 
      }

   # Handle messages

   my $pagemessage;
   if ($params->{pagemessage} || $params->{errormsg} || $errstr) { # Success/failure of delete, etc.
      $pagemessage = <<"EOF";
<div class="sectionerror">
$params->{pagemessage}
$params->{errormsg}
$errstr
</div>
EOF
      }

   ####################################
   #
   # DISPLAY BACKUP INFO
   #
   # # # # # # # # # # #

   # # # # # # # # # # #
   #
   # Display/Edit preferences
   #
   # # # # # # # # # # #

   if ($params->{backupsubcommand} eq "preferences") {

      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # how to get back and back from there
      ($donecommand, $donecrumbs) = split("!", $donetarget);
      $donecommand = $donecommand ? "backup:$donecommand" : "backupdone";

      my (%maxfilesselected, %mindaysselected);
      $maxfilesselected{$sitedata->{backupmaxfiles} || "all"} = " selected";
      $mindaysselected{$sitedata->{backupmindays} || "none"} = " selected";

      $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
<td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"backupbreadcrumbs"}$donecrumbs</div>
<div class="pagetitle">$WKCStrings{"backupprefstitle"}</div>
<div class="pagetitledesc">
$WKCStrings{"backupprefsdesc"} <b>$longsitename</b> ($params->{sitename}).
</div>
$pagemessage

<form name="f0" method="POST">

<br>
<div class="title">$WKCStrings{"backupprefsmaxfiles"}</div>
<select name="editbackupmaxfiles" size="1">
<option value="0" $maxfilesselected{"all"}>$WKCStrings{"backupprefskeepall"}
<option value="10" $maxfilesselected{10}>10
<option value="25" $maxfilesselected{25}>25
<option value="50" $maxfilesselected{50}>50
<option value="100" $maxfilesselected{100}>100
</select>
<div class="desc">
$WKCStrings{"backupprefsmaxfilesdesc"}
</div>

<div class="title">$WKCStrings{"backupprefsmindays"}</div>
<select name="editbackupmindays" size="1">
<option value="0" $mindaysselected{"none"}>$WKCStrings{"backupprefsnomin"}
<option value="1" $mindaysselected{1}>1 $WKCStrings{"backupprefsday"}
<option value="7" $mindaysselected{7}>7 $WKCStrings{"backupprefsdays"}
<option value="30" $mindaysselected{30}>30 $WKCStrings{"backupprefsdays"}
<option value="60" $mindaysselected{60}>60 $WKCStrings{"backupprefsdays"}
<option value="90" $mindaysselected{90}>90 $WKCStrings{"backupprefsdays"}
</select>
<div class="desc">
$WKCStrings{"backupprefsmindaysdesc"}
</div>
<br>
<input type="submit" name="backup:savepreferences:$donecommand" value="$WKCStrings{"backupprefssave"}">
<input type="submit" name="$donecommand" value="$WKCStrings{"backupprefscancel"}">
<input type="hidden" name="backupcalltree" value="$donetree">

EOF

      $response .= <<"EOF";
</div>
<div style="padding-bottom:10px;">
<input type="hidden" name="oktools:backup" value="1">
</div>
$inlinescripts
$hiddenfields
</form>
 </td>
</tr>
</table>
EOF

      return $response;

      }

   # # # # # # # # # # #
   #
   # Show Details of one backup file
   #
   # # # # # # # # # # #

   elsif ($params->{backupsubcommand} eq "details") {

      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # how to get back and back from there
      ($donecommand, $donecrumbs) = split("!", $donetarget);
      $donecommand = $donecommand ? "backup:$donecommand" : "backupdone";
      my $backupcalltree = "details:$params->{backupfilename}!$donecrumbs $WKCStrings{backupdetailsbreadcrumb}:"; # remember what "Done" should do for those we call
      $backupcalltree .= "|$params->{backupcalltree}" if $params->{backupcalltree};

      my $filepath = get_page_edit_path($params, $hostinfo, $sitename, "all");
      $filepath =~ s/\/all\.edit\.[a-z0-9\-]+?\.txt$/"\/".$params->{backupfilename}/e;
      my (@headerlines, %headerdata);
      $ok = load_page($filepath, \@headerlines, "");
      $ok = parse_header_save(\@headerlines, \%headerdata);
      my $fullname = special_chars($headerdata{fullname});
      my $shortname = $filepath;
      $shortname =~ s/.*\/([a-z0-9\-]+?)\.(\w+?)\.[^\/]+?$/$1/;
      my $filetype = $2; # could be archive, backup, or edit
      my $lastauthor = $headerdata{lastauthor};
      my $edits = $headerdata{editlog} ? scalar @{$headerdata{editlog}} : "";
      my $comments = special_chars($headerdata{editcomments});
      my $basefiledt = $headerdata{basefiledt};
      $comments =~ s/\n/<br>/g;

      my $basefiledt = $headerdata{basefiledt};

      my $warnmsg = get_warnmsg($params, $hostinfo, $siteinfo, $shortname);

      $response .= <<"EOF";
<script>
function multieditwarn(pn) {
return(confirm("$warnmsg"+pn+"'?\\n$WKCStrings{"backupclickoktoedit"}"))
}
</script>
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"backupbreadcrumbs"}$donecrumbs</div>
<div class="pagetitle">$WKCStrings{"backupdetailspagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"backupdetailspagedesc"}</div>
</div>

<form name="f0" method="POST">
<br>
<input type="submit" class="smaller" name="$donecommand" value="$WKCStrings{"backupdone"}" onClick="document.f0.backupcalltree.value='$donetree';">
<input type="hidden" name="backupcalltree" value="$backupcalltree">
<input class="smaller" type="submit" name="help" value="$WKCStrings{"backuphelp"}" onClick="toggle_help('backupdetailshelptext');this.blur();return false;">
</div><div id="helptext" style="width:500px;padding:10px 0px 0px 0px;display:none;">
 <div style="border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;color:white;background-color:#66CC66;">
 <table cellspacing="0" cellpadding="0"><tr><td align="center" width="100%" class="smaller"><b>$WKCStrings{"helphelp"}</b></td>
 </td><td align="right"><input class="smaller" type="submit" name="hidehelp" value="$WKCStrings{"helphide"}" onClick="toggle_help('');this.blur();return false;"></td>
 </tr></table></div>
 <div id="helpbody" class="smaller" style="height:200px;overflow:auto;background-color:white;padding:4px;border:1px solid black;">
  $WKCStrings{"helpnotloaded"}
 </div>
</div>
<div style="padding-top:10px;margin-top:1em;background-color:white;border:1px solid #99CC99;">
$pagemessage
<table cellspacing="0" cellpadding="0">
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupdetailssite"}:</td><td class="browsepageavailable2">$longsitename ($params->{sitename})</td>
 </tr>
EOF
      $response .= <<"EOF" if $filetype ne "edit";
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupdetailsbackupfilename"}:</td><td class="browsepageavailable">$params->{backupfilename}</td>
 </tr>
 <tr>
  <td class="browsepageavailable3">&nbsp;</td>
  <td style="padding-left:4pt;"><input class="smaller" type="submit" name="choosepagebackup:$params->{backupfilename}" value="$WKCStrings{"pagelistedit"}" onClick="return multieditwarn('$params->{backupfilename}');"></td>
 <tr>
EOF
      $response .= <<"EOF" if $filetype eq "edit";
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupdetailstype"}:</td><td class="browsepageavailable2"><i>$WKCStrings{"backupunpubopen"}</i></td>
 </tr>
EOF
      $response .= <<"EOF";
  <td class="browsepageavailable3">$WKCStrings{"backupdetailspage"}:</td><td class="browsepageavailable">$fullname <span style="font-weight:normal;">($shortname)</span></td>
 </tr>
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backuplastauthor"}:</td><td class="browsepageavailable2">$lastauthor</td>
 </tr>
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupcomments"}:</td><td class="browsepageavailable">$comments</td>
 </tr>
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupstartedwith"}:</td><td class="browsepageavailable2">$basefiledt</td>
 </tr>
 <tr>
  <td class="browsepageavailable3">$WKCStrings{"backupedits"}:</td><td class="browsepageavailable2">&nbsp;</td>
 </tr>
EOF

      if ($edits) {
         my $count=0;
         foreach my $logstr (@{$headerdata{editlog}}) {
            my $logstrsc = special_chars($logstr);
            $count++;
            $response .= <<"EOF";
 <tr>
  <td class="browsepageavailable3" style="font-weight:normal;">$count:</td><td class="browsepageavailable2">$logstrsc</td>
 </tr>
EOF
            }
         }

      $response .= <<"EOF";
</table>
<br>
</div>
<br>
<div style="padding-bottom:10px;">
<input type="hidden" name="oktools:backup" value="1">
EOF
      }

   # # # # # # # # # # #
   #
   # Display a list of all files' backup files
   #
   # # # # # # # # # # #

   elsif ($params->{backupsubcommand} eq "all" || (!$params->{datafilename} && !$params->{backupfilename})) {

      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # how to get back and back from there
      ($donecommand, $donecrumbs) = split("!", $donetarget);
      $donecommand = $donecommand ? "backup:$donecommand" : "backupdone";
      my $backupcalltree = "all:all:$params->{startitem}!$donecrumbs $WKCStrings{backuplistallbreadcrumb}:"; # remember what "Done" should do for those we call
      $backupcalltree .= "|$params->{backupcalltree}" if $params->{backupcalltree};

      my %backuplist;

      get_page_backup_list($params, $hostinfo, $sitename, "", \%backuplist);

      if ($backuplist{error}) { # FTP problem probably
         $pagemessage .= <<"EOF";
<div class="sectionerror">
$backuplist{error}
</div>
EOF
         }

      my @sortlist;
      foreach my $bfile (keys %{$backuplist{pages}}) { # sort by date -- make list of files associated with date
         push @sortlist, ($backuplist{pages}->{$bfile}->{dtm} . ":" . $bfile);
         }
      my @revsortlist = reverse sort @sortlist;
      push @revsortlist, ""; # one at the end to kick out info before it

      my @okpages;

      my ($currentname, $groupcount, $firstdtmstr, %pageshown);
      foreach my $sname (@revsortlist) { # Go through all files and group
         my ($dtm, $pname) = split(":", $sname); # get filename away from sort field

         my $blp = $backuplist{pages}->{$pname};

         my ($yr, $mon, $day, $hr, $minute, $sec) = split("-", $blp->{dtm});
         my $dtmstr = sprintf("%02d-%s-%04d %02d:%02d:%02d GMT", $day, $WKCmonthnames[$mon-1], $yr, $hr, $minute, $sec);

         if (!$currentname) { # first one
            $currentname = $blp->{pagename};
            $groupcount = 1;
            $firstdtmstr = $dtmstr;
            next;
            }

         if ($blp->{pagename} ne $currentname) { # start new group
            push @okpages, "$currentname|$firstdtmstr|$groupcount";
            $currentname = $blp->{pagename};
            $groupcount = 1;
            $firstdtmstr = $dtmstr;
            }
         else {
            $groupcount++;
            }
         }

      my $listsize = scalar @okpages;
      my $pagesize = $backuplistallpagesize;
      my $startitem = $params->{startitem} > 0 ? ($params->{startitem} < $listsize ? $params->{startitem} : $listsize) : 1;
      my $enditem = $startitem + $pagesize;
      $enditem = $listsize if $enditem > $listsize; # note use of 1-origin arith


      my $newerdisabled = $startitem <= 1 ? " disabled" : "";
      my $olderdisabled = $startitem+$pagesize >= $listsize ? " disabled" : "";

      my $newerstart = $startitem - $pagesize; # item numbers to start with
      my $olderstart = $startitem + $pagesize;
      my $neweststart = 1;
      my $oldeststart = $listsize - $pagesize;

      $response .= <<"EOF";

<script>
function stayhere() {
 document.f0.backupcalltree.value="$params->{backupcalltree}";
}
</script>

<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"backupbreadcrumbs"}$donecrumbs</div>
<div class="pagetitle">$WKCStrings{"backuplistallpagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"backuppagedesc"}</div>
</div>

<form name="f0" method="POST">

<div class="sectionplain">
<div class="pagefilename">$WKCStrings{"backuplistallsite"}: $longsitename <span style="font-weight:normal;">($params->{sitename})</span></div>
<br>
<input type="submit" class="smaller" name="$donecommand" value="$WKCStrings{"backupdone"}" onClick="document.f0.backupcalltree.value='$donetree';">
<input class="smaller" type="submit" name="backup:preferences:all" value="$WKCStrings{"backuppreferences"}">
<input class="smaller" type="submit" name="help" value="$WKCStrings{"backuphelp"}" onClick="toggle_help('backuphelptext');this.blur();return false;">
<input type="hidden" name="backupcalltree" value="$backupcalltree">
<br>
$pagemessage

<div id="helptext" style="width:500px;padding:10px 0px 0px 0px;display:none;">
 <div style="border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;color:white;background-color:#66CC66;">
 <table cellspacing="0" cellpadding="0"><tr><td align="center" width="100%" class="smaller"><b>$WKCStrings{"helphelp"}</b></td>
 </td><td align="right"><input class="smaller" type="submit" name="hidehelp" value="$WKCStrings{"helphide"}" onClick="toggle_help('');this.blur();return false;"></td>
 </tr></table></div>
 <div id="helpbody" class="smaller" style="height:200px;overflow:auto;background-color:white;padding:4px;border:1px solid black;">
  $WKCStrings{"helpnotloaded"}
 </div>
</div>
<br>

<table cellspacing="3">
EOF

      my $nextprevhtml = <<"EOF";
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td align="left" colspan="4">
 <table cellspacing="0" cellpadding="0" width="100%"><tr>
  <td align="left" class="browsebuttoncell">
   <input class="smaller" type="submit" name="backup:all:all:$newerstart" value="$WKCStrings{"backupnewer"}" onclick="stayhere();"$newerdisabled>
   <input class="smaller" type="submit" name="backup:all:all:$olderstart" value="$WKCStrings{"backupolder"}" onclick="stayhere();"$olderdisabled>
  </td>
  <td align="center" class="smaller">
   Items $startitem-$enditem of $listsize
  </td>
  <td align="right" class="browsebuttoncell">
   <input class="smaller" type="submit" name="backup:all:all:$neweststart" value="$WKCStrings{"backupnewest"}" onclick="stayhere();"$newerdisabled>
   <input class="smaller" type="submit" name="backup:all:all:$oldeststart" value="$WKCStrings{"backupoldest"}" onclick="stayhere();"$olderdisabled>
  </td>
 </tr></table>
</td>
<td>&nbsp;</td>
</tr>
EOF

      $response .= $nextprevhtml if $listsize > $pagesize+1;

      $response .= <<"EOF";
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistallpagename"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistallfullname"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistallwhenpub"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistallnfiles"}</td>
</tr>
EOF

      for (my $groupnum=1; $groupnum<=$enditem; $groupnum++) { # output a page's worth of edit groups
         my ($pname, $dtm, $gcount) = split(/\|/, $okpages[$groupnum-1]); # get name, most recently modified, and count
         if (!$pageshown{$pname}) {
            $pageshown{$pname} = 1; # remember first time shown
            next if $groupnum < $startitem; # starts with 1 to make pageshown correct
            my $fullname = special_chars($siteinfo->{files}->{$pname}->{fullnamepublished} || $pname);
            $response .= <<"EOF";
<tr>
 <td class="browsebuttoncell"><input class="smaller" type="submit" name="backup:list:$pname" value="$WKCStrings{"backuplistalllist"}">&nbsp;</td>
 <td class="browsepagedim" align="right">$groupnum</td>
 <td class="browsepagename">$pname</td>
 <td class="browsepagename"><b>$fullname</b></td>
EOF
            }
         else {
            next if $groupnum < $startitem;
            $response .= <<"EOF";
<tr>
 <td class="browsebuttoncell">&nbsp;</td>
 <td class="browsepagedim" align="right">$groupnum</td>
 <td class="browsepagename">$pname</td>
 <td class="browsepagename">&nbsp;</td>
EOF
            }
         $response .= <<"EOF";
 <td class="browsepagename">$dtm</td>
 <td class="browsepagename">$gcount</td>
</tr>
EOF
         }

      $response .= $nextprevhtml if $listsize > $pagesize+1;

      $response .= <<"EOF";
<tr><td class="browsepagename" colspan="6">
$WKCStrings{"backupshowprefs1"}: $maxfilesstr, $WKCStrings{"backupshowprefs2"}: $mindaysstr
</td></tr>
</table>
<br>
EOF
      }

   # # # # # # # # # # #
   #
   # Default and "list" - show specified page's list of backup files (current page is default)
   #
   # # # # # # # # # # #

   else { # normal top level

      my $backupdatafilename = $params->{backupfilename} || $params->{datafilename};
      my $fileinfo = $siteinfo->{files}->{$backupdatafilename};
      my $fullname = special_chars($fileinfo->{fullnamepublished});

      ($donetarget, $donetree) = split(/\|/, $params->{backupcalltree}, 2); # how to get back and back from there
      ($donecommand, $donecrumbs) = split("!", $donetarget);
      $donecommand = $donecommand ? "backup:$donecommand" : "backupdone";
      my $backupcalltree = "list:$backupdatafilename:$params->{startitem}!$donecrumbs $WKCStrings{backuplistonebreadcrumb}:"; # remember what "Done" should do for those we call
      $backupcalltree .= "|$params->{backupcalltree}" if $params->{backupcalltree};

      my $warnmsg = get_warnmsg($params, $hostinfo, $siteinfo, $backupdatafilename);

      my %backuplist;

      get_page_backup_list($params, $hostinfo, $sitename, $backupdatafilename, \%backuplist);

      if ($backuplist{error}) { # FTP problem probably
         $pagemessage .= <<"EOF";
<div class="sectionerror">
$backuplist{error}
</div>
EOF
         }

      my @sortlist;
      foreach my $bfile (keys %{$backuplist{pages}}) { # get list of dtm's to sort along with associated filenames
         push @sortlist, ($backuplist{pages}->{$bfile}->{dtm} . ":" . $bfile);
         }
      my @revsortlist = reverse sort @sortlist;
      my $listsize = scalar @revsortlist;
      my $count = 0;
      my $startitem = $params->{startitem} > 0 ? ($params->{startitem} < $listsize ? $params->{startitem} : $listsize) : 1;
      my $pagesize = $backuplistonepagesize;
      my @okpages;

      for (my $thisitem=0; $thisitem < $listsize; $thisitem++) { # Find out which files to list on this page
         my ($dtm, $pname) = split(":", $revsortlist[$thisitem]); # get filename
         my $blp = $backuplist{pages}->{$pname};
         next if $blp->{pagename} ne $backupdatafilename;
         $count++;
         next if $count < $startitem; # ignore if not on this page
         next if $count > $startitem + $pagesize;
         push @okpages, $thisitem;
         }

      my $lastitem = $startitem + scalar @okpages - 1;

      my $newerdisabled = $startitem <= 1 ? " disabled" : "";
      my $olderdisabled = $startitem+$pagesize >= $count ? " disabled" : "";

      my $newerstart = $startitem - $pagesize; # item numbers to start with
      my $olderstart = $startitem + $pagesize;
      my $neweststart = 1;
      my $oldeststart = $count - $pagesize;

      $response .= <<"EOF";
<script>
function multieditwarn(pn) {
return(confirm("$warnmsg"+pn+"'?\\n$WKCStrings{backupclickoktoedit}"))
}

function stayhere() {
 document.f0.backupcalltree.value="$params->{backupcalltree}";
}

</script>

<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"backupbreadcrumbs"}$donecrumbs</div>
<div class="pagetitle">$WKCStrings{"backuplistonepagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"backuppagedesc"}</div>
</div>

<form name="f0" method="POST">

<div class="sectionplain">
<div class="pagefilename">$WKCStrings{"backuplistonesite"}: $longsitename <span style="font-weight:normal;">($params->{sitename})</span></div>
<br>
<input type="submit" class="smaller" name="$donecommand" value="$WKCStrings{"backupdone"}" onClick="document.f0.backupcalltree.value='$donetree';">
<input class="smaller" type="submit" name="backup:all:all" value="$WKCStrings{"backuplistonelistall"}">
<input class="smaller" type="submit" name="backup:preferences:all" value="$WKCStrings{"backuppreferences"}">
<input class="smaller" type="submit" name="help" value="$WKCStrings{"backuphelp"}" onClick="toggle_help('backuphelptext');this.blur();return false;">
<input type="hidden" name="backupcalltree" value="$backupcalltree">
<br>
$pagemessage

<div id="helptext" style="width:500px;padding:10px 0px 0px 0px;display:none;">
 <div style="border-top:1px solid black;border-left:1px solid black;border-right:1px solid black;color:white;background-color:#66CC66;">
 <table cellspacing="0" cellpadding="0"><tr><td align="center" width="100%" class="smaller"><b>$WKCStrings{"helphelp"}</b></td>
 </td><td align="right"><input class="smaller" type="submit" name="hidehelp" value="$WKCStrings{"helphide"}" onClick="toggle_help('');this.blur();return false;"></td>
 </tr></table></div>
 <div id="helpbody" class="smaller" style="height:200px;overflow:auto;background-color:white;padding:4px;border:1px solid black;">
  $WKCStrings{"helpnotloaded"}
 </div>
</div>
<br>
<table cellspacing="3">
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td colspan="5" class="browsetablehead">$fullname<br><span style="font-weight:normal;">($backupdatafilename)</span></td>
<td>&nbsp;</td>
</tr>
EOF

      my $nextprevhtml = <<"EOF";
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td align="left" colspan="5">
 <table cellspacing="0" cellpadding="0" width="100%"><tr>
  <td align="left" class="browsebuttoncell">
   <input class="smaller" type="submit" name="backup:list:$backupdatafilename:$newerstart" value="$WKCStrings{"backupnewer"}" onclick="stayhere();"$newerdisabled>
   <input class="smaller" type="submit" name="backup:list:$backupdatafilename:$olderstart" value="$WKCStrings{"backupolder"}" onclick="stayhere();"$olderdisabled>
  </td>
  <td align="center" class="smaller">
   Items $startitem-$lastitem of $count
  </td>
  <td align="right" class="browsebuttoncell">
   <input class="smaller" type="submit" name="backup:list:$backupdatafilename:$neweststart" value="$WKCStrings{"backupnewest"}" onclick="stayhere();"$newerdisabled>
   <input class="smaller" type="submit" name="backup:list:$backupdatafilename:$oldeststart" value="$WKCStrings{"backupoldest"}" onclick="stayhere();"$olderdisabled>
  </td>
 </tr></table>
</td>
<td>&nbsp;</td>
</tr>
EOF

      $response .= $nextprevhtml if $count > $pagesize+1;

      $response .= <<"EOF";
<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistonewhenpub"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistoneauthor"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistoneedit"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistonecomments"}</td>
<td class="browsecolumnhead">$WKCStrings{"backuplistonetype"}</td>
<td>&nbsp;</td>
</tr>
EOF

      if ($backupdatafilename eq $params->{datafilename} && $startitem == 1) { # listing current file - give access to details
            my $editname = get_page_edit_path($params, $hostinfo, $sitename, $backupdatafilename);
            $editname =~ s/^.*\/([^\/]*)$/$1/;
            $response .= <<"EOF";
<tr>
 <td class="browsebuttoncell">&nbsp;</td>
 <td class="browsepagedim" align="right">&nbsp;</td>
 <td class="browsepagename">$WKCStrings{"backuplistonenotpub"}</td>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagename">$WKCStrings{"backuplistonecurrentedits"}</td>
 <td class="browsepagename">$WKCStrings{"backuplistonecurrent"}</td>
 <td class="browsebuttoncell">
  <input class="smaller" type="submit" name="backup:details:$editname" value="$WKCStrings{"backuplistonedetails"}">
 </td>
</tr>
EOF
         }

      my $itemnum = $startitem-1;
      foreach my $snamepos (@okpages) { # List each file
         my ($dtm, $pname) = split(":", $revsortlist[$snamepos]); # get filename

         my $blp = $backuplist{pages}->{$pname};
         next if $blp->{pagename} ne $backupdatafilename;

         $itemnum++;
         my ($yr, $mon, $day, $hr, $minute, $sec) = split("-", $blp->{dtm});
         my $dtmstr = sprintf("%02d-%s-%04d %02d:%02d:%02d GMT", $day, $WKCmonthnames[$mon-1], $yr, $hr, $minute, $sec);

         $response .= <<"EOF";
<tr>
EOF

         if ($blp->{local} eq "yes") {
            my $noarchive = $blp->{type} eq "archive" ? " disabled" : "";
            $response .= <<"EOF";
 <td class="browsebuttoncell"><input class="smaller" type="submit" name="choosepagebackup:$pname" value="$WKCStrings{"pagelistedit"}" onClick="return multieditwarn('$pname');">&nbsp;</td>
 <td class="browsepagedim" align="right">$itemnum</td>
 <td class="browsepagename">$dtmstr</td>
 <td class="browsepagename">$blp->{author}</td>
 <td class="browsepagename">$blp->{edits}</td>
 <td class="browsepageavailable2">$blp->{comments}</td>
 <td class="browsepagename">$blp->{type}</td>
 <td class="browsebuttoncell">
  <input class="smaller" type="submit" name="backup:details:$pname" value="$WKCStrings{"backuplistonedetails"}">
  <input class="smaller" type="submit" name="backup:archive:$pname:$backupdatafilename" value="$WKCStrings{"backuplistonearchive"}"$noarchive>
  <input class="smaller" type="submit" name="backup:delete:$pname:$backupdatafilename" value="$WKCStrings{"backuplistonedelete"}">
 </td>
EOF
            }
         else {
            $response .= <<"EOF";
 <td class="browsebuttoncell"><input class="smaller" type="submit" name="choosepagebackup:$pname" value="$WKCStrings{"pagelistedit"}">&nbsp;</td>
 <td class="browsepagedim" align="right">$itemnum</td>
 <td class="browsepagename">$dtmstr</td>
 <td class="browsepagename"></td>
 <td class="browsepagename"></td>
 <td class="browsepagename">$WKCStrings{"backuplistoneonserver"}</td>
 <td class="browsepagename">$blp->{type}</td>
 <td class="browsebuttoncell">
  <input class="smaller" type="submit" name="backup:download:$pname:$backupdatafilename" value="$WKCStrings{"backuplistonedownload"}">
  <input class="smaller" type="submit" name="backup:delete:$pname:$backupdatafilename" value="$WKCStrings{"backuplistonedelete"}">
 </td>
</tr>
EOF
            }
         }

      $response .= $nextprevhtml if $count > $pagesize+1;

      $response .= <<"EOF";
<tr><td class="browsepagename" colspan="6">
$WKCStrings{"backupshowprefs1"}: $maxfilesstr, $WKCStrings{"backupshowprefs2"}: $mindaysstr
</td></tr>
</table>
<br>
EOF
      }

   #
   # Output closing "Done"
   #

   $response .= <<"EOF";
<input type="submit" class="smaller" name="$donecommand" value="$WKCStrings{"backupdone"}" onClick="document.f0.backupcalltree.value='$donetree';">

</div>
$inlinescripts
$hiddenfields
</form>
 </td>
</tr>
</table>
EOF

   return $response;

}


# # # # # # # #
#
# $warnmsg = get_warnmsg($params, $hostinfo, $siteinfo, $backupdatafilename)
#
# Construct message warning about editing a backup file
#
# # # # # # # #

sub get_warnmsg {

   my ($params, $hostinfo, $siteinfo, $backupdatafilename) = @_;

   my $fileinfo = $siteinfo->{files}->{$backupdatafilename};

   my $currentauthor = $hostinfo->{sites}->{$params->{sitename}}->{authoronhost};
   if ($hostinfo->{sites}->{$params->{sitename}}->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $currentauthor = $params->{loggedinusername};
      }

   my ($othereditors, $editstatus); # find out if it's being edited and by whom
   foreach my $author (sort keys %{$fileinfo->{authors}}) {
      if ($author ne $currentauthor) { # not us
         $othereditors++;
         }
      else {
         $editstatus = $fileinfo->{authors}->{$author}->{editstatus};
         }
      }

   my $warnmsg;
   if ($editstatus eq "modified") { # this author is in the middle of editing it
      $warnmsg = "$WKCStrings{backupwarning1} '$backupdatafilename'.";
      $warnmsg .= " $WKCStrings{backupwarning2} '";
      }
   elsif ($editstatus eq 1) {
      $warnmsg = "$WKCStrings{backupwarning3a} '$backupdatafilename' $WKCStrings{backupwarning3b}.";
      $warnmsg .= " $WKCStrings{backupwarning4} '";
      }
   elsif ($othereditors) {
      $warnmsg = "$WKCStrings{backupwarning5} '$backupdatafilename'.";
      $warnmsg .= " $WKCStrings{backupwarning6}";
      $warnmsg .= " $WKCStrings{backupwarning7} '";
      }
   else {
      $warnmsg = " $WKCStrings{backupwarning8a} '$backupdatafilename' $WKCStrings{backupwarning8b} '";
      }

   return $warnmsg;

   }

