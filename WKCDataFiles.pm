#
# WKCDataFiles.pl -- Access disk data files
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCDataFiles;

   use strict;
   use CGI qw(:standard);
   use utf8;
   use Time::Local;
   use Net::FTP;

   use WKC;
   use WKCSheet; # For encode/decode from save, log stuff
   use WKCStrings; # For WKCmonthnames

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(get_siteinfo save_siteinfo update_siteinfo get_hostinfo save_hostinfo
                    get_userinfo update_userinfo get_userinfofileinfo
                    get_templateinfo get_template get_templatedirectory
                    check_site_exists delete_site
                    create_new_page save_page load_page load_page_from_array
                    edit_published_page edit_backup_page publish_page
                    delete_page abandon_page_edit rename_existing_page
                    rename_specific_file delete_specific_file download_specific_file
                    get_page_backup_list delete_old_backups
                    get_page_edit_path get_page_published_datafile_path
                    get_ensured_page_published_datafile_path get_ensured_page_edit_path
                    );
   our $VERSION = '1.0.0';

#
# Locals
#

   #
   # %siteinfo - Information about the pages on a web site
   #
   # Contents:
   #
   #   $siteinfo{files}
   #      {$pagename} - One for each page being tracked
   #         {filename} - name of file
   #         {fullnamepublished} - Title (in published file)
   #         {dtmpublished} - date/time last modified for published version (string from dir listing)
   #         {size} - size in bytes of published file
   #         {pubstatus} - 0 if unpublished, 1 otherwise
   #         {authors} - if null, nobody editing
   #            {$author} - One for each copy open for edit (usually zero or one)
   #               {fullnameedit} - Title (in edited file)
   #               {dtmedit} - date/time last modified for edit version (string)
   #               {editstatus} - "", "modified", 1 (editing, unchanged from published), "remote" (version on FTP site)
   #   $siteinfo{ftpdatetime} - Last time reconciled by FTP
   #   $siteinfo{updates} - used by update_siteinfo to let caller know if there are changes to the saved version
   #
   
   my %siteinfo;

   my @siteinfofilesfields = qw(filename fullnamepublished dtmpublished size pubstatus);

   my @siteinfoauthorsfields = qw(fullnameedit dtmedit editstatus);

   my %siteinfoauthordata = ('fullnameedit' => 1, 'dtmedit' => 1, 'editstatus' => 1);

   #
   # %hostinfo - Information about accessing hosts and the sites on them
   #
   # Contents:
   #
   #   $hostinfo{hosts}
   #      {$hostname} - One for each host listed
   #         {longname} - A more descriptive name (optional)
   #         {url} - How to access it by ftp (e.g., ftp.domainname.com) or blank if local
   #         {loginname} - Name to use in logging in by ftp (only if not local)
   #         {loginpassword} - Password to use when logging in (only if not local)
   #         {wkcpath} - Path to the directory containing the wkcdata directory (only if not local)
   #   $hostinfo{sites}
   #      {$sitename} - One for each site listed
   #         {longname} - A more descriptive name (optional)
   #         {host} - Name of host where this site resides
   #         {nameonhost} - Name of site used on host
   #         {authoronhost} - Author name to use on host
   #         {authorfromlogin} - If yes, if requiring login use logged in name as author
   #         {htmlpath} - Path to directory
   #         {htmlurl} - URL to directory with HTML
   #         {editurl} - URL to invoke editing a path
   #         {servicesurl} - URL to invoke runtime recalc (Not used: replaced after 0.91 with just editurl)
   #         {checked} - True if checked existence on host
   #         {backupmindays} - minimum number of days to keep backups no matter what the max files
   #         {backupmaxfiles} - maximum number of backup files for each page, delete oldest (archive files are not deleted)
   #                            if absent or <0, keep all
   #         {publishrss} - yes/no, if yes publishes both page and site RSS files (RSS 2.0)
   #         {rssmaxsiteitems} - Maximum of items to list on site feed (default is 10)
   #         {rssmaxpageitems} - Maximum of items to list on page feed (default is 10)
   #         {rsstitle} - Title of site RSS feed, start of title for each page
   #         {rsslink} - URL of HTML website corresponding to this feed
   #         {rssdescription} - Phrase or sentence describing site feed
   #         {rsschannelxml} - Additional XML for all feeds
   #   $hostinfo{requirelogin} - yes/no, if yes, there is a user directory with files
   #   $hostinfo{lastsaved} - date/time last saved for display purposes
   #   $hostinfo{version} - 1 (if missing or null, original format from 0.1 Alpha)
   #
   
   my %hostinfo;

   my @hostinfohostfields = qw(longname url loginname loginpassword wkcpath);
   my @hostinfositefields = qw(longname host nameonhost authoronhost authorfromlogin htmlpath htmlurl editurl
                               backupmindays backupmaxfiles checked
                               publishrss rssmaxsiteitems rssmaxpageitems rsstitle rsslink rssdescription rsschannelxml
                               );
   my %restricted_sitevalues = ("host" => 1, "nameonhost" => 1, "authoronhost" => 1); # restricted to a-zA-Z0-0\- charset

   #
   # %userinfo - Information about the registered users
   #
   # Contents:
   #
   #   $userinfo{$username} - One for each user (must be lower case, no special chars, etc.) for filename
   #      {displayname} - A longer form of the name
   #      {password} - An MD5 hash of the password
   #      {admin} - yes/no if admin permissions
   #      {allsites} - yes if r/w access to all sites, ignoring {sites} value
   #      {allreadsites} - yes if read access to all sites, ignoring {readsites} value
   #      {sites} - comma separated list of sites this user has r/w access to (saved in file separately)
   #      {readsites} - comma separated list of sites this user has read access to (may be in sites and not readsites)
   #      {lastsaved} - date/time last saved
   #   $userinfo{HOSTrequirelogin} - copy of host's requirelogin value (set and used elsewhere)
   #
   
   my %userinfo;

# Return something

   1;



# # # # # # #
#
# $ok = ensure_wkcdata(\%params)
#
# Makes sure we have a directory structure for local data
#

sub ensure_wkcdata {

   my $params = shift @_;

   return 1 if $params->{ensuredwkcdata};

   my $ok = -e "$params->{localwkcpath}/wkcdata";
   mkdir "$params->{localwkcpath}/wkcdata" if !$ok;

   $params->{ensuredwkcdata} = 1;

   return $ok;
}


# # # # # # #
#
# $whichsite = get_whichsite(\%params)
#
# Returns the sitename for the current parameters
#

sub get_whichsite {

   my $params = shift @_;

   my $whichsite;

   $whichsite = $params->{sitename};
   $whichsite =~ s/[^a-z0-9\-]//g;
   $whichsite ||= "sitename error";

   return $whichsite;

}


# # # # # # #
#
# $siteinfo = get_siteinfo(\%params)
#
# Returns a pointer to %siteinfo, filled in, for the current site
#

sub get_siteinfo {

   my $params = shift @_;

   %siteinfo = ();

   my @filelines;

   if (!$params->{sitename}) {
      return \%siteinfo; # empty
      }

   ensure_wkcdata($params);

   my $whichsite = get_whichsite($params);

   open (DATAFILEIN, "$params->{localwkcpath}/wkcdata/sites/$whichsite/siteinfo.txt");
   @filelines = <DATAFILEIN>;
   close DATAFILEIN;

   my $ok = parse_siteinfo_data(\@filelines, \%siteinfo);

#!!! Check ok!

   return \%siteinfo;
}

# # # # # # #
#
# $ok = save_siteinfo(\%params, \%siteinfo)
#
# Saves the siteinfo as a file
#

sub save_siteinfo {

   my ($params, $siteinfo) = @_;

   if (!$params->{sitename}) {
      return 0; # failure
      }

   my $ok;

   my $outstr;

   $outstr .= "filetype:wkcsiteinfo:version:1\n"; # output file type and version

   my $ftpdatetime = encode_for_save($siteinfo->{ftpdatetime});
   $outstr .= "ftpdatetime:$ftpdatetime\n";

   foreach my $name (sort keys %{$siteinfo->{files}}) { # Output each name
      my $fileinfo = $siteinfo->{files}->{$name};
      my $string = encode_fields(\@siteinfofilesfields, $fileinfo); # output regular fields
      foreach my $author (sort keys %{$fileinfo->{authors}}) { # and each author's fields working on that name
         my $str = encode_fields(\@siteinfoauthorsfields, $fileinfo->{authors}->{$author});
         $author = encode_for_save($author);
         $string .= ":author:$author$str";
         }
      $outstr .= "file:$name$string\n"
      }
   
   my $whichsite = get_whichsite($params);

#print "Writing out siteinfo.\n";
   open (DATAFILEIN, "> $params->{localwkcpath}/wkcdata/sites/$whichsite/siteinfo.txt");
   print DATAFILEIN $outstr;
   close DATAFILEIN;

   return $ok;
}


# # # # # # #
#
# $error = parse_siteinfo_data(\@lines, \%siteinfo)
#
# Returns "" if OK, otherwise error string.
# Fills in %siteinfo.
#
# File Format is:
#
#   filetype:wkcsiteinfo:version:1
#   file:name
#            :filename:filename
#            :fullnamepublished:full name
#            :dtmpublished:dt modified
#            :size:size
#            :pubstatus:pubstatus
#            :author:name - remembered for the following three until next author
#            :fullnameedit:full name
#            :dtmedit:dt modified
#            :editstatus:editstatus
#   ftpdatetime:datetime
#

sub parse_siteinfo_data {

   my ($lines, $siteinfo) = @_;

   my ($rest, $linetype, $name, $type, $type2, $rest, $value, $filetype, $fileversion);

   $siteinfo->{files} ||= {};

   my $filevalues = $siteinfo->{files};

   foreach my $line (@$lines) {
      chomp $line;
      $line =~ s/\r//g;
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      ($linetype, $rest) = split(/:/, $line, 2);
      if ($linetype eq "filetype") {
         ($filetype, $name, $fileversion, $rest) = split(/:/, $rest, 4);
         }
      elsif ($linetype eq "file") {
         ($name, $type, $rest) = split(/:/, $rest, 3);
         $filevalues->{$name} ||= {};
         my $author;
         while ($type) {
            ($value, $type2, $rest) = split(/:/, $rest, 3);
            if ($type eq "author") { # remember author
               $author = decode_from_save($value);
               $filevalues->{$name}->{authors} ||= {};
               $filevalues->{$name}->{authors}->{$author} = {};
               }
            elsif ($siteinfoauthordata{$type}) { # a value that is in the author sub-hash
# $params->{debugmessage} = "Missing author in siteinfo for page $name\n" unless $author;
               $filevalues->{$name}->{authors}->{$author}->{$type} = decode_from_save($value);
               }
            else {
               $filevalues->{$name}->{$type} = decode_from_save($value);
               }
            $type = $type2;
            }
         }
      elsif ($linetype eq "ftpdatetime") {
         $siteinfo->{ftpdatetime} = decode_from_save($rest);
         }
      if ($filetype ne "wkcsiteinfo" || $fileversion ne "1") { # first line must be filetype so this will pass
         $siteinfo->{files} = {}; # bad version - wipe out so we'll load it from the directories
         $siteinfo->{updates} = 1;
# $params->{debugmessage} = "Old version siteinfo - will be updated automatically.\n";
         return "";
         }
      }

   $siteinfo->{updates} = 0; # Initialize to "no changes to saved file"

   return "";

   }


