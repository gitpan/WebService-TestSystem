# $Id: 00_initialize.t,v 1.1 2004/09/16 22:53:06 bryce Exp $

use strict;
use Test::More tests => 2;

BEGIN { use_ok('WebService::TestSystem'); }

diag( "Testing WebService::TestSystem $WebService::TestSystem::VERSION" );

