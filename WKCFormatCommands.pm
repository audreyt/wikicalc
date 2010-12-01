#
# WKCFormatCommands.pl -- Commands to set number or text formats, column widths, etc.
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCFormatCommands;

   use strict;
   use CGI qw(:standard);
   use utf8;

   use WKCStrings;
   use WKC;
   use WKCSheet;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(do_format_command);
   our $VERSION = '1.0.0';

#
# Locals
#

# Return something

   1;

# # # # # # # #
#
# ($stylestr, $response) = do_format_command(\%params, \%sheetdata, \%headerdata, $hiddenfields, $editcoords, $editmode)
#
# Do the stuff for the Format tab
#
# # # # # # # #

sub do_format_command {

   my ($params, $sheetdata, $headerdata, $hiddenfields, $editcoords, $editmode) = @_;

   my ($response, $inlinescripts);

   # Load scripts from a file

   $inlinescripts .= $WKCStrings{"jsdefinestrings"};
   open JSFILE, "$WKCdirectory/WKCjs.txt";
   while (my $line = <JSFILE>) {
      $inlinescripts .= $line;
      }
   close JSFILE;

   $inlinescripts .= $WKCStrings{"formatjsdefinestrings"};
   open JSFILE, "$WKCdirectory/WKCformatjs.txt";
   while (my $line = <JSFILE>) {
      $inlinescripts .= $line;
      }
   close JSFILE;
 
   my (@formatdef_samples, @formatdef_textformats, @formatdef_numberformats, @formatdef_currencies);

   open FDFILE, "$WKCdirectory/$definitionsfile";
   while (my $line = <FDFILE>) {
      chomp $line;
      $line =~ s/\r//g;
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      my ($fdtype, $rest) = split(/:/, $line, 2);
      if ($fdtype eq "sample") { # sample:index:value1|value2|...
         my ($sindex, $srest) = split(/:/, $rest, 2);
         $formatdef_samples[$sindex] = $srest;
         }
      elsif ($fdtype eq "number") { # number:displayname|category1:category2:...|sampleindex|format-text
         push @formatdef_numberformats, $rest;
         }
      elsif ($fdtype eq "text") { # text:displayname|sampleindex|hint|format-text
         push @formatdef_textformats, $rest;
         }
      elsif ($fdtype eq "currency") { # currency:displayname|value
         push @formatdef_currencies, $rest;
         }
      # ignore other lines
      }
   close FDFILE;
 
   my $coord = $editcoords;
   $coord =~ s/:.*$//; # only first cell

   my $linkstyle = "?view=$params->{sitename}/[[pagename]]";
   my ($stylestr, $outstr) = render_sheet($sheetdata, 'id="sheet0" class="wkcsheet"', "", "s", "a", "ajax", $coord, q! onclick="rc0('$coord');"!, , $linkstyle);

   my %celldata;
   my ($lcol, $lrow) = render_values_only($sheetdata, \%celldata, $linkstyle);
   my $jsdata = qq!var isheet="";\nisheet="!;

   foreach my $cr (sort keys %celldata) { # construct output
      my $cellspecifics = $celldata{$cr};
      my $displayvalue = encode_for_save($cellspecifics->{display});
      $displayvalue = "" if $displayvalue eq "&nbsp;"; # this is the default
      my $crattribs = $sheetdata->{cellattribs}->{$cr};
      my $csssvalue = encode_for_save($crattribs->{csss});
      my $str = "$cr:$displayvalue:$cellspecifics->{align}:$cellspecifics->{colspan}:$cellspecifics->{rowspan}:$cellspecifics->{skip}";
      $str .= ":b|$crattribs->{bt}|$crattribs->{br}|$crattribs->{bb}|$crattribs->{bl}|l|$crattribs->{layout}";
      $str .= "|f|$crattribs->{font}|c|$crattribs->{color}|bg|$crattribs->{bgcolor}";
      $str .= "|cv|$crattribs->{cellformat}|tvf|$crattribs->{textvalueformat}|ntvf|$crattribs->{nontextvalueformat}|cssc|$crattribs->{cssc}|csss|$csssvalue|mod|$crattribs->{mod}";
      $str =~ s/\\/\\\\/g;
      $str =~ s/"/\\x22/g;
      $str =~ s/</\\x3C/g;
      $jsdata .= "$str\\n";
      }

   my $fonts = $sheetdata->{fonts}; # include full format attribute strings
   my $colors = $sheetdata->{colors};
   my $layoutstyles = $sheetdata->{layoutstyles};
   my $borderstyles = $sheetdata->{borderstyles};
   my $cellformats = $sheetdata->{cellformats};
   my $valueformats = $sheetdata->{valueformats};
   my $colattribs = $sheetdata->{colattribs};
   my $rowattribs = $sheetdata->{rowattribs};
   my $sheetattribs = $sheetdata->{sheetattribs};

   for (my $i=1; $i<@$fonts; $i++) {
      my $f = $fonts->[$i];
      $f =~ s/"/\\x22/g;
      $f =~ s/</\\x3C/g;
      $jsdata .= "font:$i:$f\\n";
      }
   for (my $i=1; $i<@$colors; $i++) {
      $jsdata .= "color:$i:$colors->[$i]\\n";
      }
   for (my $i=1; $i<@$layoutstyles; $i++) {
      my $str = $layoutstyles->[$i];
      $str =~ s/\:/\\\\c/g;
      $jsdata .= "layout:$i:$str\\n";
      }
   for (my $i=1; $i<@$borderstyles; $i++) {
      $jsdata .= "border:$i:$borderstyles->[$i]\\n";
      }
   for (my $i=1; $i<@$cellformats; $i++) {
      my $str = $cellformats->[$i];
      $str =~ s/"/\\x22/g;
      $str =~ s/</\\x3C/g;
      $str =~ s/\:/\\\\c/g;
      $str =~ s/</\\x3C/g;
      $jsdata .= "cellformat:$i:$str\\n";
      }
   for (my $i=1; $i<@$valueformats; $i++) {
      my $str = $valueformats->[$i];
      $str =~ s/\\/\\\\/g;
      $str =~ s/"/\\x22/g;
      $str =~ s/\:/\\\\c/g;
      $str =~ s/</\\x3C/g;
      $jsdata .= "valueformat:$i:$str\\n";
      }
   for (my $col = 1; $col <= $lcol; $col++) {
      my $colcoord = cr_to_coord($col, 1);
      $colcoord =~ s/\d+//;
      $jsdata .= "col:$colcoord:w:$colattribs->{$colcoord}->{width}\\n" if $colattribs->{$colcoord}->{width};
      $jsdata .= "col:$colcoord:hide:$colattribs->{$colcoord}->{hide}\\n" if $colattribs->{$colcoord}->{hide};
      }
   for (my $row = 1; $row <= $lrow; $row++) {
      $jsdata .= "row:$row:hide:$rowattribs->{$row}->{hide}\\n" if $rowattribs->{$row}->{hide};
      }
   foreach my $field (keys %sheetfields) {
      $jsdata .= "sheet:$sheetfields{$field}:$sheetattribs->{$field}\\n" if $sheetattribs->{$field};
      }

   $jsdata .= qq!"\n!; # end the long string with initialization data

   $response .= <<"EOF";
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td class="ttbody" width="100%"><form name="f0" method="POST"><table cellspacing="0" cellpadding="0" style="margin-top:4px;"><tr><td valign="top">
<div style="margin-bottom:4px;">
<span id="coordtext"><span class="smaller">$WKCStrings{formatloading}</span></span>
<span id="rangeend">&nbsp;</span>
<span class="warning" id="warning">&nbsp;</span><br>
<table class="buttonbar" cellspacing="0" cellpadding="0"><tr>
<td id="numbersbutton"><input class="smaller" type="submit" name="bnumbers" value="$WKCStrings{"formatnumbers"}" onclick="this.blur();return switchto('numbers');">
</td><td id="textbutton"><input class="smaller" type="submit" name="btext" value="$WKCStrings{"formattext"}" onclick="this.blur();return switchto('text');">
</td><td id="fontsbutton"><input class="smaller" type="submit" name="bfonts" value="$WKCStrings{"formatfonts"}" onclick="this.blur();return switchto('fonts');">
</td><td id="colorsbutton"><input class="smaller" type="submit" name="bcolors" value="$WKCStrings{"formatcolors"}" onclick="this.blur();return switchto('colors');">
</td><td id="bordersbutton"><input class="smaller" type="submit" name="bborders" value="$WKCStrings{"formatborders"}" onclick="this.blur();return switchto('borders');">
</td><td id="layoutbutton"><input class="smaller" type="submit" name="blayout" value="$WKCStrings{"formatlayout"}" onclick="this.blur();return switchto('layout');">
</td><td id="columnsbutton"><input class="smaller" type="submit" name="bcolumns" value="$WKCStrings{"formatcolumns"}" onclick="this.blur();return switchto('columns');">
</td><td id="rowsbutton"><input class="smaller" type="submit" name="brows" value="$WKCStrings{"formatrows"}" onclick="this.blur();return switchto('rows');">
</td><td id="miscbutton"><input class="smaller" type="submit" name="bmisc" value="$WKCStrings{"formatmisc"}" onclick="this.blur();return switchto('misc');">
</td></tr></table></div>

<div id="c1numbers" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatalignment"}</td><td>&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatformat"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td>
<input type="radio" name="numbersalign" value="default" onclick="display_controls_numbers();" CHECKED><span class="smaller">$WKCStrings{"formatdefault"}</span>
<input type="radio" name="numbersalign" value="left" onclick="display_controls_numbers();"><span class="smaller">$WKCStrings{"formatleft"}</span>
<input type="radio" name="numbersalign" value="center" onclick="display_controls_numbers();"><span class="smaller">$WKCStrings{"formatcenter"}</span>
<input type="radio" name="numbersalign" value="right" onclick="display_controls_numbers();"><span class="smaller">$WKCStrings{"formatright"}</span>
</td>
<td></td>
<td>
<input type="hidden" name="numbersvalueformat" value="">
<select name="nvclist" size="1" onchange="set_controls_numbers_newcategory();" onfocus="nvclistfocus=true;" onblur="nvclistfocus=false;">
EOF

   $inlinescripts .= "<script>\n"; # var valueformatvalues=[];\n";
   $inlinescripts .= "var vfnames=[], vfcategories=[], vfsamples=[], vfstrings=[];\n";
   my $i = 0;
   my %foundcategories;
   foreach my $fdef (@formatdef_numberformats) {
      my ($dname, $categories, $sindex, $ftext) = split(/\|/, $fdef, 4);
      my $str;
      foreach my $val (split(/\|/, $formatdef_samples[$sindex])) {
         $str .= "<br>" if length($str);
         if ($val =~ m/^'/) { # explict text
            $str = substr($val,1);
            }
         else { # a number to convert
            $str .= format_number_for_display($val+0, "n", ($ftext eq "default" ? "" : $ftext));
            }
         }
      $str =~ s/\\/\\\\/g;
      $str =~ s/"/\\x22/g;
      $str =~ s/</\\x3C/g;
      $ftext =~ s/\\/\\\\/g;
      $ftext =~ s/"/\\x22/g;
      $ftext =~ s/</\\x3C/g;
      $inlinescripts .= qq!vfnames[$i]="$dname";vfcategories[$i]=":$categories:";vfsamples[$i]="$str";vfstrings[$i]="$ftext";\n!;
      $i++;
      foreach my $cat (split(/:/, $categories)) { # Fill in list of categories
         if (!$foundcategories{$cat}) {
            $foundcategories{$cat} = 1;
            $response .= <<"EOF";
<option value="$cat">$cat
EOF
            }
         }
      }
   $inlinescripts .= "</script>\n";

   $response .= <<"EOF";
</select>
<select name="nvflist" size="1" onchange="display_controls_numbers();">
</select>
<select name="nvcurrencylist" size="1" onchange="update_explicit_currency();display_controls_numbers();">
EOF
   foreach my $cur (@formatdef_currencies) { # Fill in list of currencies
      my ($dn, $val) = split(/\|/, $cur, 2);
      $response .= <<"EOF";
<option value="$val">$dn
EOF
      }

   $response .= <<"EOF";
</select><input type="text" name="numbercustomformat" size="15" autocomplete="off" onfocus="cwvedit=true;" onblur="cwvedit=false;">
</td>
<td></td><td><input name="numbersedefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefault"}</span></td>
</tr></table>
<br>
</div>