# # # # # # #
#
# $ok = update_siteinfo(\%params, $hostsinfo, \%siteinfo)
#
# Looks at the web site and local directory to update the siteinfo
#

sub update_siteinfo {

   my ($params, $hostsinfo, $siteinfo) = @_;

   if (!$params->{sitename}) {
      return 0; # failure
      }

   my ($name, $fileinfo, $authorinfo, $mtime, @tv, $mtimestr, $fsize);

   $siteinfo->{files} ||= {};

   foreach $name (keys %{$siteinfo->{files}}) {
      $siteinfo->{files}->{$name} ||= {};
      $siteinfo->{files}->{$name}->{relevant} = 0;
      foreach my $author (keys %{$siteinfo->{files}->{$name}->{authors}}) {
         $siteinfo->{files}->{$name}->{authors}->{$author} ||= {};
         $siteinfo->{files}->{$name}->{authors}->{$author}->{relevant} = 0;
         }
      }

   my $whichsite = get_whichsite($params);

#print "Listing: $params->{localwkcpath}/wkcdata/sites/$whichsite/*.edit.*.txt\n";
   my @localfiles = glob("$params->{localwkcpath}/wkcdata/sites/$whichsite/*.edit.*.txt");

   my $sitedata = $hostsinfo->{sites}->{$params->{sitename}};
   my $hostdata = $hostsinfo->{hosts}->{$sitedata->{host}};

   foreach my $lfile (@localfiles) {
#print "Local file: $lfile\n";
      $name = lc $lfile;
      $name =~ s/^.*\/(.+?)\.edit\.(.*?)\.txt$/$1/;
      $siteinfo->{files}->{$name} ||= {};
      $fileinfo = $siteinfo->{files}->{$name};
      $fileinfo->{relevant} = 1;
      $fileinfo->{filename} = "$name.html";

      $fileinfo->{authors} ||= {};
      $fileinfo->{authors}->{$2} ||= {};
      $authorinfo = $fileinfo->{authors}->{$2};
      $authorinfo->{relevant} = 1;
      $mtime = (stat($lfile))[9];
      @tv = localtime($mtime);
      $mtimestr = sprintf("%s %d, %04d %02d:%02d:%02d", $WKCmonthnames[$tv[4]], $tv[3], $tv[5]+1900,
                                            $tv[2], $tv[1], $tv[0]);
      if ($authorinfo->{dtmedit} ne $mtimestr) { # Modified since last checked
         $authorinfo->{dtmedit} = $mtimestr; # Update time
         $siteinfo->{updates} += 1;
         my (@pubheaderlines, %pubheaderdata);
         my $loaderr = load_page($lfile, \@pubheaderlines, 0); # Get header info
         my $pareseok = parse_header_save(\@pubheaderlines, \%pubheaderdata); # Get data from header
         $authorinfo->{fullnameedit} = $pubheaderdata{fullname};
         $authorinfo->{editstatus} = "modified" if $pubheaderdata{lastmodified}; # if there is a time, it was modified
         }
      $authorinfo->{editstatus} ||= 1;
      }

   if ($hostdata->{url}) { # remote publishing

      my $ftp;
      if (!$siteinfo->{ftpdatetime}) {
         $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
         }
      else {
         foreach $name (keys %{$siteinfo->{files}}) { # Mark remote published ones relevant
            if ($siteinfo->{files}->{$name}->{pubstatus}
                || $siteinfo->{files}->{$name}->{authors}) {
               $siteinfo->{files}->{$name}->{relevant} = 1;
               foreach my $author (keys %{$siteinfo->{files}->{$name}->{authors}}) { # All authors, too
                  $siteinfo->{files}->{$name}->{authors}->{$author}->{relevant} = 1;
                  }
               }
            }
         }
      if ($ftp) {
         my $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my @dir;
         @dir = $ftp->dir if $ok;
         my $filenumber;
         my $filenames;
         my (@fsize, @fmon, @fday, @fname, @fhour, @fmin, @fyear, @ftime);
         my @timevalues = localtime;
         my $year = $timevalues[5];
         foreach my $line (@dir) { # go through once to find values to sort
#print "ls: $line\n";
            my ($access, $links, $owner, $group, $s, $m, $d, $timeyr, $n) = split(" ", $line, 9);
            next unless $access =~ /^-/;
            $filenumber++;
            ($fsize[$filenumber], $fmon[$filenumber], $fday[$filenumber], $fname[$filenumber]) = ($s, ucfirst lc $m, $d, $n);
            if ($timeyr =~ /:/) {
               ($fhour[$filenumber], $fmin[$filenumber]) = split(/:/, $timeyr);
               $fyear[$filenumber] = $year + 1900;
               }
            else {
               ($fyear[$filenumber], $fhour[$filenumber], $fmin[$filenumber]) = ($timeyr, 0, 0);
               }
            }

         for (my $j = 1; $j <= $filenumber; $j++) {
            $name = lc $fname[$j];
            if ($name =~ /^(.+?)\.published\.txt$/) {
               $name = $1;
               $siteinfo->{files}->{$name} ||= {};
               $fileinfo = $siteinfo->{files}->{$name};
               $fileinfo->{filename} = "$name.html";
               my $dtmpub = sprintf("%s %d, %04d %02d:%02d", $fmon[$j], $fday[$j], $fyear[$j], $fhour[$j] ,$fmin[$j]);
               if ($dtmpub ne $fileinfo->{dtmpublished} || $fsize[$j] != $fileinfo->{size}) {
                  my $pubpath = get_page_published_datafile_path($params, $hostsinfo, $whichsite, $name);
                  $ok = $ftp->get($fname[$j], $pubpath); # Download published file
                  my (@pubheaderlines, %pubheaderdata);
                  my $loaderr = load_page($pubpath, \@pubheaderlines, 0); # Get header info
                  my $pareseok = parse_header_save(\@pubheaderlines, \%pubheaderdata); # Get data from header
                  $fileinfo->{fullnamepublished} = $pubheaderdata{fullname}; # Save long name
                  $fileinfo->{dtmpublished} = $dtmpub; # Update dtm
                  $fileinfo->{size} = $fsize[$j]; # and size
                  }
               $fileinfo->{pubstatus} = 1;
               $fileinfo->{relevant} = 1;
               }
            elsif ($name =~ /^(.+?)\.edit\.(.*?)\.txt$/) { # see if anybody is editing
               $name = $1;
               $siteinfo->{files}->{$name} ||= {};
               $fileinfo = $siteinfo->{files}->{$name};
               $fileinfo->{filename} = "$name.html";

               $fileinfo->{authors} ||= {};
               $fileinfo->{authors}->{$2} ||= {};
               $authorinfo = $fileinfo->{authors}->{$2};
               $authorinfo->{relevant} = 1;
               $authorinfo->{editstatus} ||= "remote"; # set to remote if no local version
               $fileinfo->{relevant} = 1;
               }
            }

         $ftp->quit;

         if (!$ok) {
            my $msgsc = special_chars($ftp->message);
            $params->{debugmessage} = qq!$WKCStrings{datafilesunableftperrorstatus}: $msgsc.\n!;
            }
         else {
            @tv = localtime;
            $siteinfo->{ftpdatetime} = sprintf("%s %d, %04d %02d:%02d:%02d", $WKCmonthnames[$tv[4]], $tv[3], $tv[5]+1900,
                                               $tv[2], $tv[1], $tv[0]); # remember when we last loaded
            $siteinfo->{updates} += 1;
            }
         }
      }

   else { # Local publishing
      @localfiles = glob("$params->{localwkcpath}/wkcdata/sites/$whichsite/*.published.txt");

      foreach my $lfile (@localfiles) {
         $name = lc $lfile;
         if ($name =~ /^.*\/(.+?)\.published\.txt$/) {
            $name = $1;
            $siteinfo->{files}->{$name} ||= {};
            $fileinfo = $siteinfo->{files}->{$name};
            $fileinfo->{relevant} = 1;
            $fileinfo->{filename} = "$name.html";
            $mtime = (stat($lfile))[9];
            @tv = localtime($mtime);
            $mtimestr = sprintf("%s %d, %04d %02d:%02d:%02d", $WKCmonthnames[$tv[4]], $tv[3], $tv[5]+1900,
                                                  $tv[2], $tv[1], $tv[0]);
            $fsize = (stat(_))[7];
            if ($fileinfo->{dtmpublished} ne $mtimestr || $fileinfo->{size} != $fsize) {
               my (@pubheaderlines, %pubheaderdata);
               my $loaderr = load_page($lfile, \@pubheaderlines, 0); # Get header info
               my $pareseok = parse_header_save(\@pubheaderlines, \%pubheaderdata); # Get data from header
               $fileinfo->{fullnamepublished} = $pubheaderdata{fullname};
               $fileinfo->{dtmpublished} = $mtimestr;
               $fileinfo->{size} = $fsize;
               $siteinfo->{updates} += 1;
               }
            $fileinfo->{pubstatus} = 1;
            }
         }
      @tv = localtime;
      $siteinfo->{ftpdatetime} = sprintf("%s %d, %04d %02d:%02d:%02d", $WKCmonthnames[$tv[4]], $tv[3], $tv[5]+1900,
                                               $tv[2], $tv[1], $tv[0]); # show now as last loaded
      }

   foreach $name (keys %{$siteinfo->{files}}) { # Go through all
#print "Name: $name\n";
      $fileinfo = $siteinfo->{files}->{$name};
      if ($fileinfo->{relevant}) { # Still around
         foreach my $author (keys %{$siteinfo->{files}->{$name}->{authors}}) {
            next if $siteinfo->{files}->{$name}->{authors}->{$author}->{relevant}; # author still has it open
            delete $siteinfo->{files}->{$name}->{authors}->{$author}; # remove author no longer seen editing this page
            }
         next; # look at next page
         }
      delete $siteinfo->{files}->{$name}; # Remove ones we don't see anymore
      $siteinfo->{updates} += 1;
      }

   return 1;
   }


# # # # # # #
#
# $hostinfo = get_hostinfo(\%params)
#
# Returns a pointer to %hostinfo, filled in
#

sub get_hostinfo {

   my $params = shift @_;

   %hostinfo = ();

   my @filelines;

   ensure_wkcdata($params);

   open (DATAFILEIN, "$params->{localwkcpath}/wkcdata/hostinfo.txt");
   @filelines = <DATAFILEIN>;
   close DATAFILEIN;

   my $errtext = parse_hostinfo_data(\@filelines, \%hostinfo);

   if ($errtext) {
$params->{debugmessage} = "$errtext\n";
      }

   if ($hostinfo{version} ne 1 && (scalar @filelines) > 0) {
$params->{debugmessage} = "Hostinfo version not 1 - resetting site checked flags.\n";
      foreach my $hostname (sort keys %{$hostinfo{sites}}) {
         $hostinfo{sites}->{$hostname}->{checked} = 0;
         }
      my $ok = save_hostinfo($params, \%hostinfo);
      }

   return \%hostinfo;
}

# # # # # # #
#
# $ok = save_hostinfo(\%params, \%hostinfo)
#
# Saves the hostinfo as a file
#

