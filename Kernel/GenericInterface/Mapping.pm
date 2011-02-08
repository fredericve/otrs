# --
# Kernel/GenericInterface/Mapping.pm - GenericInterface data mapping interface
# Copyright (C) 2001-2011 OTRS AG, http://otrs.org/
# --
# $Id: Mapping.pm,v 1.3 2011-02-08 11:12:26 sb Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::GenericInterface::Mapping;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.3 $) [1];

=head1 NAME

Kernel::GenericInterface::Mapping

=head1 SYNOPSIS

GenericInterface data mapping interface.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. This will return the Mapping backend for the current web service configuration.

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Time;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::GenericInterface::Mapping;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $MappingObject = Kernel::GenericInterface::Mapping->new(
        ConfigObject       => $ConfigObject,
        LogObject          => $LogObject,
        DBObject           => $DBObject,
        MainObject         => $MainObject,
        TimeObject         => $TimeObject,
        EncodeObject       => $EncodeObject,

        MappingConfig   => {
            Type => 'MappingSimple',
            Config => {
                ...
            },
        },
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    # check needed params
    for my $Needed (qw(DBObject DebuggerObject MainObject MappingConfig)) {
        return { ErrorMessage => "Got no $Needed!" } if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }

    # load backend module
    if ( $Param{MappingConfig}->{'Type'} ) {
        my $GenericModule = 'Kernel::GenericInterface::Mapping::' . $Param{MappingConfig}->{'Type'};
        if ( !$Self->{MainObject}->Require($GenericModule) ) {
            return { ErrorMessage => "Can't load mapping backend module $GenericModule! $@" };
        }
        $Self->{Backend} = $GenericModule->new( %{$Self}, MappingConfig => \$Param{MappingConfig} );
    }
    else {
        return { ErrorMessage => 'No type was supplied in MappingConfig!' };
    }

    return $Self;
}

=item Map()

perform data mapping

    my $Result = $MappingObject->Map(
        Data => {                               # data payload before mapping
            ...
        },
    );

    $Result = {
        Success         => 1,                   # 0 or 1
        ErrorMessage    => '',                  # in case of error
        Data            => {                    # data payload of after mapping
            ...
        },
    };

=cut

sub Map {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Data} ) {
        $Self->{LogObject}->Log( Priority => 'error', Message => 'Need Data!' );
        return;
    }
    return $Self->{Backend}->Map(%Param)

}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.3 $ $Date: 2011-02-08 11:12:26 $

=cut