<div id="c1text" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatalignment"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatformat"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td>
<input type="radio" name="textalign" value="default" onclick="display_controls_text();" CHECKED><span class="smaller">$WKCStrings{"formatdefault"}</span>
<input type="radio" name="textalign" value="left" onclick="display_controls_text();"><span class="smaller">$WKCStrings{"formatleft"}</span>
<input type="radio" name="textalign" value="center" onclick="display_controls_text();"><span class="smaller">$WKCStrings{"formatcenter"}</span>
<input type="radio" name="textalign" value="right" onclick="display_controls_text();"><span class="smaller">$WKCStrings{"formatright"}</span>
</td><td></td>
<td>
<select name="textvalueformat" size="1" onchange="display_controls_text();">
EOF

   $inlinescripts .= "<script>\nvar tvfsamples=[];\n";
   my $tfindex=0;
   foreach my $fdef (@formatdef_textformats) {
      my ($dname, $samplenum, $ihint, $ftext) = split(/\|/, $fdef, 4);
      $ftext ||= $ihint;
      $ftext =~ s/"/&quot;/g;
      $response .= qq!<option value="$ftext">$dname!;
      my $str = $formatdef_samples[$samplenum];
      $str =~ s/^'//;
      $str =~ s/\\/\\\\/g;
      $str =~ s/"/\\x22/g;
      $str =~ s/</\\x3C/g;
      $inlinescripts .= qq!tvfsamples[$tfindex]="$str";\n!;
      $tfindex++;
      }
   $inlinescripts .= "</script>\n";

   $response .= <<"EOF";
