
=head1 NAME

WebService::TestSystem - Web service for implementing a distributed
testing system.

=head1 SYNOPSIS

    my $testsys = new WebService::TestSystem;

    # TODO:  Add API

=head1 DESCRIPTION

WebService::TestSystem implements the 'business logic' for a distributed
testing system.  This is designed to provide a uniform API layer,
receive RPC commands from a SOAP server and either process them or pass
them along to backend processes.

For example, it provides search commands for querying a database about
available tests, host machines, software, linux distros, etc.  

=head1 FUNCTIONS

=cut

package WebService::TestSystem;

use strict;
use DBI;

# TODO:  Move this into the object
my $stpdb_dbi  = 'dbi:mysql:STPDB:osdlab';
my $stpdb_user = 'stp_plm_report';
my $stpdb_pass = '';

my $STPDB_DBH;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.01';

use fields qw(
              _stpdb_dbh
              _stpdb_dbi
              _stpdb_user
              _stpdb_pass
              _error_msg
              _debug
              );

=head2 new(%args)

Establishes a new WebService::TestSystem instance.  This sets up a database
connection.

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    while (my ($field, $value) = each %args) {
        if (exists $FIELDS{"_$field"}) {
            $self->{"_$field"} = $value;
            if ($args{debug} && $args{debug}>3 && defined $value) {
                warn 'Setting WebService::TestSystem::_'.$field." = $value\n";
            }
        }
    }

    # Specify defaults
    $self->{'_stpdb_dbi'}  ||= 'dbi:mysql:STPDB:osdlab';
    $self->{'_stpdb_user'} ||= 'stp_plm_report';
    $self->{'_stpdb_pass'} ||= '';


    return $self;
}

# Internal routine for getting the database handle; if it does not
# yet exist, it creates a new one.
sub _get_dbh {
    my $self = shift;
    if (! $self->{'_stpdb_dbh'}) {
        $self->{'_stpdb_dbh'} = 
            DBI->connect($self->{'_stpdb_dbi'}, 
                         $self->{'_stpdb_user'}, 
                         $self->{'_stpdb_pass'}
                         );
        if (! $self->{'_stpdb_dbh'}) {
            $self->_set_error("Could not connect to '"
                              .$self->{'_stpdb_dbi'}
                              ."' as user '"
                              .$self->{'_stpdb_user'}
                              ."':  $!\n");
        }
    }
    return $self->{'_stpdb_dbh'};
}

