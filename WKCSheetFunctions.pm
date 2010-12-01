#
# WKCSheetFunctions.pl -- Spreadsheet functions
#
# (c) Copyright 2006 Software Garden, Inc.
# All Rights Reserved.
# Subject to Software License included with WKC.pm
#

   package WKCSheetFunctions;

   use strict;
   use CGI qw(:standard);
   use utf8;

#   use WKC;
   use WKCStrings;
   use WKCSheet;
   use LWP::UserAgent;
   use Time::Local;

#
# Export symbols
#

   require Exporter;
   our @ISA = qw(Exporter);
   our @EXPORT = qw(calculate_function);
   our $VERSION = '1.0.0';

#
# Locals
#

   # List of functions
   #
   # %function_list{function_name} = [function_subroutine, number_of_arguments]
   #   function_subroutine takes arguments $fname, \@operand, \@foperand, \$errortext, \%typelookup, \%sheetdata.
   #   number_of_arguments is:
   #      0 = no arguments
   #      >0 = exactly that many arguments
   #      <0 = that many arguments (abs value) or more
   #      100 = don't check

   my %function_list = (
       ABS => [\&math1_function, 1],
       ACOS => [\&math1_function, 1],
       AND => [\&and_or_function, -1],
       ASIN => [\&math1_function, 1],
       ATAN => [\&math1_function, 1],
       ATAN2 => [\&math2_function, 2],
       AVERAGE => [\&series_functions, -1],
       CHOOSE => [\&choose_function, -2],
       COLUMNS => [\&columns_rows_function, 1],
       COS => [\&math1_function, 1],
       COUNT => [\&series_functions, -1],
       COUNTA => [\&series_functions, -1],
       COUNTBLANK => [\&series_functions, -1],
       COUNTIF => [\&countif_sumif_functions, 2],
       DATE => [\&date_function, 3],
       DAVERAGE => [\&dseries_functions, 3],
       DAY => [\&dmy_function, 1],
       DCOUNT => [\&dseries_functions, 3],
       DCOUNTA => [\&dseries_functions, 3],
       DDB => [\&ddb_function, -4],
       DEGREES => [\&math1_function, 1],
       DGET => [\&dseries_functions, 3],
       DMAX => [\&dseries_functions, 3],
       DMIN => [\&dseries_functions, 3],
       DPRODUCT => [\&dseries_functions, 3],
       DSTDEV => [\&dseries_functions, 3],
       DSTDEVP => [\&dseries_functions, 3],
       DSUM => [\&dseries_functions, 3],
       DVAR => [\&dseries_functions, 3],
       DVARP => [\&dseries_functions, 3],
       EVEN => [\&math1_function, 1],
       EXACT => [\&exact_function, 2],
       EXP => [\&math1_function, 1],
       FACT => [\&math1_function, 1],
       FALSE => [\&zeroarg_functions, 0],
       FIND => [\&string_functions, -2],
       FV => [\&interest_functions, -2],
       HLOOKUP => [\&lookup_functions, -3],
       HOUR => [\&hms_function, 1],
       IF => [\&if_function, 3],
       INDEX => [\&index_function, -1],
       INT => [\&math1_function, 1],
       IRR => [\&irr_function, -1],
       ISBLANK => [\&is_functions, 1],
       ISERR => [\&is_functions, 1],
       ISERROR => [\&is_functions, 1],
       ISLOGICAL => [\&is_functions, 1],
       ISNA => [\&is_functions, 1],
       ISNONTEXT => [\&is_functions, 1],
       ISNUMBER => [\&is_functions, 1],
       ISTEXT => [\&is_functions, 1],
       LEFT => [\&string_functions, -2],
       LEN => [\&string_functions, 1],
       LN => [\&math1_function, 1],
       LOG => [\&log_function, -1],
       LOG10 => [\&math1_function, 1],
       LOWER => [\&string_functions, 1],
       MATCH => [\&lookup_functions, -2],
       MAX => [\&series_functions, -1],
       MID => [\&string_functions, 3],
       MIN => [\&series_functions, -1],
       MINUTE => [\&hms_function, 1],
       MOD => [\&math2_function, 2],
       MONTH => [\&dmy_function, 1],
       N => [\&ntv_functions, 1],
       NA => [\&zeroarg_functions, 0],
       NOT => [\&not_function, 1],
       NOW => [\&zeroarg_functions, 0],
       NPER => [\&interest_functions, -2],
       NPV => [\&npv_function, -2],
       ODD => [\&math1_function, 1],
       OR => [\&and_or_function, -1],
       PI => [\&zeroarg_functions, 0],
       PMT => [\&interest_functions, -2],
       POWER => [\&math2_function, 2],
       PRODUCT => [\&series_functions, -1],
       PROPER => [\&string_functions, 1],
       PV => [\&interest_functions, -2],
       RADIANS => [\&math1_function, 1],
       RATE => [\&interest_functions, -2],
       REPLACE => [\&string_functions, 4],
       REPT => [\&string_functions, 2],
       RIGHT => [\&string_functions, -2],
       ROUND => [\&round_function, -1],
       ROWS => [\&columns_rows_function, 1],
       SECOND => [\&hms_function, 1],
       SIN => [\&math1_function, 1],
       SLN => [\&sln_function, 3],
       SQRT => [\&math1_function, 1],
       STDEV => [\&series_functions, -1],
       STDEVP => [\&series_functions, -1],
       SUBSTITUTE => [\&string_functions, -3],
       SUM => [\&series_functions, -1],
       SUMIF => [\&countif_sumif_functions, -2],
       SYD => [\&syd_function, 4],
       T => [\&ntv_functions, 1],
       TAN => [\&math1_function, 1],
       TIME => [\&time_function, 3],
       TODAY => [\&zeroarg_functions, 0],
       TRIM => [\&string_functions, 1],
       TRUE => [\&zeroarg_functions, 0],
       TRUNC => [\&math2_function, 2],
       UPPER => [\&string_functions, 1],
       VALUE => [\&ntv_functions, 1],
       VAR => [\&series_functions, -1],
       VARP => [\&series_functions, -1],
       VLOOKUP => [\&lookup_functions, -3],
       WEEKDAY => [\&dmy_function, -1],
       WKCERRCELL => [\&zeroarg_functions, 0],
       WKCHTML => [\&wkchtml_function, -1],
       WKCHTTP => [\&wkchttp_function, -1],
       WKCTEXT => [\&wkctext_function, -1],
       YEAR => [\&dmy_function, 1],
       );

   my $PI = atan2(1,1)*4;

1;

# # # # # # # # #
#
# $ok = calculate_function($fname, \@operand, \$errortext, \%typelookup, \%sheetdata)
#
# # # # # # # # #

sub calculate_function {

   my ($fname, $operand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $value2, $tostype, $tostype2, $resulttype);

   my $ok = 1;

   my ($function_sub, $function_argnum) = @{$function_list{$fname}}[0, 1];

   if ($function_sub) {
      my @foperand;
      copy_function_args($operand, \@foperand);
      if ($function_argnum != 100) {
         if ($function_argnum < 0) {
            if (scalar @foperand < -$function_argnum) {
               function_args_error($fname, $operand, $errortext);
               return 0;
               }
            }
         else {
            if (scalar @foperand != $function_argnum) {
               function_args_error($fname, $operand, $errortext);
               return 0;
               }
            }
         }
      $function_sub->($fname, $operand, \@foperand, $errortext, $typelookup, $sheetdata);
      }

   else {
         my $ttext = $fname;

         if (@$operand && $operand->[@$operand-1]->{type} eq "start") { # no arguments - name or zero arg function
            pop @$operand;
            push @$operand, {type => "name", value => $ttext};
            }

         else {
            $$errortext = "$WKCStrings{sheetfuncunknownfunction} $ttext. ";
            }
      }

   return $ok;

}


# # # # # # # # #
#
# AVERAGE(v1,c1:c2,...)
# COUNT(v1,c1:c2,...)
# COUNTA(v1,c1:c2,...)
# COUNTBLANK(v1,c1:c2,...)
# MAX(v1,c1:c2,...)
# MIN(v1,c1:c2,...)
# PRODUCT(v1,c1:c2,...)
# STDEV(v1,c1:c2,...)
# STDEVP(v1,c1:c2,...)
# SUM(v1,c1:c2,...)
# VAR(v1,c1:c2,...)
# VARP(v1,c1:c2,...)
#
# Calculate all of these and then return the desired one (overhead is in accessing not calculating)
# If this routine is changed, check the dseries_functions, too.
#
# # # # # # # # #