</select>
</td>
<td></td><td><input name="textedefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefault"}</span></td>
</tr></table>
<br>
</div>

<div id="c1fonts" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatfontfamily"}</td><td>&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600"">$WKCStrings{"formatfontsize"}</td><td>&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600"">$WKCStrings{"formatfontweightandstyle"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td>
<select name="fontfamily" size="1" onchange="display_controls_font();">
EOF

   while ($WKCStrings{formatfontfamilies} =~ m/^([^\|]+)\|([^\|]+)$/gm) {
      $response .= <<"EOF";
<option value="$1">$2
EOF
      }

   $response .= <<"EOF";
</select>
</td>
<td></td>
<td>
<select name="fontsize" size="1" onchange="display_controls_font();">
EOF

   while ($WKCStrings{formatfontsizes} =~ m/^([^\|]+)\|([^\|]+)$/gm) {
      $response .= <<"EOF";
<option value="$1">$2
EOF
      }

   $response .= <<"EOF";
</select>
</td>
<td></td>
<td>
<input name="fontdefault" type="checkbox" CHECKED onclick="document.f0.fontbold.checked=false;document.f0.fontitalic.checked=false;display_controls_font();" value="*"><span class="smaller">$WKCStrings{"formatdefault"}</span>
<input name="fontbold" type="checkbox" onclick="document.f0.fontdefault.checked=false;display_controls_font();" value="bold"><span class="smaller">$WKCStrings{"formatbold"}</span>
<input name="fontitalic" type="checkbox" onclick="document.f0.fontdefault.checked=false;display_controls_font();" value="italic"><span class="smaller">$WKCStrings{"formatitalic"}</span>
</td>
<td></td><td><input name="fontedefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefault"}</span></td>
</tr></table>
<br>
</div>