# Internal routine for setting the error message
sub _set_error {
    my $self = shift;
    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message.  If any of this module's routines
return undef, this routine can be called to retrieve a message about
what happened.  If several errors have occurred, this will only return
the most recently encountered one.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

=head2 get_tests()

Returns a list of tests in the system.  Each test object will include
several fields, including its name, id number, etc.

=cut

sub get_tests {
    my $self = shift;

    my $sql = qq|SELECT * from test|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @tests = ();
    while (my $test = $sth->fetchrow_hashref) {
        push @tests, $test;
    }

    return \@tests;
}

=head2 get_hosts()

Returns a list of host machines registered in the system.  Each host
record will include its name, id, and other info.

=cut

sub get_hosts {
    my $self = shift;

    my $sql = qq|SELECT * from host|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @hosts = ();
    while (my $host = $sth->fetchrow_hashref) {
        push @hosts, $host;
    }

    return \@hosts;
}

=head2 get_images()

This routine returns a list of distro images that are available in
the system.  Each image record includes its name, id, and other info.

=cut

sub get_images {
    my $self = shift;

    my $sql = qq|SELECT * FROM distro_tag WHERE status='Available'|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @images = ();
    while (my $image = $sth->fetchrow_hashref) {
        push @images, $image;
    }

    return \@images;
}

=head2 get_packages()

Returns a list of software packages available in the system for doing
testing against.  

=cut

sub get_packages {
    my $self = shift;

    # TODO:  Pull this from PLM
    my $sql = qq|SELECT * FROM patch_tag|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @packages = ();
    while (my $package = $sth->fetchrow_hashref) {
        push @packages, $package;
    }

    return \@packages;
}

=head2 get_requests(%args)

This routine permits searching against the test requests in the system.
Arguments can be provided via the %args hash.  Accepted arguments
include:

    limit           - the number of records to return
    order_by        - the fieldname to order the records by

    distro          - search condition (supports % wildcards)
    test            - search condition (supports % wildcards)
    host            - search condition (supports % wildcards)
    host_type       - search condition (supports % wildcards)
    project         - search condition (supports % wildcards)
    priority        - search condition (must match exactly)
    status          - search condition (must match exactly)
    patch_id        - search condition (must be a valid patch id number)
    patch           - search condition (must match a valid patch name)
    created_by      - user id number for requestor
    username        - username of requestor
    

Each test request record returned includes the following info:

    id              - the test request's id
    created_by      - user id# of the requestor
    username        - username of the requestor
    project         - project associated with the request
    status          - the state the test request is currently in
    priority        - priority

    created_date    - date it was created
    started_date    - datetime the test run began
    completion_date - date it was completed

    distro          - distro image name
    test            - test name
    host            - host name
    host_type       - host class
    patch           - patch name

    distro_tag_id   - id# of distro image
    test_id         - id# of test
    host_id         - id# of host
    host_type_id    - id# of host type
    project_id      - id# of project
    patch_tag_uid   - id# of patch

=cut

# TODO:  I think this returns one row per patch_tag record...  
#        Perhaps it should return this info as a nested structure?
sub get_requests {
    my ($self, %args) = @_;

    while (my ($key, $value) = each %args) {
        warn " '$key' = '$value'\n";
    }

    # limit can only be between 0-1000 and must be a number.
    my $limit = $args{limit} || 20;
    if ($limit !~ /^\d+$/ || $limit > 1000) {
        $self->set_error("Invalid limit '$limit'.  ".
                         "Must be a number in the range 0-1000.");
        return undef;
    } else {
        delete $args{limit};
    }

    # Order field must be alphanumeric
    my $order_by = $args{order_by} || 'uid';
    if ($order_by !~ /^\w+$/) {
        $self->_set_error("Invalid order_by field '$order_by'.  ".
                          "Must be an alphanumeric field name.");
        return undef;
    } else {
        delete $args{order_by};
    }

    # Rest of the arguments can only be alphanumeric values
    foreach my $key (keys %args) {
        if ($key !~ m/^\w+$/) {
            my $err = "Invalid key '$key' specified.  ".
                "Only alphanumeric characters may be used.";
            warn "Error:  $err\n";
            $self->_set_error($err);
            return undef;
        } elsif ($args{$key} !~ m/^\w+$/) {
            my $err = "Invalid value '$args{'$key'}' specified for '$key'.  "
                ."Only alphanumeric characters may be used.";
            $self->_set_error($err);
            warn "Error:  $err\n";
            return undef;
        }
    }

    my $sql = qq|
SELECT 
    test_request.uid AS id,
    test_request.created_by AS created_by,
    DATE_FORMAT(test_request.created_date, '%Y-%m-%d') AS created_date,
    test_request.status AS status,
    DATE_FORMAT(test_request.completion_date, '%Y-%m-%d') AS completion_date,
    test_request.test_priority AS priority,
    test_request.started_date AS started_date,

    test_request.distro_tag_uid AS distro_tag_uid,
    test_request.test_uid AS test_uid,
    test_request.host_uid AS host_uid,
    test_request.host_type_uid AS host_type_uid,
    test_request.project_uid AS project_uid,

    distro_tag.descriptor AS distro,
    test.descriptor AS test,
    host.descriptor AS host,
    host_type.descriptor AS host_type,
    EIDETIC.user.descriptor AS username,
    EIDETIC.project.descriptor AS project,

    test_request_to_patch_tag.patch_tag_uid AS patch_tag_uid,
    patch_tag.descriptor AS patch
FROM 
    test_request, 
    distro_tag, 
    test, 
    host, 
    host_type, 
    test_request_to_patch_tag, 
    patch_tag, 
    EIDETIC.user, 
    EIDETIC.project
WHERE 1
    AND test_request.distro_tag_uid = distro_tag.uid
    AND test_request.test_uid = test.uid
    AND (test_request.host_uid = host.uid OR (test_request.host_uid=0 AND host.uid=1))
    AND test_request.host_type_uid = host_type.uid
    AND test_request.project_uid = EIDETIC.project.uid
    AND test_request.uid = test_request_to_patch_tag.test_request_uid
    AND test_request_to_patch_tag.patch_tag_uid = patch_tag.uid
    AND test_request.created_by = EIDETIC.user.uid
|;

    if (defined $args{'distro'}) {
        $sql .= qq|    AND distro_tag.descriptor LIKE "$args{'distro'}"\n|;
    }
    if (defined $args{'test'}) {
        $sql .= qq|    AND test.descriptor LIKE "$args{'test'}"\n|;
    }
    if (defined $args{'host'}) {
        $sql .= qq|    AND host.descriptor LIKE "$args{'host'}"\n|;
    }
    if (defined $args{'host_type'}) {
        $sql .= qq|    AND host.descriptor LIKE "$args{'host_type'}"\n|;
    }
    if (defined $args{'project'}) {
        $sql .= qq|    AND EIDETIC.project.descriptor LIKE "$args{'project'}"\n|;
    }
    if (defined $args{'priority'}) {
        $sql .= qq|    AND test_request.test_priority = $args{'priority'}\n|;
    }
    if (defined $args{'status'}) {
        $sql .= qq|    AND test_request.status = "$args{'status'}"\n|;
    }
    if (defined $args{'patch_id'}) {
        if ($args{'patch_id'} !~ m/^\d+$/) {
            $self->_set_error("Invalid patch ID '$args{'patch_id'}' specified.  ".
                              "Must be a positive integer.");
            return undef;
        }
        $sql .= qq|    AND test_request_to_patch_tag.patch_tag_uid = $args{'patch_id'}\n|;
    }
    if (defined $args{'patch'}) {
        $sql .= qq|    AND patch_tag.descriptor LIKE '$args{'patch'}'|;
    }
    if (defined $args{'created_by'}) {
        if ($args{'created_by'} !~ m/^\d+$/) {
            $self->_set_error("Invalid created_by UID '$args{'created_by'}'.  ".
                              "Must be a positive integer.");
            return undef;
        }
        $sql .= qq|    AND test_request.created_by=$args{'created_by'}\n|;
    }
    if (defined $args{'username'}) {
        $sql .= qq|    AND EIDETIC.user.descriptor LIKE "$args{'username'}"\n|;
    }

    $sql .= qq|ORDER BY $order_by DESC\n|;
    $sql .= qq|LIMIT $limit\n|;

    warn "sql = '$sql'\n";

    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @test_requests = ();
    while (my $tr = $sth->fetchrow_hashref) {
        push @test_requests, $tr;
    }

    return \@test_requests;
}

# TODO:  Implement this
sub get_machine_queue {
    my $sql = qq|
        select test_request.uid, patch_tag.descriptor as patch, test_request.status, host_type.descriptor as host_type, test_request.created_date from test_request, patch_tag, test_request_to_patch_tag, host_type where patch_tag.descriptor like 'patch-2.%-bk%' and test_request.uid=test_request_to_patch_tag.test_request_uid and test_request_to_patch_tag.patch_tag_uid=patch_tag.uid and test_request.host_type_uid=host_type.uid and host_type.descriptor='stp2-002' and test_request.status='Queued';
        |;
}


# TODO:  Implement this
sub get_patches {
    my $self = shift;

    my $sql = qq|SELECT * FROM patch_tag LIMIT 20|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @patches = ();
    while (my $patch = $sth->fetchrow_hashref) {
        push @patches, $patch;
    }

    return \@patches;
}

# Updates the description and other settings about a test
# If user is authenticated, updates directly, else it just
# sends an email to the admins
sub set_test {
    my $self = shift;
}

1;