sub series_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype);

   my $sum = 0;
   my $resulttypesum = "";
   my $count = 0;
   my $counta = 0;
   my $countblank = 0;
   my $product = 1;
   my $maxval;
   my $minval;
   my ($mk, $sk, $mk1, $sk1); # For variance, etc.: M sub k, k-1, and S sub k-1
                              # as per Knuth "The Art of Computer Programming" Vol. 2 3rd edition, page 232

   while (@$foperand) {
      $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);

      $count += 1 if substr($tostype,0,1) eq "n";
      $counta += 1 if substr($tostype,0,1) ne "b";
      $countblank += 1 if substr($tostype,0,1) eq "b";

      if (substr($tostype,0,1) eq "n") {
         $sum += $value1;
         $product *= $value1;
         $maxval = (defined $maxval) ? ($value1 > $maxval ? $value1 : $maxval) : $value1;
         $minval = (defined $minval) ? ($value1 < $minval ? $value1 : $minval) : $value1;
         if ($count eq 1) { # initialize with with first values for variance used in STDEV, VAR, etc.
            $mk1 = $value1;
            $sk1 = 0;
            }
         else { # Accumulate S sub 1 through n as per Knuth noted above
            $mk = $mk1 + ($value1 - $mk1) / $count;
            $sk = $sk1 + ($value1 - $mk1) * ($value1 - $mk);
            $sk1 = $sk;
            $mk1 = $mk;
            }
         $resulttypesum = lookup_result_type($tostype, $resulttypesum || $tostype, $typelookup->{plus});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttypesum,0,1) ne "e") {
         $resulttypesum = $tostype;
         }
      }

   $resulttypesum ||= "n";

   if ($fname eq "SUM") {
      push @$operand, {type => $resulttypesum, value => $sum};
      }
   elsif ($fname eq "PRODUCT") { # may handle cases with text differently than some other spreadsheets
      push @$operand, {type => $resulttypesum, value => $product};
      }
   elsif ($fname eq "MIN") {
      push @$operand, {type => $resulttypesum, value => ($minval || 0)};
      }
   elsif ($fname eq "MAX") {
      push @$operand, {type => $resulttypesum, value => ($maxval || 0)};
      }
   elsif ($fname eq "COUNT") {
      push @$operand, {type => "n", value => $count};
      }
   elsif ($fname eq "COUNTA") {
      push @$operand, {type => "n", value => $counta};
      }
   elsif ($fname eq "COUNTBLANK") {
      push @$operand, {type => "n", value => $countblank};
      }
   elsif ($fname eq "AVERAGE") {
      if ($count > 0) {
         push @$operand, {type => $resulttypesum, value => ($sum / $count)};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "STDEV") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => (sqrt($sk / ($count - 1)))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "STDEVP") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => (sqrt($sk / $count))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "VAR") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => ($sk / ($count - 1))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "VARP") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => ($sk / $count)};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }

   return;

}


# # # # # # # # #
#
# DAVERAGE(databaserange, fieldname, criteriarange)
# DCOUNT(databaserange, fieldname, criteriarange)
# DCOUNTA(databaserange, fieldname, criteriarange)
# DGET(databaserange, fieldname, criteriarange)
# DMAX(databaserange, fieldname, criteriarange)
# DMIN(databaserange, fieldname, criteriarange)
# DPRODUCT(databaserange, fieldname, criteriarange)
# DSTDEV(databaserange, fieldname, criteriarange)
# DSTDEVP(databaserange, fieldname, criteriarange)
# DSUM(databaserange, fieldname, criteriarange)
# DVAR(databaserange, fieldname, criteriarange)
# DVARP(databaserange, fieldname, criteriarange)
#
# Calculate all of these and then return the desired one (overhead is in accessing not calculating)
# If this routine is changed, check the series_functions, too.
#
# # # # # # # # #

sub dseries_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $cr);

   my $sum = 0;
   my $resulttypesum = "";
   my $count = 0;
   my $counta = 0;
   my $countblank = 0;
   my $product = 1;
   my $maxval;
   my $minval;
   my ($mk, $sk, $mk1, $sk1); # For variance, etc.: M sub k, k-1, and S sub k-1
                              # as per Knuth "The Art of Computer Programming" Vol. 2 3rd edition, page 232

   my ($dbrange, $dbrangetype) = top_of_stack_value_and_type($foperand);
   my ($fieldname, $fieldtype);
   $fieldname = operand_value_and_type($sheetdata, $foperand, $errortext, \$fieldtype);
   my ($criteriarange, $criteriarangetype) = top_of_stack_value_and_type($foperand);

   if ($dbrangetype ne "range" || $criteriarangetype ne "range") {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }


   my ($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num, $ndbrows) = decode_range_parts($sheetdata, $dbrange, $dbrangetype);
   my ($criteriasheetdata, $criteriacol1num, $ncriteriacols, $criteriarow1num, $ncriteriarows) = decode_range_parts($sheetdata, $criteriarange, $criteriarangetype);

   my $fieldasnum = field_to_colnum($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num, $fieldname, $fieldtype);
   $fieldasnum = int($fieldasnum);
   if ($fieldasnum <= 0) {
      push @$operand, {type => "e#VALUE!", value => 0};
      return;
      }

   my $targetcol = $dbcol1num + $fieldasnum - 1;

   my (@criteriafieldnums, $criteriacr, $criteriafieldname, $criteriafieldtype, $criterianum);

   for (my $i=0; $i<$ncriteriacols; $i++) { # get criteria field colnums
      $criteriacr = cr_to_coord($criteriacol1num+$i, $criteriarow1num);
      $criteriafieldname = $criteriasheetdata->{datavalues}->{$criteriacr};
      $criteriafieldtype = $criteriasheetdata->{valuetypes}->{$criteriacr};
      $criterianum = field_to_colnum($dbsheetdata, $dbcol1num, $ndbcols, $dbrow1num, $criteriafieldname, $criteriafieldtype);
      $criterianum = int($criterianum);
      if ($criterianum <= 0) {
         push @$operand, {type => "e#VALUE!", value => 0};
         return;
         }
      push @criteriafieldnums, $dbcol1num + $criterianum - 1;
      }

   my ($testok, $criteriacr, $criteria, $testcol, $testcr);

   for (my $i=1; $i<$ndbrows; $i++) { # go through each row of the database
      $testok = 0;
CRITERIAROW:
      for (my $j=1; $j<$ncriteriarows; $j++) { # go through each criteria row
         for (my $k=0; $k<$ncriteriacols; $k++) { # look at each column
            $criteriacr = cr_to_coord($criteriacol1num+$k, $criteriarow1num+$j); # where criteria is
            $criteria = $criteriasheetdata->{datavalues}->{$criteriacr};
            next unless $criteria; # blank items are OK
            $testcol = $criteriasheetdata->{datavalues}->{cr_to_coord($criteriacol1num+$k,$criteriarow1num)};
            $testcol = $criteriafieldnums[$k];
            $testcr = cr_to_coord($testcol,$dbrow1num+$i); # cell to check
            next CRITERIAROW unless test_criteria($criteriasheetdata->{datavalues}->{$testcr},
                                                  ($criteriasheetdata->{valuetypes}->{$testcr} || "b"),
                                                  $criteria);
            }
         $testok = 1;
         last CRITERIAROW;
         }
      next unless $testok;

      $cr = cr_to_coord($targetcol, $dbrow1num + $i); # get cell of this row to do the function on
      $value1 = $dbsheetdata->{datavalues}->{$cr};
      $tostype = $dbsheetdata->{valuetypes}->{$cr};
      $tostype ||= "b";
      if ($tostype eq "b") { # blank
         $value1 = 0;
         }

      $count += 1 if substr($tostype,0,1) eq "n";
      $counta += 1 if substr($tostype,0,1) ne "b";
      $countblank += 1 if substr($tostype,0,1) eq "b";

      if (substr($tostype,0,1) eq "n") {
         $sum += $value1;
         $product *= $value1;
         $maxval = (defined $maxval) ? ($value1 > $maxval ? $value1 : $maxval) : $value1;
         $minval = (defined $minval) ? ($value1 < $minval ? $value1 : $minval) : $value1;
         if ($count eq 1) { # initialize with with first values for variance used in STDEV, VAR, etc.
            $mk1 = $value1;
            $sk1 = 0;
            }
         else { # Accumulate S sub 1 through n as per Knuth noted above
            $mk = $mk1 + ($value1 - $mk1) / $count;
            $sk = $sk1 + ($value1 - $mk1) * ($value1 - $mk);
            $sk1 = $sk;
            $mk1 = $mk;
            }
         $resulttypesum = lookup_result_type($tostype, $resulttypesum || $tostype, $typelookup->{plus});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttypesum,0,1) ne "e") {
         $resulttypesum = $tostype;
         }
      }

   $resulttypesum ||= "n";

   if ($fname eq "DSUM") {
      push @$operand, {type => $resulttypesum, value => $sum};
      }
   elsif ($fname eq "DPRODUCT") { # may handle cases with text differently than some other spreadsheets
      push @$operand, {type => $resulttypesum, value => $product};
      }
   elsif ($fname eq "DMIN") {
      push @$operand, {type => $resulttypesum, value => ($minval || 0)};
      }
   elsif ($fname eq "DMAX") {
      push @$operand, {type => $resulttypesum, value => ($maxval || 0)};
      }
   elsif ($fname eq "DCOUNT") {
      push @$operand, {type => "n", value => $count};
      }
   elsif ($fname eq "DCOUNTA") {
      push @$operand, {type => "n", value => $counta};
      }
   elsif ($fname eq "DAVERAGE") {
      if ($count > 0) {
         push @$operand, {type => $resulttypesum, value => ($sum / $count)};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "DSTDEV") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => (sqrt($sk / ($count - 1)))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "DSTDEVP") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => (sqrt($sk / $count))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "DVAR") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => ($sk / ($count - 1))};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "DVARP") {
      if ($count > 1) {
         push @$operand, {type => $resulttypesum, value => ($sk / $count)};
         }
      else {
         push @$operand, {type => "e#DIV/0!", value => 0};
         }
      }
   elsif ($fname eq "DGET") {
      if ($count == 1) {
         push @$operand, {type => $resulttypesum, value => $sum};
         }
      elsif ($count == 0) {
         push @$operand, {type => "e#VALUE!", value => 0};
         }
      else {
         push @$operand, {type => "e#NUM!", value => 0};
         }
      }

   return;
}