<div id="c1colors" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formattextcolor"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600"">$WKCStrings{"formatbackgroundcolor"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td align="center">
<div id="textcolorbox" style="height:20px;width:20px;border:1px solid black;" onclick="showcolorchooser(event,'textcolorbox','edittextcolor');"><img src="?getfile=1x1" width=1 height=1></div>
<input name="edittextcolor" type="hidden" value="">
</td>
<td></td>
<td align="center">
<div id="bgcolorbox" style="height:20px;width:20px;border:1px solid black;" onclick="showcolorchooser(event,'bgcolorbox','editbackgroundcolor');"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editbackgroundcolor" type="hidden" value="">
</td>
<td></td><td><input name="colorsedefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefault"}</span></td>
</tr></table>
<br>
</div>

<div id="colorchooser" style="display:none;position:absolute;border:1px solid black;background-color:#EEEEEE;padding:4px;z-index:100;">
<table cellspacing="2" cellpadding="0">
<tr>
<td colspan="5">
<table cellspacing="0" cellpadding="0"
<tr><td><div class="defaultbox" onclick="ccolor('');"><img src="?getfile=1x1" height="1" width="1"></div></td>
<td class="smaller" valign="center">&nbsp;$WKCStrings{"formatcolordefault"}</td>
</tr></table></td>
<td colspan="5" valign="center" align="right"><input type="submit" class="smaller" value="$WKCStrings{"formatcolorcancel"}" onclick="this.blur();hidecolorchooser();return false;">
</td>
</tr>
<script>
var colorlist="";
colorlist+="FFCCCC:FFCC99:FFFFCC:CCFFCC:99FFCC:CCCCFF:CC99FF:FFCCFF:FFFFFF|";
colorlist+="FF9999:FFCC66:FFFF99:99FF99:66FFCC:9999FF:CC66FF:FF99FF:DDDDDD|";
colorlist+="FF6666:FFCC33:FFFF66:66FF66:33FFCC:6666FF:CC33FF:FF66FF:CCCCCC|";
colorlist+="FF3333:FF9933:FFFF33:33FF33:33FF99:3333FF:9933FF:FF33FF:BBBBBB|";
colorlist+="FF0000:FF9900:FFFF00:00FF00:00FF99:0000FF:9900FF:FF00FF:AAAAAA|";
colorlist+="CC0000:FF6600:CCCC00:00CC00:00FF66:0000CC:6600FF:CC00CC:999999|";
colorlist+="990000:CC6600:999900:009900:00CC66:000099:6600CC:990099:666666|";
colorlist+="660000:993300:666600:006600:009933:000066:330099:660066:333333|";
colorlist+="330000:663300:333300:003300:006633:000033:330066:330033:000000";
var colorline=colorlist.split("|");
for (var i=0;i<colorline.length;i++) {
 document.write('<tr>');
 var colors=colorline[i].split(":")
 for (var j=0;j<colors.length;j++) {
  document.write('<td style="font-size:1pt;"><div class="colorbox" style="background-color:#'+colors[j]+'" onclick="ccolor(\\''+colors[j]+'\\');"><img src="?getfile=1x1" width=1 height=1></div></td>');
  }
 document.write("</tr>");
 }
