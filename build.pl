#!/usr/bin/perl -w
# Build the Unified Strong's Dictionaries XML
# by Weston Ruter
# License: GPL 3.0 <http://www.gnu.org/licenses/gpl.html>

# @todo We need to convert the transliteration into Unicode Hebrew text (use lookup table at http://home.comcast.net/~rciampa/Translit.htm)


use strict;
use warnings;
use utf8;
use Data::Dumper;
use open ':encoding(utf8)';
use XML::LibXML;

my $parser = XML::LibXML->new();
my $greekXML = $parser->parse_file( "StrongsGreekDictionaryXML_1.4/strongsgreek.xml" );

#require('../../conn.pl') if not defined($dbh);

my %entries = ();

if($ARGV[0] && ($ARGV[0] eq '--correct' || $ARGV[0] eq '-c')){
	print "Patches are furthermore submitted manually";
	#require 'correct.pl';	
}
#generate diffs

my $hebrew = 'hbo';
my $greek = 'grc';
my $aramaic = 'oar';


#First pass over the data to gather all of the segments of information
open HE, "<:encoding(Latin-1)", "./strongshebrew.dat"
   or die "Unable to load Hebrew";
open GR, "<:encoding(utf8)", "./strongsgreek.dat"
   or die "Unable to load Greek";

print "Parsing Hebrew data...";
parseStrongsFile(*HE, 'ot');
print "done\n";
print "Parsing Greek data...";
parseStrongsFile(*GR, 'nt');
print "done\n";
close HE;
close GR;

my @otNumbers;
my @ntNumbers;