sub save_hostinfo {

   my ($params, $hostinfo) = @_;

   my $ok;

   my $outstr;

   $outstr .= "filetype:wkchostinfo:version:1\n"; # output file type and version

   my $clocktime = encode_for_save(scalar localtime);
   $outstr .= "lastsaved:$clocktime\n";

   if ($hostinfo->{requirelogin}) {
      $outstr .= "requirelogin:$hostinfo->{requirelogin}\n";
      }
   foreach my $name (sort keys %{$hostinfo->{hosts}}) { # Output each host name
      my $hostvals = $hostinfo->{hosts}->{$name};
      my $string = encode_fields(\@hostinfohostfields, $hostvals);
      $outstr .= "host:$name$string\n";
      }
   foreach my $name (sort keys %{$hostinfo->{sites}}) { # Output each site name
      my $sitevals = $hostinfo->{sites}->{$name};
      my $string = encode_fields(\@hostinfositefields, $sitevals);
      $outstr .= "site:$name$string\n";
      }
   
   open (DATAFILEIN, "> $params->{localwkcpath}/wkcdata/hostinfo.txt");
   print DATAFILEIN $outstr;
   close DATAFILEIN;
# $params->{debugmessage} = "Saving hostinfo\n";
   return $ok;
}


# # # # # # #
#
# $string = encode_fields(\@fieldnames, \%info)
#
# Returns ":fieldname1:fieldvalue1:fieldname2:fieldvalue2..."
#

sub encode_fields {

   my ($fieldnames, $info) = @_;
   my $str;

   foreach my $val (@$fieldnames) {
      my $valstr = encode_for_save($info->{$val});
      $str .= ":$val:$valstr";
      }

   return $str;

   }

# # # # # # #
#
# $error = parse_hostinfo_data(\@lines, \%hostinfo)
#
# Returns "" if OK, otherwise error string.
# Fills in %hostinfo.
#
# File Format is:
#
#   filetype:wkchostinfo:version:1
#   host:name
#            :hostfieldname:fieldvalue
#   site:name
#            :sitefieldname:fieldvalue
#

sub parse_hostinfo_data {

   my ($lines, $hostinfo) = @_;

   my ($rest, $linetype, $name, $type, $type2, $rest, $value, $filetype, $fileversion);

   $hostinfo->{hosts} ||= {};
   $hostinfo->{sites} ||= {};


   my $hostsvalues = $hostinfo->{hosts};
   my $sitesvalues = $hostinfo->{sites};

   foreach my $line (@$lines) {
      chomp $line;
      $line =~ s/\r//g;
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      ($linetype, $rest) = split(/:/, $line, 2);
      if ($linetype eq "filetype") {
         ($filetype, $name, $fileversion, $rest) = split(/:/, $rest, 4);
         if ($filetype ne "wkchostinfo") { # if present, must be this
            return "Incorrect filetype: $filetype";
            }
         $hostinfo->{version} = $fileversion; # remember this
         }
      elsif ($linetype eq "host") {
         ($name, $type, $rest) = split(/:/, $rest, 3);
         $name =~ s/[^a-z0-9\-]//g; # just in case corrupted file
         $hostsvalues->{$name} ||= {};
         while ($type) {
            ($value, $type2, $rest) = split(/:/, $rest, 3);
            $hostsvalues->{$name}->{$type} = decode_from_save($value);
            $type = $type2;
            }
         }
      elsif ($linetype eq "site") {
         ($name, $type, $rest) = split(/:/, $rest, 3);
         $name =~ s/[^a-z0-9\-]//g; # just in case corrupted file
         $sitesvalues->{$name} ||= {};
         while ($type) {
            ($value, $type2, $rest) = split(/:/, $rest, 3);
            $sitesvalues->{$name}->{$type} = decode_from_save($value);
            $sitesvalues->{$name}->{$type} =~ s/[^a-z0-9\-]//g if $restricted_sitevalues{$type};
            $type = $type2;
            }
         }
      elsif ($linetype eq "requirelogin") {
         ($value, $rest) = split(/:/, $rest, 2);
         $hostinfo->{requirelogin} = decode_from_save($value);
         }
      elsif ($linetype eq "lastsaved") {
         $hostinfo->{lastsaved} = decode_from_save($rest);
         }
      }
   }


# # # # # # #
#
# $userinfo = get_userinfo(\%params)
#
# Retrieves the userinfo data and returns a reference to %userinfo
#

sub get_userinfo {

   my $params = shift @_;

   %userinfo = ();

   mkdir "$params->{localwkcpath}/wkcdata/users"; # ensure directory exists

   my @localfiles = glob("$params->{localwkcpath}/wkcdata/users/*.txt"); # get a list of all defined users

   foreach my $lfile (@localfiles) {
      my $name = lc $lfile;
      $name =~ s/^.*\/(.+?)\.txt$/$1/;
      next unless $name;
      get_userinfofileinfo($params, \%userinfo, $name);
      }

   return \%userinfo;
}


# # # # # # #
#
# $errortext = get_userinfofileinfo(\%params, \%userinfo, $name)
#
# Reads in data from user file and fills in $userinfo->{$name}.
# Returns $errortext if user not found.
#

sub get_userinfofileinfo {

   my ($params, $userinfo, $name) = @_;

   my @filelines;

   my $ok = open (DATAFILEIN, "$params->{localwkcpath}/wkcdata/users/$name.txt");
   if (!$ok) {
      return "$WKCStrings{datafilesnotfound}";
      }

   @filelines = <DATAFILEIN>;
   close DATAFILEIN;

   $userinfo->{$name} ||= {}; # make sure there is a hash for the data

   foreach my $line (@filelines) {
      chomp $line;
      $line =~ s/\r//g;
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      my ($linetype, $rest) = split(/:/, $line, 2);
      if ($linetype eq "site") {
         my $sitename = decode_from_save($rest);
         if ($userinfo->{$name}->{sites}) {
            $userinfo->{$name}->{sites} .= ",$sitename";
            }
         else {
            $userinfo->{$name}->{sites} = $sitename;
            }
         }
      elsif ($linetype eq "readsite") {
         my $sitename = decode_from_save($rest);
         if ($userinfo->{$name}->{readsites}) {
            $userinfo->{$name}->{readsites} .= ",$sitename";
            }
         else {
            $userinfo->{$name}->{readsites} = $sitename;
            }
         }
      else {
         $userinfo->{$name}->{$linetype} = decode_from_save($rest);
         }
      }

   return;
}

# # # # # # #
#
# $errtext = update_userinfo(\%params, \%userinfo, $username)
#
# Updates the userinfo data about the specified user.
# If $userinfo->{username}->{delete}, the user is deleted from the system.
#

sub update_userinfo {

   my ($params, $userinfo, $username) = @_;

   my ($outstr, $str);

   if ($userinfo->{$username}->{delete}) { # delete user file
      unlink "$params->{localwkcpath}/wkcdata/users/$username.txt";
      return;
      }

   my $clocktime = encode_for_save(scalar localtime);
   $outstr .= "lastsaved:$clocktime\n";

   $str = encode_for_save($userinfo->{$username}->{displayname});
   $outstr .= "displayname:$str\n";

   $str = encode_for_save($userinfo->{$username}->{password});
   $outstr .= "password:$str\n";

   $str = encode_for_save($userinfo->{$username}->{admin});
   $outstr .= "admin:$str\n";

   $str = encode_for_save($userinfo->{$username}->{allsites});
   $outstr .= "allsites:$str\n" if $str;

   $str = encode_for_save($userinfo->{$username}->{allreadsites});
   $outstr .= "allreadsites:$str\n" if $str;

   foreach my $sitename (split (/,/, $userinfo->{$username}->{sites})) { # Output each site name
      $str = encode_for_save($sitename);
      $outstr .= "site:$str\n";
      }
   
   foreach my $sitename (split (/,/, $userinfo->{$username}->{readsites})) { # Output each read site name
      $str = encode_for_save($sitename);
      $outstr .= "readsite:$str\n";
      }
   
   open (DATAFILEIN, "> $params->{localwkcpath}/wkcdata/users/$username.txt");
   print DATAFILEIN $outstr;
   close DATAFILEIN;
   return;

}


# # # # # # #
#
# get_templateinfo(\%params, $type, \@templateinfo)
#
# Retrieves the templateinfo data for specified templates in all locations available for the current site.
# Type is something like "htmltemplate", "pagetemplate", etc.
#

sub get_templateinfo {

   my ($params, $type, $templateinfo) = @_;

   splice @$templateinfo; # erase whatever is there

   fill_templateinfo($params, "system", $type, $templateinfo);
   fill_templateinfo($params, "shared", $type, $templateinfo);
   fill_templateinfo($params, "site", $type, $templateinfo);

   return;
}


# # # # # # #
#
# $directory = get_templatedirectory(\%params, $where)
#
# Returns a directory path to the "system", "shared", and "site" template directories.
#

sub get_templatedirectory {

   my ($params, $where) = @_;

   my $sitename = $params->{sitename};
   $sitename =~ s/[^a-z0-9\-]//g;

   if ($where eq "system") {
      return "$params->{localwkcpath}";
      }
   elsif ($where eq "shared") {
      return "$params->{localwkcpath}/wkcdata/templates";
      }
   elsif ($where eq "site") {
      return "$params->{localwkcpath}/wkcdata/sites/$sitename/templates";
      }

   return $WKCStrings{"datafilesunknownlocation"}; # hopefully this isn't a dir name
}


# # # # # # #
#
# fill_templateinfo($params, $location, $type, \@templateinfo)
#
# Fills in the template_info for $type files in $location type of directory
#

sub fill_templateinfo {

   my ($params, $location, $type, $templateinfo) = @_;

   my $directory = get_templatedirectory($params, $location);

   my $ok = -e "$directory";
   if (!$ok) {
      return; # if no dir, then no files to list
      }

   my @localfiles = glob("$directory/*.$type.txt"); # get a list of all templates

   my @names;
   foreach my $lfile (@localfiles) {
      my $name = lc $lfile;
      $name =~ s/^.*\/(.+?)\.$type\.txt$/$1/;
      push @names, $name if $name;
      }

   foreach my $name (sort @names) {
      my $templatename = "$location:$name"; # create a template name
      my $tcontents = get_template($params, $type, $templatename);
      $tcontents =~ m/{{templatedescriptionline}}(.+?)\n/;
      push @$templateinfo, {name => $templatename, longname => $1};
      }

   return;
}


# # # # # # #
#
# $contents = get_template(\%params, $type, $templatename)
#
# Returns the contents of $templatename, or null.
# $templatename is in the form of "location:name".
#

sub get_template {

   my ($params, $type, $templatename) = @_;

   my ($location, $name) = split(/:/, $templatename, 2);
   $location =~ s/[^a-z0-9\-]//g;
   $name =~ s/[^a-z0-9\-]//g;

   my $directory = get_templatedirectory($params, $location);

   my $ok = open (DATAFILEIN, "$directory/$name.$type.txt");
   if (!$ok) {
      return;
      }

   my $content;
   while (my $line = <DATAFILEIN>) {
      $content .= $line;
      }
   close DATAFILEIN;

   return $content;
}


# # # # # # #
#
# $str = check_site_exists(\%params, $hostinfo, $sitename)
#
# Makes sure that site info points to a real site and creates the
# directory structure there if necessary
#
# Remembers successful checks in hostinfo so no need to do each time
# Updates hostinfo on disk if needed to check and succeeded
#
# Returns $errstr with error string nor null if OK.
#

