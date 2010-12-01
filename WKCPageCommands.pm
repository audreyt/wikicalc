#
# WKCPageCommands.pl -- Commands to choose page to edit, etc.
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCPageCommands;

   use strict;
   use CGI qw(:standard);
   use utf8;

   use WKCStrings;
   use WKC;
   use WKCDataFiles;
   use WKCSheet; # for special_chars
   use LWP::UserAgent;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(do_page_command);
   our $VERSION = '1.0.0';

#
# Locals
#

   my %a;


# Return something

   1;

# # # # # # # #
#
# $response = do_page_command(\%params, $user, \%userinfo, $hiddenfields)
#
# Do the stuff for the Page tab
#
# # # # # # # #

sub do_page_command {

   my ($params, $user, $userinfo, $hiddenfields) = @_;

   my $response;

   $params->{sitename} = "" if WKC::site_not_allowed($userinfo, $user, $params->{sitename}); # just in case

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td class="ttbody" width="100%">
EOF

   # Process any page commands

   if ($params->{dopageaddedithost} && $params->{loggedinadmin}) {
      my $str = do_pageaddedithost($params, $hiddenfields);
      if ($str) { # Error message
         $params->{errormsg} = $str;
         $params->{subpagedoedithost} = "error";
         }
      else {
         if ($params->{pagemode} eq "changesite") {
            $params->{subpageaddsite} = "added new";
            }
         elsif ($params->{pagemode} eq "managesite") {
            $params->{subpageaddsite} = "added new";
            }
         elsif ($params->{pagemode} eq "managehost") {
            $params->{subpagemanagehosts} = "added or edited";
            }
         else {
            $params->{errormsg} = $WKCStrings{"pagemissingpagemode"};
            $params->{subpagemanagehosts} = "added new";
            }
         }
      }

   if ($params->{dopageaddsite} && $params->{loggedinadmin}) {
      my $str = do_pageaddsite($params, $hiddenfields);
      if ($str) { # Error message
         $params->{errormsg} = $str;
         $params->{subpageaddsite2} = "added new";
         }
      else {
         if ($params->{pagemode} eq "changesite") {
            $params->{subpagechangesite} = "added new";
            }
         elsif ($params->{pagemode} eq "managesite") {
            $params->{subpagemanagesites} = "added new";
            }
         else {
            $params->{errormsg} = $WKCStrings{"pagemissingpagemode"};
            $params->{subpageaddsite2} = "added new";
            }
         }
      }

   if ($params->{dopageaddpage}) {
      my $str;
      $str = do_pageaddpage($params, $hiddenfields) unless WKC::site_not_allowed($userinfo, $user, $params->{sitename});
      if ($str) { # Error message
         $params->{errormsg} = <<"EOF";
<div class="sectionerror">
$str<br>
$WKCStrings{"pagecreatedlocalonly"}<br><br>
</div>
EOF
         $params->{subpageaddpage} = "error";
         }
      else {
         $params->{datafilename} = $params->{editpagename};
         $params->{etpurl} = "";
         $params->{editcoords} = "";
         delete $params->{scrollrow};
         }
      }

   if ($params->{dopagesiteedit} && $params->{loggedinadmin}) {
      my $str = do_pagesiteedit($params, $hiddenfields);
      if ($str) { # Error message
         $params->{errormsg} = $str;
         $params->{subpagedoeditsite} = "error";
         }
      else {
         $params->{subpagemanagesites} = "updated";
         }
      }



   foreach my $p (keys %{$params}) {  # go through all the parameters

      if ($p =~ /^subpageaddsite2:(.*)/) { # Choose host for new site
         $params->{subpageaddsite2} = 1;
         $params->{newhost} = $1;
         }

      elsif ($p =~ /^dochoosesite:(.*)/) { # Choose new site to edit
         $params->{subdochoosesite} = 1;
         $params->{newsite} = $1;
         }

      elsif ($p =~ /^doeditsite:(.*)/) { # Choose site to edit description of
         $params->{subpagedoeditsite} = 1;
         $params->{managedsite} = $1;
         }

      elsif ($p =~ /^docopysite:(.*)/) { # Choose site to edit a copy of and then create
         $params->{subpagedocopysite} = 1;
         $params->{managedsite} = $1;
         }

      elsif (($p =~ /^dodeletesite:(.*)/) && $params->{loggedinadmin}) { # Choose site delete
         $params->{managedsite} = $1;
         my $str = do_pagedeletesite($params, $hiddenfields);
         $hiddenfields = WKC::update_hiddenfields($params, $hiddenfields); # in case deleted current site
         $params->{subpagemanagesites} = "manage";
         if ($str) { # Error message
            $params->{errormsg} = $str;
            }
         }
      elsif ($p =~ /^doedithost:(.*)/) { # Choose host to edit description of
         $params->{subpagedoedithost} = 1;
         $params->{managedhost} = $1;
         }

      elsif ($p =~ /^docopyhost:(.*)/) { # Choose host to edit a copy of and then create
         $params->{subpagedocopyhost} = 1;
         $params->{managedhost} = $1;
         }

      elsif (($p =~ /^dodeletehost:(.*)/) && $params->{loggedinadmin}) { # Choose host delete
         $params->{managedhost} = $1;
         my $str = do_pagedeletehost($params, $hiddenfields);
         $params->{subpagemanagehosts} = "manage";
         if ($str) { # Error message
            $params->{errormsg} = $str;
            }
         }
      }

   # Display appropriate main part of the screen

   if ($params->{subpagechangesite}) {
      $response .= compose_pagechangesite($params, $user, $userinfo, $hiddenfields);
      }

   elsif ($params->{subdochoosesite}) {
      $response .= compose_pagedochoosesite($params, $user, $userinfo, $hiddenfields);
      }

   elsif ($params->{subpageaddsite} && $params->{loggedinadmin}) {
      $response .= compose_pageaddsite($params, $hiddenfields);
      }

   elsif ($params->{subpageaddsite2}&& $params->{loggedinadmin}) {
      $response .= compose_pageaddsite2($params, $hiddenfields);
      }

   elsif ($params->{subpagemanagesites} && $params->{loggedinadmin}) {
      $response .= compose_pagemanagesites($params, $hiddenfields);
      }

   elsif ($params->{subpagedoeditsite} && $params->{loggedinadmin}) {
      $response .= compose_pageeditsite($params, $hiddenfields, 0); # copysite is false
      }

   elsif ($params->{subpagedocopysite} && $params->{loggedinadmin}) {
      $response .= compose_pageeditsite($params, $hiddenfields, 1); # copysite is true
      }

   elsif (($params->{subpageaddhost} || $params->{subpageaddmanagedhost}) && $params->{loggedinadmin}) {
      $response .= compose_pageaddhost($params, $hiddenfields);
      }

   elsif ($params->{subpagemanagehosts} && $params->{loggedinadmin}) {
      $response .= compose_pagemanagehosts($params, $hiddenfields);
      }

   elsif ($params->{subpagedoedithost} && $params->{loggedinadmin}) {
      $response .= compose_pageedithost($params, $hiddenfields, 0); # copyhost is false
      }

   elsif ($params->{subpagedocopyhost} && $params->{loggedinadmin}) {
      $response .= compose_pageedithost($params, $hiddenfields, 1); # copyhost is true
      }

   elsif ($params->{subpageaddpage}) {
      $response .= compose_pageaddpage($params, $user, $userinfo, $hiddenfields);
      }

   elsif ($params->{subpagedemosetup} && $params->{loggedinadmin}) {
      $response .= compose_pagedemosetup($params, $hiddenfields);
      }

   else {
      $response .= compose_pagetop($params, $user, $userinfo, $hiddenfields);
      }

   $response .= <<"EOF";
</td></tr>
</table>
EOF

   return $response;

}

# # # # # # # #
#
# $response = compose_pagetop(\%params, $user, \%userinfo, $hiddenfields)
#
# Do the main part for the top level list of pages to choose from
#
# # # # # # # #

sub compose_pagetop {

   my ($params, $user, $userinfo, $hiddenfields) = @_;

   my $response;

   my $hostsinfo = get_hostinfo($params);

   if ((keys %{$hostsinfo->{sites}})==0 && (keys %{$hostsinfo->{hosts}})==0) { # Nothing yet -- prompt to create something
      $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"pagewelcometitle"}</div>
<div class="pagetitledesc">
$WKCStrings{"pagewelcomedesc"}
</div>
</div>

<form name="f0" method="POST">
$params->{promptlevelspacing}
<div class="sectionoutlined">
<div class="title">$WKCStrings{"pagedemonstrationsetuptitle"}</div>
<div class="desc">
$WKCStrings{"pagedemonstrationsetupdesc"}
</div>
<input class="smaller" type="submit" name="subpagedemosetup" value="$WKCStrings{"pagedemosetup"}"><br>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"pagemanualsetuptitle"}</div>
<div class="desc">
$WKCStrings{"pagemanualsetupdesc"}</div>
<input class="smaller" type="submit" name="subpagechangesite" value="$WKCStrings{"pagemanualsetup"}">
</div>

$hiddenfields
</form>
$params->{promptlevelspacing}
EOF

      return $response;
      }

   my $sitename = $params->{sitename};

   if (!$sitename) { # No site set -- see if only one to choose from and assume that
      my $siteshash = $hostsinfo->{sites};
      if ((scalar keys %$siteshash) == 1) { # only one site
         $sitename = (keys %$siteshash)[0];
         if (WKC::site_not_allowed($userinfo, $user, $sitename)) { # only if allowed
            $sitename = "";
            }
         else {
            $params->{sitename} = $sitename;
            $hiddenfields = WKC::update_hiddenfields($params, $hiddenfields);
            }
         }
      }

   if (!$sitename) { # No site set -- prompt to get one
      $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"pagetoppagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pagetoppagedesc"}</div>