sub parseStrongsFile {
	local *FILE = shift;
	my $lang;
	my $volume = shift;
	if($volume eq 'nt'){
		$lang = $greek;
	}
	else {
		$lang = $hebrew;
	}
	my $lineNum = 0;
	my $count = 0;

	my $token = "[^ ,](?:[^ ,;]| (?=\\S))*";
	while(<FILE>){
		if(/^\\(\d+)/){
			$_ = <FILE>;
			&myChomp;
			my $strongs = int $1;
			
			#Skip if not used
			next if(/^ $strongs\s+Not\s+Used/);
			
			die "$volume:$strongs: Expected first line to begin with strongs number" if !s{^ $strongs\b}{};
			
			my $definition = '';
			my $kjv_def;
			my $lemma_count = 0;
			
			my %see = ();
			
			#while(/^\s+((?:\S+| (?=\S))+)\s\s+((?:\S+| (?=\S))+)(.*)/){
			#print "\n\n$strongs:\n";
			#while(($_ || !eof(FILE)) && !/^\$\$/ && !/^ see [A-Z]+\s/){
			while($_){	#&& !/^\$\$/ && !/^ see [A-Z]+\s/
				
				#s#($token)  +($token)(?=\s*,|\s*$|  )#\[span xml:lang="$lang" title="$2"\]$1\[/span\]#;
				s/^( *(?:or\b|and\b)? *)(?!also dative)($token)  +($token)(?=\s*[;,]|\s*$|  )/$1$2  {$3}/;
				
				$definition .= $_;
				
				$lemma_count++;
				$_ = <FILE>;
				&myChomp;
			}
			
			$_ = <FILE>;
			&myChomp;
			#print "$_\n";
			#if(/^\s+\(Aramaic\)/){
			#	$definition =~ s/(?<=xml:lang=")$lang(?=")/$aramaic/;
			#	#$lang = $aramaic;
			#}
			#else {
			#	$definition =~ s/(?<=xml:lang=")$lang(?=")/$lang/;
			#}
			
			#my $strongsDefinition = "";
			
			#Get descriptions
			while(($_ || !eof(FILE)) && !/^\$\$/ && !/^ see [A-Z]+\s/){
				&myChomp if $_;
				
				#Parse out pronunciations (note that a verse reference may intersperse)
				#s#($token)  +($token)(?=\s*,|\s*$)#\[span xml:lang="$lang" title="$2"\]$1\[/span\]#;
				#(?<=or|and\s+)($token)(\s*\(.+?\))?\s*{([^}]+)}
				# --> $2[span title="$3"]$1[/span]
				
				#s{(?<=\b(?:and|or)\s+)}{};
				
				##Note that $lang needs to ne sniffed from the context
				#s`
				#  ( #what we know to precedes
				#      \b(?:[Aa]nd|[Oo]r)\b(?:\s+shorter)?
				#	  |
				#	  \bby\s+Aramaic
				#	  |
				#	  the\s+text\s+is
				#  )
				#  ((?:\s+(?:\(.+?\))?)*)   #parenthetical note(s)
				#  (\S[^{]+?)               #transliteration
				#  ((?:\s+(?:\(.+?\))?)*)   #parenthetical note(s)
				#  {([^{]+)}                #pronunciation
				#  ((?:\s+(?:\(.+?\))?)*)   #parenthetical note(s)
				# `
				#	qq^$1$2\[span title="$5" xml:lang="^ . (index($1.$2.$4.$6, 'Aramaic') != -1 ? $aramaic : $hebrew) . qq^"]$3\[/span\]$4$6^
				# `gex;
				#s{\s+(?=[,;\.])}{}g; #don't let punctuation appear after a space (remove the space)
				
				
				$definition .= $_;
				$_ = <FILE>;
			}
			
			#$definition .= ' [span class="strongs_def"]' . trim($strongsDefinition) . '[/span]';
			#$definition .= ' ' . trim($strongsDefinition);
			
			
			#Note that $lang needs to ne sniffed from the context
			$definition =~ s`
			  ( #what we know to precedes
			      ^\s+
				  |
				  \((?=\w+ \s+ {)
				  |
				  (?:
				    \s\s\s\s+
					|
					\b(?:[Aa]nd|[Oo]r)\b
						(?:
						\s+	short(?:er | ed | ened)
						|
						\s+ prolonged
						|
						\s+ rather \s+ \(by \s+ permutation\)
						|
						\s+ genitival \s+ form \s+ of
						|
						\s+ by \s+ permutation
						|
						\s+ (?: rather | variation | even | simpler)
						|
						\s+ genitive \s+ case
					)?
					|
					\bis\s+(?=ham-)
					|
					\bfrom (?=\s+ \w+ \s+ {)
					|
					prolongation (?: \s+ from \s+ a \s+ still \s+ simpler )? | contracted | obsolete
					|
					\bby\s+(?: Aramaic | transposition)\b
					|
					voice \s+ of (?=\s+otheo)
					|
					defect\. (?:\s+ transcription)? | written
					|
					\)
					|
					for\b (?: \s+ the \s+ textual \s+ reading, | \s+ a \s+ primary )?
					|
					[Aa]lso | thus
					|
					forms? (?! \s+ of \s+ a ) | tenses | vowel
					|
					be \s+ pointed
					|
					rarely | simply | usually | perhaps | erroneously | primary
					|
					probably\s+rather
					|
					masculine (?:\s+ as \s+ if \s+ from )? | feminine | plural (?! \s+ of\b) | comparative | singular | neuter | sometimes | contracted
					|
					accusative \s+ case
					|
					single \s+ word
					|
					the\s+text\s+is
					|
					fully\);
					|
					is:
			      )
				  (?! \s+ (?: perhaps | nominative | singular | plural | or \s+ feminine | the | accusative | \w+ \s+ tenses | which | and | \d+ | dative)\b )
				  \s+
			  )
			  ( (?: \([^{;]+?\) \s+ )* )    #parenthetical note(s)
			  ( (?: (?:
						simply
						|
						by \s+ transposition
						|
						(?<= \)\s ) is
						|
						feminine
						|
						of \s+ an \s+ unused \s+ noun
						|
						of (?:\s+term)? | which
						|
						a \s+ prolonged
						|
						form
						|
						prolongation | contracted | neuter
						|
						noun
					) \s+ )* )
			  (?! (?:feminine | \s*, | masculine | sometimes | rather | but | for \s+ which | prolonged | form | the | of\s+the | irregular | neuter | including | five | of \s+ five \s+ places | (?:of\s+)? a \s+ derivative | or | also)\b)
			  ([^, \(][^{;]*? )                 #transliteration
			  ( \s+ (?: (?:\([^{]+?\))? \s+ )* )   #parenthetical note(s)
			  ({[^{]+}  #pronunciation
				 (?:\s+ (?: sometimes | or ) \s+ {[^{;]+})?  #with alternates
			  )
			  ( (?: \s+ (?:\([^{]+?\))? )* )   #parenthetical note(s)
			 `
			    markUpWord($volume, $strongs, $lang, "$1$2$3", $4, $6, "$5$7")
				#qq^$1$2$3\[i title="$6" xml:lang="^ . (index($1.$2.$5.$7, 'Aramaic') != -1 ? $aramaic : $lang) . qq^"]$4\[/i\]$5$7^
			 `gexs;
			
			
			
			
			$definition =~ s{\s+(?=[,;\.\)])}{}gs; #don't let punctuation appear after a space (remove the space)
			
			
			
			
			
			my %codeLanguageLookup = ();
				
			#Get cross references (store in hash so that duplicates are removed)
			while(($_ || !eof(FILE)) && !/^\$\$/ && /^ see ([A-Z]+)\s+for\s+(\d+)([a-z0-9]*)/i){ #!eof(FILE)
				my $code = int $2;
				
				if($code){
					if($1 eq 'HEBREW'){
						$see{"ot:$code"} = 1;
						$codeLanguageLookup{$code} = 'ot';
					}
					elsif($1 eq 'GREEK'){
						$see{"nt:$code"} = 1;
						$codeLanguageLookup{$code} = 'nt';
					}
					else {
						die "Unexpected language $1";
					}
				}
				else {
					warn "Skipping bad strongs number in $volume:$strongs: see $1 for $2$3\n";
				}
				
				#push @see, [$1, int $2];
				$_ = <FILE>;
				&myChomp if $_;
			}
			
			#Add cross references that appear in the definition to %see
			foreach($definition =~ m{\b0*(\d\d\d\d+)\b}g){
				my $code = int $_;
				
				#If the language was already given for this coe in the @see section, then use it
				if(exists $codeLanguageLookup{$code}){
					$see{$codeLanguageLookup{$code} . ":$code"} = 1;
				}
				else {
					#warn "$strongs with $code\n";
					#my $lang = $lang;
					
					#Every item should have a lookup code
					#foreach($definition =~ /(Greek|Hebrew)/ig){
					#	if(lc $_ eq 'greek'){
					#		$lang = $greek;
					#	}
					#	else {
					#		$lang = $hebrew;
					#	}
					#}
					
					#Otherwise infer from the current language
					$see{"$volume:$code"} = 1;
				}
			}
			
			#Mark up the king james defs for parsing later; replace the :--(\.+). with a link <a href="db://lemma_definition[@id=333]"><xi:include href="db://lemma_definition@definition[@id=333]" parse="text"></a> (this FK may return multiple texts of which one should be chosen)
			$definition =~ s{(?<=:)\s*--(.+?)(?=\.)}
							{ \[span class="kjv_def"\]$1\[/span\]};
			#$kjv_def = $1;
			
			if(exists $entries{"$volume:$strongs"}){
				die "$volume:$strongs exists\n";
			}
			
			if($lang eq $hebrew){
				push @otNumbers, $strongs;
			}
			else {
				push @ntNumbers, $strongs;
			}
			$definition = trim($definition);
			
			
			#Mark up other languages
			$definition =~ s{(?<=\bLatin )(?!origin|derivation)("?)(\w+)}
			                {$1\[i xml:lang="lat"\]$2\[/i\]};
			$definition =~ s{\b(terminus ad quem)\b}{\[i xml:lang="lat"\]$1\[/i\]};
			if($strongs == 787){
				$definition =~ s{(assarius)}{\[i xml:lang="lat"\]$1\[/i\]};
				$definition =~ s{(\bas(?=,))}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			if($strongs == 5415){
				$definition =~ s{(Fortunatus)}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			if($strongs == 675){
				$definition =~ s{(Appius)}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			if($strongs == 828){
				$definition =~ s{(Augustus)}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			if($strongs == 1050){
				$definition =~ s{(Gaius)}{\[i xml:lang="lat"\]$1\[/i\]};
				$definition =~ s{(Caius)}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			if($strongs == 1058){
				$definition =~ s{(Gallio\b)}{\[i xml:lang="lat"\]$1\[/i\]};
			}
			
			#Get the first lemma (used when other entries link here); note: should we just use <A> or should we use <I> too?
			die "Couldn't get first in $definition" if $definition !~ m{(\[i\b.+?\].+?\[/i\])};
			
			my $revLink = "[a href='#$volume:$strongs']" . $1 . "[/a]";
			die "No revlink " if !$revLink;
			#$revLink =~ s{(?<=\[)span}{a href="#$volume:$strongs"};
			#$revLink =~ s{span(?=\])}{a};
			
			warn "Didn't stop on time in $volume:$strongs\n" if $definition =~ /\$\$T/;
			
			$entries{"$volume:$strongs"} = {
				revlink           => $revLink,
				volume            => $volume,
				language          => $lang,
				strongs           => $strongs,
				definition        => $definition,
				#kjv_def           => $kjv_def,
				see               => [keys %see],
				lemma_count       => $lemma_count
			};
			
			#if($strongs == 5083){
			#	print Dumper($entries{"$lang:$strongs"});
			#}
			#print "$strongs: $translit\n";
		}
	}
	
	#print "Total $lang: $count\n";
}

#open F, ">strongsDump.txt";
#print F Dumper({%entries});
#close F;

sub markUpWord {
	my $volume = shift;
	my $strongs = shift;
	my $lang = shift;
	my $before = shift;
	my $word = shift;
	my $transliteration = shift;
	my $after = shift;
	
	my $betacode;
	#look up the word in the XML file to get the best values
	if($volume eq 'nt'){
		
		
		
	}
	
	#my $lang = shift;
	
	my $html = $before;
	$html .= '[i';
	$html .= ' title="' . $transliteration . '"';
	$html .= ' xml:lang="' . (index($before.$after, 'Aramaic') != -1 ? $aramaic : $lang) . '"';
	$html .= ' data-betacode="' . $betacode . '"' if $betacode;
	$html .= ']';
	$html .= $word;
	$html .= '[/i]';
	$html .= $after;
	
	return $html;
}
			
#The strongs "see" cross-references are only internal (none go out to Greek); however, in the Greek, it will be important to
# detect whether a number is Hebrew or Greek by looking at the @see area

#For strongsrefs we should replace the NUMBER with a link <a href="db://lemma[@id=333]"><xi:include href="db://lemma@data[@id=333]" parse="text"></a>


open OUT, ">:encoding(utf8)", "strongs-dictionary.xhtml";
print OUT <<XHTMLCODE;
<?xml version="1.0" encoding="utf-8"?>
<!--
Unified Strong's Dictionaries of Greek and Hebrew in XML
Copyright (c) 2008, Open Scriptures <http://openscriptures.org/>.
Freely released under GPL 3.0 license <http://www.gnu.org/licenses/gpl.html>
This work is a derivative of the following:
 - http://open-scriptures.googlecode.com/svn/trunk/sources/strongs-dictionaries/strongsgreek.dat
 - http://open-scriptures.googlecode.com/svn/trunk/sources/strongs-dictionaries/strongshebrew.dat
 - http://files.morphgnt.org/strongs-dictionary/StrongsGreekDictionaryXML_1.4.zip
\$Id\$
-->
<!DOCTYPE html><!-- XHTML5 -->
<html dir="ltr" xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>Unified Strong's Dictionaries of Hebrew and Greek in XML (alpha release)</title>
	<style type="text/css">
	/*
	li::before {
		-moz-user-select:text;
	}*/
	:lang(hbo) {
		background-color:LightYellow;
		/*direction: rtl;*/
	}
	:lang(oar) {
		background-color:LavenderBlush;
		/*direction: rtl;*/
	}
	:lang(grc) {
		background-color:Honeydew;
	}
	:lang(lat) {
		background-color:Azure;
	}
	a i{
		text-decoration:underline;
	}
	li a {
		color:black;
	}
	li {
		margin-bottom:.25em;
	}
	li:target {
		padding:5px;
		background-color:#eee;
		border:solid 1px #DDD;
	}
	</style>
</head>
<body>
	<h1>Unified Strong's Dictionaries of <a href="#ot">Hebrew</a> and <a href="#nt">Greek</a> in XML (<em>alpha release</em>)</h1>
	
	
XHTMLCODE

print "Outputting Hebrew entries...";
print OUT "\t<section id='ot'>\n";
print OUT  "\t\t<h2>Hebrew</h2>\n";
processEntries('ot', @otNumbers);
print OUT  "\t</section>\n";
print "done\n";

print OUT "\t<section id='nt'>\n";
print OUT "\t\t<h2>Greek</h2>\n";
print "Outputting Greek entries...";
processEntries('nt', @ntNumbers);
print OUT  "\t</section>\n";
print "done\n";


sub processEntries {
	my $volume = shift;
	my $lang = $volume eq 'nt' ? $greek : $hebrew;
	
	print OUT "\t\t<ol>\n";
	foreach(@_){
		#next if $entries{"$volume:$_"}->{lemma_count} <= 1;
		#next if $entries{"$volume:$_"}->{lemma_count} <= 1 && $_ != 3801 && $_ != 3808 && $_ != 3809 && $_ != 3810 && $_ != 726; #$entries{"$volume:$_"}->{definition} =~ /Aramaic/; #temp
		#next if $_ > 2000 || $_ < 1000;
		#next if $_ > 3000 || $_ < 2000;
		#next if $_ > 4000 || $_ < 3000;
		#next if $_ > 5000 || $_ < 4000;
		#next if $_ > 6000 || $_ < 5000;
		#next if $_ < 6000;
		
		print OUT "\t\t\t<li value='$_' id='$volume:$_'>";
		
		my $definition = htmlspecialchars($entries{"$volume:$_"}->{definition});
		
		#Replace numbers in the definition with links
		my @alsoSee = ();
		foreach my $see(@{$entries{"$volume:$_"}->{see}}){
			$see =~ /(ot|nt):(\d+)/;
			my $num = $2;
			#my $link = "<a href=\"#$see\" title='" . ($1 eq $hebrew ? 'Hebrew' : 'Greek') . " $2'>" . $entries{$see}->{transliteration} . "</a>";
			#my $link = "<a href=\"#$see\" title='" . ($1 eq 'ot' ? 'OT' : 'NT') . " $2'>" . $see . "</a>";
			my $link = $entries{$see}->{revlink};
			if(!$link){
				die "No revlink in $see exists\n" . Dumper($entries{$see});
			}
			if($definition !~ s{\b0*$num\b}{$link}g){
				die "See also in $_: can't find $see in: $definition";
			}
		}
		$definition =~ s{\[(a|i|span)\b([^\]]*)\]}{<$1$2>}g;
		$definition =~ s{\[/(a|i|span)\]}{</$1>}g;
		
		#Do something with pronunciations
		
		print OUT $definition;
		
		#print OUT "\t\t\t<p>$definition</p>";
		#if(@{$entries{"$volume:$_"}->{see}}){
		#	print OUT "See: <ul class='see'>";
		#	foreach my $see(@{$entries{"$volume:$_"}->{see}}){
		#		print OUT "<li><a href='#$see' title=\"" . ($see =~ /^$hebrew:/ ? "Hebrew" : "Greek") . $entries{$see}->{strongs} . "\">" . htmlspecialchars($entries{$see}->{transliteration}) . "</a></li>";
		#	}
		#	print OUT "</ul>";
		#}
		print OUT "</li>\n";
	}
	print OUT "\t\t</ol>\n";
}






#Iterate over all of the entries again, but this time:
#  - parse the derivation
#  - replace numbers with hyperlinked values (pseudo bbCode)
#  - verify that the SEE ALSO links are 
my $count = 0;
foreach my $key ( keys %entries){
	#Make sure that @see contains all of the references made to other words (if a reference points to a word that doesn't exist, then die)
	#Ensure that all of the @see references are valid
	
	foreach(@{$entries{$key}->{see}}){
		die "$_ doesn't exist in entry $key" if(!exists($entries{$_}));
	}
}


print OUT "\t<hr />";
print OUT "\t<address>Copyright © 2008, <a href='http://openscriptures.org/'>Open Scriptures</a>. <a href='http://www.gnu.org/licenses/gpl.html'>GPL 3.0 License</a>.</address>\n";
print OUT "</body>\n";
print OUT "</html>\n";
close OUT;



no warnings;
\%entries; #return results for processing



#my $sthInsertLemma = $dbh->prepare("INSERT INTO lemma (value) VALUES(?)");
#my $sthInsertIdentifier = $dbh->prepare("INSERT INTO lemma_identifier (source, lemma, identifier) VALUES(?, ?, ?)");
#my $sthInsertDefinition = $dbh->prepare("INSERT INTO lemma_definition (source, lemma, definition, language) VALUES(?, ?, ?, ?)");
#my $sthInsertLink = $dbh->prepare("INSERT INTO lemma_link (source, lemma1, lemma2) VALUES(?, ?, ?)");
#my $sthInsertParsing = $dbh->prepare("INSERT INTO lemma_parsing (source, lemma, parsing, language) VALUES(?, ?, ?)");

# SELECT lemma FROM lemma_identifier WHERE source = $sourceId AND identifier = ? LIMIT 0, 1

#my $sthSelectLemmaId = $dbh->prepare("SELECT lemma FROM lemma_identifier WHERE source = $sourceId AND identifier = ?");

#
#$hebrewId

#my $count = 0;


=old
foreach(values(%entries)){
	$sthInsertLemma->execute($_->{translit});
	my $lemmaId = $dbh->last_insert_id(undef, undef, 'lemma', 'id');
	$_->{lemmaId} = $lemmaId;
	
	$sthInsertIdentifier->execute($sourceId, $lemmaId, $_->{strongs});
	$sthInsertDefinition->execute($sourceId, $lemmaId, $_->{definition}, 'en');
	#$sthInsertParsing->execute($sourceId, $lemmaId, $_->{parsing});
	
	#last if $count++ == 10;
}

foreach(values(%entries)){
	
	
	foreach my $see(@{$_->{see}}){
		if($see->[0] eq 'HEBREW'){
			#print $_->{lemmaId} . "\n";
			#print $entries{$see->[1]}->{lemmaId} . "\n";
			#print $entries{$see->[1]}->{lemmaId} . "--\n";
			$sthInsertLink->execute($sourceId, $_->{lemmaId}, $entries{$see->[1]}->{lemmaId});
		}
		else {
			die "Expected hebrew see";
		}
	}
	
	#last if $count++ == 20;
}
=cut

sub trim {
	$_[0] =~ s{^\s+}{};
	$_[0] =~ s{\s+$}{};
	$_[0] =~ s{\s+}{ }g;
	return $_[0];
}

sub htmlspecialchars {
	my $str = shift;
	$str =~ s{&}{&amp;}g;
	$str =~ s{<}{&lt;}g;
	$str =~ s{>}{&gt;}g;
	return $str;
	
}

sub myChomp {
	s{\r?\n$}{};
}