sub check_site_exists {

   my ($params, $hostinfo, $sitename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   #
   # Return OK if already checked
   #

   if ($sitedata->{checked}) {
      return $errstr;
      }

   #
   # Do check on remote host by FTP
   #

   if ($hostdata->{url}) {

      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd($hostdata->{wkcpath}) if $ok;
         $ftp->mkdir("wkcdata") if $ok; # fails if exists, which is OK
         $ok = $ftp->cwd("wkcdata") if $ok;
         $ftp->mkdir("sites") if $ok; # fails if exists, which is OK
         $ok = $ftp->cwd("sites") if $ok;
         if ($ok) { # check for Alpha version 1.0 version naming
            $ok = $ftp->cwd("local_host.$sitedata->{nameonhost}");
            if ($ok) { # yes -- old style: convert to new style
               $ok = $ftp->cdup(); # go to parent directory "site"
               $ok = $ftp->rename("local_host.$sitedata->{nameonhost}", $sitedata->{nameonhost});
$params->{debugmessage} = "Converted old-style local_host.$sitedata->{nameonhost} to $sitedata->{nameonhost}, code=$ok\n";
               }
            $ok = 1;
            }
         $ftp->mkdir("$sitedata->{nameonhost}") if $ok; # fails if exists, which is OK
         $ok = $ftp->cwd("$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->cwd("/") if $ok; # go back to top
         $ok = $ftp->cwd($sitedata->{htmlpath}) if $ok;
         if (!$ok) {
            $errstr .= "$WKCStrings{datafilesunablehtml}: ";
            }
         $ftp->quit;
         }
      if (!$ftp) {
         $errstr = qq!$WKCStrings{datafilesunableftp}.\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr .= qq!$WKCStrings{datafilesunableftpok1}: '$ok'. $WKCStrings{datafilesunableftpok2}: $msgsc.\n!;
         }
      else { # success - remember it had a successful check
         $sitedata->{checked} = 1;
         }
      }
   else {
      $sitedata->{checked} = 1; # assume local is OK
      }

   #
   # Do check on local host whether or not remote host
   #

   mkdir "$params->{localwkcpath}/wkcdata";
   mkdir "$params->{localwkcpath}/wkcdata/sites";
   mkdir "$params->{localwkcpath}/wkcdata/sites/$sitename";

   #
   # Save with current value unless error
   #

   $ok = save_hostinfo($params, $hostinfo) unless $errstr;

   return $errstr;

   }


# # # # # # #
#
# $str = delete_site(\%params, $hostinfo, $sitename, $remotealso)
#
# Deletes the site files and hierarchy locally and, if $remotealso, on the host
# The HTML files are left alone.
#
# Returns $errstr with error string nor null if OK.
#

sub delete_site {

   my ($params, $hostinfo, $sitename, $remotealso) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   #
   # Do it on remote host by FTP
   #

   if ($remotealso && $hostdata->{url}) {

      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd($hostdata->{wkcpath}) if $ok;
         $ok = $ftp->cwd("wkcdata") if $ok;
         $ok = $ftp->cwd("sites") if $ok;
         if (!$ok) {
            $errstr .= "$WKCStrings{datafilesunabledelete}: ";
            }
# !!!! Need to delete all files and directory !!!!!!!!!
         $ftp->quit;
         }
      if (!$ftp) {
         $errstr = qq!$WKCStrings{datafilesunableftp}.\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr .= qq!$WKCStrings{datafilesunableftpok1}: '$ok'. $WKCStrings{datafilesunableftpok2}: $msgsc.\n!;
         }
      else {
         }
      }

   #
   # Delete locally
   #

   my @localfiles = glob("$params->{localwkcpath}/wkcdata/sites/$sitename/*");

   foreach my $lfile (@localfiles) {
      unlink $lfile;
      }
   rmdir "$params->{localwkcpath}/wkcdata/sites/$sitename";

   #
   # Save without info about that site
   #

   delete $hostinfo->{sites}->{$sitename};

   $ok = save_hostinfo($params, $hostinfo) unless $errstr;

   return $errstr;

   }


# # # # # # #
#
# $str = create_new_page(\%params, $hostinfo, $sitename, $pagename, $initialheadercontents, $initialsheetcontents)
#
# Create a new page on the current site
#
# Returns $errstr with error string nor null if OK.
#

sub create_new_page {

   my ($params, $hostinfo, $sitename, $pagename, $initialheadercontents, $initialsheetcontents) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   #
   # First create on local host whether or not remote host
   #

   my $editpath = get_page_edit_path($params, $hostinfo, $sitename, $pagename);
   $ok = save_page($editpath, $initialheadercontents, $initialsheetcontents);

   #
   # Create on remote host by FTP
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->put($editpath) if $ok;
         $ftp->quit;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableftp}.\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafilesunableftpok1}: '$ok'. $WKCStrings{datafilesunableftpok2}: $msgsc.\n!;
         }
      }

   return $errstr;

   }


# # # # # # #
#
# $errstr = save_page($filename, $headercontents, $sheetcontents)
#
# Saves the page data (in encoded text) to an edit file
#
# Returns $errstr with error string nor null if OK.
#

sub save_page {

   my ($filename, $headercontents, $sheetcontents) = @_;

   my $errstr;

   if (!$filename) { # check just in case
      return "No file";
      }

   open (DATAFILEOUT, ">$filename");

# NO!   print DATAFILEOUT "\xEF\xBB\xBF"; # output UTF Byte Order Mark http://www.unicode.org/faq/utf_bom.html#BOM
   print DATAFILEOUT "MIME-Version: 1.0\n";
   print DATAFILEOUT "Content-Type: multipart/mixed; boundary=wkc-boundary\n";
   print DATAFILEOUT "--wkc-boundary\nContent-type: text/plain; charset=UTF-8\n\n";
   print DATAFILEOUT $headercontents;
   print DATAFILEOUT "--wkc-boundary\nContent-type: text/plain; charset=UTF-8\n\n";
   print DATAFILEOUT $sheetcontents;
   print DATAFILEOUT "--wkc-boundary--\n";

   close DATAFILEOUT;


   return $errstr;

   }


# # # # # # #
#
# $errstr = load_page($filename, \@headerlines, \@sheetlines)
#
# Loads the page data (as lines of text) from an edit file
# If @headerlines or @sheetlines are null, then they are skipped (saving time)
#
# Note that all lines up until the first one with "MIME-Version:" are skipped
#
# Returns $errstr with error string if error or null if OK.
#

sub load_page {

   my ($filename, $headerlines, $sheetlines) = @_;

   my ($line, $boundary);

   my $ok = open (DATAFILEIN, $filename);
   return "$WKCStrings{datafilesfile} '$filename' $WKCStrings{datafilesnotfound2}" unless $ok;

   while ($line = <DATAFILEIN>) {
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      last if $line =~ m/^MIME-Version:\s1\.0/i;
      }

   while ($line = <DATAFILEIN>) {
      last if $line =~ m/^Content-Type:\smultipart\/mixed;/i;
      }
   $line =~ m/\sboundary=(\S+)/i;
   $boundary = $1;
   while ($line = <DATAFILEIN>) {
      $line =~ s/\r//g;
      last if $line =~ m/^--$boundary$/o;
      }

   while ($line = <DATAFILEIN>) { # go to blank line
      chomp $line;
      $line =~ s/\r//g;
      last unless $line;
      }

   my $bregex = qr/^--$boundary/;

   while ($line = <DATAFILEIN>) { # copy header lines
      last if $line =~ m/$bregex/;
      push @$headerlines, $line if $headerlines;
      }

   while ($line = <DATAFILEIN>) { # go to blank line
      chomp $line;
      $line =~ s/\r//g;
      last unless $line;
      }

   while (($line = <DATAFILEIN>) && $sheetlines) { # copy sheet lines
      last if $line =~ m/$bregex/;
      push @$sheetlines, $line;
      }

   close DATAFILEIN;

   return "";

   }


# # # # # # #
#
# $errstr = load_page_from_array($filelines, \@headerlines, \@sheetlines)
#
# Loads the page data as lines of text from an array, breaking into parts for parsing.
#
# Note that all lines up until the first one with "MIME-Version:" are skipped
#
# Returns $errstr with error string or null if OK.
#

sub load_page_from_array {

   my ($filelines, $headerlines, $sheetlines) = @_;

   my ($line, $boundary);

   my @lines = split(/\n/, $filelines);

   while (defined($line = shift @lines)) {
      $line =~ s/^\x{EF}\x{BB}\x{BF}//; # remove UTF-8 Byte Order Mark if present
      last if $line =~ m/^MIME-Version:\s1\.0/i;
      }

   while (defined($line = shift @lines)) {
      last if $line =~ m/^Content-Type:\smultipart\/mixed;/i;
      }
   $line =~ m/\sboundary=(\S+)/i;
   $boundary = $1;
   while (defined($line = shift @lines)) {
      $line =~ s/\r//g;
      last if $line =~ m/^--$boundary$/o;
      }

   while (defined($line = shift @lines)) { # go to blank line
      $line =~ s/\r//g;
      last unless $line;
      }

   my $bregex = qr/^--$boundary/;

   while (defined($line = shift @lines)) { # copy header lines
      last if $line =~ m/$bregex/;
      push @$headerlines, $line if $headerlines;
      }

   while (defined($line = shift @lines)) { # go to blank line
      $line =~ s/\r//g;
      last unless $line;
      }

   while ((defined($line = shift @lines)) && $sheetlines) { # copy sheet lines
      last if $line =~ m/$bregex/;
      push @$sheetlines, $line;
      }

   return "";

   }


# # # # # # #
#
# $str = edit_published_page(\%params, $hostinfo, $sitename, $pagename)
#
# Start editing from a previously published page
#
# Returns $errstr with error string nor null if OK.
#