</script>
</table>
<input type="text" name="explicitcolor" class="smaller" value="4D5EFF" size="8">
<input type="submit" class="smaller" value="$WKCStrings{"formatcolorok"}" onclick="this.blur();ccolor(document.f0.explicitcolor.value);return false;"><br>
</div>

<div id="c1borders" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr><td>
<table cellspacing="0" cellpadding="0" id="bordertable1">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatvisibility"}</td><td>&nbsp;&nbsp;</td>
<td id="bhead0t" style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatthickness"}</td><td>&nbsp;&nbsp;</td>
<td id="bhead0s" style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatstyle"}</td><td>&nbsp;&nbsp;</td>
<td id="bhead0c" style="font-size:smaller;font-weight:bold;color:#006600"">$WKCStrings{"formatcolor"}</td>
</tr>
<tr>
<td valign="top" nowrap>
<input name="showborder0" type="checkbox" onclick="display_controls_borders();"><span id="showbtext0" class="smaller">$WKCStrings{"formatallborders"}</span>
</td>
<td>&nbsp;</td>
<td valign="top">
<select name="border0width" size="1" onchange="document.f0.showborder0.checked=true;display_controls_borders();">$WKCStrings{formatborderwidthoptions}</select>
</td>
<td>&nbsp;</td>
<td valign="top">
<select size="1" name="border0style" onchange="document.f0.showborder0.checked=true;display_controls_borders();">$WKCStrings{formatborderstyleoptions}</select>
</td>
<td>&nbsp;</td>
<td align="center" valign="top">
<div id="border0colorbox" style="height:20px;width:20px;border:1px solid black;" onclick="document.f0.showborder0.checked=true;showcolorchooser(event,'border0colorbox',false);"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editborder0" type="hidden" value="">
</td>
</tr>
</table>

<table cellspacing="0" cellpadding="0" id="bordertable4" style="display:none;">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatvisibility"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatthickness"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatstyle"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600"">$WKCStrings{"formatcolor"}</td>
</tr>
<tr>
<td valign="top" nowrap>
<input name="showborder1" type="checkbox" onclick="display_controls_borders();"><span id="showbtext1" class="smaller">$WKCStrings{"formattopborder"}</span>
</td>
<td>&nbsp;</td>
<td valign="top">
<select name="border1width" size="1" onchange="document.f0.showborder1.checked=true;display_controls_borders();">$WKCStrings{formatborderwidthoptions}</select>
</td>
<td>&nbsp;</td>
<td valign="top" style="padding-bottom:6px;">
<select size="1" name="border1style" onchange="document.f0.showborder1.checked=true;display_controls_borders();">$WKCStrings{formatborderstyleoptions}</select>
</td>
<td>&nbsp;</td>
<td align="center" valign="top">
<div id="border1colorbox" style="height:20px;width:20px;border:1px solid black;" onclick="document.f0.showborder1.checked=true;showcolorchooser(event,'border1colorbox',false);"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editborder1" type="hidden" value="">
</td>
</tr>

<tr>
<td valign="top" nowrap>
<input name="showborder2" type="checkbox" onclick="display_controls_borders();"><span id="showbtext2" class="smaller">$WKCStrings{"formatrightborder"}</span>
</td>
<td>&nbsp;</td>
<td valign="top">
<select name="border2width" size="1" onchange="document.f0.showborder2.checked=true;display_controls_borders();">$WKCStrings{formatborderwidthoptions}</select>
</td>
<td>&nbsp;</td>
<td valign="top" style="padding-bottom:6px;">
<select size="1" name="border2style" onchange="document.f0.showborder2.checked=true;display_controls_borders();">$WKCStrings{formatborderstyleoptions}</select>
</td>
<td>&nbsp;</td>
<td align="center" valign="top">
<div id="border2colorbox" style="height:20px;width:20px;border:1px solid black;" onclick="document.f0.showborder2.checked=true;showcolorchooser(event,'border2colorbox',false);"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editborder2" type="hidden" value="">
</td>
</tr>