# # # # # # # # #
#
# $colnum = field_to_colnum(\@sheetdata, $col1num, $ncols, $row1num, $fieldname, $fieldtype)
#
# If fieldname is a number, uses it, otherwise looks up string in cells in row to find field number
#
# If not found, returns 0.
#
# # # # # # # # #

sub field_to_colnum {

   my ($sheetdata, $col1num, $ncols, $row1num, $fieldname, $fieldtype) = @_;

   if (substr($fieldtype,0,1) eq "n") { # number - return it if legal
      if ($fieldname <= 0 || $fieldname > $ncols) {
         return 0;
         }
      return int($fieldname);
      }

   if (substr($fieldtype,0,1) ne "t") { # must be text otherwise
      return 0;
      }

   utf8::decode($fieldname); # change UTF-8 bytes to chars
   $fieldname = lc $fieldname;

   my ($cr, $value);

   for (my $i=0; $i < $ncols; $i++) { # look through column headers for a match
      $cr = cr_to_coord($col1num+$i, $row1num);
      $value = $sheetdata->{datavalues}->{$cr};
      utf8::decode($value);
      $value = lc $value; #ignore case
      next if $value ne $fieldname; # no match
      return $i+1; # match
      }
   return 0; # looked at all and no match
   }


# # # # # # # # #
#
# HLOOKUP(value, range, row, [rangelookup])
# VLOOKUP(value, range, col, [rangelookup])
# MATCH(value, range, [rangelookup])
#
# # # # # # # # #

sub lookup_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value, $value8, $tostype, $cr);

   my ($lookupvalue, $lookupvalue8, $lookuptype);
   $lookupvalue = operand_value_and_type($sheetdata, $foperand, $errortext, \$lookuptype);
   $lookupvalue8 = $lookupvalue;
   utf8::decode($lookupvalue8);
   $lookupvalue8 = lc $lookupvalue8;

   my ($range, $rangetype) = top_of_stack_value_and_type($foperand);
   my ($offsetvalue, $offsettype);
   my $rangelookup = 1; # default to true or 1
   if ($fname eq "MATCH") {
      if (scalar @$foperand) {
         $rangelookup = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
         if (substr($tostype,0,1) ne "n") {
            push @$operand, {type => "e#VALUE!", value => 0};
            return;
            }
         if (scalar @$foperand) {
            function_args_error($fname, $operand, $errortext);
            return 0;
            }
         }
      }
   else {
      $offsetvalue = int(operand_as_number($sheetdata, $foperand, $errortext, \$offsettype));
      if (scalar @$foperand) {
         $rangelookup = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
         if (substr($tostype,0,1) ne "n") {
            push @$operand, {type => "e#VALUE!", value => 0};
            return;
            }
         if (scalar @$foperand) {
            function_args_error($fname, $operand, $errortext);
            return 0;
            }
         $rangelookup = $rangelookup ? 1 : 0; # convert to 1 or 0
         }
      }
   $lookuptype = substr($lookuptype,0,1); # only deal with general type

   if ($rangetype ne "range") {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }
   my ($rangesheetdata, $rangecol1num, $nrangecols, $rangerow1num, $nrangerows) = decode_range_parts($sheetdata, $range, $rangetype);

   my $c = 0;
   my $r = 0;
   my $cincr = 0;
   my $rincr = 0;
   if ($fname eq "HLOOKUP") {
      $cincr = 1;
      if ($offsetvalue > $nrangerows) {
         push @$operand, {type => "e#REF!", value => 0};
         return;
         }
      }
   elsif ($fname eq "VLOOKUP") {
      $rincr = 1;
      if ($offsetvalue > $nrangecols) {
         push @$operand, {type => "e#REF!", value => 0};
         return;
         }
      }
   elsif ($fname eq "MATCH") {
      if ($nrangecols > 1) {
         if ($nrangerows > 1) {
            push @$operand, {type => "e#N/A", value => 0};
            return;
            }
         $cincr = 1;
         }
      else {
         $rincr = 1;
         }
      }
   else {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }
   if ($offsetvalue < 1 && $fname ne "MATCH") {
      push @$operand, {type => "e#VALUE!", value => 0};
      return 0;
      }

   my $previousOK; # if 1, previous test was <. If 2, also this one wasn't
   my ($csave, $rsave); # col and row of last OK

   while (1) {
      $cr = cr_to_coord($rangecol1num+$c, $rangerow1num+$r);
      $value = $rangesheetdata->{datavalues}->{$cr};
      $tostype = $rangesheetdata->{valuetypes}->{$cr};
      $tostype = substr($tostype,0,1); # only deal with general types
      $tostype ||= "b";
      if ($rangelookup) { # look for within brackets for matches
         if ($lookuptype eq "n" && $tostype eq "n") {
            last if ($lookupvalue == $value); # match
            if (($rangelookup > 0 && $lookupvalue > $value)
                || ($rangelookup < 0 && $lookupvalue < $value)) { # possible match: wait and see
               $previousOK = 1;
               $csave = $c;
               $rsave = $r;
               }
            elsif ($previousOK) { # last one was OK, this one isn't
               $previousOK = 2;
               last;
               }
            }
         elsif ($lookuptype eq "t" && $tostype eq "t") {
            $value8 = $value;
            utf8::decode($value8);
            $value8 = lc $value8;
            last if ($lookupvalue8 eq $value8); # match
            if (($rangelookup > 0 && $lookupvalue gt $value)
                || ($rangelookup < 0 && $lookupvalue lt $value)) { # possible match: wait and see
               $previousOK = 1;
               $csave = $c;
               $rsave = $r;
               }
            elsif ($previousOK) { # last one was OK, this one isn't
               $previousOK = 2;
               last;
               }
            }
         }
      else { # exact value matches
         if ($lookuptype eq "n" && $tostype eq "n") {
            last if ($lookupvalue == $value); # match
            }
         elsif ($lookuptype eq "t" && $tostype eq "t") {
            $value8 = $value;
            utf8::decode($value8);
            $value8 = lc $value8;
            last if ($lookupvalue8 eq $value8); # match
            }
         }
      $r += $rincr;
      $c += $cincr;
      if ($r >= $nrangerows || $c >= $nrangecols) { # end of range to check, no exact match
         if ($previousOK) { # at least one could have been OK
            $previousOK = 2;
            last;
            }
         push @$operand, {type => "e#N/A", value => 0};
         return;
         }
      }

   if ($previousOK == 2) { # back to last OK
      $r = $rsave;
      $c = $csave;
      }

   if ($fname eq "MATCH") {
      $value = $c + $r + 1; # only one may be <> 0
      $tostype = "n";
      }
   else {
      $cr = cr_to_coord($rangecol1num+$c+($fname eq "VLOOKUP" ? $offsetvalue-1 : 0), $rangerow1num+$r+($fname eq "HLOOKUP" ? $offsetvalue-1 : 0));
      $value = $rangesheetdata->{datavalues}->{$cr};
      $tostype = $rangesheetdata->{valuetypes}->{$cr};
      }
   push @$operand, {type => $tostype, value => $value};
   return;

}


# # # # # # # # #
#
# INDEX(range, rownum, colnum)
#
# # # # # # # # #

sub index_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($range, $rangetype) = top_of_stack_value_and_type($foperand); # get range
   if ($rangetype ne "range") {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }
   my ($indexsheetdata, $col1num, $ncols, $row1num, $nrows) = decode_range_parts($sheetdata, $range, $rangetype);

   my $rowindex = 0;
   my $colindex = 0;
   my $tostype;

   if (scalar @$foperand) { # look for row number
      $rowindex = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype,0,1) ne "n" || $rowindex < 0) {
         push @$operand, {type => "e#VALUE!", value => 0};
         return;
         }
      if (scalar @$foperand) {
         $colindex = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
         if (substr($tostype,0,1) ne "n" || $colindex < 0) {
            push @$operand, {type => "e#VALUE!", value => 0};
            return;
            }
         if (scalar @$foperand) {
            function_args_error($fname, $operand, $errortext);
            return 0;
            }
         }
      }

   if ($rowindex > $nrows || $colindex > $ncols) {
      push @$operand, {type => "e#REF!", value => 0};
      return;
      }

   my ($result, $resulttype);

   if ($rowindex == 0) {
      if ($colindex == 0) {
         if ($nrows == 1 && $ncols == 1) {
            $result = cr_to_coord($col1num, $row1num);
            $result = "coord";
            }
         else {
            $result = cr_to_coord($col1num, $row1num) . "|" . cr_to_coord($col1num+$ncols-1, $row1num+$nrows-1) . "|";
            $resulttype = "range";
            }
         }
      else {
         if ($nrows == 1) {
            $result = cr_to_coord($col1num+$colindex-1, $row1num);
            $result = "coord";
            }
         else {
            $result = cr_to_coord($col1num+$colindex-1, $row1num) . "|" . cr_to_coord($col1num+$colindex-1, $row1num+$nrows-1) . "|";
            $resulttype = "range";
            }
         }
      }
   else {
      if ($colindex == 0) {
         if ($ncols == 1) {
            $result = cr_to_coord($col1num, $row1num+$rowindex-1);
            $result = "coord";
            }
         else {
            $result = cr_to_coord($col1num, $row1num+$rowindex-1) . "|" . cr_to_coord($col1num+$ncols-1, $row1num+$rowindex-1) . "|";
            $resulttype = "range";
            }
         }
      else {
         $result = cr_to_coord($col1num+$colindex-1, $row1num+$rowindex-1);
         $resulttype = "coord";
         }
      }

   push @$operand, {type => $resulttype, value => $result};
   return;

}


