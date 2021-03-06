package AssemblyUtil::AssemblyUtilClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

AssemblyUtil::AssemblyUtilClient

=head1 DESCRIPTION





=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => AssemblyUtil::AssemblyUtilClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my $token = Bio::KBase::AuthToken->new(@args);
	
	if (!$token->error_message)
	{
	    $self->{token} = $token->token;
	    $self->{client}->{token} = $token->token;
	}
        else
        {
	    #
	    # All methods in this module require authentication. In this case, if we
	    # don't have a token, we can't continue.
	    #
	    die "Authentication failed: " . $token->error_message;
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 get_assembly_as_fasta

  $file = $obj->get_assembly_as_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.GetAssemblyParams
$file is an AssemblyUtil.FastaAssemblyFile
GetAssemblyParams is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	filename has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.GetAssemblyParams
$file is an AssemblyUtil.FastaAssemblyFile
GetAssemblyParams is a reference to a hash where the following keys are defined:
	ref has a value which is a string
	filename has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string


=end text

=item Description

Given a reference to an Assembly (or legacy ContigSet data object), along with a set of options,
construct a local Fasta file with the sequence data.  If filename is set, attempt to save to the
specified filename.  Otherwise, a random name will be generated.

=back

=cut

 sub get_assembly_as_fasta
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_assembly_as_fasta (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_assembly_as_fasta:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_assembly_as_fasta');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyUtil.get_assembly_as_fasta",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_assembly_as_fasta',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_assembly_as_fasta",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_assembly_as_fasta',
				       );
    }
}
 


=head2 export_assembly_as_fasta

  $output = $obj->export_assembly_as_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.ExportParams
$output is an AssemblyUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.ExportParams
$output is an AssemblyUtil.ExportOutput
ExportParams is a reference to a hash where the following keys are defined:
	input_ref has a value which is a string
ExportOutput is a reference to a hash where the following keys are defined:
	shock_id has a value which is a string


=end text

=item Description

A method designed especially for download, this calls 'get_assembly_as_fasta' to do
the work, but then packages the output with WS provenance and object info into
a zip file and saves to shock.

=back

=cut

 sub export_assembly_as_fasta
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function export_assembly_as_fasta (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to export_assembly_as_fasta:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'export_assembly_as_fasta');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyUtil.export_assembly_as_fasta",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'export_assembly_as_fasta',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method export_assembly_as_fasta",
					    status_line => $self->{client}->status_line,
					    method_name => 'export_assembly_as_fasta',
				       );
    }
}
 


=head2 save_assembly_from_fasta

  $ref = $obj->save_assembly_from_fasta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is an AssemblyUtil.SaveAssemblyParams
$ref is a string
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	ftp_url has a value which is a string
	workspace_name has a value which is a string
	assembly_name has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string

</pre>

=end html

=begin text

$params is an AssemblyUtil.SaveAssemblyParams
$ref is a string
SaveAssemblyParams is a reference to a hash where the following keys are defined:
	file has a value which is an AssemblyUtil.FastaAssemblyFile
	shock_id has a value which is an AssemblyUtil.ShockNodeId
	ftp_url has a value which is a string
	workspace_name has a value which is a string
	assembly_name has a value which is a string
FastaAssemblyFile is a reference to a hash where the following keys are defined:
	path has a value which is a string
	assembly_name has a value which is a string
ShockNodeId is a string


=end text

=item Description

WARNING: has the side effect of moving the file to a temporary staging directory, because the upload
script for assemblies currently requires a working directory, not a specific file.  It will attempt
to upload everything in that directory.  This will move the file back to the original location, but
if you are trying to keep an open file handle or are trying to do things concurrently to that file,
this will break.  So this method is certainly NOT thread safe on the input file.

=back

=cut

 sub save_assembly_from_fasta
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function save_assembly_from_fasta (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to save_assembly_from_fasta:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'save_assembly_from_fasta');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AssemblyUtil.save_assembly_from_fasta",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'save_assembly_from_fasta',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method save_assembly_from_fasta",
					    status_line => $self->{client}->status_line,
					    method_name => 'save_assembly_from_fasta',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "AssemblyUtil.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AssemblyUtil.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'save_assembly_from_fasta',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method save_assembly_from_fasta",
            status_line => $self->{client}->status_line,
            method_name => 'save_assembly_from_fasta',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for AssemblyUtil::AssemblyUtilClient\n";
    }
    if ($sMajor == 0) {
        warn "AssemblyUtil::AssemblyUtilClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 FastaAssemblyFile

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
path has a value which is a string
assembly_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
path has a value which is a string
assembly_name has a value which is a string


=end text

=back



=head2 GetAssemblyParams

=over 4



=item Description

@optional filename


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
ref has a value which is a string
filename has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
ref has a value which is a string
filename has a value which is a string


=end text

=back



=head2 ExportParams

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
input_ref has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
input_ref has a value which is a string


=end text

=back



=head2 ExportOutput

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
shock_id has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
shock_id has a value which is a string


=end text

=back



=head2 ShockNodeId

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 SaveAssemblyParams

=over 4



=item Description

Options supported:
    file / shock_id / ftp_url - mutualy exclusive parameters pointing to file content
    workspace_name - target workspace
    assembly_name - target object name

Uploader options not yet supported
    taxon_reference: The ws reference the assembly points to.  (Optional)
    source: The source of the data (Ex: Refseq)
    date_string: Date (or date range) associated with data. (Optional)
    contig_information_dict: A mapping that has is_circular and description information (Optional)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file has a value which is an AssemblyUtil.FastaAssemblyFile
shock_id has a value which is an AssemblyUtil.ShockNodeId
ftp_url has a value which is a string
workspace_name has a value which is a string
assembly_name has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file has a value which is an AssemblyUtil.FastaAssemblyFile
shock_id has a value which is an AssemblyUtil.ShockNodeId
ftp_url has a value which is a string
workspace_name has a value which is a string
assembly_name has a value which is a string


=end text

=back



=cut

package AssemblyUtil::AssemblyUtilClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