</div>

<form name="f0" method="POST">
$params->{promptlevelspacing}
<div class="sectionoutlined">
<div class="title">$WKCStrings{"pagenositesettitle"}
</div>
<div class="desc">
$WKCStrings{"pagenositesetdesc"}
</div>
<input class="smaller" type="submit" name="subpagechangesite" value="$WKCStrings{"pagechoose"}">
</div>

$hiddenfields
</form>
$params->{promptlevelspacing}
EOF

      return $response;
      }

   my $pagemessage;
   if ($params->{pagemessage}) { # Success/failure of delete, etc.
      $pagemessage = <<"EOF";
<div class="sectionerror">
$params->{pagemessage}
</div>
EOF
      }

   my ($editdisplayed, $viewdisplayed, $otherdisplayed, $editchecked, $viewchecked, $otherchecked);
   if ($params->{pagebuttons} eq "Other") {
      $editdisplayed = " style='display:none;'";
      $viewdisplayed = " style='display:none;'";
      $otherchecked = " CHECKED";
      }
   elsif ($params->{pagebuttons} eq "View") {
      $editdisplayed = " style='display:none;'";
      $otherdisplayed = " style='display:none;'";
      $viewchecked = " CHECKED";
      }
   else {
      $otherdisplayed = " style='display:none;'";
      $viewdisplayed = " style='display:none;'";
      $editchecked = " CHECKED";
      }

   my $htmlurl = $hostsinfo->{sites}->{$sitename}->{htmlurl};
   my $editurl = $hostsinfo->{sites}->{$sitename}->{editurl};

   my $longsitename = special_chars($hostsinfo->{sites}->{$sitename}->{longname});

   my $siteinfo = get_siteinfo($params);

   if ($params->{reloadftp}) { # Get up to date info from server
      $siteinfo->{ftpdatetime} = "";
      }

   my $currentauthor = $hostsinfo->{sites}->{$params->{sitename}}->{authoronhost};
   if ($hostsinfo->{sites}->{$params->{sitename}}->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $currentauthor = $params->{loggedinusername};
      }

   my $ok = update_siteinfo($params, $hostsinfo, $siteinfo);

   if ($siteinfo->{updates}) {
      $ok = save_siteinfo($params, $siteinfo);
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagetitle">$WKCStrings{"pagetoppagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pagetoppagedesc"}</div>
</div>

<form name="fdatafile" method="POST">

<script>
function multieditwarn(pn) {
return(confirm("$WKCStrings{"pagelistmultieditprompt1"}"+pn+"$WKCStrings{"pagelistmultieditprompt2"}"))
}

function set_display(dtype, newval) {
var itable = document.getElementsByTagName("input");
var iid;
for (var i=0; i<itable.length; i++) {
 iid = itable[i].id;
 if (iid.match("^"+dtype+"-")) {
  itable[i].style.display = newval;
  }
 }
}
</script>

<div class="sectionplain">
<div class="title">$WKCStrings{"pagelisttitle"}$longsitename ($params->{sitename})</div>
<div class="pagefilename">$WKCStrings{"pagelistuser"}$currentauthor</div>
$pagemessage
<table cellspacing="3">
<tr>
 <td colspan="6" style="padding-bottom:6px;">
  <input class="smaller" type="radio" name="pagebuttons" value="Edit" onclick="set_display('view','none');set_display('del','none');set_display('ab','none');set_display('edit','inline');"$editchecked><span class="smaller">$WKCStrings{"pageeditbuttons"}&nbsp;</span>
  <input class="smaller" type="radio" name="pagebuttons" value="View" onclick="set_display('edit','none');set_display('del','none');set_display('ab','none');set_display('view','inline');"$viewchecked><span class="smaller">$WKCStrings{"pageviewonwebbuttons"}&nbsp;</span>
  <input class="smaller" type="radio" name="pagebuttons" value="Other" onclick="set_display('edit','none');set_display('view','none');set_display('del','inline');set_display('ab','inline');"$otherchecked><span class="smaller">$WKCStrings{"pagedelabandonbuttons"}</span>
 </td>
</tr>
<tr>
<td>&nbsp;</td>
<td class="browsecolumnhead">$WKCStrings{"pagelistcolfilename"}</td>
<td class="browsecolumnhead">$WKCStrings{"pagelistcolfullname"}</td>
<td class="browsecolumnhead">$WKCStrings{"pagelistcoleditstatus"}</td>
<td class="browsecolumnhead">$WKCStrings{"pagelistcolpublishstatus"}</td>
<td>&nbsp;</td>
</tr>
EOF

   foreach my $name (sort keys %{$siteinfo->{files}}) { # List each file, depending on edit/pub status
      my $fileinfo = $siteinfo->{files}->{$name};
      my $editstatus = $fileinfo->{authors}->{$currentauthor}->{editstatus};
      my ($otherbuttons, $textstylefilename, $textstylefullname, $textstyleeditstatus, $textstylepublishstatus,
          $fullname, $opentext);

      my ($othereditors, $othereditorsstr);
      foreach my $author (sort keys %{$fileinfo->{authors}}) {
         if ($author ne $currentauthor) { # not us
            $othereditors .= "$author, ";
            }
         }

      if ($name eq $params->{datafilename} && $editstatus) { # page currently being edited (shown by param and status in case param is wrong)
         $response .= qq!<tr><td class="browsebuttoncellediting"><input id="edit-$name" class="smaller" type="submit" name="choosepagelocal:$name" value="$WKCStrings{"pagelistedit"}"$editdisplayed>&nbsp;!;
         $textstylefilename = "browsepageediting3";
         $textstylefullname = "browsepageediting";
         $textstyleeditstatus = "browsepageediting2";
         $textstylepublishstatus = "browsepagedim";
         $fullname = $fileinfo->{authors}->{$currentauthor}->{fullnameedit};
         $opentext = $WKCStrings{"pagelistcurrentedit"};
         }
      else {
         if ($editstatus && $editstatus ne "remote") { # edit from local copy if already editing locally
            $response .= qq!<tr><td class="browsebuttoncell"><input id="edit-$name" class="smaller" type="submit" name="choosepagelocal:$name" value="$WKCStrings{"pagelistedit"}"$editdisplayed>&nbsp;!;
            $textstylefilename = "browsepagename";
            $textstylefullname = "browsepageavailable";
            $textstyleeditstatus = "browsepageavailable2";
            $textstylepublishstatus = "browsepagedim";
            $fullname = $fileinfo->{authors}->{$currentauthor}->{fullnameedit};
            $opentext = $WKCStrings{"pagelistopenforedit"};
            }
         else { # edit from copy on server
            my $multieditwarn = $othereditors ? qq! onClick="return multieditwarn('$name');"! : "";
            $response .= qq!<tr><td class="browsebuttoncell"><input id="edit-$name" class="smaller" type="submit" name="choosepagepub:$name" value="$WKCStrings{"pagelistedit"}"$multieditwarn$editdisplayed>&nbsp;!;
            $textstylefilename = "browsepagename";
            $textstylefullname = "browsepageavailable";
            $textstyleeditstatus = "browsepagedim";
            $textstylepublishstatus = "browsepageavailable2";
            $fullname = $fileinfo->{fullnamepublished};
            }
         }

      if ($editstatus && $fileinfo->{pubstatus}) { # can delete or abandon if editing a published page
         $otherbuttons .= <<"EOF";
<input id="del-$name" class="smaller" type="submit" name="choosepagedel:$name" value="$WKCStrings{"pagelistdelete"}"$otherdisplayed>
<input id="ab-$name" class="smaller" type="submit" name="choosepageabandon:$name" value="$WKCStrings{"pagelistabandonedit"}"$otherdisplayed>
EOF
         }
      else { # otherwise can only delete
         $otherbuttons .= <<"EOF";
<input id="del-$name" class="smaller" type="submit" name="choosepagedel:$name" value="$WKCStrings{"pagelistdelete"}"$otherdisplayed>
EOF
         }

      if ($fileinfo->{pubstatus}) { # can view website if published page
         if ($htmlurl) {
            $otherbuttons .= <<"EOF";
<input id="view-$name" type="submit" class="smaller" value="View HTML" onclick="location.href='$htmlurl/$name.html';return false;"$viewdisplayed>
EOF
            }
         if ($editurl) {
            $otherbuttons .= <<"EOF";
<input id="view-$name" type="submit" class="smaller" value="View Live" onclick="location.href='$editurl?view=$params->{sitename}/$name';return false;"$viewdisplayed>
EOF
            }
         if (!$htmlurl && !$editurl) {
            $otherbuttons .= <<"EOF";
<input id="view-$name" type="submit" class="smaller" value="No URL for HTML or Edit"$viewdisplayed disabled>
EOF
            }
         }

      if ($editstatus eq "modified") {
         $response .= qq!<input id="edit-$name" class="smaller" type="submit" name="publishfrompage:$name" value="$WKCStrings{"pagelistpublish"}"$editdisplayed>$otherbuttons&nbsp;</td>!;
         }
      else {
         $response .= qq!$otherbuttons</td>!;
         }

      $fullname = special_chars($fullname);
      $response .= <<"EOF";
<td class="$textstylefilename">$fileinfo->{filename}</td>
<td class="$textstylefullname">$fullname</td>
EOF
      if ($editstatus eq "modified") {
         my $dtmstr = $fileinfo->{authors}->{$currentauthor}->{dtmedit};
         $dtmstr =~ s/ /&nbsp;/g;
         $response .= <<"EOF";
<td class="$textstyleeditstatus"><b><i>$opentext</i></b><br>$WKCStrings{"pagelistlastmod"} $dtmstr</td>
EOF
         }
      elsif ($editstatus) {
         $response .= <<"EOF";
<td class="$textstyleeditstatus"><b><i>$opentext</i></b><br>$WKCStrings{"pagelistunchanged"}</span></td>
EOF
         }
      else {
         $response .= <<"EOF";
<td class="$textstyleeditstatus"><i>$WKCStrings{"pagelistnotediting"}</i></span></td>
EOF
         }

      if ($fileinfo->{pubstatus} || $othereditors) {          
         my $dtmstr = $fileinfo->{dtmpublished} || $WKCStrings{"pagelistnotpublished"};
         if ($othereditors) {
            $othereditors =~ s/, $//;
            $othereditorsstr = <<"EOF";
<br><b>$WKCStrings{"pagelisteditedby"}</b> $othereditors
EOF
            }
         $dtmstr =~ s/ /&nbsp;/g;
         $response .= <<"EOF";
<td class="$textstylepublishstatus">$WKCStrings{"pagelistpublished"} $dtmstr</span>$othereditorsstr</td>
EOF
         }
      else {
         $response .= <<"EOF";
<td class="$textstylepublishstatus"><i>[$WKCStrings{"pagelistnotpublishedshort"}]</i></td>
EOF
         }


      $response .= <<"EOF";
</tr>
EOF
      }

   $response .= <<"EOF";
<tr>
<td colspan="4">&nbsp;</td>
<td class="browsereconcile">
<div class="smaller">
<b>$WKCStrings{"pagelistlastreconciled"}$siteinfo->{ftpdatetime}</b>
</div>
<div style="padding-top:4pt;">
<input class="smaller" type="submit" name="reloadftp" value="$WKCStrings{"pagelistreload"}">
</div>
</td>
</tr>
</table>
<br>
<input type="submit" name="subpageaddpage" value="$WKCStrings{"pagelistcreatenewpage"}">
EOF
   $response .= <<"EOF" if $params->{loggedinadmin};
<input type="submit" name="subpagemanagesites" value="$WKCStrings{"pagelistmanagesites"}">
<input type="submit" name="subpagemanagehosts" value="$WKCStrings{"pagelistmanagehosts"}">
EOF
   $response .= <<"EOF";
</div>

$params->{promptlevelspacing}
<div class="sectionoutlined">
<div class="title">$WKCStrings{"pagelisteditingsitetitle"}: $longsitename ($sitename)
</div>
<div class="desc">
$WKCStrings{"pagelisteditingsitedesc"}
</div>
<input class="smaller" type="submit" name="subpagechangesite" value="$WKCStrings{"pagelistchangesite"}">
</div>
<br>
$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pagechangesite(\%params, $user, %\userinfo, $hiddenfields)
#
# Do the main part for the list of sites to choose from
#
# # # # # # # #

sub compose_pagechangesite {

   my ($params, $user, $userinfo, $hiddenfields) = @_;

   my $response;

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"pagechangesitebreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"pagechangesitepagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pagechangesitepagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}

<div class="sectionplain">
<table>
<tr>
<td>&nbsp;</td>
<td class="browsecolumnhead">SITE&nbsp;</td>
<td class="browsecolumnhead">&nbsp;</td>
<td class="browsecolumnhead">HOST&nbsp;</td>
<td class="browsecolumnhead">NAME&nbsp;ON&nbsp;HOST&nbsp;</td>
<td class="browsecolumnhead">HTML&nbsp;PATH&nbsp;</td>
</tr>
EOF

   my $hostinfo = get_hostinfo($params);

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      next if WKC::site_not_allowed($userinfo, $user, $sitename);
      my $longname = special_chars($hostinfo->{sites}->{$sitename}->{longname});
      my $htmlpath = special_chars($hostinfo->{sites}->{$sitename}->{htmlpath});
      if ($sitename eq $params->{sitename}) {
         $response .= <<"EOF";
<tr>
 <td class="browsebuttoncellediting">&nbsp;</td>
 <td class="browsepageediting">$sitename&nbsp;</td>
 <td class="browsepageediting2">$longname</td>
 <td class="browsepageediting2">$hostinfo->{sites}->{$sitename}->{host}</td>
 <td class="browsepageediting2">$hostinfo->{sites}->{$sitename}->{nameonhost}</td>
 <td class="browsepageediting2">$htmlpath</td>
</tr>
EOF
         }
      else {
         $response .= <<"EOF";
<tr>
 <td class="browsebuttoncell">
  <input class="smaller" type="submit" name="dochoosesite:$sitename" value="Select">
 </td>
 <td class="browsepageavailable">$sitename&nbsp;</td>
 <td class="browsenormal">$longname</td>
 <td class="browsenormal">$hostinfo->{sites}->{$sitename}->{host}</td>
 <td class="browsenormal">$hostinfo->{sites}->{$sitename}->{nameonhost}</td>
 <td class="browsenormal">$htmlpath</td>
</tr>
EOF
         }
      }

   $response .= <<"EOF";