# # # # # # # # #
#
# COUNTIF(c1:c2,"criteria")
# SUMIF(c1:c2,"criteria")
#
# # # # # # # # #

sub countif_sumif_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $value2, $tostype2, $criteriavalue, $criteriatype, $sumrangevalue, $sumrangetype);

   my ($rangevalue, $rangetype) = top_of_stack_value_and_type($foperand); # get range or coord
   my ($criteriavalue, $criteriatype) = operand_as_text($sheetdata, $foperand, $errortext, \$tostype); # get criteria
   if ($fname eq "SUMIF") {
      if ((scalar @$foperand) == 1) { # three arg form of SUMIF
         ($sumrangevalue, $sumrangetype) = top_of_stack_value_and_type($foperand);
         }
      elsif ((scalar @$foperand) == 0) { # two arg form
         $sumrangevalue = $rangevalue;
         $sumrangetype = $rangetype;
         }
      else {
         function_args_error($fname, $operand, $errortext);
         return 0;
         }
      }
   else {
      $sumrangevalue = $rangevalue;
      $sumrangetype = $rangetype;
      }

   if (substr($criteriatype,0,1) eq "n") {
      $criteriavalue = "$criteriavalue";
      }
   elsif (substr($criteriatype,0,1) eq "e") { # error
      undef $criteriavalue;
      }
   elsif (substr($criteriatype,0,1) eq "b") { # blank here is undefined
      undef $criteriavalue;
      }

   if ($rangetype ne "coord" && $rangetype ne "range") {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }

   if ($fname eq "SUMIF" && $sumrangetype ne "coord" && $sumrangetype ne "range") {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }

   push @$foperand, {type => $rangetype, value => $rangevalue};
   my @f2operand; # to allow for 3 arg form
   push @f2operand, {type => $sumrangetype, value => $sumrangevalue};

   my $sum = 0;
   my $resulttypesum = "";
   my $count = 0;

   while (@$foperand) {
      $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
      $value2 = operand_value_and_type($sheetdata, \@f2operand, $errortext, \$tostype2);

      next unless test_criteria($value1, $tostype, $criteriavalue);

      $count += 1;

      if (substr($tostype2,0,1) eq "n") {
         $sum += $value2;
         $resulttypesum = lookup_result_type($tostype2, $resulttypesum || $tostype2, $typelookup->{plus});
         }
      elsif (substr($tostype2,0,1) eq "e" && substr($resulttypesum,0,1) ne "e") {
         $resulttypesum = $tostype2;
         }
      }

   $resulttypesum ||= "n";

   if ($fname eq "SUMIF") {
      push @$operand, {type => $resulttypesum, value => $sum};
      }
   elsif ($fname eq "COUNTIF") {
      push @$operand, {type => "n", value => $count};
      }

   return;

}


# # # # # # # # #
#
# IF(cond,truevalue,falsevalue)
#
# # # # # # # # #

sub if_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;

   my $cond = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
   if (substr($tostype,0,1) ne "n" && substr($tostype,0,1) ne "b") {
      push @$operand, {type => "e#VALUE!", value => 0};
      return;
      }

   pop @$foperand if !$cond;
   push @$operand, $foperand->[@$foperand-1];
   pop @$foperand if $cond;

   return;

}


# # # # # # # # #
#
# DATE(year,month,day)
#
# # # # # # # # #

sub date_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype1, $tostype2, $tostype3);
   my $result = 0;

   my $year = operand_as_number($sheetdata, $foperand, $errortext, \$tostype1);
   my $month = operand_as_number($sheetdata, $foperand, $errortext, \$tostype2);
   my $day = operand_as_number($sheetdata, $foperand, $errortext, \$tostype3);
   my $resulttype = lookup_result_type($tostype1, $tostype2, $typelookup->{twoargnumeric});
   $resulttype = lookup_result_type($resulttype, $tostype3, $typelookup->{twoargnumeric});
   if (substr($resulttype,0,1) eq "n") {
      $result = convert_date_gregorian_to_julian(int($year), int($month), int($day)) - $julian_offset;
      $resulttype = "nd";
      }
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# TIME(hour,minute,second)
#
# # # # # # # # #

sub time_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype1, $tostype2, $tostype3);
   my $result = 0;

   my $hours = operand_as_number($sheetdata, $foperand, $errortext, \$tostype1);
   my $minutes = operand_as_number($sheetdata, $foperand, $errortext, \$tostype2);
   my $seconds = operand_as_number($sheetdata, $foperand, $errortext, \$tostype3);
   my $resulttype = lookup_result_type($tostype1, $tostype2, $typelookup->{twoargnumeric});
   $resulttype = lookup_result_type($resulttype, $tostype3, $typelookup->{twoargnumeric});
   if (substr($resulttype,0,1) eq "n") {
      $result = (($hours * 60 * 60) + ($minutes * 60) + $seconds) / (24*60*60);
      $resulttype = "nt";
      }
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# DAY(date)
# MONTH(date)
# YEAR(date)
# WEEKDAY(date, [type])
#
# # # # # # # # #

