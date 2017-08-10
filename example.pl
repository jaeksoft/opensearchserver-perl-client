#!/opt/local/bin/perl
#
#  This file is part of OpenSearchServer PERL Client.
#
#  Copyright (C) 2013 Emmanuel Keller / Jaeksoft
#
#  http://www.open-search-server.com
#
#  OpenSearchServer PERL Client is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  OpenSearchServer PERL Client is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with OpenSearchServer PERL Client.  If not, see <http://www.gnu.org/licenses/>.
# 

use Data::Dumper;
use OpenSearchServer;

# The URL to your OpenSearchServer instance: http://localhost:8080
$oss_url = $ENV{'OSS_URL'};

# The (optional) login used to connect to the API
$oss_login = $ENV{'OSS_LOGIN'};

# The (optional) api key used to connect to the API
$oss_key = $ENV{'OSS_KEY'};

# The name of the index
$oss_index = $ENV{'OSS_INDEX'};

# The name of the query template
$template = 'search';

# The searched keywords
$keywords = 'test';

# The position of the first result
$start = 0;

# The number of rows
$rows = 10;

# The Lang of the keywords
$lang = 'FRENCH';

# An array defining the sort order (optional)
@sort = ('-score', '+lang');

# An array of sub query filters
@filter = ('author:bruno');

print 'CALL: '.$oss_url."\n";

my $result = search_pattern($oss_url, $oss_login, $oss_key, $oss_index, $template, $keywords, $start, $rows, $lang, \@sort, \@filter);

#Get the number of document found
my $found = search_num_found($result);
my $highest_score = search_max_score($result);
print 'NUM FOUND: '.$found.' - Highest score: '.$highest_score."\n";

#Get the number of documents returned
my $doc_returned = search_documents_returned($result);
print 'DOCUMENTS RETURNED: '.$doc_returned."\n";

# Loop over the returned document
for (my $i = 0; $i < $doc_returned; $i++) {
	# Get the field 
	my $id = search_document_field($result, $i, 'product_id');
	my $name = search_document_snippet($result, $i, 'name');
	my $score = search_document_score($result, $i);
	my $parution_dates = search_document_field_values($result, $i, 'parution_date');
	my $wrong_field = search_document_field($result, $i, 'wrong_field');
	print 'Document #'.$i.' - id: '.$id.' - name: '.$name.' - Date: '.$parution_dates->[0].' - score: '.$score."\n";
}

# Retrieve the number of terms for a facet
my $facet_number = search_get_facet_number($result, 'parution_date_year');
print 'FACET NUMBER for parution_date_year: '.$facet_number."\n";

# Loop over the facet to retrieve the terms and count
for (my $i = 0; $i < $facet_number; $i++) {
	my $term = search_get_facet_term($result, 'parution_date_year', $i);
	my $count = search_get_facet_count($result, 'parution_date_year', $i);
	print 'Facet '.$term.': '.$count."\n";
}

# Test autocompletion
print 'TEST AUTOCOMPLETION'."\n";
my $terms =  autocompletion_query($oss_url, $oss_login, $oss_key, $oss_index, 'autocompletion', 'a', 5);
for my $term (@$terms) {
	print $term."\n";
}