</table>
</div>
EOF
   $response .= <<"EOF" if $params->{loggedinadmin};
$params->{promptlevelspacing}
<div class="sectionoutlined">
<input class="smaller" type="submit" name="subpageaddsite" value="$WKCStrings{"pageadd"}">
<input type="hidden" name="pagemode" value="changesite">
</div>
EOF
   $response .= <<"EOF";
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="pagechangesitecancel" value="$WKCStrings{"pagecancel"}">
</div>

$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pagedochoosesite(\%params, $user, \%userinfo, $hiddenfields)
#
# Do the actual choosing, checking, etc.
#
# # # # # # # #

sub compose_pagedochoosesite {

   my ($params, $user, $userinfo, $hiddenfields) = @_;

   my $newsite = $params->{newsite};

   my $response;

   my $hostinfo = get_hostinfo($params);

   if (!$hostinfo->{sites}->{$newsite}) {
      $response .= <<"EOF";
Site "$newsite" has not been defined.
<br>
EOF
      return $response;
      }

   $params->{sitename} = $newsite;
   $params->{datafilename} = "";

   $params->{sitename} = "" if WKC::site_not_allowed($userinfo, $user, $params->{sitename});

   $hiddenfields = WKC::update_hiddenfields($params, $hiddenfields);

   check_site_exists($params, $hostinfo, $newsite) if $params->{sitename};

   $response .= compose_pagetop($params, $user, $userinfo, $hiddenfields);

   return $response;

}


# # # # # # # #
#
# $response = compose_pageaddsite(\%params, $hiddenfields)
#
# Do the first main part for adding another site to the list -- choosing the host
#
# # # # # # # #