sub dmy_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;

   my $datevalue = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});

   if ($resulttype eq "n") {
      my ($yr, $mn, $dy) = convert_date_julian_to_gregorian(int($datevalue+$julian_offset));
      if ($fname eq "DAY") {
         $result = $dy;
         }
      elsif ($fname eq "MONTH") {
         $result = $mn;
         }
      elsif ($fname eq "YEAR") {
         $result = $yr;
         }
      elsif ($fname eq "WEEKDAY") {
         my $dtype = 1;
         if (scalar @$foperand) { # get type
            $dtype = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
            if (substr($tostype,0,1) ne "n" || $dtype < 1 || $dtype > 3) {
               push @$operand, {type => "e#VALUE!", value => 0};
               return;
               }
            if (scalar @$foperand) {
               function_args_error($fname, $operand, $errortext);
               return;
               }
            }
         my $doffset = 6;
         $doffset-- if $dtype > 1;
         $result = int($datevalue+$doffset) % 7 + ($dtype < 3 ? 1 : 0);
         }
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# HOUR(datetime)
# MINUTE(datetime)
# SECOND(datetime)
#
# # # # # # # # #

sub hms_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;

   my $datetimevalue = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});

   if ($resulttype eq "n") {
      my $fraction = $datetimevalue - int($datetimevalue); # fraction of a day
      $fraction *= 24;
      my $hours = int($fraction);
      $fraction -= int($fraction);
      $fraction *= 60;
      my $minutes = int($fraction);
      $fraction -= int($fraction);
      $fraction *= 60;
      my $seconds = int($fraction + ($datetimevalue >= 0 ? 0.5: -0.5));
      if ($fname eq "HOUR") {
         $result = $hours;
         }
      elsif ($fname eq "MINUTE") {
         $result = $minutes;
         }
      elsif ($fname eq "SECOND") {
         $result = $seconds;
         }
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# EXACT(v1,v2)
#
# # # # # # # # #

sub exact_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype, $tostype2);

   my $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
   my $value2 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype2);

   my $result = 0;
   my $resulttype = "nl";

   if (substr($tostype,0,1) eq "t") {
      if (substr($tostype2,0,1) eq "t") {
         $result = $value1 eq $value2 ? 1 : 0;
         }
      elsif (substr($tostype2,0,1) eq "b") {
         $result = len($value1) ? 0 : 1;
         }
      elsif (substr($tostype2,0,1) eq "n") {
         $result = $value1 eq "$value2" ? 1 : 0;
         }
      elsif (substr($tostype2,0,1) eq "e") {
         $result = $value2;
         $resulttype = $tostype2;
         }
      else {
         $result = 0;
         }
      }
   elsif (substr($tostype,0,1) eq "n") {
      if (substr($tostype2,0,1) eq "n") {
         $result = $value1 == $value2 ? 1 : 0;
         }
      elsif (substr($tostype2,0,1) eq "b") {
         $result = 0;
         }
      elsif (substr($tostype2,0,1) eq "t") {
         $result = "$value1" eq $value2 ? 1 : 0;
         }
      elsif (substr($tostype2,0,1) eq "e") {
         $result = $value2;
         $resulttype = $tostype2;
         }
      else {
         $result = 0;
         }
      }
   elsif (substr($tostype,0,1) eq "b") {
      if (substr($tostype2,0,1) eq "t") {
         $result = len($value2) ? 0 : 1;
         }
      elsif (substr($tostype2,0,1) eq "b") {
         $result = 1;
         }
      elsif (substr($tostype2,0,1) eq "n") {
         $result = 0;
         }
      elsif (substr($tostype2,0,1) eq "e") {
         $result = $value2;
         $resulttype = $tostype2;
         }
      else {
         $result = 0;
         }
      }
   elsif (substr($tostype,0,1) eq "e") {
      $result = $value1;
      $resulttype = $tostype;
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# FIND(key,string,[start])
# LEFT(string,[length])
# LEN(string)
# LOWER(string)
# MID(string,start,length)
# PROPER(string)
# REPLACE(string,start,length,new)
# REPT(string,count)
# RIGHT(string,[length])
# SUBSTITUTE(string,old,new,[which])
# TRIM(string)
# UPPER(string)
#
# # # # # # # # #

# arg_list has an array for each function, one entry for each possible arg (up to max).
# Min args are specified in %function_list.
# If array element is 1 then it's a text argument, if it's 0 then it's numeric, if -1 then just get whatever's there
# Text values are manipulated as UTF-8, converting from and back to byte strings

my %arg_list = (
                FIND => [1, 1, 0],
                LEFT => [1, 0],
                LEN => [1],
                LOWER => [1],
                MID => [1, 0, 0],
                PROPER => [1],
                REPLACE => [1, 0, 0, 1],
                REPT => [1, 0],
                RIGHT => [1, 0],
                SUBSTITUTE => [1, 1, 1, 0],
                TRIM => [1],
                UPPER => [1],
               );

sub string_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value, $tostype, @operand_value, @operand_type);

   my $numargs = scalar @$foperand;
   my @argdef = @{$arg_list{$fname}};

   for (my $i=1; $i <= $numargs; $i++) { # go through each arg, get value and type, and check for errors
      if ($i > scalar @argdef) { # too many args
         function_args_error($fname, $operand, $errortext);
         return;
         }
      if ($argdef[$i-1] == 0) {
         $value = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
         }
      elsif ($argdef[$i-1] == 1) {
         $value = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
         utf8::decode($value); # convert UTF-8 stuff to chars, not bytes
         }
      elsif ($argdef[$i-1] == -1) {
         $value = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
         }
      $operand_value[$i] = $value;
      $operand_type[$i] = $tostype;
      if (substr($tostype,0,1) eq "e") {
         push @$operand, {type => $tostype, value => $value};
         }
      }

   my $result = 0;
   my $resulttype = "e#VALUE!";

   if ($fname eq "FIND") {
      my $offset = $operand_type[3] ? $operand_value[3]-1 : 0;
      if ($offset < 0) {
         $result = "Start is before string"; # !! not displayed, so not in WKCStrings
         }
      else {
         $result = index($operand_value[2], $operand_value[1], $offset); # (null string matches first char)
         if ($result >= 0) {
            $result += 1;
            $resulttype = "n";
            }
         else {
            $result = "Not found";
            }
         }
      }
   elsif ($fname eq "LEFT") {
      my $len = $operand_type[2] ? $operand_value[2] : 1;
      if ($len < 0) {
         $result = "Negative length";
         }
      else {
         $result = substr($operand_value[1], 0, $len);
         $resulttype = "t";
         }
      }
   elsif ($fname eq "LEN") {
      $result = length($operand_value[1]);
      $resulttype = "n";
      }
   elsif ($fname eq "LOWER") {
      $result = lc($operand_value[1]);
      $resulttype = "t";
      }
   elsif ($fname eq "MID") {
      my $start = $operand_value[2];
      my $len = $operand_value[3];
      if ($len < 1 || $start < 1) {
         $result = "Bad arguments";
         }
      else {
         $result = substr($operand_value[1], $start-1, $len);
         $resulttype = "t";
         }
      }
   elsif ($fname eq "PROPER") {
      $result = $operand_value[1];
      $result =~ s/(\w+)/\u\L$1/g; # uppercase first character only after breaking into words
      $resulttype = "t";
      }
   elsif ($fname eq "REPLACE") {
      my $start = $operand_value[2];
      my $len = $operand_value[3];
      if ($len < 0 || $start < 1) {
         $result = "Bad arguments";
         }
      else {
         $result = $operand_value[1];
         substr($result, $start-1, $len) = $operand_value[4];
         $resulttype = "t";
         }
      }
   elsif ($fname eq "REPT") {
      my $count = $operand_value[2];
      if ($count < 0) {
         $result = "Negative count";
         }
      else {
         $result = $operand_value[1] x $count;
         $resulttype = "t";
         }
      }
   elsif ($fname eq "RIGHT") {
      my $len = $operand_type[2] ? $operand_value[2] : 1;
      if ($len < 0) {
         $result = "Negative length";
         }
      else {
         $result = substr($operand_value[1], -$len, $len);
         $resulttype = "t";
         }
      }
   elsif ($fname eq "SUBSTITUTE") {
      my $oldtext = $operand_value[2];
      my $newtext = $operand_value[3];
      my $which = $operand_value[4];
      if (!$operand_type[4]) { # no "which" value -- substitute all
         $result = $operand_value[1];
         if (length($oldtext) > 0) {
            $result =~ s/\Q$oldtext\E/$newtext/g;
            }
         $resulttype = "t";
         }
      elsif ($which >= 1) {
         $result = $operand_value[1];
         for (my $i=1; $i <= $which; $i++) {
            if ($i == $which) {
               $result =~ s/\G(.*?)\Q$oldtext\E/$1$newtext/;
               last;
               }
            last unless $result =~ m/\Q$oldtext\E/g;
            }
         $resulttype = "t";
         }
      }
   elsif ($fname eq "TRIM") {
      $result = $operand_value[1];
      $result =~ s/^ *//;
      $result =~ s/ *$//;
      $result =~ s/ +/ /g;
      $resulttype = "t";
      }
   elsif ($fname eq "UPPER") {
      $result = uc($operand_value[1]);
      $resulttype = "t";
      }

   if (substr($resulttype,0,1) eq "t") {
      utf8::encode($result); # convert UTF-8 back to bytes
      }
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# is_functions:
#
# ISBLANK(value)
# ISERR(value)
# ISERROR(value)
# ISLOGICAL(value)
# ISNA(value)
# ISNONTEXT(value)
# ISNUMBER(value)
# ISTEXT(value)
#
# # # # # # # # #

sub is_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;
   my $resulttype = "nl";

   my $value = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);

   if ($fname eq "ISBLANK") {
      $result = $tostype eq "b" ? 1 : 0;
      }
   elsif ($fname eq "ISERR") {
      $result = substr($tostype,0,1) eq "e" ? ($tostype eq "e#N/A" ? 0 : 1) : 0;
      }
   elsif ($fname eq "ISERROR") {
      $result = substr($tostype,0,1) eq "e" ? 1 : 0;
      }
   elsif ($fname eq "ISLOGICAL") {
      $result = $tostype eq "nl" ? 1 : 0;
      }
   elsif ($fname eq "ISNA") {
      $result = $tostype eq "e#N/A" ? 1 : 0;
      }
   elsif ($fname eq "ISNONTEXT") {
      $result = substr($tostype,0,1) eq "t" ? 0 : 1;
      }
   elsif ($fname eq "ISNUMBER") {
      $result = substr($tostype,0,1) eq "n" ? 1 : 0;
      }
   elsif ($fname eq "ISTEXT") {
      $result = substr($tostype,0,1) eq "t" ? 1 : 0;
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# ntv_functions:
#
# N(value)
# T(value)
# VALUE(value)
#
# # # # # # # # #

sub ntv_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;
   my $resulttype = "e#VALUE!";

   my $value = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);

   if (substr($tostype,0,1) eq "e") {
      $resulttype = $tostype;
      }
   elsif ($fname eq "N") {
      $result = substr($tostype,0,1) eq "n" ? $value : 0;
      $resulttype = "n";
      }
   elsif ($fname eq "T") {
      $result = substr($tostype,0,1) eq "t" ? $value : "";
      $resulttype = "t";
      }
   elsif ($fname eq "VALUE") {
      if (substr($tostype,0,1) eq "n" || substr($tostype,0,1) eq "b") {
         $result = $value;
         $resulttype = "n";
         }
      elsif (substr($tostype,0,1) eq "t") {
         my $type;
         $result = determine_value_type($value, \$type);
         if (substr($type,0,1) ne "n") {
            $result = 0;
            $resulttype = "e#VALUE!";
            }
         else {
            $resulttype = "n";
            }
         }
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# math1_function:
#
# ABS(value)
# ACOS(value)
# ASIN(value)
# ATAN(value)
# COS(value)
# DEGREES(value)
# EVEN(value)
# EXP(value)
# FACT(value)
# INT(value)
# LN(value)
# LOG10(value)
# ODD(value)
# RADIANS(value)
# SIN(value)
# TAN(value)
#
# # # # # # # # #

sub math1_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;

   my $value = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});

   if ($resulttype eq "n") {
      if ($fname eq "ABS") {
         $result = $value < 0 ? -$value : $value;
         }
      elsif ($fname eq "ASIN") {
         if ($value >= -1 && $value <= 1) {
            $result = atan2($value, sqrt(1-$value*$value));
            }
         else {
            $resulttype = "e#NUM!";
            }
         }
      elsif ($fname eq "COS") {
         $result = cos($value);
         }
      elsif ($fname eq "ACOS") { # using formulas from Programming Perl rather than Math::Trig (and Math::Complex)
         if ($value >= -1 && $value <= 1) {
            $result = atan2(sqrt(1-$value*$value), $value);
            }
         else {
            $resulttype = "e#NUM!";
            }
         }
      elsif ($fname eq "ATAN") {
         $result = atan2($value,1);
         }
      elsif ($fname eq "EVEN") {
         $result = $value < 0 ? -$value : $value;
         my $extra = $result - int($result);
         if ($extra) {
            $result = int($result + 1) + (($result + 1) % 2);
            }
         else { # integer
            $result = $result + ($result % 2);
            }
         $result = -$result if $value < 0;
         }
      elsif ($fname eq "DEGREES") {
         $result = $value * 180/$PI;
         }
      elsif ($fname eq "EXP") {
         $result = exp($value);
         }
      elsif ($fname eq "FACT") {
         $result = 1;
         $value = int($value);
         for (;$value>0;$value--) {
            $result *= $value;
            }
         }
      elsif ($fname eq "INT") {
         if ($value >= 0) {
            $result = int($value);
            }
         else {
            $result = int($value);
            $result -= 1 if $result != $value; # truncates towards minus infinity
            }
         }
      elsif ($fname eq "LN") {
         if ($value <= 0) {
            function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfunclnarg});
            return 0;
            }
         $result = log($value);
         }
      elsif ($fname eq "LOG10") {
         if ($value <= 0) {
            function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfunclog10arg});
            return 0;
            }
         $result = log($value)/log(10);
         }
      elsif ($fname eq "ODD") {
         $result = $value < 0 ? -$value : $value;
         my $extra = $result - int($result);
         if ($extra) {
            $result = int($result + 1) + (1 - (($result + 1) % 2));
            }
         else { # integer
            $result = $result + (1 - ($result % 2));
            }
         $result = -$result if $value < 0;
         }
      elsif ($fname eq "RADIANS") {
         $result = $value * $PI/180;
         }
      elsif ($fname eq "SIN") {
         $result = sin($value);
         }
      elsif ($fname eq "SQRT") {
         if ($value >= 0) {
            $result = sqrt($value);
            }
         else {
            $resulttype = "e#NUM!";
            }
         }
      elsif ($fname eq "TAN") {
         $result = cos($value);
         if ($result != 0) {
            $result = sin($value)/$result;
            }
         else {
            $resulttype = "e#NUM!";
            }
         }
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# math2_function:
#
# ATAN2(x, y)
# MOD(a, b)
# POWER(a, b)
# TRUNC(value, precision)
#
# # # # # # # # #

