
use strict;
use warnings;
use utf8;
use open ':encoding(utf8)';
use Algorithm::Diff;
use Unicode::Normalize qw(decompose NFC);
use Data::Dumper;
use JSON;
use XML::LibXML;

open OUT, ">strongs-greek-dictionary.js";
print OUT <<HEAD;
/**
 *                      Dictionary of Greek Words
 *                              taken from
 *                    Strong's Exhaustive Concordance
 *                                   by
 *                      James Strong, S.T.D., LL.D.
 *                                  1890
 * 
 * JSON version
 * ============
 * Copyright 2009, Open Scriptures. CC-BY-SA. Derived from XML.
 * \$Id\$
 *
 * XML e-text version
 * ==================
 * 
 * The XML version of this work was prepared in 2006 by Ulrik Petersen
 * (http://ulrikp.org) from the ASCII e-text version presented below.
 * The XML version contains "real" UTF-8 Greek where the original ASCII
 * e-text version had transliteration.  The XML has a stand-alone DTD
 * which should be easy to follow.
 * 
 * Ulrik Petersen welcomes bugfixes to the text.  Please send them to the
 * address provided on the website:
 * 
 * http://ulrikp.org
 * 
 * Ulrik Petersen
 */

HEAD

#my $svnId = '$Id: StrongsGreekDictionaryXML-to-JSON.pl 91 2009-01-30 07:29:25Z WestonRuter@gmail.com $';

#Get the KJV definitions for all of the strongs numbers

#print "Gathering KJV definitions for Strong's numbers\n";
my %strongsGreekDict = ();
my $parser = XML::LibXML->new();
my $strongsGreekDoc = $parser->parse_file( "StrongsGreekDictionaryXML_1.4/strongsgreek.xml" );
my @entries = $strongsGreekDoc->findnodes('//entry');

foreach my $entry (@entries){
	my ($el,$value);
	my $def = {};
	my $greek = $entry->findnodes('./greek')->item(0) or next;
	
	$def->{lemma} = $greek->getAttribute('unicode');
	$strongsGreekDict{'G' . int $entry->getAttribute('strongs')} = $def;
}


foreach my $entry (@entries){
	my ($el,$value);
	my $def = {};
	my $greek = $entry->findnodes('./greek')->item(0) or next;
	my $strongs = 'G' . (int $entry->getAttribute('strongs'));
	
	#$def->{lemma} = $greek->getAttribute('unicode');
	#Replace strongsref with Strong's number
	#my $strongsrefs = $entry->findnodes('.//strongsref');
	foreach($entry->findnodes('.//strongsref')){
		if($_->getAttribute('language') ne 'GREEK'){
			$_->replaceNode($strongsGreekDoc->createTextNode('H' . $_->getAttribute('strongs')));
		}
		else {
			my $root_strongs = 'G' . (int $_->getAttribute('strongs'));
			my $root_lemma = '';
			if ( $strongsGreekDict{$root_strongs} ) {
				$root_lemma = ' (' . $strongsGreekDict{$root_strongs}->{lemma} . ')';
			}
			$_->replaceNode($strongsGreekDoc->createTextNode( $root_strongs . $root_lemma ));
		}
		
		
	}

	if($el = $entry->findnodes('./greek')->item(0)){
		my $value = $el->getAttribute('translit');
		$value =~ s{\s+}{ }g;
		$strongsGreekDict{$strongs}->{translit} = $value;
	}

	if($el = $entry->findnodes('./kjv_def')->item(0)){
		my $value = $el->textContent;
		$value =~ s{\s+}{ }g;
		$value =~ s/\.$//;
		$value =~ s/^:--//;
		$strongsGreekDict{$strongs}->{kjv_def} = $value;
	}
	
	if($el = $entry->findnodes('./strongs_def')->item(0)){
		my $value = $el->textContent;
		$value =~ s{\s+}{ }g;
		#$kjv_def =~ s{\s+}{ }g;
		#$kjv_def =~ s/\.$//;
		#$kjv_def =~ s/^:--//;
		$strongsGreekDict{$strongs}->{strongs_def} = $value;
	}
	
	if($el = $entry->findnodes('./strongs_derivation')->item(0)){
		my $value = $el->textContent;
		$value =~ s{\s+}{ }g;
		#$kjv_def =~ s{\s+}{ }g;
		#$kjv_def =~ s/\.$//;
		#$kjv_def =~ s/^:--//;
		$strongsGreekDict{$strongs}->{derivation} = $value;
	}
	
	
	#$strongsGreekDict{int $entry->getAttribute('strongs')} = $def;
}


my $json = NFC to_json(\%strongsGreekDict);
$json =~ s/(?<=\},)/\n/g;
print OUT "var strongsGreekDictionary = $json; module.exports = strongsGreekDictionary;";
close OUT;

#use File::Copy;
#copy('strongs-greek-dictionary.js', '../../web/prototypes/manuscript-comparator/strongs-greek-dictionary.js');