sub edit_published_page {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my ($errstr, $ok, $success);

   my $siteinfo = get_siteinfo($params);
   my $fileinfo = $siteinfo->{files}->{$pagename};

   if (!$siteinfo || !$fileinfo) { # can't find page
      return qq!$WKCStrings{datafilespage} "$pagename" $WKCStrings{datafilesonsite} "$sitename" $WKCStrings{datafilescannotedit}.!;
      }

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $thisauthor = $sitedata->{authoronhost};
   if ($sitedata->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $thisauthor = $params->{loggedinusername};
      $thisauthor =~ s/[^a-z0-9\-]//g;
      }

   if ($fileinfo->{authors}->{$thisauthor}->{editstatus} && $fileinfo->{authors}->{$thisauthor}->{editstatus} ne "remote") { # if already editing
      return ""; # nothing to do
      }

   my $editdatafilepathlocal = get_page_edit_path($params, $hostinfo, $sitename, $pagename);
   my $editnameonly = $editdatafilepathlocal;
   $editnameonly =~ s/.*\///;
   my $publisheddatafilepathlocal = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   my $publishednameonly = $publisheddatafilepathlocal;
   $publishednameonly =~ s/.*\///;

   #
   # If on remote host, download by FTP
   #

   my $ftp;
   if ($hostdata->{url}) {
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;

         # Download the copy

         if ($fileinfo->{authors}->{$thisauthor}->{editstatus} eq "remote") { # use edit copy on host
            $ok = $ftp->get($editnameonly, $editdatafilepathlocal) if $ok;
            }
         else { # start from published copy
            $ok = $ftp->get($publishednameonly, $editdatafilepathlocal) if $ok;
            $ok = $ftp->put($editdatafilepathlocal) if $ok; # Upload current state to indicate we are editing it
            }
         $ftp->quit;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableftp}.\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = "$WKCStrings{datafilesunableftperrorstatusis}: $msgsc.\n";
         }
      else {
         $success = 1;
         }
      }

   #
   # If local or host unaccessable, do copying here
   #

   if (!$ftp) {
      if ($hostdata->{url}) { # already tried FTP
         $errstr .= "<br>" if $errstr;
         $errstr .= "$WKCStrings{datafilesattemptedit}";
         }
      if (-e $publisheddatafilepathlocal) { # there is a published version to copy
         open (DATAFILEIN, $publisheddatafilepathlocal);
         open (DATAFILEOUT, "> $editdatafilepathlocal");
         while (my $line = <DATAFILEIN>) {
            print DATAFILEOUT $line;
            }
         close DATAFILEIN;
         close DATAFILEOUT;
         $success = 1;
         if ($hostdata->{url}) { # already tried FTP
            $errstr .= "<br>" if $errstr;
            $errstr .= $WKCStrings{"datafilesfoundlocal"};
            }
         }
      else {
         $errstr .= "<br>" if $errstr;
         $errstr .= $WKCStrings{"datafilesnolocal"};
         }
      }

   #
   # Initialize header by removing and initializing stuff (read in, modify/delete, write out...)
   #

   my (@headerlines, @sheetlines, %headerdata, %sheetdata);

   $errstr = load_page($editdatafilepathlocal, \@headerlines, \@sheetlines);
   parse_header_save(\@headerlines, \%headerdata); # get header data
   parse_sheet_save(\@sheetlines, \%sheetdata);
   $headerdata{basefiledt} = $headerdata{backupfiledt}; # remember where previous stuff is if known
   delete $headerdata{backupfiledt}; # this is only in final copies
   delete $headerdata{editlog}; # remove edit log, etc., to start anew
   delete $headerdata{lastmodified};
   delete $headerdata{lastauthor};
   delete $headerdata{editcomments};
   my $headercontents = create_header_save(\%headerdata);
   my $sheetcontents = create_sheet_save(\%sheetdata);
   save_page($editdatafilepathlocal, $headercontents, $sheetcontents) if !$errstr;

   #
   # Change siteinfo
   #

   $fileinfo->{authors}->{$thisauthor}->{editstatus} = 1; # unmodified from publish but still editing

   $fileinfo->{authors}->{$thisauthor}->{dtmedit} = 0;

   $ok = save_siteinfo($params, $siteinfo) if $success;

   # Done

   return $errstr;

   }


# # # # # # #
#
# $str = edit_backup_page(\%params, $hostinfo, $sitename, $backupname)
#
# Start editing from a backup version of a previously published page, possibly overwriting current edit
#
# Returns $errstr with error string nor null if OK.
#

sub edit_backup_page {

   my ($params, $hostinfo, $sitename, $backupname) = @_;

   my ($errstr, $ok, $success);

   $backupname =~ m/^([a-z0-9\-]+?)\./;
   my $pagename = $1; # get just the name

   my $siteinfo = get_siteinfo($params);
   my $fileinfo = $siteinfo->{files}->{$pagename};

   if (!$siteinfo || !$fileinfo) { # can't find page
      return qq!$WKCStrings{datafilespage} "$pagename" $WKCStrings{datafilesonsite} "$sitename" $WKCStrings{datafilescannotedit}.!;
      }

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $thisauthor = $sitedata->{authoronhost};
   if ($sitedata->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $thisauthor = $params->{loggedinusername};
      $thisauthor =~ s/[^a-z0-9\-]//g;
      }

   my $editdatafilepathlocal = get_page_edit_path($params, $hostinfo, $sitename, $pagename);
   my $editnameonly = $editdatafilepathlocal;
   $editnameonly =~ s/.*\///;
   my $backupdatafilepathlocal = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   $backupdatafilepathlocal =~ s/^(.*\/)[^\/]+$/$1.$backupname/e;

   #
   # If on remote host, download by FTP
   #

   my $ftp;
   if ($hostdata->{url}) {
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;

         # Download the backup copy (remote is considered authoritative)

         $ok = $ftp->get($backupname, $editdatafilepathlocal) if $ok;
         $ok = $ftp->put($editdatafilepathlocal) if $ok; # Upload current state to indicate we are editing it
         $ftp->quit;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableaccessbackupftp}\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = "$WKCStrings{datafilesbackuperroraccessing}: $msgsc.\n";
         }
      else {
         $success = 1;
         }
      }

   #
   # If local or host unaccessable, do copying here
   #

   if (!$ftp) {
      if ($hostdata->{url}) { # already tried FTP
         $errstr .= "<br>" if $errstr;
         $errstr .= $WKCStrings{"datafilesattemptfrombackup"};
         }
      if (-e $backupdatafilepathlocal) { # is there a local copy? If so, use that
         open (DATAFILEIN, $backupdatafilepathlocal);
         open (DATAFILEOUT, "> $editdatafilepathlocal");
         while (my $line = <DATAFILEIN>) {
            print DATAFILEOUT $line;
            }
         close DATAFILEIN;
         close DATAFILEOUT;
         $success = 1;
         if ($hostdata->{url}) { # already tried FTP
            $errstr =""; # no error - got backup successfully
            }
         }
      else {
         $errstr .= "<br>" if $errstr;
         $errstr .= $WKCStrings{"datafilesnolocalbackup"};
         }
      }

   #
   # Initialize header by removing and initializing stuff specially (read in, modify/delete, write out...)
   #

   my (@headerlines, @sheetlines, %headerdata, %sheetdata);

   $errstr = load_page($editdatafilepathlocal, \@headerlines, \@sheetlines);
   parse_header_save(\@headerlines, \%headerdata); # get header data
   parse_sheet_save(\@sheetlines, \%sheetdata);
   $headerdata{basefiledt} = $headerdata{backupfiledt}; # keep thread back to backup copy
   delete $headerdata{backupfiledt}; # this is only in final copies
   delete $headerdata{editlog}; # remove edit log, etc., to start anew
   delete $headerdata{lastmodified};
   delete $headerdata{lastauthor};
   $headerdata{editcomments} = "$WKCStrings{datafilesrevertedtobackup} $backupname $WKCStrings{datafilesrevertedby} $thisauthor"; # indicate we did a revert
   add_to_editlog(\%headerdata, "# $WKCStrings{datafilesrevertedtobackup} $backupname $WKCStrings{datafilesrevertedby} $thisauthor");
   $headerdata{reverted} = $backupname;
   my $headercontents = create_header_save(\%headerdata);
   my $sheetcontents = create_sheet_save(\%sheetdata);
   save_page($editdatafilepathlocal, $headercontents, $sheetcontents) if !$errstr;

   #
   # Change siteinfo
   #

   $fileinfo->{authors}->{$thisauthor}->{editstatus} = 1; # unmodified from publish but still editing

   $fileinfo->{authors}->{$thisauthor}->{dtmedit} = 0;

   $ok = save_siteinfo($params, $siteinfo) if $success;

   # Done

   return $errstr;

   }


# # # # # # #
#
# $errstr = publish_page(\%params, $hostinfo, $sitename, $pagename, $HTMLcontents, $JScontents, \%headerdata, \%sheetdata, $continueediting)
#
# Publishes a page on the current site after updating edit file with given HTML,
# optional Javascript version, and given header/sheet data
#
# Returns $errstr with error string nor null if OK.
#