sub compose_pageaddsite {

   my ($params, $hiddenfields) = @_;

   my $response;

   my ($pagebreadcrumbs, $cancelname);

   if ($params->{pagemode} eq "changesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddsitechangebreadcrumbs"};
      $cancelname = "subpagechangesite";
      }
   elsif ($params->{pagemode} eq "managesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddsitemanagebreadcrumbs"};
      $cancelname = "subpagemanagesites";
      }
   else {
      $pagebreadcrumbs = "Error: missing pagemode";
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$pagebreadcrumbs</div>
<div class="pagetitle">$WKCStrings{"pageaddsitepagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pageaddsitepagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}

<div class="sectionplain">
<table>
<tr>
<td>&nbsp;</td>
<td class="browsecolumnhead">HOST&nbsp;</td>
<td class="browsecolumnhead">&nbsp;</td>
<td class="browsecolumnhead">URL&nbsp;</td>
</tr>
EOF

   my $hostinfo = get_hostinfo($params);

   foreach my $hostname (sort keys %{$hostinfo->{hosts}}) {
      my $longname = special_chars($hostinfo->{hosts}->{$hostname}->{longname});
      my $url = special_chars($hostinfo->{hosts}->{$hostname}->{url});
      $response .= <<"EOF";
<tr>
 <td class="browsebuttoncell">
  <input class="smaller" type="submit" name="subpageaddsite2:$hostname" value="Select">
 </td>
 <td class="browsepageavailable">$hostname&nbsp;</td>
 <td class="browsenormal">$longname</td>
 <td class="browsenormal">$url</td>
</tr>
EOF
      }

   $response .= <<"EOF";
</table>
</div>
$params->{promptlevelspacing}
<div class="sectionoutlined">
<input type="submit" name="subpageaddhost" value="$WKCStrings{"pageaddhost"}">
</div>
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="$cancelname" value="$WKCStrings{"pagecancel"}">
</div>

<input type="hidden" name="pagemode" value="$params->{pagemode}">
$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pageaddsite2(\%params, $hiddenfields)
#
# Do the second main part for adding another site to the list -- get the info
#
# # # # # # # #

sub compose_pageaddsite2 {

   my ($params, $hiddenfields) = @_;

   my $response;

   my $pagebreadcrumbs;

   if ($params->{pagemode} eq "changesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddsite2changebreadcrumbs"};
      }
   elsif ($params->{pagemode} eq "managesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddsite2managebreadcrumbs"};
      }
   else {
      $pagebreadcrumbs = "Error: missing pagemode";
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$pagebreadcrumbs</div>
<div class="pagetitle">$WKCStrings{"pageaddsite2pagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pageaddsite2pagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="title">$WKCStrings{"pageaddsite2valuestitle"}$params->{newhost}</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"pageaddsite2sitename"}</div>
<input name="editsitename" type="text" size="32" maxlength="32" value="">
<div class="desc">$WKCStrings{"pageaddsite2sitenamedesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2sitelongname"}</div>
<input name="editlongname" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2sitelongnamedesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2sitenameonhost"}</div>
<input name="editnameonhost" type="text" size="32" value="">
<div class="desc">$WKCStrings{"pageaddsite2sitenameonhostdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2authornameonhost"}</div>
<input name="editauthoronhost" type="text" size="32" value="">
<div class="desc">$WKCStrings{"pageaddsite2authornameonhostdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2authorfromlogin"}</div>
<input name="editauthorfromlogin" type="radio" value="yes"><span class="smaller">$WKCStrings{"pageauthorfromloginyes"}</span>
<input name="editauthorfromlogin" type="radio" value="no" CHECKED><span class="smaller">$WKCStrings{"pageauthorfromloginno"}</span>
<div class="desc">$WKCStrings{"pageaddsite2authorfromlogindesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2htmlpath"}</div>
<input name="edithtmlpath" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2htmlpathdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2htmlurl"}</div>
<input name="edithtmlurl" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2htmlurldesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2editurl"}</div>
<input name="editediturl" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2editurldesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2publishrss"}</div>
<div style="margin-bottom:6px;"><input name="editpublishrss" type="checkbox" value="yes"><span class="smaller">$WKCStrings{"pageaddsite2publishrsstag"}</span></div>
<div class="desc">$WKCStrings{"pageaddsite2publishrssdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rssmaxitems"}</div>
<div style="margin-bottom:6px;">
<select name="editrssmaxsiteitems" size="1">
<option value="1">1
<option value="2">2
<option value="3">3
<option value="4">4
<option value="5">5
<option value="6">6
<option value="7">7
<option value="8">8
<option value="9">9
<option value="10" SELECTED>10
<option value="11">11
<option value="12">12
<option value="13">13
<option value="14">14
<option value="15">15
</select>
<span class="smaller">$WKCStrings{"pageaddsite2rssmaxitemssite"}</span>&nbsp;
<select name="editrssmaxpageitems" size="1">
<option value="1">1
<option value="2">2
<option value="3">3
<option value="4">4
<option value="5">5
<option value="6">6
<option value="7">7
<option value="8">8
<option value="9">9
<option value="10" SELECTED>10
<option value="11">11
<option value="12">12
<option value="13">13
<option value="14">14
<option value="15">15
</select>
<span class="smaller">$WKCStrings{"pageaddsite2rssmaxitemspage"}</span>
</div>
<div class="desc">$WKCStrings{"pageaddsite2rssmaxitemsdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsstitle"}</div>
<input name="editrsstitle" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2rsstitledesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsslink"}</div>
<input name="editrsslink" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2rsslinkdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rssdescription"}</div>
<input name="editrssdescription" type="text" size="60" value="">
<div class="desc">$WKCStrings{"pageaddsite2rssdescriptiondesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsschannelxml"}</div>
<textarea name="editrsschannelxml" rows="3" cols="55" wrap="virtual"></textarea>
<div class="desc">$WKCStrings{"pageaddsite2rsschannelxmldesc"}</div>


<input type="hidden" name="newhost" value="$params->{newhost}">

<input type="submit" name="dopageaddsite" value="$WKCStrings{"pageaddsite2save"}">
</div>
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="subpageaddsite" value="$WKCStrings{"pagecancel"}">
</div>

<input type="hidden" name="pagemode" value="$params->{pagemode}">
$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pagemanagesites(\%params, $hiddenfields)
#
# Do the main part for listing sites and their attributes for management
#
# # # # # # # #

sub compose_pagemanagesites {

   my ($params, $hiddenfields) = @_;

   my $response;

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"pagemanagesitebreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"pagemanagesitepagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pagemanagesitepagedesc"}</div>
</div>

<form name="f0" method="POST">

<div class="sectionplain">
<table>
<tr><td></td><td></td>
<td class="browsebuttons">
<input class="smaller" type="submit" name="pagemanagesitedone2" value="$WKCStrings{"pagedone"}">
</td></tr>
<tr>
<td class="browsecolumnhead">$WKCStrings{"pagemanagesitecolhead"}&nbsp;</td>
<td class="browsecolumnhead">$WKCStrings{"pagemanagesitecurrentsettingscolhead"}&nbsp;</td>
<td>&nbsp;</td>
</tr>
EOF

   my $hostinfo = get_hostinfo($params);

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      my $siteinfo = $hostinfo->{sites}->{$sitename};
      my $longname = special_chars($siteinfo->{longname});
      my $hostlongname = special_chars($hostinfo->{hosts}->{$siteinfo->{host}}->{longname});
      my $hostauthorfromlogin = $siteinfo->{authorfromlogin} eq "yes" ? $WKCStrings{"pageauthorfromloginyes"} : $WKCStrings{"pageauthorfromloginno"};
      my $htmlpath = special_chars($siteinfo->{htmlpath});
      my $htmlurl = special_chars($siteinfo->{htmlurl});
      my $editurl = special_chars($siteinfo->{editurl});
      my $rssmaxsiteitems = $siteinfo->{rssmaxsiteitems} || 10;
      my $rssmaxpageitems = $siteinfo->{rssmaxpageitems} || 10;
      my $rsstitle = special_chars($siteinfo->{rsstitle});
      my $rsslink = special_chars($siteinfo->{rsslink});
      my $rssdescription = special_chars($siteinfo->{rssdescription});
      my $rsschannelxml = special_chars($siteinfo->{rsschannelxml});

      my $hostchecked = $siteinfo->{checked} ? $WKCStrings{"pagemanagesiteyes"} : $WKCStrings{"pagemanagesiteno"};

      my $currentsitename = $params->{sitename}; # save
      $params->{sitename} = $sitename; # temporarily use this instead

      my $siteinfofile = get_siteinfo($params);

      my $ok = update_siteinfo($params, $hostinfo, $siteinfofile);

      if ($siteinfofile->{updates}) {
         $ok = save_siteinfo($params, $siteinfofile);
         }

      $params->{sitename} = $currentsitename; # restore name

      my ($nfiles, $npublished, $estring, $rstring);
      $npublished = 0;
      foreach my $name (sort keys %{$siteinfofile->{files}}) {
         $nfiles++;
         $npublished++ if $siteinfofile->{files}->{$name}->{pubstatus};
         }
      if ($nfiles) {
         $estring = qq!<tr><td class="browsepageavailable3">$WKCStrings{pagemanagesitepages}:</td><td class="browsepageavailable2">!;
         $estring .= "$nfiles $WKCStrings{pagemanagesitetotal}, ";
         $estring .= "$npublished $WKCStrings{pagemanagesitepublished}</td></tr>";
         }
      else {
         $estring = qq!<tr><td class="browsepageavailable3">$WKCStrings{pagemanagesitepages}:</td><td class="browsepageavailable2">$WKCStrings{pagemanagesitenopagesyet}</td></tr>!;
         }

      if ($siteinfofile->{ftpdatetime}) {
         $rstring = "$WKCStrings{pagemanagesitestatuslastrec} $siteinfofile->{ftpdatetime}";
         }
      else {
         $rstring = "<i>$WKCStrings{pagemanagesitestatusnotrec}</i>";
         }

      $response .= <<"EOF";
<tr>
 <td class="browsepagemedium">$sitename&nbsp;</td>
 <td class="browsepageavailable1">
  <table cellspacing="0" cellpadding="0">
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitelongname"}</td><td class="browsepageavailable">$longname</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitehost"}</td><td class="browsepageavailable2">$hostlongname ($siteinfo->{host})</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitesitenameonhost"}</td><td class="browsepageavailable2">$siteinfo->{nameonhost}</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiteauthornameonhost"}</td><td class="browsepageavailable2">$siteinfo->{authoronhost}</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiteauthorfromlogin"}</td><td class="browsepageavailable2">$hostauthorfromlogin</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitepathforhtml"}</td><td class="browsepageavailable2">$htmlpath</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiteurlforhtml"}</td><td class="browsepageavailable2">$htmlurl</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiteurlforediting"}</td><td class="browsepageavailable2">$editurl</td><tr>
EOF
      if ($siteinfo->{publishrss} eq "yes") {
         $response .= <<"EOF"
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitepublishrss"}</td><td class="browsepageavailable2">$WKCStrings{"pagemanagesitepubrssyes"}</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiterssmaxitems"}</td><td class="browsepageavailable2">$WKCStrings{"pageaddsite2rssmaxitemssite"}: $rssmaxsiteitems, $WKCStrings{"pageaddsite2rssmaxitemspage"}: $rssmaxpageitems</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiterssfeedtitle"}</td><td class="browsepageavailable2">$rsstitle</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitersssitefeedlinkurl"}</td><td class="browsepageavailable2">$rsslink</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitersssitefeeddesc"}</td><td class="browsepageavailable2">$rssdescription</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiterssaddlxml"}</td><td class="browsepageavailable2">$rsschannelxml</td><tr>
EOF
         }
      else {
         $response .= <<"EOF"
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitepublishrss"}</td><td class="browsepageavailable2">$WKCStrings{"pagemanagesitepubrssno"}</td><tr>
EOF
         }
      $response .= <<"EOF";
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesitehostchecked"}</td><td class="browsepageavailable2">$hostchecked</td><tr>
   $estring
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagesiteloaded"}</td>
       <td class="browsepageavailable2">$rstring</td></tr>
  </table>
 </td>
 <td class="browsebuttons" valign="top">
  <input class="smaller" type="submit" name="doeditsite:$sitename" value="$WKCStrings{"pagemanagesiteedit"}">
  <input class="smaller" type="submit" name="docopysite:$sitename" value="$WKCStrings{"pagemanagesitecopy"}">
  <input class="smaller" type="submit" name="dodeletesite:$sitename" value="$WKCStrings{"pagemanagesitedelete"}" onClick="return checkdelete('$sitename');">
 </td>
</tr>
EOF
      }

   $response .= <<"EOF";
<tr>
 <td>
 </td>
 <td>
 </td>
 <td class="browsebuttons">
  <input class="smaller" type="submit" name="subpageaddsite" value="$WKCStrings{"pagemanagesiteadd"}">
  <input type="hidden" name="pagemode" value="managesite">
 </td>
</tr>
</table>
</div>
<div class="sectionplain">
<input type="submit" name="pagemanagesitedonel" value="$WKCStrings{"pagedone"}">
</div>