<tr>
<td valign="top" nowrap>
<input name="showborder3" type="checkbox" onclick="display_controls_borders();"><span id="showbtext3" class="smaller">$WKCStrings{"formatbottomborder"}</span>
</td>
<td>&nbsp;</td>
<td valign="top">
<select name="border3width" size="1" onchange="document.f0.showborder3.checked=true;display_controls_borders();">$WKCStrings{formatborderwidthoptions}</select>
</td>
<td>&nbsp;</td>
<td valign="top" style="padding-bottom:6px;">
<select size="1" name="border3style" onchange="document.f0.showborder3.checked=true;display_controls_borders();">$WKCStrings{formatborderstyleoptions}</select>
</td>
<td>&nbsp;</td>
<td align="center" valign="top">
<div id="border3colorbox" style="height:20px;width:20px;border:1px solid black;" onclick="document.f0.showborder3.checked=true;showcolorchooser(event,'border3colorbox',false);"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editborder3" type="hidden" value="">
</td>
</tr>

<tr>
<td valign="top" nowrap>
<input name="showborder4" type="checkbox" onclick="display_controls_borders();"><span id="showbtext4" class="smaller">$WKCStrings{"formatleftborder"}</span>
</td>
<td>&nbsp;</td>
<td valign="top">
<select name="border4width" size="1" onchange="document.f0.showborder4.checked=true;display_controls_borders();">$WKCStrings{formatborderwidthoptions}</select>
</td>
<td>&nbsp;</td>
<td valign="top">
<select size="1" name="border4style" onchange="document.f0.showborder4.checked=true;display_controls_borders();">$WKCStrings{formatborderstyleoptions}</select>
</td>
<td>&nbsp;</td>
<td align="center" valign="top">
<div id="border4colorbox" style="height:20px;width:20px;border:1px solid black;" onclick="document.f0.showborder4.checked=true;showcolorchooser(event,'border4colorbox',false);"><img src="?getfile=1x1" width=1 height=1></div>
<input name="editborder4" type="hidden" value="">
</td>
</tr>
</table>

</td>
<td>&nbsp;&nbsp;</td>
<td valign="top">
<input name="borderoutline" type="checkbox" value="outline"><span class="smaller">$WKCStrings{"formatoutlinecellrangeonly"}</span><br>
<input name="bordersseparately" type="checkbox" onclick="display_controls_borders();"><span class="smaller">$WKCStrings{"formatsetsidesseparately"}</span>
</td>
</tr></table>
<br>
</div>

<div id="c1layout" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatcelllayout"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600" id="lalignment">$WKCStrings{"formatvalignment"}</td><td>&nbsp;&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600" id="lpadding">$WKCStrings{"formatpadding"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td valign="top">
<input type="radio" name="explicitlayout" value="no" onclick="display_controls_layout();" CHECKED><span class="smaller" id="lusedefault">$WKCStrings{"formatlusedefault"}</span><br>
<input type="radio" name="explicitlayout" value="yes" onclick="display_controls_layout();"><span class="smaller" id="lsetexplicitly">$WKCStrings{"formatlsetexplicitly"}</span><br>
</td>
<td></td>
<td valign="top" nowrap>
<input type="radio" name="verticalalign" value="top" onclick="document.f0.explicitlayout[1].checked=true;display_controls_layout();" CHECKED><span class="smaller">$WKCStrings{"formataligntop"}</span><br>
<br>
<input type="radio" name="verticalalign" value="middle" onclick="document.f0.explicitlayout[1].checked=true;display_controls_layout();"><span class="smaller">$WKCStrings{"formatalignmiddle"}</span><br>
<br>
<input type="radio" name="verticalalign" value="bottom" onclick="document.f0.explicitlayout[1].checked=true;display_controls_layout();"><span class="smaller">$WKCStrings{"formatalignbottom"}</span>
</td>
<td></td>
EOF

   my $paddingoptionstr;
   while ($WKCStrings{formatpaddingsizes} =~ m/^([^\|]+)\|([^\|]+)$/gm) {
      $paddingoptionstr .= <<"EOF";
<option value="$1">$2
EOF
      }
   $response .= <<"EOF";
