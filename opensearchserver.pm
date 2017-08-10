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
package OpenSearchServer;

use strict;
use warnings;

use feature "switch";

our $VERSION = '1.14';

use base 'Exporter';

our @EXPORT = qw(
    search
    search_pattern
    search_field
    search_num_found
    search_max_score
    search_documents_returned
    search_document_field
    search_document_field_values
    search_document_snippet
    search_document_score
    search_get_facet_number
    search_get_facet_term
    search_get_facet_count
    autocompletion_query
    morelikethis
    morelikethis_docquery
    morelikethis_liketext
    spellcheck_query);

use REST::Client;
use JSON;
use URI::Escape;
use Data::Dumper;

# Check the server and index parameter
sub check_server_index {
    my $server = shift;
    my $index = shift;

    if (not defined $server) {
        warn 'The server URL is required';
        return undef;
    }
    if (not defined $index) {
        warn 'The index name is required';
        return undef;
    }
}

# Add the optional login/apikey in the query string
sub check_login_key {
    my $request = shift;
    my $login = shift;
    my $apikey = shift;
    $request .= '?';
    if (defined $login) {
        $request .= 'login=' . uri_escape($login) . '&';
    }
    if (defined $apikey) {
        $request .= 'key=' . uri_escape($apikey) . '&';
    }
    return $request;
}

# Search request
sub search {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    my $lang = shift;
    my $sort = shift;
    my $filter = shift;
    my $type = shift;

    if (not defined check_server_index($server, $index)) {
        return;
    }
    if (not defined $type) {
        $type = 'pattern';
    }
    else {
        given ($type) {
            when ('pattern') {}
            when ('field') {}
            default {$type = 'pattern';}
        }
    }

    my $request = $server . '/services/rest/index/' . uri_escape($index) . '/search/' . $type;
    if (defined $template) {
        $request .= '/' . uri_escape($template);
    }
    $request = check_login_key($request, $login, $apikey);

    my %json_request;

    if (defined $query) {
        $json_request{'query'} = $query;
    }
    if (defined $start) {
        $json_request{'start'} = $start;
    }
    if (defined $rows) {
        $json_request{'rows'} = $rows;
    }
    if (defined $lang) {
        $json_request{'lang'} = $lang;
    }

    #Build the sorting sub structure
    if (defined $sort) {
        my @sort_array;
        for my $s (@$sort) {
            my %sort_item;
            for (substr($s, 0, 1)) {
                when ('+') {
                    $sort_item{'direction'} = 'ASC';
                    $sort_item{'field'} = substr($s, 1);
                }
                when ('-') {
                    $sort_item{'direction'} = 'DESC';
                    $sort_item{'field'} = substr($s, 1);
                }
                default {
                    $sort_item{'direction'} = 'ASC';
                    $sort_item{'field'} = $s;
                }
            }
            push(@sort_array, \%sort_item);
        }
        $json_request{'sorts'} = \@sort_array;
    }

    #Build the filtering sub structure
    if (defined $filter) {
        my @filter_array;
        for my $f (@$filter) {
            my %filter_item;
            $filter_item{'type'} = 'QueryFilter';
            $filter_item{'query'} = $f;
            push(@filter_array, \%filter_item);
        }
        $json_request{'filters'} = \@filter_array;
    }

    my $json_text = JSON::to_json(\%json_request);
    my $client = REST::Client->new();

    $client->addHeader('Content-type', 'application/json');
    $client->setTimeout(120);
    $client->POST($request, $json_text);

    if ($client->responseCode() ne '200') {
        warn 'Wrong HTTP response code: ' . $client->responseCode() . ' ' . $client->responseContent();
        return;
    }
    return JSON::decode_json($client->responseContent());
}

# Wrapper to search pattern
sub search_pattern {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    my $lang = shift;
    my $sort = shift;
    my $filter = shift;

    return search($server, $login, $apikey, $index, $template, $query, $start, $rows, $lang, $sort, $filter, 'pattern');
}

# Wrapper to search field
sub search_field {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    my $lang = shift;
    my $sort = shift;
    my $filter = shift;

    return search($server, $login, $apikey, $index, $template, $query, $start, $rows, $lang, $sort, $filter, 'field');
}

# Returns the number of document found
sub search_num_found {
    my $json = shift;
    return $json->{'numFound'};
}

sub search_max_score {
    my $json = shift;
    return $json->{'maxScore'};
}

sub search_documents_returned {
    my $json = shift;
    my $documents = $json->{'documents'};
    $documents = [] unless (defined $documents);
    return @$documents;
}

# Returns an array with the values, or undef if no value exists
sub search_document_field_values {
    my $json = shift;
    my $pos = shift;
    my $field_name = shift;
    my $fields = $json->{'documents'}->[$pos]->{'fields'};
    # Loop over fields
    for my $field (@$fields) {
        if ($field_name eq $field->{'fieldName'}) {
            my @result;
            my $values = $field->{'values'};
            for my $value (@$values) {
                push(@result, $value);
            }
            return \@result;
        }
    }
    return undef;
}

# Returns the named field of one document
sub search_document_field {
    my $json = shift;
    my $pos = shift;
    my $field_name = shift;
    my $values = search_document_field_values($json, $pos, $field_name);
    if ($values) {
        return$values->[0];
    }
    return undef;
}