sub publish_page {

   my ($params, $hostinfo, $sitename, $pagename, $HTMLcontents, $JScontents, $headerdata, $sheetdata, $continueediting) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $thisauthor = $sitedata->{authoronhost};
   if ($sitedata->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $thisauthor = $params->{loggedinusername};
      $thisauthor =~ s/[^a-z0-9\-]//g;
      }

   #
   # Update headerdata and save
   #

   my $backupdatafilepath = get_page_backup_datafile_path($params, $hostinfo, $sitename, $pagename); # get where backup goes
   $backupdatafilepath =~ m/\.backup\.([0-9\-]+)\.txt$/;

   $headerdata->{backupfiledt} = $1;
   delete $headerdata->{reverted}; # reset if set

   my $sheetcontents = create_sheet_save($sheetdata);
   my $headercontents = create_header_save($headerdata);

   my $editdatafilepath = get_page_edit_path($params, $hostinfo, $sitename, $pagename); # get where edit file is
   $ok = save_page($editdatafilepath, $headercontents, $sheetcontents); # save with updated data

   # # # #
   # Save the datafile as "published" in the right edit directories
   # The "published" HTML, JS, and source goes into the HTML directory if requested
   # # # #

   #
   # Copy datafile on local host in edit directory to make published copy
   #

   my $publisheddatafilepath = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   my $localhtmlpath = get_page_published_HTML_path($params, $hostinfo, $sitename, $pagename);
   my $publishedsourcefilepath = $localhtmlpath; # in case need a published source, too
   $publishedsourcefilepath =~ s/.html$/.txt/;
   my $publishsource = $headerdata->{publishsource} eq "yes";

   open (DATAFILEIN, $editdatafilepath);
   open (DATAFILEOUT, "> $publisheddatafilepath");
   open (BACKUPFILEOUT, "> $backupdatafilepath");
   open (SOURCEFILEOUT, "> $publishedsourcefilepath") if ($publishsource && !$hostdata->{url});
   while (my $line = <DATAFILEIN>) {
      print DATAFILEOUT $line;
      print BACKUPFILEOUT $line;
      print SOURCEFILEOUT $line if ($publishsource && !$hostdata->{url});
      }
   close DATAFILEIN;
   close DATAFILEOUT;
   close BACKUPFILEOUT;
   close SOURCEFILEOUT if ($publishsource && !$hostdata->{url});

   #
   # Next create local HTML -- either temp to upload or actual here
   #

   my $istmplocalhtmlpath;
   my $localjspath;
   my $publishhtml = $headerdata->{publishhtml} ne "no";
   my $publishjs = $headerdata->{publishjs} eq "yes";

   if ($hostdata->{url}) { # remote publish -- create a temp to copy
      $localhtmlpath = $publisheddatafilepath;
      $localhtmlpath =~ s/published.txt$/temp.html/;
      $istmplocalhtmlpath = 1;
      if ($publishjs) {
         $localjspath = $localhtmlpath;
         $localjspath =~ s/.html$/.js/;
         }
      }
   else { # local publish -- make the real thing
      $localhtmlpath = get_page_published_HTML_path($params, $hostinfo, $sitename, $pagename);
      if ($publishjs) {
         $localjspath = $localhtmlpath;
         $localjspath =~ s/.html$/.js/;
         }
      }

   if ($publishhtml) {
      open (DATAFILE, "> $localhtmlpath");
      print DATAFILE $HTMLcontents;
      close DATAFILE;
      }
   if ($publishjs) {
      open (DATAFILE, "> $localjspath");
      print DATAFILE $JScontents;
      close DATAFILE;
      }

   #
   # Create RSS files if necessary
   #

   my ($pagersspath, $sitersspath);

   if ($sitedata->{publishrss}) {
      my %backuplist;

      get_page_backup_list($params, $hostinfo, $sitename, $pagename, \%backuplist); # get data for RSS feeds

      my $rssstr;

      $rssstr .= get_page_rss_string($params, $hostinfo, $sitename, $pagename, \%backuplist); # page feed
      $pagersspath = $localhtmlpath;
      $pagersspath =~ s/.html$/.page.rss.xml/;
      open (PAGERSSFILE, "> $pagersspath");
      print PAGERSSFILE $rssstr;
      close PAGERSSFILE;

      $rssstr = get_site_rss_string($params, $hostinfo, $sitename, \%backuplist); # site feed
      $sitersspath = $localhtmlpath;
      $sitersspath =~ s/[^\/]+\.html$/$sitename.site.rss.xml/;
      open (SITERSSFILE, "> $sitersspath");
      print SITERSSFILE $rssstr;
      close SITERSSFILE;
      }

   #
   # Create published datafile and HTML/source/JS/RSS files on remote host by FTP
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});

         # Upload HTML file and anything else for that directory

         $ok = $ftp->cwd("$sitedata->{htmlpath}") if $ok;
         $ok = $ftp->put($localhtmlpath, "$pagename.html") if ($ok && $publishhtml);
         $ok = $ftp->put($localjspath, "$pagename.js") if ($ok && $publishjs);
         $ok = $ftp->put($publisheddatafilepath, "$pagename.txt") if ($ok && $publishsource);
         $ok = $ftp->put($pagersspath, "$pagename.page.rss.xml") if ($ok && $sitedata->{publishrss});
         $ok = $ftp->put($sitersspath, "$sitename.site.rss.xml") if ($ok && $sitedata->{publishrss});

         # Upload datafile

         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->put($publisheddatafilepath) if $ok;
         $ok = $ftp->put($backupdatafilepath) if $ok;

         # Remove editing copy if not continuing

         if (!$continueediting && $ok) {
            my $editnameonly = $editdatafilepath;
            $editnameonly =~ s/.*\///;
            $ok = $ftp->delete($editnameonly);
            }

         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunablepubftp}\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrorpubftp}: '$ok'. $WKCStrings{datafileserrorpubftpstatus}: $msgsc.\n!;
         $ftp->quit; # just in case
         }
      unlink $localhtmlpath if ($istmplocalhtmlpath && $publishhtml); # delete temp file(s)
      unlink $localjspath if ($istmplocalhtmlpath && $publishjs);
      if ($sitedata->{publishrss} && $istmplocalhtmlpath) {
         unlink $pagersspath;
         unlink $sitersspath;
         }

      }

   if ($errstr) { # if error, do not stop editing and do not update siteinfo
      $errstr .= "<br>$WKCStrings{datafilescontinueopen}\n";
$params->{debugmessage} = $errstr;
      return $errstr;
      }

   #
   # Update headerdata if continuing
   #

   if ($continueediting) { # start header as if editing from closed file
      $headerdata->{basefiledt} = $headerdata->{backupfiledt}; # remember where previous stuff is if known
      delete $headerdata->{backupfiledt}; # this is only in final copies and we are back to editing
      delete $headerdata->{editlog}; # remove edit log, etc., to start anew
      delete $headerdata->{lastmodified};
      delete $headerdata->{lastauthor};
      delete $headerdata->{editcomments};
      $headercontents = create_header_save($headerdata);
      $sheetcontents = create_sheet_save($sheetdata);
      $ok = save_page($editdatafilepath, $headercontents, $sheetcontents); # save with updated data
      }

   #
   # Change siteinfo
   #

   my $siteinfo = get_siteinfo($params);
   my $fileinfo = $siteinfo->{files}->{$pagename};

   if (!$continueediting) { # remove editing copy if not continuing
      unlink $editdatafilepath;
      $fileinfo->{authors}->{$thisauthor}->{editstatus} = 0;
      }
   else {
      $fileinfo->{authors}->{$thisauthor}->{editstatus} = 1; # unmodified from publish but still editing
      }

   $fileinfo->{authors}->{$thisauthor}->{dtmedit} = "";
   $fileinfo->{pubstatus} = 1;
   my @tv = localtime;
   $fileinfo->{dtmpublished} = sprintf("%s %d, %04d %02d:%02d:%02d", $WKCmonthnames[$tv[4]], $tv[3], $tv[5]+1900,
                                            $tv[2], $tv[1], $tv[0]);
   $fileinfo->{size} = "";
   $fileinfo->{fullnamepublished} = $headerdata->{fullname};

   $ok = save_siteinfo($params, $siteinfo);

   #
   # Now that all is done, trim backups if necessary
   #

   my $doberrstr = delete_old_backups($params, $hostinfo, $sitename, $params->{datafilename});
   $errstr = $doberrstr if ($doberrstr =~ m/^Error/);

   return $errstr;

   }


# # # # # # #
#
# $errstr = rename_existing_page(\%params, $hostinfo, $sitename, $pagename, $newpagename)
#
# Renames all files associated with a page to a new name.
#
# Returns $errstr with error string nor null if OK.
#

sub rename_existing_page {

   my ($params, $hostinfo, $sitename, $pagename, $newpagename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $pagename =~ s/[^a-z0-9\-]//g;
   $newpagename =~ s/[^a-z0-9\-]//g;

   my $datafilepath = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   $datafilepath =~ s/published.txt$/*/; # wildcard to find all files for this page

   my @localfiles = glob($datafilepath);

   #
   # rename each file locally
   #

   foreach my $lfile (@localfiles) {
      my $renamedname = $lfile;
      $renamedname =~ s!([^a-z0-9\-])$pagename\.([^/]*)\.(txt)$!"$1$newpagename.$2.$3"!e;
      rename $lfile, $renamedname;
      }

   #
   # Rename on remote host if necessary
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});

         # Rename HTML file

         $ok = $ftp->cwd("$sitedata->{htmlpath}") if $ok;
         $ok = $ftp->rename("$pagename.html", "$newpagename.html") if $ok;
         $ok = 1; # may not exist - continue anyway

         # Find and rename all other files

         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my @dir;
         @dir = $ftp->dir if $ok;
         foreach my $line (@dir) { # go through each file
            my ($access, $links, $owner, $group, $s, $m, $d, $timeyr, $fname) = split(" ", $line, 9);
            next unless $fname =~ m/^$pagename\./; # is it one for this page?
            my $renamedname = $fname;
            $renamedname =~ s/^$pagename/$newpagename/e;
            $ok = $ftp->rename($fname, $renamedname) if $ok; # rename it
            }

         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableftpdownloadrename}\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrorrename}: $msgsc. $WKCStrings{datafilespossbilerename}\n!;
         $ftp->quit; # just in case
         }
      }

   else { # Rename locally published files
      $datafilepath = get_page_published_HTML_path($params, $hostinfo, $sitename, $pagename);
      $datafilepath =~ s/html$/*/; # want .html and .txt
      @localfiles = glob($datafilepath);
      foreach my $lfile (@localfiles) {
         my $renamedname = $lfile;
         $renamedname =~ s!([^a-z0-9\-])$pagename\.(txt|html)$!"$1$newpagename.$2"!e;
         rename $lfile, $renamedname;
         }
      }

   return $errstr if $errstr;

   #
   # Rename in siteinfo and get updated info all around
   #

   my $siteinfo = get_siteinfo($params);
   delete $siteinfo->{files}->{$pagename};
   $siteinfo->{ftpdatetime} = "";
   $ok = update_siteinfo($params, $hostinfo, $siteinfo);
   $ok = save_siteinfo($params, $siteinfo);

   $params->{datafilename} = $newpagename;

   return "$WKCStrings{datafilesrenamed} '$pagename' $WKCStrings{datafilesrenamedto} '$newpagename'";

   }


# # # # # # #
#
# $errstr = rename_specific_file(\%params, $hostinfo, $sitename, $filename, $newfilename)
#
# Renames a particular file (usually backup to archive) both locally and remotely
#
# Returns $errstr with error string nor null if OK.
#

sub rename_specific_file {

   my ($params, $hostinfo, $sitename, $filename, $newfilename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $filename =~ s/[^a-zA-Z0-9\-\.]//g;
   $newfilename =~ s/[^a-zA-Z0-9\-\.]//g;

   my $filepath = get_page_published_datafile_path($params, $hostinfo, $sitename, "rename");
   $filepath =~ s/rename.published.txt$//; # get just path part

   #
   # rename locally
   #

   rename "$filepath$filename", "$filepath$newfilename";

   #
   # Rename on remote host if necessary
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->rename($filename, $newfilename) if $ok; # rename it
         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = qq!$WKCStrings{datafilesunableftplocalpossible}\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrorrename}: $msgsc. $WKCStrings{datafilespossbilerename}\n!;
         $ftp->quit; # just in case
         }
      }

   return $errstr;

   }


# # # # # # #
#
# $errstr = download_specific_file(\%params, $hostinfo, $sitename, $filename)
#
# Copies a particular file (usually backup to archive) from remote to local by FTP
#
# Returns $errstr with error string nor null if OK.
#

sub download_specific_file {

   my ($params, $hostinfo, $sitename, $filename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $filename =~ s/[^a-zA-Z0-9\-\.]//g;

   my $filepath = get_page_published_datafile_path($params, $hostinfo, $sitename, "rename");
   $filepath =~ s/rename.published.txt$//; # get just path part

   if ($hostdata->{url}) { # do the download
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->get($filename, "$filepath$filename") if $ok; # copy it
         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableftpdownload}\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrordownloadingftpis}: $msgsc. $WKCStrings{datafilesmaybecorrupt}\n!;
         $ftp->quit; # just in case
         }
      }

   else {
      $errstr = qq!$WKCStrings{datafileshost} "$sitedata->{host}" $WKCStrings{datafilesnotsetup}!;
      }

   return $errstr;

   }


# # # # # # #
#
# $errstr = delete_page(\%params, $hostinfo, $sitename, $pagename)
#
# Deletes a page
#
# Returns $errstr with error string nor null if OK.
#

sub delete_page {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $pagename =~ s/[^a-z0-9\-]//g;

   my $datafilepath = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   $datafilepath =~ s/published.txt$/*/;

   my @localfiles = glob($datafilepath);

   #
   # Delete each file locally
   #

   foreach my $lfile (@localfiles) {
      unlink $lfile;
      }

   #
   # Delete on remote host if necessary
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});

         # Delete HTML file

         $ok = $ftp->cwd("$sitedata->{htmlpath}") if $ok;
         $ok = $ftp->delete("$pagename.html") if $ok;
         $ok = 1; # may not exist - continue anyway
         $ok = $ftp->delete("$pagename.txt") if $ok;
         $ok = 1; # may not exist - continue anyway

         # Find and delete all other files

         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my @dir;
         @dir = $ftp->dir if $ok;
         foreach my $line (@dir) { # go through each file
            my ($access, $links, $owner, $group, $s, $m, $d, $timeyr, $fname) = split(" ", $line, 9);
            next unless $fname =~ m/^$pagename\./; # is it one for this page?
            $ok = $ftp->delete($fname) if $ok; # delete it
            }

         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = "$WKCStrings{datafilesunableftpdelete}\n";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrordeletingstatusis}: $msgsc.\n!;
         $ftp->quit; # just in case
         }
      }

   else { # Remove locally published files
      $datafilepath = get_page_published_HTML_path($params, $hostinfo, $sitename, $pagename);
      $datafilepath =~ s/html$/*/;
      @localfiles = glob($datafilepath);
      foreach my $lfile (@localfiles) {
         unlink $lfile;
         }
      }

   #
   # Remove from siteinfo
   #

   my $siteinfo = get_siteinfo($params);
   delete $siteinfo->{files}->{$pagename};

   $ok = save_siteinfo($params, $siteinfo);

   return $errstr;

   }