<td nowrap valign="top">
<div style="text-align:center;border:1px solid #006600;padding:0px 3px 2px 4px;margin:0px 0px 4px 0px;background-color:#EEFFEE;">
<span style="font-size:smaller;">$WKCStrings{"formatpaddingtop"}</span><br>
<select name="layoutpaddingtop" size="1" onchange="document.f0.explicitlayout[1].checked=true;display_controls_layout();">
$paddingoptionstr
</select><br>
<span style="font-size:smaller;">$WKCStrings{"formatpaddingleft"}</span>
<select name="layoutpaddingleft" size="1" onchange="document.f0.explicitlayout[1].checked=true;display_controls_layout();">
$paddingoptionstr
</select>
<select name="layoutpaddingright" size="1" onchange="document.f0.explicitlayout[1].checked=true;display_controls_layout();">
$paddingoptionstr
</select>
<span style="font-size:smaller;">$WKCStrings{"formatpaddingright"}</span>
<br>
<select name="layoutpaddingbottom" size="1" onchange="document.f0.explicitlayout[1].checked=true;display_controls_layout();">
$paddingoptionstr
</select><br>
<span style="font-size:smaller;">$WKCStrings{"formatpaddingbottom"}</span>
</div>
</td>
<td></td>
<td valign="top">
<input name="layoutdefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefault"}</span>
</td>
</tr></table>
</div>

<div id="c1columns" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatwidth"}</td><td>&nbsp;&nbsp;</td>
<td id="colvistext" style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatcolvisibility"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatallcells"}</td>
</tr><tr>
<td>
<input type="radio" name="colwidthtype" value="default" onclick="display_controls_columns();" CHECKED><span class="smaller">$WKCStrings{"formatdefault"}</span>
<input type="radio" name="colwidthtype" value="auto" onclick="display_controls_columns();"><span class="smaller">$WKCStrings{"formatauto"}</span>
<input type="radio" name="colwidthtype" value="explicit" onclick="document.f0.colwidthvalue.value=80;document.f0.colwidthpercent.checked=false;display_controls_columns();"><span class="smaller">$WKCStrings{"formatsetcol"}</span>
<input type="text" name="colwidthvalue" size="4" value="25" autocomplete="off" onfocus="cwvedit=true;if(!this.value)this.value='1';document.f0.colwidthtype[2].checked=true;display_controls_columns();" onblur="cwvedit=false;" onchange="display_controls_columns();">
<input type="checkbox" name="colwidthpercent" value="percent" onclick="display_controls_columns();"><span class="smaller">%</span>
</td>
<td></td>
<td>
<input type="checkbox" name="colhidevalue" value="hide" onclick="display_controls_columns();"><span class="smaller">$WKCStrings{"formathidewhenpublished"}</span>
</td>
<td></td>
<td><input name="columnsedefault" type="checkbox" onclick="update_formatpreview();"><span class="smaller">$WKCStrings{"formateditdefaultwidth"}</span></td>
</tr></table>
<table cellspacing="0" cellpadding="0" style="margin-top:10px;"><tr>
<td valign="top"><div style="border-bottom:1px solid black;width:500px;border-left:1px solid black;height:15px;font-size:1pt;background:url(?getfile=colsizescale) repeat-x bottom left;;z-index:75;">&nbsp;</div>
</td><td valign="top" style="font-size:1pt;"><img id="coldraghandle" unselectable="on" src="?getfile=colsizehandle" style="position:relative;top:0px;left:-400px;z-index:100;" onmousedown="begincoldrag(event);return false;"></td>
</tr></table>
</div>

<div id="c1rows" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatrowvisibility"}</td><td>&nbsp;&nbsp;</td>
</tr><tr>
<td>
<input type="checkbox" name="rowhidevalue" value="hide" onclick="display_controls_rows();"><span class="smaller">$WKCStrings{"formathiderowwhenpublished"}</span>
</td>
<td></td>
</tr></table>
<br>
</div>

