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

print search($oss_url, $oss_login, $oss_key, $oss_index, $template, $keywords, $start, $rows);