sub math2_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype1, $tostype2, $result);

   my $xval = operand_as_number($sheetdata, $foperand, $errortext, \$tostype1);
   my $yval = operand_as_number($sheetdata, $foperand, $errortext, \$tostype2);
   my $resulttype = lookup_result_type($tostype1, $tostype2, $typelookup->{twoargnumeric});
   if ($resulttype eq "n") {
      if ($fname eq "ATAN2") {
         if ($xval==0 && $yval==0) {
            $resulttype = "e#DIV/0!";
            }
         else {
            $result = atan2($yval, $xval);
            }
         }
      elsif ($fname eq "POWER") {
         $result = $xval ** $yval;
         }
      elsif ($fname eq "MOD") { # en.wikipedia.org/wiki/Modulo_operation, etc.
         if ($yval == 0) {
            $resulttype = "e#DIV/0!";
            }
         else {
            my $quotient = $xval/$yval;
            if ($quotient >= 0) {
               $quotient = int($quotient);
               }
            else {
               $quotient = int($quotient) - 1;
               }
            $result = $xval - ($quotient * $yval);
            }
         }
      elsif ($fname eq "TRUNC") {
         my $decimalscale = 1; # cut down to required number of decimal digits
         if ($yval >= 0) {
            $yval = int($yval);
            for (my $i=0; $i<$yval; $i++) {
               $decimalscale *= 10;
               }
            my $scaledvalue = int($xval * $decimalscale);
            $result = $scaledvalue / $decimalscale;
            }
         elsif ($yval < 0) {
            $yval = int(-$yval);
            for (my $i=0; $i<$yval; $i++) {
               $decimalscale *= 10;
               }
            my $scaledvalue = int($xval / $decimalscale);
            $result = $scaledvalue * $decimalscale;
            }
         }
      }
 
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# LOG(value,[base])
#
# # # # # # # # #

sub log_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype, $tostype2, $value2);
   my $result = 0;

   my $value = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});
   if ((scalar @$foperand) == 1) {
      $value2 = operand_as_number($sheetdata, $foperand, $errortext, \$tostype2);
      if (substr($tostype2,0,1) ne "n" || $value2 <= 0) {
         function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfunclogsecondarg});
         return 0;
         }
      }
   elsif ((scalar @$foperand) != 0) {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }
   else {
      $value2 = exp(1);
      }

   if ($resulttype eq "n") {
      if ($value <= 0) {
         function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfunclogfirstarg});
         return 0;
         }
      $result = log($value)/log($value2);
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# ROUND(value,[precision])
#
# # # # # # # # #

sub round_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($tostype, $tostype2, $value2);
   my $result = 0;

   my $value = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});
   if ((scalar @$foperand) == 1) {
      $value2 = operand_as_number($sheetdata, $foperand, $errortext, \$tostype2);
      if (substr($tostype2,0,1) ne "n") {
         function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfuncroundsecondarg});
         return 0;
         }
      }
   elsif ((scalar @$foperand) != 0) {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }
   else {
      $value2 = 0; # if no second arg, assume 0 for simple round
      }

   if ($resulttype eq "n") {
      if ($value2 == 0) {
         $result = int($value + ($value >= 0 ? 0.5 : -0.5));
         }
      elsif ($value2 > 0) {
         my $decimalscale = 1; # cut down to required number of decimal digits
         $value2 = int($value2);
         for (my $i=0; $i<$value2; $i++) {
            $decimalscale *= 10;
            }
         my $scaledvalue = int($value * $decimalscale + ($value >= 0 ? 0.5 : -0.5));
         $result = $scaledvalue / $decimalscale;
         }
      elsif ($value2 < 0) {
         my $decimalscale = 1; # cut down to required number of decimal digits
         $value2 = int(-$value2);
         for (my $i=0; $i<$value2; $i++) {
            $decimalscale *= 10;
            }
         my $scaledvalue = int($value / $decimalscale + ($value >= 0 ? 0.5 : -0.5));
         $result = $scaledvalue * $decimalscale;
         }
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# AND(v1,c1:c2,...)
# OR(v1,c1:c2,...)
#
# # # # # # # # #

sub and_or_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $resulttype);

   my $result;
   if ($fname eq "AND") {
      $result = 1;
      }
   elsif ($fname eq "OR") {
      $result = 0;
      }
   $resulttype = "";
   while (@$foperand) {
      $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype,0,1) eq "n") {
         if ($fname eq "AND") {
            $result = $value1 != 0 ? $result : 0;
            }
         elsif ($fname eq "OR") {
            $result = $value1 != 0 ? 1 : $result;
            }
         $resulttype = lookup_result_type($tostype, $resulttype || "nl", $typelookup->{propagateerror});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttype,0,1) ne "e") {
         $resulttype = $tostype;
         }
      }
   if (length($resulttype) < 1) {
      $resulttype = "e#VALUE!";
      $result = 0;
      }
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# not_function:
#
# NOT(value)
#
# # # # # # # # #

sub not_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;
   my $result = 0;

   my $value = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
   my $resulttype = lookup_result_type($tostype, $tostype, $typelookup->{oneargnumeric});

   if (substr($resulttype,0,1) eq "n") {
      $result = $value != 0 ? 0 : 1; # do the "not" operation
      $resulttype = "nl";
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# CHOOSE(index,value1,value2,...)
#
# # # # # # # # #

sub choose_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $resultvalue, $resulttype);

   my $cindex = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   $cindex = 0 if substr($tostype,0,1) ne "n";
   $cindex = int($cindex);

   my $count = 0;
   while (@$foperand) {
      ($value1, $tostype) = top_of_stack_value_and_type($foperand);
      $count += 1;
      if ($cindex == $count) {
         $resultvalue = $value1;
         $resulttype = $tostype;
         }
      }
   if ($resulttype) { # found something
      push @$operand, {type => $resulttype, value => $resultvalue};
      }
   else {
      push @$operand, {type => "e#VALUE!", value => 0};
      }

   return;

}


# # # # # # # # #
#
# COLUMNS(c1:c2)
# ROWS(c1:c2)
#
# # # # # # # # #

sub columns_rows_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $resultvalue, $resulttype);

   ($value1, $tostype) = top_of_stack_value_and_type($foperand);

   if ($tostype eq "coord") {
      $resultvalue = 1;
      $resulttype = "n";
      }
   elsif ($tostype eq "range") {
      my ($v1, $v2, $sequence) = split(/:/, $value1);
      my ($sheet1, $sheet2);
      ($v1, $sheet1) = split(/!/, $v1);
      ($v2, $sheet2) = split(/!/, $v2);
      my ($c1, $r1) = coord_to_cr($v1);
      my ($c2, $r2) = coord_to_cr($v2);
      ($c2, $c1) = ($c1, $c2) if ($c1 > $c2);
      ($r2, $r1) = ($r1, $r2) if ($r1 > $r2);
      if ($fname eq "COLUMNS") {
         $resultvalue = $c2 - $c1 + 1;
         }
      elsif ($fname eq "ROWS") {
         $resultvalue = $r2 - $r1 + 1;
         }
      $resulttype = "n";
      }
   else {
      $resultvalue = 0;
      $resulttype = "e#VALUE!";
      }

   push @$operand, {type => $resulttype, value => $resultvalue};

   return;

}


# # # # # # # # #
#
# WKCERRCELL()
# FALSE()
# NA()
# NOW()
# PI()
# TODAY()
# TRUE()
#
# # # # # # # # #