$hiddenfields
</form>
<script>
function checkdelete(sn) {
return(confirm("$WKCStrings{"pagemanagesitedeleteprompt1"}"+sn+"$WKCStrings{"pagemanagesitedeleteprompt2"}"))
}
</script>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pageeditsite(\%params, $hiddenfields)
#
# Do the second main part for editing the definition of a site
#
# # # # # # # #

sub compose_pageeditsite {

   my ($params, $hiddenfields, $copysite) = @_;

   my $response;

   my $hostinfo = get_hostinfo($params);
   my $siteinfo = $hostinfo->{sites}->{$params->{managedsite}};

   my $sitelongname = special_chars($siteinfo->{longname});
   my $sitehtmlpath = special_chars($siteinfo->{htmlpath});
   my $sitehtmlurl = special_chars($siteinfo->{htmlurl});
   my $siteediturl = special_chars($siteinfo->{editurl});
   my (%sitemaxsiteitemsselected, %sitemaxpageitemsselected);
   $sitemaxsiteitemsselected{$siteinfo->{rssmaxsiteitems} || 10} = " SELECTED";
   $sitemaxpageitemsselected{$siteinfo->{rssmaxpageitems} || 10} = " SELECTED";
   my $sitersstitle = special_chars($siteinfo->{rsstitle});
   my $sitersslink = special_chars($siteinfo->{rsslink});
   my $siterssdescription = special_chars($siteinfo->{rssdescription});
   my $sitersschannelxml = special_chars($siteinfo->{rsschannelxml});

   my $siteauthorfromloginyeschecked = $siteinfo->{authorfromlogin} eq "yes" ? " CHECKED" : "";
   my $siteauthorfromloginnochecked = $siteauthorfromloginyeschecked ? "" : " CHECKED";
   my $sitepublishrsschecked = $siteinfo->{publishrss} eq "yes" ? " CHECKED" : "";

   my ($pagetitle, $pagedesc, $editsitename);

   if ($copysite) { # Set up the stuff for editing a copy vs. editing this one
      $pagetitle = $WKCStrings{"pagesitecopypagetitle"};
      $pagedesc = $WKCStrings{"pagesitecopypagedesc"};
      $editsitename = <<"EOF";
<div class="title">$WKCStrings{"pageaddsite2sitename"}</div>
<input name="editsitename" type="text" size="32" maxlength="32" value="">
<div class="desc">$WKCStrings{"pageaddsite2sitenamedesc"}</div>
EOF
      }
   else {
      $pagetitle = $WKCStrings{"pagesiteeditpagetitle"};
      $pagedesc = $WKCStrings{"pagesiteeditpagedesc"};
      $editsitename = <<"EOF";
<input type="hidden" name="editsitename" value="$params->{managedsite}">
EOF
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"pagesiteeditbreadcrumbs"}</div>
<div class="pagetitle">$pagetitle$params->{managedsite}</div>
<div class="pagetitledesc">$pagedesc</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}
$editsitename
<div class="title">$WKCStrings{"pageaddsite2sitelongname"}</div>
<input name="editlongname" type="text" size="60" value="$sitelongname">
<div class="desc">$WKCStrings{"pageaddsite2sitelongnamedesc"}</div>
<div class="title">$WKCStrings{"pagesiteedithost"}</div>
<table cellspacing="0" cellpadding="0">
EOF

   foreach my $hostname (sort keys %{$hostinfo->{hosts}}) {
      my $longname = special_chars($hostinfo->{hosts}->{$hostname}->{longname});
      my $url = special_chars($hostinfo->{hosts}->{$hostname}->{url});
      my $namestyle = "browsenormal";
      my $hostchecked;
      if ($hostname eq $siteinfo->{host}) {
         $namestyle = "browsepagemedium";
         $hostchecked = " CHECKED";
         }
      $response .= <<"EOF";
<tr>
 <td class="browsenormal">
  <input class="smaller" type="radio" name="editsitehostradio" value="$hostname"$hostchecked>
 </td>
 <td class="$namestyle">$longname ($hostname)</td>
</tr>
EOF
      }

   $response .= <<"EOF";
</table>
<div class="desc">$WKCStrings{"pagesiteedithostdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2sitenameonhost"}</div>
<input name="editnameonhost" type="text" size="32" value="$siteinfo->{nameonhost}">
<div class="desc">$WKCStrings{"pageaddsite2sitenameonhostdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2authornameonhost"}</div>
<input name="editauthoronhost" type="text" size="32" value="$siteinfo->{authoronhost}">
<div class="desc">$WKCStrings{"pageaddsite2authornameonhostdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2authorfromlogin"}</div>
<input name="editauthorfromlogin" type="radio" value="yes"$siteauthorfromloginyeschecked><span class="smaller">$WKCStrings{"pageauthorfromloginyes"}</span>
<input name="editauthorfromlogin" type="radio" value="no"$siteauthorfromloginnochecked><span class="smaller">$WKCStrings{"pageauthorfromloginno"}</span>
<div class="desc">$WKCStrings{"pageaddsite2authorfromlogindesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2htmlpath"}</div>
<input name="edithtmlpath" type="text" size="60" value="$sitehtmlpath">
<div class="desc">$WKCStrings{"pageaddsite2htmlpathdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2htmlurl"}</div>
<input name="edithtmlurl" type="text" size="60" value="$sitehtmlurl">
<div class="desc">$WKCStrings{"pageaddsite2htmlurldesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2editurl"}</div>
<input name="editediturl" type="text" size="60" value="$siteediturl">
<div class="desc">$WKCStrings{"pageaddsite2editurldesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2publishrss"}</div>
<div style="margin-bottom:6px;"><input name="editpublishrss" type="checkbox" value="yes"$sitepublishrsschecked><span class="smaller">$WKCStrings{"pageaddsite2publishrsstag"}</span></div>
<div class="desc">$WKCStrings{"pageaddsite2publishrssdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rssmaxitems"}</div>
<div style="margin-bottom:6px;">
<select name="editrssmaxsiteitems" size="1">
<option value="1"$sitemaxsiteitemsselected{1}>1
<option value="2"$sitemaxsiteitemsselected{2}>2
<option value="3"$sitemaxsiteitemsselected{3}>3
<option value="4"$sitemaxsiteitemsselected{4}>4
<option value="5"$sitemaxsiteitemsselected{5}>5
<option value="6"$sitemaxsiteitemsselected{6}>6
<option value="7"$sitemaxsiteitemsselected{7}>7
<option value="8"$sitemaxsiteitemsselected{8}>8
<option value="9"$sitemaxsiteitemsselected{9}>9
<option value="10"$sitemaxsiteitemsselected{10}>10
<option value="10"$sitemaxsiteitemsselected{11}>11
<option value="10"$sitemaxsiteitemsselected{12}>12
<option value="10"$sitemaxsiteitemsselected{13}>13
<option value="10"$sitemaxsiteitemsselected{14}>14
<option value="10"$sitemaxsiteitemsselected{15}>15
</select>
<span class="smaller">$WKCStrings{"pageaddsite2rssmaxitemssite"}</span>&nbsp;
<select name="editrssmaxpageitems" size="1">
<option value="1"$sitemaxpageitemsselected{1}>1
<option value="2"$sitemaxpageitemsselected{2}>2
<option value="3"$sitemaxpageitemsselected{3}>3
<option value="4"$sitemaxpageitemsselected{4}>4
<option value="5"$sitemaxpageitemsselected{5}>5
<option value="6"$sitemaxpageitemsselected{6}>6
<option value="7"$sitemaxpageitemsselected{7}>7
<option value="8"$sitemaxpageitemsselected{8}>8
<option value="9"$sitemaxpageitemsselected{9}>9
<option value="10"$sitemaxpageitemsselected{10}>10
<option value="10"$sitemaxpageitemsselected{11}>11
<option value="10"$sitemaxpageitemsselected{12}>12
<option value="10"$sitemaxpageitemsselected{13}>13
<option value="10"$sitemaxpageitemsselected{14}>14
<option value="10"$sitemaxpageitemsselected{15}>15
</select>
<span class="smaller">$WKCStrings{"pageaddsite2rssmaxitemspage"}</span>
</div>
<div class="desc">$WKCStrings{"pageaddsite2rssmaxitemsdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsstitle"}</div>
<input name="editrsstitle" type="text" size="60" value="$sitersstitle">
<div class="desc">$WKCStrings{"pageaddsite2rsstitledesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsslink"}</div>
<input name="editrsslink" type="text" size="60" value="$sitersslink">
<div class="desc">$WKCStrings{"pageaddsite2rsslinkdesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rssdescription"}</div>
<input name="editrssdescription" type="text" size="60" value="$siterssdescription">
<div class="desc">$WKCStrings{"pageaddsite2rssdescriptiondesc"}</div>
<div class="title">$WKCStrings{"pageaddsite2rsschannelxml"}</div>
<textarea name="editrsschannelxml" rows="3" cols="55" wrap="virtual">$sitersschannelxml</textarea>
<div class="desc">$WKCStrings{"pageaddsite2rsschannelxmldesc"}</div>

<input type="hidden" name="creatingnewsite" value="$copysite">

<input type="submit" name="dopagesiteedit" value="$WKCStrings{"pagesiteeditsave"}">
</div>
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="subpagemanagesites" value="$WKCStrings{"pagecancel"}">
</div>

<input type="hidden" name="pagemode" value="$params->{pagemode}">
$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pageaddhost(\%params, $hiddenfields)
#
# Do the main part for adding another host to the list -- get the info
#
# # # # # # # #

sub compose_pageaddhost {

   my ($params, $hiddenfields) = @_;

   return compose_pageedithost($params, $hiddenfields, "new");

}

# # # # # # # #
#
# $response = compose_pageedithost(\%params, $hiddenfields, $copyhost)
#
# Do the main part for adding ($copyhost="new"), copying ($copyhost=1), or editing a host ($copyhost=0)
#
# # # # # # # #