# # # # # # #
#
# $errstr = delete_specific_file(\%params, $hostinfo, $sitename, $filename)
#
# Deletes a particular file (usually backup or archive) both locally and remotely
#
# Returns $errstr with error string nor null if OK.
#

sub delete_specific_file {

   my ($params, $hostinfo, $sitename, $filename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $filename =~ s/[^a-zA-Z0-9\-\.]//g;

   my $filepath = get_page_published_datafile_path($params, $hostinfo, $sitename, "rename");
   $filepath =~ s/rename.published.txt$//; # get just path part

   #
   # Delete locally
   #

   unlink "$filepath$filename";

   #
   # Delete on remote host if necessary
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->delete($filename) if $ok; # delete it
         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = qq!$WKCStrings{datafilesunableftpdeletelocalmaybe}\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrorftpdeletestatusis}: $msgsc.\n!;
         $ftp->quit; # just in case
         }
      }

   return $errstr;

   }


# # # # # # #
#
# $errstr = abandon_page_edit(\%params, $hostinfo, $sitename, $pagename)
#
# Deletes the edit pages of the specified page for the current author
#
# Returns $errstr with error string nor null if OK.
#

sub abandon_page_edit {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my ($errstr, $ok);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $pagename =~ s/[^a-z0-9\-]//g;

   my $thisauthor = $sitedata->{authoronhost};
   if ($sitedata->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $thisauthor = $params->{loggedinusername};
      $thisauthor =~ s/[^a-z0-9\-]//g;
      }

   my $editdatafilepath = get_page_edit_path($params, $hostinfo, $sitename, $pagename);

   #
   # Delete locally
   #

   unlink $editdatafilepath;

   #
   # Delete on remote host if necessary
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my $editnameonly = $editdatafilepath;
         $editnameonly =~ s/.*\///;
         $ok = $ftp->delete($editnameonly);
         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $errstr = qq!$WKCStrings{datafilesunableftpdeleteedit}\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $errstr = qq!$WKCStrings{datafileserrorftpdeleteeditstatusis}: $msgsc.\n!;
         $ftp->quit; # just in case
         }
      }

   #
   # Remove from siteinfo
   #

   my $siteinfo = get_siteinfo($params);
   my $fileinfo = $siteinfo->{files}->{$pagename};
   delete $fileinfo->{authors}->{$thisauthor};

   $ok = save_siteinfo($params, $siteinfo);

   return $errstr;

   }


# # # # # # # # # #
#
# get_page_backup_list(\%params, \%hostinfo, $sitename, $pagename, \%backuplist)
#
# Gets the information about all pages on $sitename, plus details on the specified page
#
# Fills in %backuplist:
#
#    $backuplist{pages}
#       {$filename} - $filename is name.backup.yyyy-mm-dd-hh-mm-ss.txt
#           {pagename} - short name
#           {dtm} - date/time in filename (yyyy-mm-dd-hh-mm-ss)
#           {type} - backup, archive
#           {local} - yes if local copy available (with details easily available), no or blank otherwise
#           Details:
#           {author} - author name
#           {edits} - number of edits
#           {comments} - comments if present (escaped for display)
#           {fullname} - full name if present (escaped for display)
#       {noftp} - yes if unable to connect to Internet and need to for full list, blank or no otherwise
#       {error} - Error message or blank
#