<div id="c1misc" style="display:none;">
<table cellspacing="0" cellpadding="0">
<tr>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatcellcssclass"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatcellcssstyle"}</td><td>&nbsp;&nbsp;</td>
<td style="font-size:smaller;font-weight:bold;color:#006600">$WKCStrings{"formatliveviewmodifiable"}</td>
</tr><tr>
<td valign="top">
<input type="text" name="miscclassvalue" size="15" value="" autocomplete="off" onfocus="cwvedit=true;" onblur="cwvedit=false;" onchange="display_controls_misc();"><br>
<div class="smaller" style="width:12em;">$WKCStrings{"formatcssclassdesc"}</div>
</td>
<td></td>
<td valign="top">
<textarea name="miscstylevalue" cols="25" rows="5" onfocus="cwvedit=true;" onblur="cwvedit=false;" onchange="display_controls_misc();">
</textarea>
<div class="smaller" style="width:20em;">$WKCStrings{"formatcssstyledesc"}</div>
</td>
<td></td>
<td valign="top">
<div class="smaller" style="width:12em;">
<input type="checkbox" name="miscmodvalue" value="y">$WKCStrings{"formatyes"}<br>
$WKCStrings{"formatmodifiabledesc"}
</td></tr>
</table>
<br>
</div>
EOF

   # Keep spaces out between hidden buttons -- some browsers (IE) don't compress them
   $response .= qq!<input id="c2numbers" class="smaller" type="submit" name="oknumeric" value="$WKCStrings{"formatsavenumbersettings"}" onclick="check_custom_vf();" style="display:none;">!;
   $response .= qq!<input id="c2text" class="smaller" type="submit" name="oktext" value="$WKCStrings{"formatsavetextsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2fonts" class="smaller" type="submit" name="okfonts" value="$WKCStrings{"formatsavefontsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2colors" class="smaller" type="submit" name="okcolors" value="$WKCStrings{"formatsavecolorsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2borders" class="smaller" type="submit" name="okborders" value="$WKCStrings{"formatsavebordersettings"}" style="display:none;">!;
   $response .= qq!<input id="c2layout" class="smaller" type="submit" name="oklayout" value="$WKCStrings{"formatsavelayoutsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2columns" class="smaller" type="submit" name="okcolumns" value="$WKCStrings{"formatsavecolumnsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2rows" class="smaller" type="submit" name="okrows" value="$WKCStrings{"formatsaverowsettings"}" style="display:none;">!;
   $response .= qq!<input id="c2misc" class="smaller" type="submit" name="okmisc" value="$WKCStrings{"formatsavemiscsettings"}" style="display:none;">!;
   $response .= <<"EOF";

<input class="smaller" type="submit" name="rangeformat" value="$WKCStrings{"formatrange"}" onClick="range_button();return false;">
<input class="smaller" type="submit" name="cancelformat" value="$WKCStrings{"formatmaincancel"}" onClick="cancel_range();">
<input class="smaller" type="submit" name="okedit" value="$WKCStrings{"formathelp"}" onclick="toggle_help('formathelptext');this.blur();return false;">
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
<td>&nbsp;</td>
<td valign="top">
<div id="formattype" style="font-size:smaller;font-weight:bold;text-align:center;margin-bottom:3px;">&nbsp;</div>
<div style="background-color:white;padding:5px;margin:5px;border:1px solid #99CC99;">
<div id='fpnumbers' style="padding:5px;display:none;">&nbsp;</div>
<div id='fptext' style="padding:5px;display:none;">$WKCStrings{"formatinitialfptext"}</div>
<div id='fpfonts' style="padding:5px;display:none;">$WKCStrings{"formatinitialfpfonts"}</div>
<div id='fpcolors' style="padding:5px;display:none;">$WKCStrings{"formatinitialfpcolors"}</div>
<div id='fpborders' style="padding:5px;margin:4px;display:none;">$WKCStrings{"formatinitialfpborders"}</div>
<div id='fplayout' style="padding:5px;display:none;">$WKCStrings{"formatinitialfplayout"}</div>
<div id='fpcolumns' style="padding:5px;display:none;font-size:smaller;text-align:center;">
$WKCStrings{"formatinitialfpcolumns"}
</div>
<div id='fprows' style="padding:5px;display:none;font-size:smaller;text-align:center;">
&nbsp;&nbsp;<br><br>
</div>
<div id='fpmisc' style="padding:5px;display:none;font-size:smaller;text-align:center;">
$WKCStrings{"formatinitialfpmisc"}
</div>
</div>
</td>
</tr></table>
EOF

   my ($highlightpos, $highlighton, $showhighlight);
   if ($editcoords =~ m/:(\S+)/) {
      $highlightpos = $1;
      $highlighton = "true";
      $showhighlight = "highlight_block(ecell, highlightpos, '#DDFFDD');";

      }
   else {
      $highlighton = "false";
      }

   $inlinescripts .= <<"EOF";
<script>

$jsdata

sheetlastcol=$lcol;
sheetlastrow=$lrow;
parse_sheet(isheet);
ecell="$coord";
highlightpos="$highlightpos";
highlighton=$highlighton;
check_error();
var setf = function() {save_initial_sheet_data();save_coldata();move_cursor(ecell,ecell,true);switchto(document.f0.formatmode.value||"numbers");$showhighlight}
</script>
EOF

   $response .= <<"EOF";
</table>
<br>
$inlinescripts
$hiddenfields
</form>
</td></tr></table>
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
<br>
EOF

   return ($stylestr, $response);

}

