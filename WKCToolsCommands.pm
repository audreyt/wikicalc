#
# WKCToolsCommands.pl -- General page settings, special operations, program settings
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCToolsCommands;

   use strict;
   use CGI qw(:standard);
   use utf8;

   use WKCStrings;
   use WKC;
   use WKCSheet;
   use WKCDataFiles;
   use WKCBackupCommands;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(do_tools_command execute_tools_command execute_tools_useradmincommand);
   our $VERSION = '1.0.0';

#
# Locals
#

   my @cryptsaltset = ('.', '/', 0..9, 'A'..'Z', 'a'..'z'); # See crypt documentation

   my %attribtargets = ( # the sheet settings array name for cell attributes that have numeric lookups
      bt => "borderstyles", br => "borderstyles", bb => "borderstyles", bl => "borderstyles", layout => "layoutstyles",
      font => "fonts", color => "colors", bgcolor => "colors", cellformat => "cellformats",
      textvalueformat => "valueformats", nontextvalueformat => "valueformats",
      );

   my %attribhashes = ( # converts attrib targets into the names of the hashes for the values
      fonts => "fonthash", colors => "colorhash", borderstyles => "borderstylehash", layoutstyles => "layoutstylehash",
      cellformats => "cellformathash", valueformats => "valueformathash",
      );

# Return something

   1;

# # # # # # # #
#
# ($stylestr, $response) = do_tools_command(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, \%userinfo)
#
# Do the stuff for the Tools tab
#
# # # # # # # #