sub compose_pageedithost {

   my ($params, $hiddenfields, $copyhost) = @_;

   $copyhost = $params->{copyhost} if exists $params->{copyhost};

   my $response;

   my ($pagebreadcrumbs, $cancelname);
   my ($hostlongname, $hosturl, $hostloginname, $hostloginpassword, $hostwkcpath);

   if ($params->{pagemode} eq "changesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddhostchangesitebreadcrumbs"};
      $cancelname = "subpageaddsite";
      }
   elsif ($params->{pagemode} eq "managesite") {
      $pagebreadcrumbs = $WKCStrings{"pageaddhostmanagesitebreadcrumbs"};
      $cancelname = "subpageaddsite";
      }
   elsif ($params->{pagemode} eq "managehost") {
      $pagebreadcrumbs = $WKCStrings{"pageaddhostmanagehostbreadcrumbs"};
      $cancelname = "subpagemanagehosts";
      if ($params->{managedhost}) {
         my $hostinfo = get_hostinfo($params);
         my $thishost = $hostinfo->{hosts}->{$params->{managedhost}};
         $hostlongname = $thishost->{longname};
         $hosturl = $thishost->{url};
         $hostloginname = $thishost->{loginname};
         $hostloginpassword = $thishost->{loginpassword};
         $hostwkcpath = $thishost->{wkcpath};
         }
      }
   else {
      $pagebreadcrumbs = "Error: missing pagemode";
      }

   my ($pagetitle, $pagedesc, $edithostname);

   if ($copyhost eq "new") { # Set up the stuff for creating a new one vs. editing a copy vs. editing this one
      $pagetitle = $WKCStrings{"pageaddhostpagetitle"};
      $pagedesc = $WKCStrings{"pageaddhostpagedesc"};
      $edithostname = <<"EOF";
<div class="title">$WKCStrings{"pageaddhosthostname"}</div>
<input name="edithostname" type="text" size="32" maxlength="32" value="">
<input name="creatingnewhost" type="hidden" value="new">
<div class="desc">$WKCStrings{"pageaddhosthostnamedesc"}</div>
EOF
      }
   elsif ($copyhost) {
      $pagetitle = $WKCStrings{"pagehostcopypagetitle"};
      $pagedesc = $WKCStrings{"pagehostcopypagedesc"};
      $edithostname = <<"EOF";
<div class="title">$WKCStrings{"pageaddhosthostname"}</div>
<input name="edithostname" type="text" size="32" maxlength="32" value="">
<input name="creatingnewhost" type="hidden" value="copy">
<div class="desc">$WKCStrings{"pageaddhosthostnamedesc"}</div>
EOF
      }
   else {
      $pagetitle = $WKCStrings{"pagehosteditpagetitle"};
      $pagedesc = $WKCStrings{"pagehosteditpagedesc"};
      $edithostname = <<"EOF";
<input type="hidden" name="edithostname" value="$params->{managedhost}">
EOF
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$pagebreadcrumbs</div>
<div class="pagetitle">$pagetitle$params->{managedhost}</div>
<div class="pagetitledesc">$pagedesc</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

$edithostname

<div class="title">$WKCStrings{"pageedithostlongnametitle"}</div>
<input name="editlongname" type="text" size="60" value="$hostlongname">
<div class="desc">
$WKCStrings{"pageedithostlongnamedesc"}
</div>
<div class="title">$WKCStrings{"pageedithostftpurltitle"}</div>
<input name="editurl" type="text" size="60" value="$hosturl">
<div class="desc">
$WKCStrings{"pageedithostftpurldesc"}
</div>
<div class="title">$WKCStrings{"pageedithostftploginnametitle"}</div>
<input name="editloginname" type="text" size="60" value="$hostloginname">
<div class="desc">
$WKCStrings{"pageedithostftploginnamedesc"}
</div>
<div class="title">$WKCStrings{"pageedithostftploginpasswordtitle"}</div>
<input name="editloginpassword" type="password" size="60" value="$hostloginpassword">
<div class="desc">
$WKCStrings{"pageedithostftploginpassworddesc"}
</div>
<div class="title">$WKCStrings{"pageedithostdatafilepathtitle"}</div>
<input name="editwkcpath" type="text" size="60" value="$hostwkcpath">
<div class="desc">
$WKCStrings{"pageedithostdatafilepathdesc"}
</div>

<input type="submit" name="dopageaddedithost" value="$WKCStrings{"pageedithostsave"}">
</div>
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="$cancelname" value="$WKCStrings{"pagecancel"}">
</div>

<input type="hidden" name="pagemode" value="$params->{pagemode}">
<input type="hidden" name="managedhost" value="$params->{managedhost}">
<input type="hidden" name="copyhost" value="$copyhost">
$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pagemanagehosts(\%params, $hiddenfields)
#
# Do the main part for listing the hosts to manage
#
# # # # # # # #

sub compose_pagemanagehosts {

   my ($params, $hiddenfields) = @_;

   my $response;

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"pagemanagehostbreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"pagemanagehostpagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pagemanagehostpagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}

<div class="sectionplain">
<table>
<tr><td></td><td></td>
<td class="browsebuttons">
<input class="smaller" type="submit" name="pagemanagehostdone2" value="$WKCStrings{"pagedone"}">
</td></tr>
<tr>
<td class="browsecolumnhead">$WKCStrings{"pagemanagehosthostcolhead"}&nbsp;</td>
<td class="browsecolumnhead">$WKCStrings{"pagemanagehostcurrentsettingscolhead"}&nbsp;</td>
<td>&nbsp;</td>
</tr>
EOF

   my $hostinfo = get_hostinfo($params);
   my %hostsites;

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      if ($hostsites{$hostinfo->{sites}->{$sitename}->{host}}) {
         $hostsites{$hostinfo->{sites}->{$sitename}->{host}} .= ", $sitename";
         }
      else {
         $hostsites{$hostinfo->{sites}->{$sitename}->{host}} = $sitename;
         }
      }

   foreach my $hostname (sort keys %{$hostinfo->{hosts}}) {
      my $hosthash = $hostinfo->{hosts}->{$hostname};
      my $hostsitelist = $hostsites{$hostname} || "<i>$WKCStrings{pagemanagehostnone}</i>";
      my $deletebutton = $hostsites{$hostname} ? "" : <<"EOF";
  <input class="smaller" type="submit" name="dodeletehost:$hostname" value="$WKCStrings{"pagemanagehostdelete"}" onClick="return checkdelete('$hostname');">
EOF
      my $longname = special_chars($hosthash->{longname});
      my $url = special_chars($hosthash->{url});
      my $loginname = special_chars($hosthash->{loginname});
      my $wkcpath = special_chars($hosthash->{wkcpath});
      my $hosttype = $url ? $WKCStrings{"pagemanagehostremote"} : $WKCStrings{"pagemanagehostlocal"};
      my $ignored = $url ? "" : $WKCStrings{"pagemanagehostignored"};

      $response .= <<"EOF";
<tr>
 <td class="browsepagemedium">$hostname&nbsp;</td>
 <td class="browsepageavailable1">
  <table cellspacing="0" cellpadding="0">
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehostlongname"}</td><td class="browsepageavailable">$longname</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehostusedbysite"}</td><td class="browsepageavailable2">$hostsitelist</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehosttype"}</td><td class="browsepageavailable2">$hosttype</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehosturl"}</td><td class="browsepageavailable2">$url</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehostloginname"}</td><td class="browsepageavailable2">$loginname$ignored</td><tr>
   <tr><td class="browsepageavailable3">$WKCStrings{"pagemanagehostdatafilepath"}</td><td class="browsepageavailable2">$wkcpath$ignored</td><tr>
  </table>
 </td>
 <td class="browsebuttons" valign="top">
  <input class="smaller" type="submit" name="doedithost:$hostname" value="$WKCStrings{"pagemanagehostedit"}">
  <input class="smaller" type="submit" name="docopyhost:$hostname" value="$WKCStrings{"pagemanagehostcopy"}">
  $deletebutton
 </td>
</tr>
EOF
      }

   $response .= <<"EOF";
<tr>
 <td>
 </td>
 <td>
 </td>
 <td class="browsebuttons">
  <input class="smaller" type="submit" name="subpageaddmanagedhost" value="$WKCStrings{"pagemanagehostadd"}">
  <input type="hidden" name="pagemode" value="managehost">
 </td>
</tr>
</table>
</div>
<div class="sectionplain">
<input type="submit" name="pagemanagehostdone" value="$WKCStrings{"pagedone"}">
</div>

$hiddenfields
</form>
<script>
function checkdelete(hn) {
return(confirm("$WKCStrings{"pagemanagehostdeleteprompt1"}"+hn+"$WKCStrings{"pagemanagehostdeleteprompt2"}"))
}
</script>
EOF

   return $response;

}


# # # # # # # #
#
# $response = compose_pageaddpage(\%params, $user, \%userinfo, $hiddenfields)
#
# Do the main part for adding another page to the site -- get the info
#
# # # # # # # #