sub zeroarg_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $result = 0;
   my $resulttype;

   if ($fname eq "WKCERRCELL") {
      $resulttype = "e#REF!";
      }
   elsif ($fname eq "FALSE") {
      $resulttype = "nl";
      $result = 0;
      }
   elsif ($fname eq "NA") {
      $resulttype = "e#N/A";
      }
   elsif ($fname eq "NOW") {
      my $startval = time();
      my $start_1_1_1970 = 25569; # Day number of 1/1/1970 starting with 1/1/1900 as 1
      my $seconds_in_a_day = 24 * 60 * 60;
      my @tmstr = localtime($startval);
      my $time2 = timegm($tmstr[0], $tmstr[1], $tmstr[2], $tmstr[3], $tmstr[4], $tmstr[5]);
      my $offset = ($time2 - $startval) / (60*60);
      my $nowdays = $start_1_1_1970 + $startval / $seconds_in_a_day + $offset/24;
      $nowdays = $start_1_1_1970 + $time2 / $seconds_in_a_day;
      $resulttype = "ndt";
      $result = $nowdays;
      }
   elsif ($fname eq "PI") {
      $resulttype = "n";
      $result = $PI;
      }
   elsif ($fname eq "TODAY") {
      my $startval = time();
      my $start_1_1_1970 = 25569; # Day number of 1/1/1970 starting with 1/1/1900 as 1
      my $seconds_in_a_day = 24 * 60 * 60;
      my @tmstr = localtime($startval);
      my $time2 = timegm(0, 0, 0, $tmstr[3], $tmstr[4], $tmstr[5]);
      my $offset = ($time2 - $startval) / (60*60);
      my $nowdays = $start_1_1_1970 + $startval / $seconds_in_a_day + $offset/24;
      $nowdays = $start_1_1_1970 + $time2 / $seconds_in_a_day;
      $resulttype = "nd";
      $result = $nowdays;
      }
   elsif ($fname eq "TRUE") {
      $resulttype = "nl";
      $result = 1;
      }

   push @$operand, {type => $resulttype, value => $result};

   return;

}


#
# * * * * * FINANCIAL FUNCTIONS * * * * *
#

# # # # # # # # #
#
# DDB(cost,salvage,lifetime,period,[method])
#
# Depreciation, method defaults to 2 for double-declining balance
# See: http://en.wikipedia.org/wiki/Depreciation
#
# # # # # # # # #

sub ddb_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;

   my $cost = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $salvage = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $lifetime = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   if ($lifetime < 1) {
      function_specific_error($fname, $operand, $errortext, "e#NUM!", $WKCStrings{sheetfuncddblife});
      return 0;
      }
   my $period = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $method = 2;
   if (scalar @$foperand > 0 ) {
      $method = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
      }
   if (scalar @$foperand != 0) {
      function_args_error($fname, $operand, $errortext);
      return 0;
      }

   my $depreciation = 0; # calculated for each period
   my $accumulateddepreciation = 0; # accumulated by adding each period's

   for (my $i=1; $i<=$period && $i<=$lifetime; $i++) { # calculate for each period based on net from previous
      $depreciation = ($cost - $accumulateddepreciation) * ($method / $lifetime);
      if ($cost - $accumulateddepreciation - $depreciation < $salvage) { # don't go lower than salvage value
         $depreciation = $cost - $accumulateddepreciation - $salvage;
         }
      $accumulateddepreciation += $depreciation;
      }

   push @$operand, {type => 'n$', value => $depreciation};

   return;

}


# # # # # # # # #
#
# SLN(cost,salvage,lifetime)
#
# Depreciation for each period by straight-line method
# See: http://en.wikipedia.org/wiki/Depreciation
#
# # # # # # # # #

sub sln_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;

   my $cost = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $salvage = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $lifetime = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   if ($lifetime < 1) {
      function_specific_error($fname, $operand, $errortext, "#NUM!", $WKCStrings{sheetfuncslnlife});
      return 0;
      }

   my $depreciation = ($cost - $salvage) / $lifetime;

   push @$operand, {type => 'n$', value => $depreciation};

   return;

}


# # # # # # # # #
#
# SYD(cost,salvage,lifetime,period)
#
# Depreciation by Sum of Year's Digits method
#
# # # # # # # # #

sub syd_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my $tostype;

   my $cost = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $salvage = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $lifetime = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   my $period = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   if ($lifetime < 1 || $period <= 0) {
      push @$operand, {type => "e#NUM!", value => 0};
      return 0;
      }

   my $sumperiods = (($lifetime + 1) * $lifetime)/2; # add up 1 through lifetime
   my $depreciation = ($cost - $salvage) * ($lifetime - $period + 1) / $sumperiods; # calc depreciation

   push @$operand, {type => 'n$', value => $depreciation};

   return;

}


# # # # # # # # #
#
# FV(rate, n, payment, [pv, [paytype]])
# NPER(rate, payment, pv, [fv, [paytype]])
# PMT(rate, n, pv, [fv, [paytype]])
# PV(rate, n, payment, [fv, [paytype]])
# RATE(n, payment, pv, [fv, [paytype, [guess]]])
#
# Following www.openformula.org and ODF formula specification:
#
#    PV = - Fv - (Payment * Nper) [if rate equals 0]
#    Pv*(1+Rate)^Nper + Payment * (1 + Rate*PaymentType) * ( (1+Rate)^nper -1)/Rate + Fv = 0
#
# For each function, the formulas are solved for the appropriate value (transformed using
# basic algebra).
#
# # # # # # # # #

sub interest_functions {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($aval, $bval, $cval, $dval, $eval, $fval, $atype, $btype, $ctype, $dtype, $etype, $ftype, $result);

   $aval = operand_as_number($sheetdata, $foperand, $errortext, \$atype);
   $bval = operand_as_number($sheetdata, $foperand, $errortext, \$btype);
   $cval = operand_as_number($sheetdata, $foperand, $errortext, \$ctype);
   my $resulttype = lookup_result_type($atype, $btype, $typelookup->{twoargnumeric});
   $resulttype = lookup_result_type($resulttype, $ctype, $typelookup->{twoargnumeric});
   if (scalar @$foperand) { # optional arguments
      $dval = operand_as_number($sheetdata, $foperand, $errortext, \$dtype);
      $resulttype = lookup_result_type($resulttype, $dtype, $typelookup->{twoargnumeric});
      if (scalar @$foperand) { # optional arguments
         $eval = operand_as_number($sheetdata, $foperand, $errortext, \$etype);
         $resulttype = lookup_result_type($resulttype, $etype, $typelookup->{twoargnumeric});
         if (scalar @$foperand) { # optional arguments
            if ($fname ne "RATE") { # only rate has 6 possible args
               function_args_error($fname, $operand, $errortext);
               return 0;
               }
            $fval = operand_as_number($sheetdata, $foperand, $errortext, \$ftype);
            $resulttype = lookup_result_type($resulttype, $ftype, $typelookup->{twoargnumeric});
            }
         }
      }

   my ($pv, $fv, $rate, $n, $payment, $paytype, $guess);

   if ($resulttype eq "n") {
      if ($fname eq "FV") { # FV(rate, n, payment, [pv, [paytype]])
         $rate = $aval;
         $n = $bval;
         $payment = $cval;
         $pv = defined $dval ? $dval : 0;
         $paytype = defined $eval ? ($eval ? 1 : 0) : 0;
         if ($rate == 0) { # simple calculation if no interest
            $fv = -$pv - ($payment * $n);
            }
         else {
            $fv = -($pv*(1+$rate)**$n + $payment * (1 + $rate*$paytype) * ( (1+$rate)**$n -1)/$rate);
            }
         $result = $fv;
         $resulttype = 'n$';
         }
      elsif ($fname eq "NPER") { # NPER(rate, payment, pv, [fv, [paytype]])
         $rate = $aval;
         $payment = $bval;
         $pv = $cval;
         $fv = defined $dval ? $dval : 0;
         $paytype = defined $eval ? ($eval ? 1 : 0) : 0;
         if ($rate == 0) { # simple calculation if no interest
            if ($payment == 0) {
               push @$operand, {type => "e#NUM!", value => 0};
               return;
               }
            $n = ($pv + $fv)/(-$payment);
            }
         else {
            my $part1 = $payment * (1 + $rate * $paytype) / $rate;
            my $part2 = $pv + $part1;
            if ($part2 == 0 || $rate <= -1) {
               push @$operand, {type => "e#NUM!", value => 0};
               return;
               }
            my $part3 = ($part1 - $fv) / $part2;
            if ($part3 <= 0) {
               push @$operand, {type => "e#NUM!", value => 0};
               return;
               }
            my $part4 = log($part3);
            my $part5 = log(1 + $rate); # rate > -1
            $n = $part4/$part5;
            }
         $result = $n;
         $resulttype = 'n';
         }
      elsif ($fname eq "PMT") { # PMT(rate, n, pv, [fv, [paytype]])
         $rate = $aval;
         $n = $bval;
         $pv = $cval;
         $fv = defined $dval ? $dval : 0;
         $paytype = defined $eval ? ($eval ? 1 : 0) : 0;
         if ($n == 0) {
            push @$operand, {type => "e#NUM!", value => 0};
            return;
            }
         elsif ($rate == 0) { # simple calculation if no interest
            $payment = ($fv - $pv)/$n;
            }
         else {
            $payment = (0 - $fv - $pv*(1+$rate)**$n)/((1 + $rate*$paytype) * ( (1+$rate)**$n -1)/$rate);
            }
         $result = $payment;
         $resulttype = 'n$';
         }
      elsif ($fname eq "PV") { # PV(rate, n, payment, [fv, [paytype]])
         $rate = $aval;
         $n = $bval;
         $payment = $cval;
         $fv = defined $dval ? $dval : 0;
         $paytype = defined $eval ? ($eval ? 1 : 0) : 0;
         if ($rate == -1) {
            push @$operand, {type => "e#DIV/0!", value => 0};
            return;
            }
         elsif ($rate == 0) { # simple calculation if no interest
            $pv = -$fv - ($payment * $n);
            }
         else {
            $pv = (-$fv - $payment * (1 + $rate*$paytype) * ( (1+$rate)**$n -1)/$rate)/((1+$rate)**$n);
            }
         $result = $pv;
         $resulttype = 'n$';
         }
      elsif ($fname eq "RATE") { # RATE(n, payment, pv, [fv, [paytype, [guess]]])
         $n = $aval;
         $payment = $bval;
         $pv = $cval;
         $fv = defined $dval ? $dval : 0;
         $paytype = defined $eval ? ($eval ? 1 : 0) : 0;
         $guess = defined $fval ? $fval : 0.1;

         # rate is calculated by repeated approximations
         # The deltas are used to calculate new guesses

         my $olddelta;
         my $maxloop = 100;
         my $tries = 0;
         my $delta = 1;
         my $epsilon = 0.0000001; # this is close enough
         $rate = $guess || 0.00000001; # zero is not allowed
         my $oldrate;
         my $m;
         while (($delta >= 0 ? $delta : -$delta) > $epsilon && ($rate != $oldrate)) {
            $delta = $fv + $pv*(1+$rate)**$n + $payment * (1 + $rate*$paytype) * ( (1+$rate)**$n -1)/$rate;
            if (defined $olddelta) {
               $m = ($delta - $olddelta)/($rate - $oldrate) || .001; # get slope (not zero)
               $oldrate = $rate;
               $rate = $rate - $delta / $m; # look for zero crossing
               $olddelta = $delta;
               }
            else { # first time - no old values
               $oldrate = $rate;
               $rate = 1.1 * $rate;
               $olddelta = $delta;
               }
            $tries++;
            if ($tries >= $maxloop) { # didn't converge yet
               push @$operand, {type => "e#NUM!", value => 0};
               return;
               }
            }
         $result = $rate;
         $resulttype = 'n%';
         }
      }
 
   push @$operand, {type => $resulttype, value => $result};

   return;

}