sub do_tools_command {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, $userinfo) = @_;

   my ($response, $outstr, $stylestr);

   if ($params->{"oktools:pageproperties"}) {
      ($stylestr, $response) = compose_pageproperties($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   elsif ($params->{"oktools:loadfromsheet"}) {
      ($stylestr, $response) = compose_loadfromsheet($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, $userinfo);
      }

   elsif ($params->{"oktools:loadfromtext"}) {
      ($stylestr, $response) = compose_loadfromtext($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   elsif ($params->{"oktools:saveastext"}) {
      ($stylestr, $response) = compose_saveastext($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   elsif ($params->{"oktools:dosaveastext"}) {
      ($stylestr, $response) = compose_dosaveastext($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   elsif ($params->{"oktools:backup"}) {
      $response = do_backup_command($params, $hiddenfields, $hostinfo);
      }

   elsif ($params->{"oktools:useradmin"}) {
      ($stylestr, $response) = compose_useradmin($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   else {
      ($stylestr, $response) = compose_pagetop($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo);
      }

   return ($stylestr, $response);
}

# # # # # # # #
#
# ($stylestr, $response) = compose_pagetop(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Default
#
# # # # # # # #

sub compose_pagetop {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($response, $onclickstr, $editcoordsstr, $inlinescripts);

   $onclickstr = q! onclick="rc('$coord');"!;
   $editcoordsstr = $editcoords;

   my $stylestr;

   my $toolsmessage;

   if ($params->{toolsmessage}) {
      $toolsmessage .= <<"EOF";
<div class="sectionerror">
$params->{toolsmessage}
</div>
EOF
      }

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
  <form name="f0" method="POST">
   <div class="sectionoutlined">
   <div class="pagetitle">$WKCStrings{"toolspagetitle"}</div>
   <div class="pagetitledesc">$WKCStrings{"toolspagedesc"}</div>
   $toolsmessage
   $params->{promptlevelspacing}
   <table cellpadding="0" cellspacing="0">
EOF
   $response .= <<"EOF" if $params->{datafilename};
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:pageproperties" value="$WKCStrings{"toolspagepagepropertiesbutton"}">
      </td>
      <td valign="top">
       <div class="desc">$WKCStrings{"toolspagepagepropertiesbuttondesc"}<br><br></div>
      </td>
     </tr>
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:loadfromsheet" value="$WKCStrings{"toolspageloadfromsheetbutton"}">
      </td>
      <td valign="top">
       <div class="desc">
         $WKCStrings{"toolspageloadfromsheetbuttondesc"}
         <br><br></div>
      </td>
     </tr>
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:loadfromtext" value="$WKCStrings{"toolspageloadfromtextbutton"}">
      </td>
      <td valign="top">
       <div class="desc">
         $WKCStrings{"toolspageloadfromtextbuttondesc"}
         <br><br></div>
      </td>
     </tr>
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:saveastext" value="$WKCStrings{"toolspagesaveastextbutton"}">
      </td>
      <td valign="top">
       <div class="desc">
        $WKCStrings{"toolspagesaveastextbuttondesc"}
        <br><br></div>
      </td>
     </tr>
EOF
   $response .= <<"EOF" if ($params->{datafilename} || $params->{sitename});
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:backup" value="$WKCStrings{"toolspagebackupsbutton"}">
      </td>
      <td valign="top">
       <div class="desc">
        $WKCStrings{"toolspagebackupsbuttondesc"}
        <br><br></div>
      </td>
     </tr>
EOF
   $response .= <<"EOF" if $params->{loggedinusername};
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="dologout" value="$WKCStrings{"toolspagelogoutbutton"}">
      </td>
      <td valign="top">
       <div class="desc">$WKCStrings{"toolspagelogoutbuttondesc"} $params->{loggedinusername}.<br><br></div>
      </td>
     </tr>
EOF
   $response .= <<"EOF";
     <tr>
      <td style="padding-right:6pt;" valign="top">
       <input class="smaller" type="submit" name="oktools:useradmin" value="$WKCStrings{"toolspageuseradminbutton"}">
      </td>
      <td valign="top">
       <div class="desc">
        $WKCStrings{"toolspageuseradminbuttondesc"}
        <br><br></div>
      </td>
     </tr>
    </table>
   </div>
   $inlinescripts
   $hiddenfields
  </form>
  $params->{promptlevelspacing}
 </td>
</tr>
</table>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_pageproperties(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Edit page properties
#
# # # # # # # #

sub compose_pageproperties {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($stylestr, $response);

   my @templateinfo;

   my @templatechecked;
   if ($headerdata->{templatefile}) {
      $templatechecked[1] = " CHECKED";
      }
   elsif ($headerdata->{templatetext}) {
      $templatechecked[2] = " CHECKED";
      }
   else {
      $templatechecked[0] = " CHECKED";
      }
   get_templateinfo($params, "htmltemplate", \@templateinfo);
   my $optionlist;
   for (my $i = 0; $i < scalar @templateinfo; $i++) {
      my $name = $templateinfo[$i]->{name};
      $name =~ m/:(.+)$/;
      my $plainname = $1;
      my $ln = special_chars($templateinfo[$i]->{longname} || $plainname);
      if ($name =~ m/^site:/) {
         $ln .= " ($WKCStrings{toolspagepropsitespecific}:$plainname)";
         }
      else {
         $ln .= " ($WKCStrings{toolspagepropshared}:$plainname)";
         }
      my $selected = $name eq $headerdata->{templatefile} ? " SELECTED" : "";
      $selected = " SELECTED" if !($headerdata->{templatefile}) && $name eq "system:default";
      $optionlist .= qq!<option value="$name"$selected>$ln</option>!;
      }

   my $fullname = special_chars($headerdata->{fullname});
   my $templatetext = special_chars($headerdata->{templatetext}
                                    || ($headerdata->{templatefile} && get_template($params, "htmltemplate", $headerdata->{templatefile}))
                                    || get_template($params, "htmltemplate", "site:default")
                                    || get_template($params, "htmltemplate", "shared:default")
                                    || get_template($params, "htmltemplate", "system:default")
                                    || $WKCStrings{"publishtemplate"});

   my ($publishhtmlchecked, $publishsourcechecked, $publishjschecked, $viewwithoutloginchecked);
   $publishhtmlchecked = " CHECKED" if $headerdata->{publishhtml} ne "no";
   $publishsourcechecked = " CHECKED" if $headerdata->{publishsource} eq "yes";
   $publishjschecked = " CHECKED" if $headerdata->{publishjs} eq "yes";
   $viewwithoutloginchecked = " CHECKED" if $headerdata->{viewwithoutlogin} eq "yes";

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"toolspagepropertiesbreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"toolspagepropertiespagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"toolspagepropertiespagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<script>
function settemplate () {
 if (document.f0.edittemplatetype[0].checked) {
  document.getElementById("templatelistid").style.display="none";
  document.getElementById("templatetextid").style.display="none";
  }
 if (document.f0.edittemplatetype[1].checked) {
  document.getElementById("templatelistid").style.display="block";
  document.getElementById("templatetextid").style.display="none";
  }
 if (document.f0.edittemplatetype[2].checked) {
  document.getElementById("templatelistid").style.display="none";
  document.getElementById("templatetextid").style.display="block";
  }
}
</script>

<div class="sectionoutlined">
<div class="title">$WKCStrings{"toolspagepgproppagename"}</div>
<input name="editpagename" type="text" size="60" value="$params->{datafilename}">
<div class="desc">
$WKCStrings{"toolspagepgproppagenamedesc"}
</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"toolspagepgproplongpgnm"}</div>
<input name="editlongname" type="text" size="60" value="$fullname">
<div class="desc">
$WKCStrings{"toolspagepgproplongpgnmdesc"}
</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"toolspagepgprophtmltmplt"}</div>
<input name="edittemplatetype" type="radio" value="default" onClick="settemplate();"$templatechecked[0]><span class="smaller">$WKCStrings{"toolspagepgpropusedeftmplt"}</span>
<input name="edittemplatetype" type="radio" value="shared" onClick="settemplate();"$templatechecked[1]><span class="smaller">$WKCStrings{"toolspagepgpropuseshared"}</span>
<input name="edittemplatetype" type="radio" value="explicit" onClick="settemplate();"$templatechecked[2]><span class="smaller">$WKCStrings{"toolspagepgpropeditcopy"}</span>
<br>
$params->{promptlevelspacing}
<div class="desc">
$WKCStrings{"toolspagepgprophtmltmpltdesc"}
</div>
$params->{promptlevelspacing}
<div id="templatelistid">
<select name="edittemplatelist" size="10">
$optionlist
</select><br>
$params->{promptlevelspacing}
</div>
<div id="templatetextid">
<textarea rows="10" cols="110" name="edittemplatetext">
$templatetext
</textarea>
<div class="desc">
$WKCStrings{"toolspagepgpropeditcopydesc"}
</div>
</div>
$params->{promptlevelspacing}
</div>

<div class="title">$WKCStrings{"toolspagepgproppuboptions"}</div>
<input type="checkbox" name="editpublishhtml" value="yes"$publishhtmlchecked><span class="smaller">$WKCStrings{"toolspagepgproppuboptionhtml"}</span>
<input type="checkbox" name="editpublishsource" value="yes"$publishsourcechecked><span class="smaller">$WKCStrings{"toolspagepgproppuboptionsource"}</span>
<input type="checkbox" name="editpublishjs" value="yes"$publishjschecked><span class="smaller">$WKCStrings{"toolspagepgproppuboptionjs"}</span>
<input type="checkbox" name="editviewwithoutlogin" value="yes"$viewwithoutloginchecked><span class="smaller">$WKCStrings{"toolspagepgproppuboptionnologin"}</span>
<br>
$params->{promptlevelspacing}
<div class="desc">
$WKCStrings{"toolspagepgproppuboptionsdesc"}
</div>

</div>

$params->{promptlevelspacing}
<input type="submit" name="oktoolspageproperties" value="$WKCStrings{"toolspagesave"}">
<input type="submit" name="toolspagepropertiescancel" value="$WKCStrings{"pagecancel"}">

</div>

<script>
settemplate();
</script>

$hiddenfields
</form>
 </td>
</tr>
</table>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_useradmin(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Manage user list, etc.
#
# # # # # # # #

sub compose_useradmin {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($stylestr, $response);

   my $userinfo = get_userinfo($params);

   my $hostinfo = get_hostinfo($params);

   my $nsites = (scalar keys %{$hostinfo->{sites}}) || 1;
   my $nsitecols = $nsites + 1; # one column for "all"

   my %requirelogin;
   $requirelogin{$hostinfo->{requirelogin}} = " CHECKED";

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"toolsuseradminbreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"toolsuseradminpagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"toolsuseradminpagedesc"}</div>
</div>
<form name="f0" method="POST">
EOF

   if ($params->{loggedinusername} && $userinfo->{$params->{loggedinusername}}->{admin} ne "yes") { # must be admin if logged in
      $response .= <<"EOF";
$params->{promptlevelspacing}
<div class="title">
$WKCStrings{"toolspageuseradminmustbeloggedin"}</div>
<input type="submit" name="toolsuseradmincancel" value="$WKCStrings{"pagecancel"}">

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
EOF

      return ($stylestr, $response);
      }

   $response .= <<"EOF";

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="pagefilename">$WKCStrings{"toolspageuseradminlastsaved"}: $hostinfo->{lastsaved}</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"toolspageuseradminrequirelogin"}</div>
<input name="editrequirelogin" type="radio" value="yes"$requirelogin{yes}><span class="smaller"> $WKCStrings{"toolspageuseradminreqadminyes"}</span>
<input name="editrequirelogin" type="radio" value="no"$requirelogin{no}><span class="smaller"> $WKCStrings{"toolspageuseradminreqadminno"}</span>
<div class="desc">
$WKCStrings{"toolspageuseradminreqadmindesc"}</div>

$params->{promptlevelspacing}
<table cellspacing="3">
<tr>
 <td class="browsecolumnhead">$WKCStrings{"toolspageuausername"}&nbsp;</td>
 <td class="browsecolumnhead">$WKCStrings{"toolspageuadisplayname"}&nbsp;</td>
 <td class="browsecolumnhead">$WKCStrings{"toolspageuanewpassword"}&nbsp;</td>
 <td class="browsecolumnhead">$WKCStrings{"toolspageuaadmin"}&nbsp;</td>
 <td class="browsecolumnhead" colspan="$nsitecols">$WKCStrings{"toolspageuaregisteredsites"}&nbsp;</td>
 <td class="browsecolumnhead">$WKCStrings{"toolspageuadelete"}&nbsp;</td>
</tr>
<tr>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagename">&nbsp;</td>
 <td class="browsepagemedium" style="color:#006600;" align="center"><i>$WKCStrings{"toolspageuaallsites"}</i><br>$WKCStrings{"toolspageuareadreadwrite"}</td>
EOF

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      $response .= <<"EOF";
 <td class="browsepagemedium" align="center">$sitename<br>$WKCStrings{"toolspageuareadreadwrite2"}</td>
EOF
      }
   $response .= <<"EOF";
 <td class="browsepagename">&nbsp;</td>
</tr>
EOF

   my $rowcolor;
   foreach my $username (sort keys %{$userinfo}) {
      my $ui = $userinfo->{$username};
      my $displayname = special_chars($userinfo->{$username}->{displayname});
      my $adminchecked = $userinfo->{$username}->{admin} eq "yes" ? " CHECKED" : "";
      my $allsiteschecked = $userinfo->{$username}->{allsites} eq "yes" ? " CHECKED" : "";
      my $allreadsiteschecked = $userinfo->{$username}->{allreadsites} eq "yes" ? " CHECKED" : "";
      $rowcolor = $rowcolor ? "" : ' style="background-color:#99CC99;"';
      $response .= <<"EOF";
<tr>
 <td class="browseusername">$username</td>
 <td class="browsepagename"><input name="editdisplayname:$username" type="text" size="20" value="$displayname"></td>
 <td class="browsepagename"><input name="editpassword:$username" type="text" size="10" value=""></td>
 <td class="browseusersite"><input name="editadmin:$username" type="checkbox" value="1"$adminchecked></td>
 <td$rowcolor>
  <table cellspacing="0" cellpadding="0" align="center"><tr><td>
   <input name="editallreadsites:$username" type="checkbox" value="1"$allreadsiteschecked onclick="if(this.checked)document.f0['editallsites:$username'].checked=false;">
   </td><td style="background-color:white;">
   <input name="editallsites:$username" type="checkbox" value="1"$allsiteschecked onclick="if(this.checked)document.f0['editallreadsites:$username'].checked=false;">
   </td></tr></table>
 </td>
EOF
      foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
         my $rwchecked = $ui->{sites} =~ /(^|,)$sitename(,|$)/ ? " CHECKED" : "";
         my $rchecked = $ui->{readsites} =~ /(^|,)$sitename(,|$)/ ? " CHECKED" : "";
         $response .= <<"EOF";
 <td class="browseusersite"$rowcolor>
<table cellspacing="0" cellpadding="0" align="center"><tr><td>
<input name="editreadsite:$username:$sitename" type="checkbox" value="1"$rchecked onclick="if(this.checked)document.f0['editsite:$username:$sitename'].checked=false;">
</td><td style="background-color:white;">
<input name="editsite:$username:$sitename" type="checkbox" value="1"$rwchecked onclick="if(this.checked)document.f0['editreadsite:$username:$sitename'].checked=false;">
</td></tr></table>
</td>
EOF
      }
      $response .= <<"EOF";
 <td class="browseusersite"><input name="editdelete:$username" type="checkbox" value="1"></td>
</tr>
EOF
      }

   $rowcolor = $rowcolor ? "" : ' style="background-color:#99CC99;"';
   $response .= <<"EOF";
<tr>
 <td class="browsepagename"><input name="editnewusername" type="text" size="10" value=""></td>
 <td class="browsepagename"><input name="editnewdisplayname" type="text" size="20" value=""></td>
 <td class="browsepagename"><input name="editnewpassword" type="text" size="10" value=""></td>
 <td class="browseusersite"><input name="editnewadmin" type="checkbox" value="1"></td>
 <td class="browseusersite"$rowcolor>
<table cellspacing="0" cellpadding="0" align="center"><tr><td>
<input name="editnewallreadsites" type="checkbox" value="1" onclick="if(this.checked)document.f0.editnewallsites.checked=false;">
</td><td style="background-color:white;">
<input name="editnewallsites" type="checkbox" value="1" onclick="if(this.checked)document.f0.editnewallreadsites.checked=false;">
</td></tr></table>
</td>
EOF
   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      $response .= <<"EOF";
 <td class="browseusersite"$rowcolor>
<table cellspacing="0" cellpadding="0" align="center"><tr><td>
<input name="editnewreadsite:$sitename" type="checkbox" value="1" onclick="if(this.checked)document.f0['editnewsite:$sitename'].checked=false;">
</td><td style="background-color:white;">
<input name="editnewsite:$sitename" type="checkbox" value="1" onclick="if(this.checked)document.f0['editnewreadsite:$sitename'].checked=false;">
</td></tr></table>
</td>
EOF
   }
   $response .= <<"EOF";
 <td class="browseuseradd">$WKCStrings{"toolspageuaaddnew"}</td>
</tr>
</table>
</div>

$params->{promptlevelspacing}


<input type="submit" name="oktoolsuseradmin" value="$WKCStrings{"toolspagesave"}">
<input type="submit" name="toolsuseradmincancel" value="$WKCStrings{"pagecancel"}">

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_loadfromsheet(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, $userinfo)
#
# Import from another sheet (Note extra arguments: $loggedinuser, $userinfo)
#
# # # # # # # #

sub compose_loadfromsheet {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo, $loggedinuser, $userinfo) = @_;

   my ($stylestr, $response);

   my $fullname = special_chars($headerdata->{fullname});

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
  <div class="sectionoutlined">
   <div class="pagebreadcrumbs">$WKCStrings{"toolsloadfromsheetbreadcrumbs"}</div>
   <div class="pagetitle">$WKCStrings{"toolsloadfromsheetpagetitle"}</div>
   <div class="pagetitledesc">$WKCStrings{"toolsloadfromsheetclipboarddesc"}</div>
  </div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="title">$WKCStrings{"toolsloadfromsheetsheettoload"}</div>
<div class="desc">
$WKCStrings{"toolsloadfromsheetsheettoloaddesc"}
</div>
<input name="editloadtype" type="radio" value="published" onClick="setload();"><span class="smaller">$WKCStrings{"toolsloadfromsheetusepublished"}</span>
<input name="editloadtype" type="radio" value="editing" onClick="setload();" CHECKED><span class="smaller">$WKCStrings{"toolsloadfromsheetuseedited"}</span>
<input name="editloadtype" type="radio" value="url" onClick="setload();"><span class="smaller">$WKCStrings{"toolsloadfromsheetusefromurl"}</span>
<br>
$params->{promptlevelspacing}
EOF

   # Load scripts from a file

   $response .= $WKCStrings{"loadsheetjsdefinestrings"};
   open JSFILE, "$WKCdirectory/WKCloadsheetjs.txt";
   while (my $line = <JSFILE>) {
      $response .= $line;
      }
   close JSFILE;

   $response .= <<"EOF";
<div id="loadpagesid">
<span class="smaller">$WKCStrings{"toolsloadfromsheetsitetolist"}</span><br>
<select name="sitelist" size="1" onchange="update_pagelist();">
EOF

   my $hostinfo = get_hostinfo($params);

   foreach my $sitename (sort keys %{$hostinfo->{sites}}) {
      next if WKC::site_not_allowed($userinfo, $loggedinuser, $sitename);
      my ($currentsite, $selectedsite);
      if ($sitename eq $params->{sitename}) {
         $currentsite = " *** $WKCStrings{toolsloadfromsheetcurrentsite} ***";
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
<span class="smaller">$WKCStrings{"toolsloadfromsheetpagetouse"}</span><br>
<select name="sitepagelist" size="10">
<option value="">$WKCStrings{"toolsloadfromsheetempty"}
</select><br>
$params->{promptlevelspacing}
</div>
<div id="loadurlid" style="display:none;">
<span class="smaller">$WKCStrings{"toolsloadfromsheetloadfromthisurl"}</span><br>
<input name="loadsheeturl" type="text" size="60" value="http://"><br>
$params->{promptlevelspacing}
</div>
<div class="title">$WKCStrings{"toolsloadfromsheetcommenttitle"}</div>
<div class="desc">
$WKCStrings{"toolsloadfromsheetcommentdesc"}
</div>
<div>
<textarea rows="2" cols="60" name="editloadcomment">
</textarea>
</div>
$params->{promptlevelspacing}
<input type="submit" name="oktoolsloadfromsheet" value="$WKCStrings{"toolspageload"}">
<input type="submit" name="toolsloadfromsheetcancel" value="$WKCStrings{"pagecancel"}">

</div>

</div>

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
<script>
 update_pagelist();
</script>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_loadfromtext(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Import from text in a variety of formats
#
# # # # # # # #

sub compose_loadfromtext {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($stylestr, $response);

   my $fullname = special_chars($headerdata->{fullname});

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
  <div class="sectionoutlined">
   <div class="pagebreadcrumbs">$WKCStrings{"toolsloadfromtextbreadcrumbs"}</div>
   <div class="pagetitle">$WKCStrings{"toolsloadfromtextpagetitle"}</div>
   <div class="pagetitledesc">$WKCStrings{"toolsloadfromtextpagedesc"}</div>
  </div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="title">$WKCStrings{"toolsloadfromtexttexttoload"}</div>
<div class="smaller">
$WKCStrings{"toolsloadfromtextinterpreteachline"}
<div style="padding-left:1em;">
<input type="radio" name="loadfromtexttype" value="rows">
$WKCStrings{"toolsloadfromtextsingledown"}<br>
<input type="radio" name="loadfromtexttype" value="cols">
$WKCStrings{"toolsloadfromtextsingleacross"}<br>
<input type="radio" name="loadfromtexttype" value="csv">
$WKCStrings{"toolsloadfromtextcsv"}<br>
<input type="radio" name="loadfromtexttype" value="tab" CHECKED>
$WKCStrings{"toolsloadfromtexttab"}
</div>
</div>
<br>
<textarea rows="10" cols="110" name="edittexttoload">
</textarea>
<div class="desc">
$WKCStrings{"toolsloadfromtextdatadesc"}
</div>
<div class="title">$WKCStrings{"toolsloadfromtextcommenttitle"}</div>
<div class="desc">
$WKCStrings{"toolsloadfromtextcommentdesc"}
</div>
<div>
<textarea rows="2" cols="60" name="editloadcomment">
</textarea>
</div>$params->{promptlevelspacing}
<input type="submit" name="oktoolsloadfromtext" value="$WKCStrings{"toolspageload"}">
<input type="submit" name="toolsloadfromtextcancel" value="$WKCStrings{"pagecancel"}">

</div>

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
<script>
var setf = function() {document.f0.edittexttoload.focus();}
</script>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_saveastext(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Export as text in a variety of formats
#
# # # # # # # #

sub compose_saveastext {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($stylestr, $response);

   my $fullname = special_chars($headerdata->{fullname});

   my $lastcell = cr_to_coord($sheetdata->{sheetattribs}->{lastcol}, $sheetdata->{sheetattribs}->{lastrow});

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"toolssavetotextbreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"toolssavetotextpagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"toolssavetotextpagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<div class="title">$WKCStrings{"toolssavetotextsource"}</div>
<div class="desc">$WKCStrings{"toolssavetotextsourcedesc"}</div>
<div class="smaller">
<input type="radio" name="saveastextsource" value="sheet" CHECKED>
$WKCStrings{"toolssavetotextsheetcurrently"} A1:$lastcell)&nbsp;
<input type="radio" name="saveastextsource" value="clipboard">
$WKCStrings{"toolssavetotextclipboardcontains"} $sheetdata->{clipboard}->{range})
</div>
$params->{promptlevelspacing}
<div class="title">$WKCStrings{"toolssavetotextformattoproduce"}</div>
<div class="desc">
$WKCStrings{"toolssavetotextformattoproducedesc"}
</div>
<div class="smaller">
<input type="radio" name="saveastexttype" value="cellvaluelines">
$WKCStrings{"toolssavetotextoneperline"}<br>
<input type="radio" name="saveastexttype" value="cellcontentslines">
$WKCStrings{"toolssavetotextoneperlineformula"}<br>
<input type="radio" name="saveastexttype" value="csv">
$WKCStrings{"toolssavetotextcsv"}<br>
<input type="radio" name="saveastexttype" value="tab" CHECKED>
$WKCStrings{"toolssavetotexttab"}
</div>
</div>
</div>
$params->{promptlevelspacing}
<input type="submit" name="oktools:dosaveastext" value="$WKCStrings{"toolspagesave"}">
<input type="submit" name="toolssavetotextcancel" value="$WKCStrings{"pagecancel"}">

</div>

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# ($stylestr, $response) = compose_dosaveastext(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $hostinfo)
#
# Show the exported text in an appropriate format
#
# In all but CSV, \ is converted to \b and newline is converted to \n
#
# # # # # # # #

sub compose_dosaveastext {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $hostinfo) = @_;

   my ($stylestr, $response, $savetext, $c1, $r1, $numcols, $numrows, $str, $strnl);

   my $fullname = special_chars($headerdata->{fullname});

   my $datavalues = $sheetdata->{datavalues};
   my $datatypes = $sheetdata->{datatypes};
   my $valuetypes = $sheetdata->{valuetypes};
   my $dataformulas = $sheetdata->{formulas};
   my $cellerrors = $sheetdata->{cellerrors};
   my $cellattribs = $sheetdata->{cellattribs};

   if ($params->{saveastextsource} eq "clipboard") { # get data from clipboard
      my $crbase = $sheetdata->{clipboard}->{range};
      if (!$crbase) {
         $savetext = $WKCStrings{"toolsdosavetotextempty"};
         }
      else {
         $datavalues = $sheetdata->{clipboard}->{datavalues};
         $datatypes = $sheetdata->{clipboard}->{datatypes};
         $valuetypes = $sheetdata->{clipboard}->{valuetypes};
         $dataformulas = $sheetdata->{clipboard}->{formulas};
         $cellerrors = $sheetdata->{clipboard}->{cellerrors};
         $cellattribs = $sheetdata->{clipboard}->{cellattribs};
         my ($clipcoord1, $clipcoord2) = split(/:/, $crbase);
         $clipcoord2 = $clipcoord1 unless $clipcoord2;
         ($c1, $r1) = coord_to_cr($clipcoord1);
         my ($clipc2, $clipr2) = coord_to_cr($clipcoord2);
         $numcols = $clipc2 - $c1 + 1;
         $numrows = $clipr2 - $r1 + 1;
         }
      }
   else { # assume entire sheet
      $datavalues = $sheetdata->{datavalues};
      $datatypes = $sheetdata->{datatypes};
      $valuetypes = $sheetdata->{valuetypes};
      $dataformulas = $sheetdata->{formulas};
      $cellerrors = $sheetdata->{cellerrors};
      $cellattribs = $sheetdata->{cellattribs};
      $c1 = 1;
      $r1 = 1;
      $numcols = $sheetdata->{sheetattribs}->{lastcol};
      $numrows = $sheetdata->{sheetattribs}->{lastrow};
      }

   for (my $r = 0; $r < $numrows; $r++) {
      for (my $c = 0; $c < $numcols; $c++) {
         my $cr = cr_to_coord($c1+$c, $r1+$r);

         $str = $cellerrors->{$cr} || "$datavalues->{$cr}"; # get value as text
         $strnl = $str; # get newlines and \ escaped
         $strnl =~ s/\\/\\b/g;
         $strnl =~ s/\n/\\n/g;

         # Save lines with cell values

         if ($params->{saveastexttype} eq "cellvaluelines") {
            $savetext .= special_chars("$strnl\n");
            }

         # Save lines with cell contents

         elsif ($params->{saveastexttype} eq "cellcontentslines") {
            if ($datatypes->{$cr} eq "f") {
               $savetext .= special_chars("$cr:=$dataformulas->{$cr}\n");
               }
            elsif ($datatypes->{$cr} eq "c") {
               $savetext .= special_chars("$cr:$dataformulas->{$cr}\n");
               }
            elsif ($datatypes->{$cr} eq "v") {
               $savetext .= special_chars("$cr:$datavalues->{$cr}\n");
               }
            elsif ($datatypes->{$cr} eq "t") {
               $savetext .= "$cr:'$strnl\n";
               }
            else {
               $savetext .= special_chars("$cr:$str\n");
               }
            }

         # CSV

         elsif ($params->{saveastexttype} eq "csv") {
            $str =~ s/"/""/g; # use unescaped string
            $str = qq!"$str"! if ($str =~ m/[, "]/);
            $str = ",$str" if $c > 0;
            $savetext .= special_chars($str);
            }

         # Tab delimited

         elsif ($params->{saveastexttype} eq "tab") {
            $strnl = "\t$strnl" if $c > 0;
            $savetext .= special_chars($strnl);
            }
         }
      if ($params->{saveastexttype} eq "csv" || $params->{saveastexttype} eq "tab") {
         $savetext .= "\n";
         }
      }

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr>
 <td class="ttbody" width="100%">
<div class="sectionoutlined">
<div class="pagebreadcrumbs">$WKCStrings{"toolsdosavetotextbreadcrumbs"}</div>
<div class="pagetitle">$WKCStrings{"toolsdosavetotextpagetitle"}</div>
<div class="pagetitledesc">$WKCStrings{"toolsdosavetotextpagedesc"}</div>
</div>

<form name="f0" method="POST">

$params->{promptlevelspacing}
$params->{errormsg}

<div class="sectionoutlined">
<textarea rows="10" cols="110" name="edittexttosave">
$savetext
</textarea>
<br>
</div>
$params->{promptlevelspacing}
<input type="submit" name="toolssavetotextdone" value="$WKCStrings{"pagedone"}">

</div>

$hiddenfields
</form>
 $params->{promptlevelspacing}
 </td>
</tr>
</table>
<script>
var setf = function() {document.f0.edittexttosave.select();}
</script>
EOF

   return ($stylestr, $response);

}


# # # # # # # #
#
# $errortext = execute_tools_command(\%params, \%sheetdata, $editcoords, \%headerdata)
#
# Do the more complex tools commands: Load From Text, Load From Sheet
#
# # # # # # # #

sub execute_tools_command {

   my ($params, $sheetdata, $editcoords, $headerdata) = @_;

   my ($ok, $errortext);

   #
   # Load From Sheet
   #

   if ($params->{oktoolsloadfromtext}) {
      add_to_editlog($headerdata, "# $WKCStrings{toolsexectoolsloadclipboardstart}");
      if ($params->{editloadcomment}) { # optional comment
         add_to_editlog($headerdata, "# $params->{editloadcomment}");
         }
      add_to_editlog($headerdata, "clearclipboard");

      # Note: Numbers come in as plain numbers and text comes in as plain text not wiki text!
      # Also: CSV doesn't handle embedded newlines...!!!!
      # Also, tab doesn't handle quoted strings with embeded newlines (Excel had/has bugs here?)

      $sheetdata->{clipboard} = {}; # clear and create clipboard
      $sheetdata->{clipboard}->{datavalues} = {};
      my $clipdatavalues = $sheetdata->{clipboard}->{datavalues};
      $sheetdata->{clipboard}->{datatypes} = {};
      my $clipdatatypes = $sheetdata->{clipboard}->{datatypes};
      $sheetdata->{clipboard}->{valuetypes} = {};
      my $clipvaluetypes = $sheetdata->{clipboard}->{valuetypes};
      $sheetdata->{clipboard}->{formulas} = {};
      my $clipdataformulas = $sheetdata->{clipboard}->{formulas};
      $sheetdata->{clipboard}->{cellerrors} = {};
      my $clipcellerrors = $sheetdata->{clipboard}->{cellerrors};
      $sheetdata->{clipboard}->{cellattribs} = {};
      my $clipcellattribs = $sheetdata->{clipboard}->{cellattribs};

      my $r = ($params->{loadfromtexttype} eq "csv" || $params->{loadfromtexttype} eq "tab") ? 1 : 0;
      my $c = 0;
      my ($cr, $maxc);

      foreach my $line (split /^/, $params->{edittexttoload}) {
         chomp $line;
         $line =~ s/\r$//g; # just in case
         if ($params->{loadfromtexttype} eq "rows") {
            $cr = cr_to_coord(1, ++$r);
            set_clipboard_cell($headerdata, $sheetdata->{clipboard}, $cr, $line);
            }
         elsif ($params->{loadfromtexttype} eq "cols") {
            $cr = cr_to_coord(++$c, 1);
            set_clipboard_cell($headerdata, $sheetdata->{clipboard}, $cr, $line);
            }
         elsif ($params->{loadfromtexttype} eq "csv") {
            my @ch = split(//, $line);
            push @ch, ","; # Add one to the end
            my ($value, $inquote);
            for (my $i=0; $i < @ch; $i++) {
               my $char = $ch[$i];
               if ($char eq ',' && !$inquote) {
                  $cr = cr_to_coord(++$c, $r);
                  set_clipboard_cell($headerdata, $sheetdata->{clipboard}, $cr, $value);
                  $value = "";
                  }
               else {
                  if ($char eq '"') {
                     if ($inquote) {
                        if ($i < @ch-1 && $ch[$i+1] eq '"') { # double quotes
                           $i++; # skip the second one
                           $value .= '"'; # add one quote
                           }
                        else {
                           $inquote = 0;
                           }
                        }
                     else {
                        $inquote = 1;
                        }
                     }
                  else {
                     $value .= $char;
                     }
                  }
               }
            $r++;
            $maxc = $c > $maxc ? $c : $maxc;
            $c = 0;
            }
         elsif ($params->{loadfromtexttype} eq "tab") {
            my @values = split(/\t/, $line);
            foreach my $value (@values) {
               $cr = cr_to_coord(++$c, $r);
               set_clipboard_cell($headerdata, $sheetdata->{clipboard}, $cr, $value);
               }
            $r++;
            $maxc = $c > $maxc ? $c : $maxc;
            $c = 0;
            }
         }

      if ($cr) { # found some data
         if ($maxc) {
            $cr = cr_to_coord($maxc, $r - 1);
            }
         $sheetdata->{clipboard}->{range} = "A1:$cr";
         }
      else {
         delete $sheetdata->{clipboard}; # clear clipboard completely
         }

      add_to_editlog($headerdata, "# $WKCStrings{toolsexectoolsloadclipboardend}");

      }

   #
   # Load From Sheet
   #

   if ($params->{oktoolsloadfromsheet}) {
      my $sheetlogname;
      if ($params->{editloadtype} eq "url") {
         $sheetlogname = $params->{loadsheeturl};
         }
      else {
         $sheetlogname = "$params->{sitelist}/$params->{sitepagelist}"
         }
      add_to_editlog($headerdata, "# $WKCStrings{toolsexectoolsloadclipboardsheetstart}: $sheetlogname");
      if ($params->{editloadcomment}) { # optional comment
         add_to_editlog($headerdata, "# $params->{editloadcomment}");
         }
      add_to_editlog($headerdata, "clearclipboard");

      $sheetdata->{clipboard} = {}; # clear and create clipboard
      $sheetdata->{clipboard}->{datavalues} = {};
      my $clipdatavalues = $sheetdata->{clipboard}->{datavalues};
      $sheetdata->{clipboard}->{datatypes} = {};
      my $clipdatatypes = $sheetdata->{clipboard}->{datatypes};
      $sheetdata->{clipboard}->{valuetypes} = {};
      my $clipvaluetypes = $sheetdata->{clipboard}->{valuetypes};
      $sheetdata->{clipboard}->{formulas} = {};
      my $clipdataformulas = $sheetdata->{clipboard}->{formulas};
      $sheetdata->{clipboard}->{cellerrors} = {};
      my $clipcellerrors = $sheetdata->{clipboard}->{cellerrors};
      $sheetdata->{clipboard}->{cellattribs} = {};
      my $clipcellattribs = $sheetdata->{clipboard}->{cellattribs};

      my $hostinfo = get_hostinfo($params);

      my ($loadpath, @headerlines, @sheetlines, $loaderror);

      if ($params->{editloadtype} eq "url") {
         $loadpath = $params->{loadsheeturl};
         if ($loadpath =~ m/^http:/i) { # URL - use HTTP GET
            my $ua = LWP::UserAgent->new; 
            $ua->agent("wikiCalc clipboard load");
            $ua->timeout(30);
            my $req = HTTP::Request->new("GET", $loadpath);
            $req->header('Accept' => '*/*');
            my $res = $ua->request($req);
            if ($res->is_success) {
               $loaderror = load_page_from_array($res->content, \@headerlines, \@sheetlines);
               }
            else {
               $loaderror = "$WKCStrings{toolspagetoolssheetunabletoload} '$loadpath'";
               }
            }
         }
      else {
         if ($params->{editloadtype} eq "published") {
            my ($sname, $pname);
            $sname = $params->{sitelist};
            $pname = $params->{sitepagelist};
            return $WKCStrings{"toolsexecsheetcannotload"} unless $pname;
            $loadpath = get_ensured_page_published_datafile_path($params, $hostinfo, $sname, $pname);
            return "$WKCStrings{toolsexecsheetnoloadpub} $sname:$pname." unless $loadpath;
            }
         elsif ($params->{editloadtype} eq "editing") {
            my ($sname, $pname);
            $sname = $params->{sitelist};
            $pname = $params->{sitepagelist};
            return $WKCStrings{"toolsexecsheetcannotload"} unless $pname;
            $loadpath = get_ensured_page_edit_path($params, $hostinfo, $sname, $pname);
            return "$WKCStrings{toolsexecsheetnoloadediting} $sname:$pname." unless $loadpath;
            }
         else {
            return $WKCStrings{"toolsexecsheetunabletoloadurl"};
            }

         $loaderror = load_page($loadpath, \@headerlines, \@sheetlines) unless $loaderror; # load the specified sheet
         }

      return $loaderror if $loaderror;

      my %loadedsheetdata;
      my $ok = parse_sheet_save(\@sheetlines, \%loadedsheetdata);

      my $crbase = $loadedsheetdata{clipboard}->{range};
      if (!$crbase) {
         $errortext = "$WKCStrings{toolsexecsheetemptyclipboard}\n";
         return $errortext;
         }
      my $loadedclipdatavalues = $loadedsheetdata{clipboard}->{datavalues};
      my $loadedclipdatatypes = $loadedsheetdata{clipboard}->{datatypes};
      my $loadedclipvaluetypes = $loadedsheetdata{clipboard}->{valuetypes};
      my $loadedclipdataformulas = $loadedsheetdata{clipboard}->{formulas};
      my $loadedclipcellerrors = $loadedsheetdata{clipboard}->{cellerrors};
      my $loadedclipcellattribs = $loadedsheetdata{clipboard}->{cellattribs};

      my ($clipcoord1, $clipcoord2) = split(/:/, $crbase);
      $clipcoord2 = $clipcoord1 unless $clipcoord2;
      my ($clipc1, $clipr1) = coord_to_cr($clipcoord1);
      my ($clipc2, $clipr2) = coord_to_cr($clipcoord2);

      for (my $r = $clipr1; $r <= $clipr2; $r++) {
         for (my $c = $clipc1; $c <= $clipc2; $c++) {
            my $clipcr = cr_to_coord($c, $r);
            $clipcellattribs->{$clipcr} = {'coord' => $clipcr}; # Start with minimal set
            foreach my $attribtype (keys %{$loadedclipcellattribs->{$clipcr}}) {
               if ($attribtype ne "coord") {
                  my $attribtarget = $attribtargets{$attribtype}; # see if the value is an index
                  if ($attribtarget) { # a numeric value indexing into a list
                     my $attribdef = 0; # find out index number of loaded sheet value in target
                     my $fullvalue = $loadedsheetdata{$attribtarget}->[$loadedclipcellattribs->{$clipcr}->{$attribtype}];
                     $attribdef = $sheetdata->{$attribhashes{$attribtarget}}->{$fullvalue} if length $fullvalue; # note: "0" is a legal format!
                     if (!$attribdef) { # create it
                        if (length $fullvalue) {
                           my $sheetattribvalues = $sheetdata->{$attribtarget};
                           my $sheetattribhash = $sheetdata->{$attribhashes{$attribtarget}};
                           push @$sheetattribvalues, "" unless scalar @$sheetattribvalues; # 1-origin
                           $attribdef = (push @$sheetattribvalues, $fullvalue) - 1;
                           $sheetattribhash->{$fullvalue} = $attribdef;
                           }
                        }
                     $clipcellattribs->{$clipcr}->{$attribtype} = $attribdef; # save index in target
                     }
                  else { # plain attribute value, just copy
                     $clipcellattribs->{$clipcr}->{$attribtype} = $loadedclipcellattribs->{$clipcr}->{$attribtype};
                     }
                  }
               }
            $clipdatavalues->{$clipcr} = $loadedclipdatavalues->{$clipcr};
            $clipdatatypes->{$clipcr} = $loadedclipdatatypes->{$clipcr};
            $clipvaluetypes->{$clipcr} = $loadedclipvaluetypes->{$clipcr};
            $clipdataformulas->{$clipcr} = $loadedclipdataformulas->{$clipcr};
            $clipcellerrors->{$clipcr} = $loadedclipcellerrors->{$clipcr};
            }
         }
      $sheetdata->{clipboard}->{range} = $loadedsheetdata{clipboard}->{range};

      add_to_editlog($headerdata, "# $WKCStrings{toolsexectoolsloadsheetclipboardsheetend}");
      }

   return $errortext;
}


# # # # # # # #
#
# $valuetype = determine_type($value)
#
# Returns the type of value to set the datatype (not valuetype): t or v
#
# !!! Eventually, make this deal with a wider range of value formats and use the "c" datatype, too. !!!
#
# # # # # # # #

sub determine_type {

   my $value = shift @_;

   return "v" if $value =~ m/^[+\- ]?[\d\.]+(?:[e|E][-+]?\d+)?$/;
   return "t";

}


# # # # # # # #
#
# set_clipboard_cell(\%headerdata, \%clipboard, $cr, $rawvalue)
#
# Sets the clipboard cell $cr with a value and type determined from $rawvalue
#
# # # # # # # #

sub set_clipboard_cell {

   my ($headerdata, $clipboard, $cr, $rawvalue) = @_;

   $clipboard->{cellattribs}->{$cr} = {'coord' => $cr};

   my $type;
   my $value = determine_value_type($rawvalue, \$type);

   if ($type eq 'n' && $value == $rawvalue) { # check that we don't need "constant" to remember original value
      $clipboard->{datatypes}->{$cr} = "v";
      $clipboard->{valuetypes}->{$cr} = "n";
      $clipboard->{datavalues}->{$cr} = $value;
      add_to_editlog($headerdata, "setclipboard $cr value $type $value");
      }
   elsif ($type eq 't') { # normal text
      $clipboard->{datatypes}->{$cr} = "t";
      $clipboard->{valuetypes}->{$cr} = "t";
      $clipboard->{datavalues}->{$cr} = $value;
      add_to_editlog($headerdata, "setclipboard $cr text $type $value");
      }
   else { # special number types
      $clipboard->{datatypes}->{$cr} = "c";
      $clipboard->{valuetypes}->{$cr} = $type;
      $clipboard->{datavalues}->{$cr} = $value;
      $clipboard->{formulas}->{$cr} = $rawvalue;
      add_to_editlog($headerdata, "setclipboard $cr constant $type $value $rawvalue");
      }

   }



# # # # # # # #
#
# $errortext = execute_tools_useradmincommand(\%params)
#
# Save updates to user admin info
#
# # # # # # # #

sub execute_tools_useradmincommand {

   my $params = shift @_;

   my ($ok, $errortext);

   my $hostinfo = get_hostinfo($params);

   $hostinfo->{requirelogin} = $params->{editrequirelogin};

   $ok = save_hostinfo($params, $hostinfo);

   my (%userinfo, %delete, %newuser);

   foreach my $p (keys %{$params}) {  # go through all the parameters

      if ($p =~ /^edit(displayname|admin|allsites|allreadsites):(.*)/) { # set values for displayname, admin, and allsites/allreadsites
         $userinfo{$2} = {} unless $userinfo{$2};
         $userinfo{$2}->{$1} = $params->{$p};
         }
      elsif ($p =~ /^editpassword:(.*)/) { # set new password
         $userinfo{$1} = {} unless $userinfo{$1};
         if ($params->{$p}) { # encrypt password if present, otherwise leave blank
            my $salt = join '', ($cryptsaltset[rand 64], $cryptsaltset[rand 64]);
            $userinfo{$1}->{password} = crypt($params->{$p}, $salt);
            }
         }
      elsif ($p =~ /^editsite:(.*):(.*)/) { # site setting
         $userinfo{$1} = {} unless $userinfo{$1};
         if ($userinfo{$1}->{sites}) {
            $userinfo{$1}->{sites} .= ",$2";
            }
          else {
            $userinfo{$1}->{sites} = $2;
            }
         }
      elsif ($p =~ /^editreadsite:(.*):(.*)/) { # readsite setting
         $userinfo{$1} = {} unless $userinfo{$1};
         if ($userinfo{$1}->{readsites}) {
            $userinfo{$1}->{readsites} .= ",$2";
            }
          else {
            $userinfo{$1}->{readsites} = $2;
            }
         }
      elsif ($p =~ /^editdelete:(.*)/) { # delete this user
         $userinfo{$1} = {} unless $userinfo{$1};
         $userinfo{$1}->{delete} = 1;
         }
      elsif ($p =~ /^editnew(username|displayname|admin|allsites|allreadsites)/) { # new user
         $newuser{$1} = $params->{$p};
         }
      elsif ($p eq "editnewpassword") { # new user password
         my $salt = join '', ($cryptsaltset[rand 64], $cryptsaltset[rand 64]);
         $newuser{password} = crypt($params->{$p}, $salt); # encrypt password
         }
      elsif ($p =~ /^editnewsite:(.*)/) { # new site setting
         if ($newuser{sites}) {
            $newuser{sites} .= ",$1";
            }
          else {
            $newuser{sites} = $1;
            }
         }
      elsif ($p =~ /^editnewreadsite:(.*)/) { # new site read setting
         if ($newuser{readsites}) {
            $newuser{readsites} .= ",$1";
            }
          else {
            $newuser{readsites} = $1;
            }
         }
      }

   my $olduserinfo = get_userinfo($params);

   foreach my $username (sort keys %userinfo) {
      my $ui = $userinfo{$username};
      my $oui = $olduserinfo->{$username};

      $ui->{admin} = $ui->{admin} ? "yes" : "no";
      $ui->{allsites} = $ui->{allsites} ? "yes" : "no";
      $ui->{allreadsites} = $ui->{allreadsites} ? "yes" : "no";

      if ($ui->{displayname} ne $oui->{displayname}
          || $ui->{admin} ne $oui->{admin}
          || $ui->{allsites} ne $oui->{allsites}
          || $ui->{allreadsites} ne $oui->{allreadsites}
          || $ui->{sites} ne $oui->{sites}
          || $ui->{readsites} ne $oui->{readsites}
          || $ui->{password} # any password is a change
          || $ui->{delete}
                            ) {
         $ui->{password} ||= $oui->{password};
         $errortext = update_userinfo($params, \%userinfo, $username);
         }
      }
   if ($newuser{username}) { # new user
      my $username = lc $newuser{username};
      $username =~ s/[^a-z0-9\-]//g;
      $userinfo{$username} = {};
      my $ui = $userinfo{$username};
      $ui->{displayname} = $newuser{displayname};
      $ui->{admin} = $newuser{admin} ? "yes" : "no";
      $ui->{allsites} = $newuser{allsites} ? "yes" : "no";
      $ui->{allreadsites} = $newuser{allreadsites} ? "yes" : "no";
      $ui->{password} = $newuser{password};
      $ui->{sites} = $newuser{sites};
      $ui->{readsites} = $newuser{readsites};

      $errortext = update_userinfo($params, \%userinfo, $username);
      }

      $params->{"oktools:useradmin"} = 1; # stay in sub-tab if error

   return "";

}