sub compose_pageaddpage {

   my ($params, $user, $userinfo, $hiddenfields) = @_;

   my $response;

   my @templateinfo;

   return "" if WKC::site_not_allowed($userinfo, $user, $params->{sitename}); # just in case

   get_templateinfo($params, "pagetemplate", \@templateinfo);
   my $optionlist;
   for (my $i = 0; $i < scalar @templateinfo; $i++) {
      my $name = $templateinfo[$i]->{name};
      $name =~ m/:(.+)$/;
      my $plainname = $1;
      my $ln = special_chars($templateinfo[$i]->{longname} || $plainname);
      if ($name =~ m/^site:/) {
         $ln .= " ($WKCStrings{pageaddpagesitespecific}:$plainname)";
         }
      else {
         $ln .= " ($WKCStrings{pageaddpageshared}:$plainname)";
         }
      my $selected = "";
      $selected = " SELECTED" if $name eq "system:default";
      $optionlist .= qq!<option value="$name"$selected>$ln</option>!;
      }

   $response .= <<"EOF";
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"pageaddpagebreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"pageaddpagepagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"pageaddpagepagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="title">$WKCStrings{"pageaddpagepagenametitle"}</div>
<input name="editpagename" type="text" size="32" maxlength="32" value="">
<div class="desc">
$WKCStrings{"pageaddpagepagenamedesc"}
</div>
<div class="title">$WKCStrings{"pageaddpagelongpagenametitle"}</div>
<input name="editlongname" type="text" size="60" value="">
<div class="desc">
$WKCStrings{"pageaddpagelongpagenamedesc"}
</div>
<script>
</script>
<div class="title">$WKCStrings{"pageaddpagepagetemplatetitle"}</div>
<input name="edittemplatetype" type="radio" value="default" onClick="settemplate();" CHECKED><span class="smaller">$WKCStrings{"pageaddpageusedefaulttemplate"}</span>
<input name="edittemplatetype" type="radio" value="shared" onClick="settemplate();"><span class="smaller">$WKCStrings{"pageaddpageusesharedtemplate"}</span>
<input name="edittemplatetype" type="radio" value="published" onClick="settemplate();"><span class="smaller">$WKCStrings{"pageaddpagecopypublished"}</span>
<input name="edittemplatetype" type="radio" value="editing" onClick="settemplate();"><span class="smaller">$WKCStrings{"pageaddpagecopyedited"}</span>
<input name="edittemplatetype" type="radio" value="url" onClick="settemplate();"><span class="smaller">$WKCStrings{"pageaddpagecopyfromurl"}</span>
<br>
$params->{promptlevelspacing}
<div class="desc">
$WKCStrings{"pageaddpagepagetemplatedesc"}
</div>
$params->{promptlevelspacing}
<div id="templatelistid">
<span class="smaller">$WKCStrings{"pageaddpagelistoftemplates"}</span><br>
<select name="edittemplatelist" size="10">
$optionlist
</select><br>
$params->{promptlevelspacing}
</div>
EOF

   # Load scripts from a file

   $response .= $WKCStrings{"newpagejsdefinestrings"};
   open JSFILE, "$WKCdirectory/WKCnewpagejs.txt";
   while (my $line = <JSFILE>) {
      $response .= $line;
      }
   close JSFILE;

   $response .= <<"EOF";
<div id="templatepagesid">
<span class="smaller">$WKCStrings{"pageaddpagesitetolist"}</span><br>
<select name="sitelist" size="1" onchange="update_pagelist();">
EOF

   my $hostinfo = get_hostinfo($params);

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      next if WKC::site_not_allowed($userinfo, $user, $sitename);
      my ($currentsite, $selectedsite);
      if ($sitename eq $params->{sitename}) {
         $currentsite = " *** $WKCStrings{pageaddpagecurrentsite} ***";
         $selectedsite = " selected";
         }
      my $longname = special_chars($hostinfo->{sites}->{$sitename}->{longname});
      $response .= <<"EOF";
<option value="$sitename"$selectedsite>$longname ($sitename)$currentsite
EOF
      }

   $response .= <<"EOF";
</select>
$params->{promptlevelspacing}
<span class="smaller">$WKCStrings{"pageaddpagepagetocopy"}</span><br>
<select name="sitepagelist" size="10">
<option value="">$WKCStrings{"pageaddpageempty"}
</select><br>
$params->{promptlevelspacing}
</div>
<div id="templateurlid">
<span class="smaller">$WKCStrings{"pageaddpageloadfromthisurl"}</span><br>
<input name="loadtemplateurl" type="text" size="60" value="http://"><br>
$params->{promptlevelspacing}
</div>
<input type="submit" name="dopageaddpage" value="$WKCStrings{"pageaddpagecreate"}">
</div>
$params->{promptlevelspacing}
<div class="sectionplain">
<input type="submit" name="pageaddpagecancel" value="$WKCStrings{"pagecancel"}">
</div>
<script>
currentpagename="$params->{datafilename}";
currentsitename="$params->{sitename}";
settemplate();
</script>

$hiddenfields
</form>
EOF

   return $response;

}


# # # # # # # #
#
# $response = do_pageaddedithost(\%params, $hiddenfields)
#
# Process the information to create a new host or edit an existing host
#
# # # # # # # #

sub do_pageaddedithost {

   my ($params, $hiddenfields) = @_;

   my $response;

   my $hostname = lc $params->{edithostname};
   $hostname =~ s/[^a-z0-9\-]//g;

   my $hostinfo = get_hostinfo($params);

   if ($params->{creatingnewhost}) { # creating a new host
      if ($hostinfo->{hosts}->{$hostname}) {
         $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pageaddedithosterr1"} "$hostname" $WKCStrings{"pageaddedithosterr2"}
</div>
$params->{promptlevelspacing}
EOF
         return $response;
         }
      $hostinfo->{hosts}->{$hostname} = {}; # Initialize hash to hold values
      }

   $hostinfo->{hosts}->{$hostname}->{longname} = $params->{editlongname};
   $hostinfo->{hosts}->{$hostname}->{url} = $params->{editurl};
   $hostinfo->{hosts}->{$hostname}->{loginname} = $params->{editloginname};
   $hostinfo->{hosts}->{$hostname}->{loginpassword} = $params->{editloginpassword};
   $hostinfo->{hosts}->{$hostname}->{wkcpath} = $params->{editwkcpath};

   my $ok = save_hostinfo($params, $hostinfo);

   return "";  

}


# # # # # # # #
#
# $response = do_pagedeletehost(\%params, $hiddenfields)
#
# Process the information to delete an existing host
#
# # # # # # # #

sub do_pagedeletehost {

   my ($params, $hiddenfields) = @_;

   my $response;
   my $ok;

   my $hostname = $params->{managedhost};

   my $hostinfo = get_hostinfo($params);

   if (!$hostinfo->{hosts}->{$hostname}) { # make sure host exists
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagedeletehosterr1"} "$hostname" $WKCStrings{"pagedeletehosterr2"}
</div>
$params->{promptlevelspacing}
EOF
      return $response;
      }

   # Assumes that the code to check for no use of this host is correct and doesn't allow it!

   delete $hostinfo->{hosts}->{$hostname};
   $ok = save_hostinfo($params, $hostinfo); # write out changed version

   return "";  

}


# # # # # # # #
#
# $response = do_pageaddsite(\%params, $hiddenfields)
#
# Process the information to create a new site
#
# # # # # # # #

sub do_pageaddsite {

   my ($params, $hiddenfields) = @_;

   my $response;
   my $ok;

   $params->{editsitehostradio} = $params->{newhost};
   $params->{creatingnewsite} = 1;

   return do_pagesiteedit($params, $hiddenfields);

}


# # # # # # # #
#
# $response = do_pagedeletesite(\%params, $hiddenfields)
#
# Process the information to delete an existing site
#
# # # # # # # #

sub do_pagedeletesite {

   my ($params, $hiddenfields) = @_;

   my $response;
   my $ok;

   my $sitename = $params->{managedsite};

   my $hostinfo = get_hostinfo($params);

   if (!$hostinfo->{sites}->{$sitename}) { # make sure site exists
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagedeletesiteerr1"} "$sitename" $WKCStrings{"pagedeletesiteerr2"}
</div>
$params->{promptlevelspacing}
EOF
      return $response;
      }

   my $errstr = delete_site($params, $hostinfo, $sitename, 0); # delete locally
   if ($errstr) { # if error, changes were not written out
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagedeletesiteerr3"}
$errstr
</div>
$params->{promptlevelspacing}
EOF
      return $response;
      }

   if ($params->{sitename} eq $sitename) { # deleted current site
      $params->{sitename} = "";
      }

   return "";  

}


# # # # # # # #
#
# $response = do_pageaddpage(\%params, $hiddenfields)
#
# Process the information to create a new page
#
# # # # # # # #