# # # # # # # # #
#
# NPV(rate,v1,v2,c1:c2,...)
#
# # # # # # # # #

sub npv_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype);

   my $rate = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
   if (substr($tostype,0,1) eq "e") {
      push @$operand, {type => $tostype, value => 0};
      return;
      }

   my $sum = 0;
   my $resulttypenpv = "n";
   my $factor = 1;

   while (@$foperand) {
      $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);

      if (substr($tostype,0,1) eq "n") {
         $factor *= (1 + $rate);
         if ($factor == 0) {
            push @$operand, {type => "e#DIV/0!", value => 0};
            return;
            }
         $sum += $value1 / $factor;
         $resulttypenpv = lookup_result_type($tostype, $resulttypenpv || $tostype, $typelookup->{plus});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttypenpv,0,1) ne "e") {
         $resulttypenpv = $tostype;
         last;
         }
      }

   if (substr($resulttypenpv,0,1) eq "n") {
      $resulttypenpv = 'n$';
      }

   push @$operand, {type => $resulttypenpv, value => $sum};

   return;

}


# # # # # # # # #
#
# IRR(c1:c2,[guess])
#
# # # # # # # # #

sub irr_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype);

   my @rangeoperand;
   push @rangeoperand, pop @$foperand; # first operand is a range

   my @cashflows;
   while (@rangeoperand) { # get values from range so we can do iterative approximations
      $value1 = operand_value_and_type($sheetdata, \@rangeoperand, $errortext, \$tostype);
      if (substr($tostype,0,1) eq "n") {
         push @cashflows, $value1;
         }
      elsif (substr($tostype,0,1) eq "e") {
         push @$operand, {type => "e#VALUE!", value => 0};
         return;
         }
      }

   my $guess = 0;

   if (@$foperand) { # guess is provided
      $guess = operand_as_number($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype,0,1) ne "n" && substr($tostype,0,1) ne "b") {
         push @$operand, {type => "e#VALUE!", value => 0};
         return;
         }
      if (@$foperand) { # should be no more args
         function_args_error($fname, $operand, $errortext);
         return;
         }
      }

   $guess ||= 0.1;

   # rate is calculated by repeated approximations
   # The deltas are used to calculate new guesses

   my $oldsum;
   my $maxloop = 20;
   my $tries = 0;
   my $epsilon = 0.0000001; # this is close enough
   my $rate = $guess;
   my $oldrate;
   my $m;
   my $sum = 1;
   my $factor;

   while (($sum >= 0 ? $sum : -$sum) > $epsilon && ($rate != $oldrate)) {
      $sum = 0;
      $factor = 1;
      for (my $i=0; $i<@cashflows; $i++) {
         $factor *= (1 + $rate);
         if ($factor == 0) {
            push @$operand, {type => "e#DIV/0!", value => 0};
            return;
            }
         $sum += $cashflows[$i] / $factor;
         }

      if (defined $oldsum) {
         $m = ($sum - $oldsum)/($rate - $oldrate); # get slope
         $oldrate = $rate;
         $rate = $rate - $sum / $m; # look for zero crossing
         $oldsum = $sum;
         }
      else { # first time - no old values
         $oldrate = $rate;
         $rate = 1.1 * $rate;
         $oldsum = $sum;
         }
      $tries++;
      if ($tries >= $maxloop) { # didn't converge yet
         push @$operand, {type => "e#NUM!", value => 0};
         return;
         }
      }

   push @$operand, {type => 'n%', value => $rate};

   return;

}


#
# * * * * * WKC FUNCTIONS * * * * *
#

# # # # # # # # #
#
# WKCTEXT
#
# # # # # # # # #

sub wkctext_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $resulttype);

   my $textstr = "";
   $resulttype = "";
   while (@$foperand) {
      $value1 = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype,0,1) eq "t") {
         $textstr .= $value1;
         $resulttype = lookup_result_type($tostype, $resulttype || $tostype, $typelookup->{concat});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttype,0,1) ne "e") {
         $resulttype = $tostype;
         }
      }
   $resulttype = substr($resulttype,0,1) eq "t" ? "t" : $resulttype;
   push @$operand, {type => $resulttype, value => $textstr};

   return;

}


# # # # # # # # #
#
# WKCHTML
#
# # # # # # # # #

sub wkchtml_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $tostype, $resulttype);

   my $textstr = "";
   $resulttype = "";
   while (@$foperand) {
      $value1 = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
      if (substr($tostype,0,1) eq "t") {
         $textstr .= $value1;
         $resulttype = lookup_result_type($tostype, $resulttype || $tostype, $typelookup->{concat});
         }
      elsif (substr($tostype,0,1) eq "e" && substr($resulttype,0,1) ne "e") {
         $resulttype = $tostype;
         }
      }
   $resulttype = substr($resulttype,0,1) eq "t" ? "th" : $resulttype;
   push @$operand, {type => $resulttype, value => $textstr};

   return;

}


# # # # # # # # #
#
# WKCHTTP
#
# # # # # # # # #

sub wkchttp_function {

   my ($fname, $operand, $foperand, $errortext, $typelookup, $sheetdata) = @_;

   my ($value1, $value2, $tostype, $resulttype);

   my $requesturl = operand_as_text($sheetdata, $foperand, $errortext, \$tostype);
   my $timeout = (scalar @$foperand ? operand_as_number($sheetdata, $foperand, $errortext, \$tostype) : 0) || 10;
   my ($errorvalue, $errorvaluetype);
   $errorvalue = operand_value_and_type($sheetdata, $foperand, $errortext, \$errorvaluetype);
   $errorvaluetype ||= "t";
   my $requestmethod = scalar @$foperand ? uc operand_as_text($sheetdata, $foperand, $errortext, \$tostype) : "GET";
   if ($requestmethod ne "GET" && $requestmethod ne "POST") {
      $requestmethod = "GET";
      }
   my $paramstr;
   my %tostochar = (n => "N", t => "T", b => "B", "e" => "E");
   my %chartotos = (N => "n", T => "t", H => "th", E => "ewkcHTTP $WKCStrings{sheetfuncwkchttperr}");
   my $pcount = 0;
   my $separator;
   while (scalar @$foperand) { # output args
      $value1 = operand_value_and_type($sheetdata, $foperand, $errortext, \$tostype);
      $tostype = $tostochar{substr($tostype,0,1)} || "T";
      $pcount++;
      $paramstr .= $separator . "V$pcount=" . $tostype . url_encode_plain($value1);
      $separator = "&";
      }
   if ($requestmethod eq "GET") {
      $requesturl .= "?$paramstr";
      $paramstr = "";
      }
   my $ua = LWP::UserAgent->new; 
   $ua->agent("wikiCalc WKCHTTP function");
   $ua->timeout($timeout);
   my $req = HTTP::Request->new($requestmethod, $requesturl);
   $req->header('Accept' => '*/*');
   $req->content($paramstr);
   my $res = $ua->request($req);
   if ($res->is_success) {
      $value2 = $res->content;
      $value2 =~ s/\r|\n//g;
      push @$operand, {type => ($chartotos{substr($value2,0,1)} || "t"), value => substr($value2,1)};
      }
   else {
      push @$operand, {type => $errorvaluetype, value => $errorvalue};
      }

   return;

}