sub get_page_backup_list {

   my ($params, $hostinfo, $sitename, $pagename, $backuplist) = @_;

   my ($errstr, $ok, $loaderr);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   %$backuplist = ();
   $backuplist->{pages} = {};

   my $pathwildcard = get_page_edit_path($params, $hostinfo, $sitename, "all");
   $pathwildcard =~ s/\/all\.edit\.[a-z0-9\-]+?\.txt$/\/*.txt/;

   my @localfiles = glob($pathwildcard);

   foreach my $lfilefull (@localfiles) {
      my $lfile = $lfilefull;
      $lfile =~ s/^.+\/([^\/]+)$/$1/; # get just filenames
      next unless $lfile =~ m/^(.+?)\.(backup|archive)\.([0-9\-]+)\.txt/; # backups only
      $backuplist->{pages}->{$lfile} ||= {}; # init if first file for this
      my $blp = $backuplist->{pages}->{$lfile};
      $blp->{pagename} = $1;
      $blp->{dtm} = $3;
      $blp->{type} = $2;
      $blp->{local} = "yes";
      next unless $1 eq $pagename; # only get details for specified page
      my (@headerlines, %headerdata);
      $loaderr = load_page($lfilefull, \@headerlines, "");
      $ok = parse_header_save(\@headerlines, \%headerdata);
      $blp->{author} = $headerdata{lastauthor};
      $blp->{edits} = $headerdata{editlog} ? scalar @{$headerdata{editlog}} : "";
      $blp->{comments} = special_chars($headerdata{editcomments});
      $blp->{comments} =~ s/\n/<br>/g;
      $blp->{fullname} = special_chars($headerdata{fullname});
      }

   #
   # Look on remote host if publishing there
   #

   if ($hostdata->{url}) {
      my $ftp;
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});

         # Find all files in site data

         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my @dir;
         @dir = $ftp->dir if $ok;
         foreach my $line (@dir) { # go through each file
            my ($access, $links, $owner, $group, $s, $m, $d, $timeyr, $fname) = split(" ", $line, 9);
            next unless $fname =~ m/^(.+?)\.(backup|archive)\.([0-9\-]+)\.txt/; # is it a backup?
            $backuplist->{pages}->{$fname} ||= {}; # init if first file for this
            my $blp = $backuplist->{pages}->{$fname};
            $blp->{pagename} = $1;
            $blp->{dtm} = $3;
            $blp->{type} = $2;
            }

         $ftp->quit if $ok;
         }
      if (!$ftp) {
         $backuplist->{error} = qq!$WKCStrings{datafilesunableftplistbackup}\n!;
         $backuplist->{noftp} = "yes";
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $backuplist->{error} = qq!$WKCStrings{datafileserrorftplistbackupstatusis}: $msgsc.\n!;
         $ftp->quit; # just in case
         }
      }

   return;
   }


# # # # # # # # # #
#
# $statusstr = delete_old_backups(\%params, \%hostinfo, $sitename, $pagename)
#
# Deletes backup files scheduled for deleting as set in hostinfo site settings.
# Returns a string explaining what it did or did not do.
#
#

sub delete_old_backups {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my ($statusstr, $ok, $needquit);

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};
   $pagename =~ s/[^a-zA-Z0-9\-]//g;

   # Check if there is anything to do

   if (!$sitedata->{backupmaxfiles} || $sitedata->{backupmaxfiles} <= 0) { # missing or <0 means keep all
      return $statusstr; # Just return
      }

   my %filelist;

   my $pathwildcard = get_page_edit_path($params, $hostinfo, $sitename, $pagename);
   $pathwildcard =~ s/^(.+\/)($pagename)\.edit\.[a-z0-9\-]+?\.txt$/$1$2.backup.*.txt/; # make wildcard for backup files
   my $localpath = $1; # remember directory where files are

   my @localfiles = glob($pathwildcard);

   foreach my $lfilefull (@localfiles) {
      my $lfile = $lfilefull;
      $lfile =~ s/^.+\/([^\/]+)$/$1/; # get just filenames
      $filelist{$lfile} = "L"; # remember file and that it's local
      }

   #
   # Look on remote host if publishing there
   #

   my $ftp;
   if ($hostdata->{url}) {
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});

         # Find all files in site data

         $ok = $ftp->cwd("/$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         my @dir;
         @dir = $ftp->dir if $ok;
         foreach my $line (@dir) { # go through each file
            my ($access, $links, $owner, $group, $s, $m, $d, $timeyr, $fname) = split(" ", $line, 9);
            next unless $fname =~ m/^$pagename\.backup\.([0-9\-]+)\.txt/; # get our backup files
            $filelist{$fname} = $filelist{$fname} ? "B" : "R"; # remember file and if it's just remote or both
            }
         $needquit = 1; # don't quit now, but remember to quit later
         }
      if (!$ftp) {
         $statusstr = qq!$WKCStrings{datafilesunableftplistremotetodelete}\n!;
         }
      elsif (!$ok) {
         my $msgsc = special_chars($ftp->message);
         $statusstr = qq!$WKCStrings{datafileserrorftplistremotetodelete}: $msgsc.\n!;
         }
      }

   #
   # Go through list, apply criteria, and delete files that have expired
   #

   my @sortedfiles = reverse sort keys %filelist;
   my $now = time(); # get time GMT in seconds
   my $minseconds = $sitedata->{backupmindays} * 60 * 60 * 24;
   my $numdeleted;

   for (my $fn=$sitedata->{backupmaxfiles}; $fn < scalar @sortedfiles; $fn++) { # look at files after max kept
      my $bfile = $sortedfiles[$fn];
      $bfile =~ m/^.+?\.backup\.([0-9\-]+)\.txt$/;
      my ($yr, $mon, $day, $hr, $min, $sec) = split(/\-/, $1);
      my $ftime = timegm($sec, $min, $hr, $day, $mon-1, $yr);
      my $tdelta = $now - $ftime;
      next if $tdelta < $minseconds;
      $numdeleted++;
      if ($filelist{$bfile} eq "B" || $filelist{$bfile} eq "L") {
         unlink "$localpath$bfile"; # delete locally
         }
      if ($filelist{$bfile} eq "B" || $filelist{$bfile} eq "R") {
         $ftp->delete($bfile); # delete remotely
         }
      }

   #
   # Finish up
   #

   $ftp->quit if $needquit;

   $statusstr .= "<br><br>" if $statusstr;
   $statusstr .= "$WKCStrings{datafilesbackupsdeleted1} $numdeleted $WKCStrings{datafilesbackupsdeleted2}.<br>";

   return $statusstr;
   }


# # # # # # # #
#
# $rssstr = get_page_rss_string($params, $hostinfo, $sitename, $pagename, \%backuplist)
#
# Render RSS content for a page given a backuplist created with that sitename/pagename
#
# # # # # # # #

sub get_page_rss_string {

   my ($params, $hostinfo, $sitename, $pagename, $backuplist) = @_;

   my $rssstr;

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $longsitename = special_chars($hostinfo->{sites}->{$sitename}->{longname});

   my @sortlist;
   foreach my $bfile (keys %{$backuplist->{pages}}) { # get list of dtm's to sort along with associated filenames
      push @sortlist, ($backuplist->{pages}->{$bfile}->{dtm} . ":" . $bfile);
      }
   my @revsortlist = reverse sort @sortlist;
   my $listsize = scalar @revsortlist;
   my $count;

   my ($dtm0, $pname0);
   for (my $thisitem=0; $thisitem < $listsize; $thisitem++) { # Find our page's full name - it's in the data
      ($dtm0, $pname0) = split(":", $revsortlist[$thisitem]); # get filename
      last if $backuplist->{pages}->{$pname0}->{pagename} eq $pagename;
      }
   my $longpagename = special_chars($backuplist->{pages}->{$pname0}->{fullname}) || $pagename;

   my $rsstitle = (special_chars($sitedata->{rsstitle}) || "$sitename") . ": $longpagename";
   my $rsslink = $sitedata->{htmlurl} ? "$sitedata->{htmlurl}/$pagename.html" : $sitedata->{rsslink};

   my $rssdescription = qq!$WKCStrings{datafilesrsspage} "$longpagename" ($pagename) $WKCStrings{datafilesrssonsite} "! . (special_chars($sitedata->{rsstitle}) || $longsitename || $sitename) . '"';

   my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime;
   my $dayname = $WKCrfc822daynames[$wday];
   my $monname = $WKCrfc822monthnames[$mon];
   my $dtstring = sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", $dayname, $mday, $monname, $year+1900,
      $hour, $min, $sec);
   my $extraxml = $sitedata->{rsschannelxml} ? "\n$sitedata->{rsschannelxml}" : "";

   my $rssstr;

   $rssstr = <<"EOF";
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
 <channel>
  <title>$rsstitle</title>
  <link>$rsslink</link>
  <description>$rssdescription</description>
  <lastBuildDate>$dtstring</lastBuildDate>
  <generator>$WKC::programname</generator>
  <docs>http://blogs.law.harvard.edu/tech/rss</docs>$extraxml
EOF

   for (my $thisitem=0; $thisitem < $listsize; $thisitem++) { # Output most recent 10
      my ($dtm, $pname) = split(":", $revsortlist[$thisitem]); # get filename
      my $blp = $backuplist->{pages}->{$pname};
      next if $blp->{pagename} ne $pagename;
      $count++;
      last if $count > $sitedata->{rssmaxpageitems};
      my $fullname = $blp->{fullname} || $pagename;
      my $author = $blp->{author} ? " $WKCStrings{datafilesrssby} $blp->{author}" : "";
      my $edits = $blp->{edits} ? " $WKCStrings{datafilesrsswith} $blp->{edits} edit".($blp->{edits}>1?$WKCStrings{datafilesrsseditpluralending}:"") : "";
      my $comments = special_chars($blp->{comments}); # escape once more
      my $description = $comments ? "\n   <description>$comments</description>" : "";
      my $pagelink = $sitedata->{htmlurl} && $count==1 ? "\n   <link>$sitedata->{htmlurl}/$pagename.html</link>" : "";
      my ($yr, $mon, $day, $hr, $minute, $sec) = split("-", $blp->{dtm}); # Note: RFC822 has ***optional*** day of week
      my $dtmstr = sprintf("%02d %s %04d %02d:%02d:%02d GMT", $day, $WKCmonthnames[$mon-1], $yr, $hr, $minute, $sec);
      my $dtmstr822 = sprintf("%02d %s %04d %02d:%02d:%02d GMT", $day, $WKCrfc822monthnames[$mon-1], $yr, $hr, $minute, $sec);

      $rssstr .= <<"EOF";
  <item>
   <title>$fullname published $dtmstr$author$edits</title>$pagelink$description
   <guid isPermaLink="false">$pname</guid>
   <pubDate>$dtmstr822</pubDate>
  </item>
EOF
      }

   $rssstr .= <<"EOF";
 </channel>
</rss>
EOF

   return $rssstr;
   }


# # # # # # # #
#
# $rssstr = get_site_rss_string($params, $hostinfo, $sitename, \%backuplist)
#
# Render RSS content for entire site given a backuplist
#
# # # # # # # #

sub get_site_rss_string {

   my ($params, $hostinfo, $sitename, $backuplist) = @_;

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $longsitename = special_chars($hostinfo->{sites}->{$sitename}->{longname});

   my $rsstitle = special_chars($sitedata->{rsstitle} || $sitename);
   my $rssdescription = special_chars($sitedata->{rssdescription}) || $longsitename;

   my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime;
   my $dayname = $WKCrfc822daynames[$wday];
   my $monname = $WKCrfc822monthnames[$mon];
   my $dtstring = sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", $dayname, $mday, $monname, $year+1900,
      $hour, $min, $sec);
   my $extraxml = $sitedata->{rsschannelxml} ? "\n$sitedata->{rsschannelxml}" : "";

   my $rssstr;

   $rssstr = <<"EOF";
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
 <channel>
  <title>$rsstitle</title>
  <link>$sitedata->{rsslink}</link>
  <description>$rssdescription</description>
  <lastBuildDate>$dtstring</lastBuildDate>
  <generator>$WKC::programname</generator>
  <docs>http://blogs.law.harvard.edu/tech/rss</docs>$extraxml
EOF

   my $localpath = get_page_edit_path($params, $hostinfo, $sitename, "all");
   $localpath =~ s/^(.+\/)[^\/]+$/$1/; # get directory where files are

   my @sortlist;
   foreach my $bfile (keys %{$backuplist->{pages}}) { # get list of dtm's to sort along with associated filenames
      push @sortlist, ($backuplist->{pages}->{$bfile}->{dtm} . ":" . $bfile);
      }
   my @revsortlist = reverse sort @sortlist;
   my $listsize = scalar @revsortlist;

   my %pagelinked; # only link to most recent page edit

   for (my $thisitem=0; $thisitem < $listsize && $thisitem < $sitedata->{rssmaxsiteitems}; $thisitem++) { # Output most recent
      my ($dtm, $pname) = split(":", $revsortlist[$thisitem]); # get filename
      my $blp = $backuplist->{pages}->{$pname};
      if (!$blp->{author} && !$blp->{comments}) { # skip if already got details for this file
         my (@headerlines, %headerdata); # Get details about this publish
         load_page("$localpath$pname", \@headerlines, "");
         parse_header_save(\@headerlines, \%headerdata);
         $blp->{author} = $headerdata{lastauthor} || $WKCStrings{datafilesrssunknown};
         $blp->{edits} = $headerdata{editlog} ? scalar @{$headerdata{editlog}} : "";
         $blp->{comments} = special_chars($headerdata{editcomments});
         $blp->{comments} =~ s/\n/<br>/g;
         $blp->{fullname} = special_chars($headerdata{fullname});
         }
      my $fullname = $blp->{fullname} || $blp->{pagename};
      my $author = $blp->{author} ? " $WKCStrings{datafilesrssby} $blp->{author}" : "";
      my $edits = $blp->{edits} ? " $WKCStrings{with} $blp->{edits} $WKCStrings{datafilesrssedit}".($blp->{edits}>1?$WKCStrings{datafilesrsseditpluralending}:"") : "";
      my $comments = special_chars($blp->{comments}); # escape once more
      my $description = $comments ? "\n   <description>$comments</description>" : "";
      my $pagelink = $sitedata->{htmlurl} && !$pagelinked{$blp->{pagename}} ? "\n   <link>$sitedata->{htmlurl}/$blp->{pagename}.html</link>" : "";
      $pagelinked{$blp->{pagename}} = 1; # remember not to link to this page again
      my ($yr, $mon, $day, $hr, $minute, $sec) = split("-", $blp->{dtm}); # Note: RFC822 has ***optional*** day of week
      my $dtmstr = sprintf("%02d %s %04d %02d:%02d:%02d GMT", $day, $WKCmonthnames[$mon-1], $yr, $hr, $minute, $sec);
      my $dtmstr822 = sprintf("%02d %s %04d %02d:%02d:%02d GMT", $day, $WKCrfc822monthnames[$mon-1], $yr, $hr, $minute, $sec);

      $rssstr .= <<"EOF";
  <item>
   <title>$fullname published $dtmstr$author$edits</title>$pagelink$description
   <guid isPermaLink="false">$pname</guid>
   <pubDate>$dtmstr822</pubDate>
  </item>
EOF
      }

   $rssstr .= <<"EOF";
 </channel>
</rss>
EOF

   return $rssstr;
   }


# # # # # # #
#
# $path = get_page_edit_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's edit file on the local machine
#

sub get_page_edit_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $thisauthor = $sitedata->{authoronhost};
   if ($sitedata->{authorfromlogin} eq "yes" && $params->{loggedinusername}) {
      $thisauthor = $params->{loggedinusername};
      $thisauthor =~ s/[^a-z0-9\-]//g;
      }

   return "$params->{localwkcpath}/wkcdata/sites/$sitename/$pagename.edit.$thisauthor.txt";

   }


# # # # # # #
#
# $path = get_ensured_page_edit_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's edit file on the local machine, copying it from the server if necessary
# Assumes you already checked that this page likely exists somewhere (could be "remote").
# Returns "" if can't find it.
#

sub get_ensured_page_edit_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my $editdatafilepathlocal = get_page_edit_path($params, $hostinfo, $sitename, $pagename);

   return $editdatafilepathlocal if -e $editdatafilepathlocal; # If exists already locally, use that

   my $editnameonly = $editdatafilepathlocal;
   $editnameonly =~ s/.*\///;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   #
   # Must be on remote host so download by FTP
   #

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $ftp;
   if ($hostdata->{url}) {
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         my $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->get($editnameonly, $editdatafilepathlocal) if $ok; # Download the copy
         $ftp->quit;
         }
      }

   $editdatafilepathlocal = "" unless -e $editdatafilepathlocal; # Make sure exists

   return $editdatafilepathlocal;

   }


# # # # # # #
#
# $path = get_page_published_datafile_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's published datafile on the local machine
#

sub get_page_published_datafile_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   return "$params->{localwkcpath}/wkcdata/sites/$sitename/$pagename.published.txt";

   }


# # # # # # #
#
# $path = get_ensured_page_published_datafile_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's published datafile on the local machine, copying it from the server if necessary
# Assumes you already checked that this page likely exists somewhere.
# Returns "" if can't find it.
#

sub get_ensured_page_published_datafile_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   my $publisheddatafilepathlocal = get_page_published_datafile_path($params, $hostinfo, $sitename, $pagename);
   my $publishednameonly = $publisheddatafilepathlocal;
   $publishednameonly =~ s/.*\///;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   #
   # If on remote host, download by FTP to get latest version
   #

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my $ftp;
   if ($hostdata->{url}) {
      $ftp = Net::FTP->new($hostdata->{url}, Debug => 0, Passive => 1, Timeout => 30);
      if ($ftp) {
         my $ok = $ftp->login($hostdata->{loginname}, $hostdata->{loginpassword});
         $ok = $ftp->cwd("$hostdata->{wkcpath}/wkcdata/sites/$sitedata->{nameonhost}") if $ok;
         $ok = $ftp->get($publishednameonly, $publisheddatafilepathlocal) if $ok; # Download the copy
         $ftp->quit;
         }
      }

   # Return path to local copy -- either retrieved from host or already here

   $publisheddatafilepathlocal = "" unless -e $publisheddatafilepathlocal; # Make sure exists

   return $publisheddatafilepathlocal;

   }


# # # # # # #
#
# $path = get_page_backup_datafile_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's backup datafile on the local machine
#

sub get_page_backup_datafile_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   my $sitedata = $hostinfo->{sites}->{$sitename};
   my $hostdata = $hostinfo->{hosts}->{$sitedata->{host}};

   my @tv = gmtime;   
   my $dtstring = sprintf("%04d-%02d-%02d-%02d-%02d-%02d", $tv[5]+1900, $tv[4]+1, $tv[3], $tv[2], $tv[1], $tv[0]);

   return "$params->{localwkcpath}/wkcdata/sites/$sitename/$pagename.backup.$dtstring.txt";

   }


# # # # # # #
#
# $path = get_page_published_HTML_path(\%params, $hostinfo, $sitename, $pagename)
#
# Returns the pathname of the page's HTML file on the local machine
#

sub get_page_published_HTML_path {

   my ($params, $hostinfo, $sitename, $pagename) = @_;

   $sitename =~ s/[^a-z0-9\-]//g; # just in case
   $pagename =~ s/[^a-z0-9\-]//g;

   my $sitedata = $hostinfo->{sites}->{$sitename};

   return "$sitedata->{htmlpath}/$pagename.html";

   }