sub do_pageaddpage {

   my ($params, $hiddenfields) = @_;

   my $response;
   my $ok;

   my $pagename = lc $params->{editpagename};
   $pagename =~ s/[^a-z0-9\-]//g;

   if (!$pagename) { # no name
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pageaddpagenonamegiven"}
</div>
$params->{promptlevelspacing}
EOF
      return $response;
      }

   my ($templatepath, $templateistemp, $templatelogstring);

   my $hostinfo = get_hostinfo($params);

   if ($params->{edittemplatetype} eq "shared") {
      my ($location, $name) = split(/:/, $params->{edittemplatelist}, 2);
      $location =~ s/[^a-z0-9\-]//g;
      $name =~ s/[^a-z0-9\-]//g;
      my $directory = get_templatedirectory($params, $location);
      $templatepath = "$directory/$name.pagetemplate.txt";
      if ($location eq "site") {
         $templatelogstring = $WKCStrings{pageaddpagetypesite};
         }
      else {
         $templatelogstring = $WKCStrings{pageaddpagetypeshared};
         }
      $templatelogstring .= " $name";
      }
   elsif ($params->{edittemplatetype} eq "published") {
      my ($sname, $pname);
      $sname = $params->{sitelist};
      $pname = $params->{sitepagelist};
      return $WKCStrings{"pageaddpagecannotcopy"} unless $pname;
      $templatepath = get_ensured_page_published_datafile_path($params, $hostinfo, $sname, $pname);
      return "$WKCStrings{pageaddpagenocopypub} $sname:$pname." unless $templatepath;
      $templatelogstring = "$WKCStrings{pageaddpagetypepublished} $sname/$pname";
      }
   elsif ($params->{edittemplatetype} eq "editing") {
      my ($sname, $pname);
      $sname = $params->{sitelist};
      $pname = $params->{sitepagelist};
      return $WKCStrings{"pageaddpagecannotcopy"} unless $pname;
      $templatepath = get_ensured_page_edit_path($params, $hostinfo, $sname, $pname);
      return "$WKCStrings{pageaddpagenocopyediting} $sname:$pname." unless $templatepath;
      $templatelogstring = "$WKCStrings{pageaddpagetypeediting} $sname/$pname";
      }
   elsif ($params->{edittemplatetype} eq "url") {
      my $ua = LWP::UserAgent->new; # try to do a GET 
      $ua->agent("wikiCalc Template Load");
      my $req = HTTP::Request->new(GET => $params->{loadtemplateurl});
      $req->header('Accept' => '*/*');
      my $res = $ua->request($req);
      if ($res->is_success) {
         $templatepath = "temptemplate" . (int(rand 10000)+1) . ".txt";
         open (TEMPTEMPLATEFILE, "> $templatepath");
         print TEMPTEMPLATEFILE $res->content;
         close TEMPTEMPLATEFILE;
         $templateistemp = 1;
         }
      else {
         return $WKCStrings{"pageaddpageunabletoloadurl"};
         }
      $templatelogstring = "$WKCStrings{pageaddpagetypeurl} $params->{loadtemplateurl}";
      }
   else {
      $templatepath = get_templatedirectory($params, "site") if get_template($params, "pagetemplate", "site:default");
      $templatepath = get_templatedirectory($params, "shared") if !$templatepath && get_template($params, "pagetemplate", "shared:default");
      $templatepath = get_templatedirectory($params, "system") if !$templatepath && get_template($params, "pagetemplate", "system:default");
      $templatepath = "$templatepath/default.pagetemplate.txt" if $templatepath;
      $templatelogstring = $WKCStrings{pageaddpagetypedefault};
      }

   my (@newheaderlines, %newheaderdata, @newsheetlines, %newsheetdata);

   if ($templatepath) {
      $ok = load_page($templatepath, \@newheaderlines, \@newsheetlines);
      my $pareseok = parse_header_save(\@newheaderlines, \%newheaderdata); # Get data from header
      $pareseok = parse_sheet_save(\@newsheetlines, \%newsheetdata); # Get data from sheet
      unlink $templatepath if $templateistemp; # delete temp file used by URL template
      }

   $newheaderdata{fullname} = $params->{editlongname}; # Set initial values
   $newheaderdata{lastmodified} = scalar localtime; # Say it was modified, since it's new even if blank
   delete $newheaderdata{editlog}; # remove edit log, etc., to start anew (leave things like publish settings)
   delete $newheaderdata{lastauthor};
   delete $newheaderdata{editcomments};
   delete $newheaderdata{basefiledt};
   delete $newheaderdata{backupfiledt};
   delete $newheaderdata{reverted};

   $newheaderdata{editlog} = ();
   push @{$newheaderdata{editlog}}, "# $templatelogstring"; # say where we came from as first comment

   my $initialheadercontents = create_header_save(\%newheaderdata);
   my $initialsheetcontents;
   if ($templatepath) {
      $initialsheetcontents = create_sheet_save(\%newsheetdata);
      }
   $initialsheetcontents ||= "cell:A1:\n"; # make sure it has something

   my $hostinfo = get_hostinfo($params);

   return create_new_page($params, $hostinfo, $params->{sitename}, $pagename, $initialheadercontents, $initialsheetcontents);

}


# # # # # # # #
#
# $response = do_pagesiteedit(\%params, $hiddenfields)
#
# Process the information to update site settings or create a new site
#
# # # # # # # #

sub do_pagesiteedit {

   my ($params, $hiddenfields) = @_;

   my $response;
   my $ok;

   my $sitename = lc $params->{editsitename};
   $sitename =~ s/[^a-z0-9\-]//g;

   my $hostinfo = get_hostinfo($params);

   if ($params->{creatingnewsite}) { # creating a new site
      if ($hostinfo->{sites}->{$sitename}) { # make sure sitename is unique
         $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagesiteediterr1"} "$sitename" $WKCStrings{"pagesiteediterr2"}
</div>
$params->{promptlevelspacing}
EOF
         return $response;
         }
      $hostinfo->{sites}->{$sitename} = {}; # Initialize hash to hold values
      }

   my $siteinfo = $hostinfo->{sites}->{$sitename};

   if ($params->{editnameonhost} !~ m/\S+/ || $params->{editauthoronhost} !~ m/\S+/) {
      $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagesiteediterr3"}
</div>
$params->{promptlevelspacing}
EOF
      return $response;
      }

   my $sitechecked = $siteinfo->{checked};
   $sitechecked = $siteinfo->{host} eq $params->{editsitehostradio} ? $sitechecked : 0;
   $sitechecked = $siteinfo->{nameonhost} eq $params->{editnameonhost} ? $sitechecked : 0;
   $sitechecked = $siteinfo->{htmlpath} eq $params->{edithtmlpath} ? $sitechecked : 0;

   $siteinfo->{longname} = $params->{editlongname};
   $siteinfo->{host} = $params->{editsitehostradio};
   $siteinfo->{nameonhost} = lc $params->{editnameonhost};
   $siteinfo->{nameonhost} =~ s/[^a-z0-9\-]//g;
   $siteinfo->{authoronhost} = lc $params->{editauthoronhost};
   $siteinfo->{authoronhost} =~ s/[^a-z0-9\-]//g;
   $siteinfo->{authorfromlogin} = $params->{editauthorfromlogin};
   $siteinfo->{htmlpath} = $params->{edithtmlpath};
   $siteinfo->{htmlurl} = $params->{edithtmlurl};
   $siteinfo->{editurl} = $params->{editediturl};
   $siteinfo->{publishrss} = $params->{editpublishrss};
   $siteinfo->{rssmaxsiteitems} = $params->{editrssmaxsiteitems};
   $siteinfo->{rssmaxpageitems} = $params->{editrssmaxpageitems};
   $siteinfo->{rsstitle} = $params->{editrsstitle};
   $siteinfo->{rsslink} = $params->{editrsslink};
   $siteinfo->{rssdescription} = $params->{editrssdescription};
   $siteinfo->{rsschannelxml} = $params->{editrsschannelxml};

   if (!$sitechecked) { # if not checked, or if those values changed, check they are ok before committing
      $siteinfo->{checked} = 0;
      my $errstr = check_site_exists($params, $hostinfo, $sitename);
      if ($errstr) { # if error, changes were not written out
         $response .= <<"EOF";
<div class="sectionerror">
$WKCStrings{"pagesiteediterr4"}
$errstr
</div>
$params->{promptlevelspacing}
EOF
         return $response;
         }
      }
   else { 
      $ok = save_hostinfo($params, $hostinfo);
      }

   return "";  

}



# # # # # # # #
#
# $response = compose_pagedemosetup(\%params, $hiddenfields)
#
# Setup from scratch ready to go
#
# # # # # # # #

sub compose_pagedemosetup {

   my ($params, $hiddenfields) = @_;

   my $response;
   my ($ok, $line, $cmd, $value, $log);

   open (SCRIPTFILEIN, "$WKCdirectory/demosetup.script.txt");

   while ($line = <SCRIPTFILEIN>) {
      chomp $line;
      $line =~ s/\r//g; # make sure no CR's either
      ($cmd, $value) = split(/\s/, $line, 2);
      if ($cmd eq "mkdir") {
         $log .= "<i>$WKCStrings{pagedemosetupcreatingdir} $params->{localwkcpath}/$value</i><br>\n";
         $ok = -e "$params->{localwkcpath}/$value";
         if ($ok) {
            $log .= "<i>$WKCStrings{pagedemosetupcreatingdirerr1} $params->{localwkcpath}/$value already exists</i><br>\n";
            }
         else {
            $ok = mkdir "$params->{localwkcpath}/$value";
            $log .= "<i>$WKCStrings{pagedemosetupcreatingdirerr3} $params->{localwkcpath}/$value</i><br>\n" unless $ok;
            }
         }
      elsif ($cmd eq "mkfile") {
         $log .= "<i>$WKCStrings{pagedemosetupcreatingfile} $params->{localwkcpath}/$value</i><br>\n";
         if (-e "$params->{localwkcpath}/$value") { # file exists, don't clobber it
            $log .= "<i>$WKCStrings{pagedemosetupcreatingfileexists} $params->{localwkcpath}/$value</i><br>\n";
            }
         else {
            $ok = open (NEWFILEOUT, "> $params->{localwkcpath}/$value");
            $log .= "<i>$WKCStrings{pagedemosetupcreatingfileerr1} $params->{localwkcpath}/$value</i><br>\n" unless $ok;
            while ($line = <SCRIPTFILEIN>) {
               last if ($line =~ m/^\[END\]/);
               $line =~ s/\r//g; # make sure no CR's
               print NEWFILEOUT $line;
               }
            close NEWFILEOUT;
            }
         }
      elsif ($cmd eq "log") {
         $log .= "$value<br>\n";
         }
      }

   close SCRIPTFILEIN;


   $response .= <<"EOF";
<div class="sectionoutlined">
<table cellpadding="0" cellspacing="0" width="100%"><tr>
<td valign="top">
<div class="pagebreadcrumbs">$WKCStrings{"pageaddpagebreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"pagedemosetupcompletetitle"}</div></td>
<td valign="top" align="right">
</td>
</tr></table>
<div class="pagetitledesc">$WKCStrings{"pagedemosetupcompletedesc"}</div>
</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"pagedemosetupactionlist"}</div>
<div class="desc">
$log
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<input type="submit" name="pagedemosetupdone" value="$WKCStrings{"pagedemosetupcontinue"}"}"><br>

$params->{promptlevelspacing}

$hiddenfields
</form>
EOF

   return $response;

}