# Returns the named snippet of one document
sub search_document_snippet {
    my $json = shift;
    my $pos = shift;
    my $field_name = shift;
    my $snippets = $json->{'documents'}->[$pos]->{'snippets'};
    # Loop over snippets
    for my $snippet (@$snippets) {
        if ($field_name eq $snippet->{'fieldName'}) {
            return $snippet->{'values'}[0];
        }
    }
}

# Returns the score of the document at the given position
sub search_document_score {
    my $json = shift;
    my $pos = shift;
    return $json->{'documents'}->[$pos]->{'score'};
}


# Returns the facet hash relate to a field name
sub search_get_facet {
    my $json = shift;
    my $field_name = shift;
    my $facets = $json->{'facets'};
    for my $facet (@$facets) {
        if ($field_name eq $facet->{'fieldName'}) {
            return $facet;
        }
    }
    return undef;
}

# Returns the number of terms for a facet
sub search_get_facet_number {
    my $facet = search_get_facet(@_);
    if (!defined($facet)) {
        return 0;
    }
    my $term_array = $facet->{'terms'};
    return @$term_array;
}


# Returns the term of one facet array at a given position
sub search_get_facet_term {
    my $facet = search_get_facet(@_);
    if (!defined($facet)) {
        return 0;
    }
    my $json = shift;
    my $field_name = shift;
    my $pos = shift;
    return $facet->{'terms'}->[$pos]->{'term'};
}

# Returns the number of document for one facet term at a given position
sub search_get_facet_count {
    my $facet = search_get_facet(@_);
    if (!defined($facet)) {
        return 0;
    }
    my $json = shift;
    my $field_name = shift;
    my $pos = shift;
    return $facet->{'terms'}->[$pos]->{'count'};
}

# Query an autocompletion item
sub autocompletion_query {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $autocompletion_name = shift;
    my $prefix = shift;
    my $rows = shift;

    if (not defined check_server_index($server, $index)) {
        return;
    }

    my $request = $server . '/services/rest/index/' . uri_escape($index) . '/autocompletion/' . uri_escape($autocompletion_name);
    $request = check_login_key($request, $login, $apikey);

    if (defined $prefix) {
        $request .= 'prefix=' . uri_escape($prefix) . '&';
    }
    if (defined $rows) {
        $request .= 'rows=' . uri_escape($rows) . '&';
    }

    my $client = REST::Client->new();

    print 'REQUEST: ' . $request . "\n";

    $client->GET($request);

    if ($client->responseCode() ne '200') {
        warn 'Wrong HTTP response code: ' . $client->responseCode() . ' ' . $client->responseContent();
        return;
    }
    my @results;
    my $json = JSON::decode_json($client->responseContent());
    my $terms = $json->{'terms'};
    for my $term (@$terms) {
        push(@results, $term);
    }
    return \@results;
}

# Query an morelikethis item with template
sub morelikethis {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    my $type = shift;

    if (not defined check_server_index($server, $index)) {
        return;
    }
    if (not defined $type) {
        $type = 'likeText';
    }
    else {
        given ($type) {
            when ('likeText') {}
            when ('docQuery') {}
            default {$type = 'likeText';}
        }
    }
    my $request = $server . '/services/rest/index/' . uri_escape($index) . '/morelikethis/template/' . uri_escape($template);
    $request = check_login_key($request, $login, $apikey);

    my %json_request;
    if (defined $query) {
        $json_request{$type} = $query;
    }
    if (defined $start) {
        $json_request{'start'} = $start;
    }
    if (defined $rows) {
        $json_request{'rows'} = $rows;
    }

    my $json_text = JSON::to_json(\%json_request);
    my $client = REST::Client->new();
    $client->POST($request, $json_text, { "Content-type" => 'application/json' });
    if ($client->responseCode() ne '200') {
        warn 'Wrong HTTP response code: ' . $client->responseCode() . ' ' . $client->responseContent();
        return;
    }
    return JSON::decode_json($client->responseContent());
}

# Wrapper to morelikethis document Query
sub morelikethis_docquery {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    return morelikethis($server, $login, $apikey, $index, $template, $query, $start, $rows, 'docQuery');
}

# Wrapper to morelikethis like Text
sub morelikethis_liketext {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $template = shift;
    my $query = shift;
    my $start = shift;
    my $rows = shift;
    return morelikethis($server, $login, $apikey, $index, $template, $query, $start, $rows, 'likeText');
}

# Query an spellcheck suggestion
sub spellcheck_query {
    my $server = shift;
    my $login = shift;
    my $apikey = shift;
    my $index = shift;
    my $spellcheck_name = shift;
    my $query = shift;
    my $lang = shift;

    if (not defined check_server_index($server, $index)) {
        return;
    }

    my $request = $server . '/services/rest/index/' . uri_escape($index) . '/spellcheck/' . uri_escape($spellcheck_name);
    $request = check_login_key($request, $login, $apikey);

    if (defined $query) {
        $request .= 'query=' . uri_escape($query) . '&';
    }
    if (defined $lang) {
        $request .= 'lang=' . uri_escape($lang) . '&';
    }

    my $client = REST::Client->new();

    $client->GET($request);

    if ($client->responseCode() ne '200') {
        warn 'Wrong HTTP response code: ' . $client->responseCode() . ' ' . $client->responseContent();
        return;
    }
    return JSON::decode_json($client->responseContent());
}

1;
