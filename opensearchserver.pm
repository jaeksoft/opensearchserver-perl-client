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

our $VERSION = '1.00';

use base 'Exporter';

our @EXPORT = qw(search);

use REST::Client;
use JSON;
use URI::Escape;

#
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

	if (not defined $server) {
		warn 'The server URL is required';
		return;
	}	
	if (not defined $index) {
		warn 'The index name is required';
		return;
	}	
	my $request = $server.'/services/rest/select/search/'.uri_escape($index).'/json?';
	if (defined $login) {
		$request.='login='.uri_escape($login).'&';
	}
	if (defined $apikey) {
		$request.='key='.uri_escape($apikey).'&';
	}
	if (defined $template) {
		$request.='template='.uri_escape($template).'&';
	}
	if (defined $query) {
		$request.='query='.uri_escape($query).'&';
	}
	if (defined $start) {
		$request.='start='.uri_escape($start).'&';
	}
	if (defined $rows) {
		$request.='rows='.uri_escape($rows).'&';
	}
	if (defined $lang) {
		$request.='lang='.uri_escape($lang).'&';
	}
	
	print $request."\n";
	
    my $client = REST::Client->new();
    $client->GET($request);
   	if ($client->responseCode() ne '200') {
		warn 'Wrong HTTP response code: '.$client->responseCode();
		return;
	}
    return JSON::decode_json($client->responseContent());
}

1;
