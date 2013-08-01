use strict;
use warnings;

package RT::Extension::AdminConditionsAndActions;

our $VERSION = '0.01';

use RT::ScripCondition;
no warnings 'redefine';

package RT::ScripCondition;

sub Delete {
    my $self = shift;

    unless ( $self->CurrentUser->HasRight( Object => RT->System, Right => 'ModifyScrips' ) ) {
        return ( 0, $self->loc('Permission Denied') );
    }

    my $scrips = RT::Scrips->new( RT->SystemUser );
    $scrips->Limit( FIELD => 'ScripCondition', VALUE => $self->id );
    if ( $scrips->Count ) {
        return ( 0, $self->loc('Condition is in use') );
    }

    return $self->SUPER::Delete(@_);
}

sub UsedBy {
    my $self = shift;

    my $scrips = RT::Scrips->new( $self->CurrentUser );
    $scrips->Limit( FIELD => 'ScripCondition', VALUE => $self->Id );
    return $scrips;
}

package RT::ScripAction;

sub Delete {
    my $self = shift;

    unless ( $self->CurrentUser->HasRight( Object => RT->System, Right => 'ModifyScrips' ) ) {
        return ( 0, $self->loc('Permission Denied') );
    }

    my $scrips = RT::Scrips->new( RT->SystemUser );
    $scrips->Limit( FIELD => 'ScripAction', VALUE => $self->id );
    if ( $scrips->Count ) {
        return ( 0, $self->loc('Action is in use') );
    }

    return $self->SUPER::Delete(@_);
}

sub UsedBy {
    my $self = shift;

    my $scrips = RT::Scrips->new( $self->CurrentUser );
    $scrips->Limit( FIELD => 'ScripAction', VALUE => $self->Id );
    return $scrips;
}

1;

__END__

=head1 NAME

RT-Extension-AdminConditionsAndActions - Admin Conditions And Actions

=head1 INSTALLATION 

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Set(@Plugins, qw(RT::Extension::AdminConditionsAndActions));

or add C<RT::Extension::AdminConditionsAndActions> to your existing C<@Plugins> line.

You can customize Condition/Action list format by config C<%AdminSearchResultFormat>, e.g.

    Set(%AdminSearchResultFormat,
        ...
        Conditions =>
            q{'<a href="__WebPath__/Admin/Conditions/Modify.html?&id=__id__">__id__</a>/TITLE:#'}
            .q{,'<a href="__WebPath__/Admin/Conditions/Modify.html?id=__id__">__Name__</a>/TITLE:Name'}
            .q{,'__Description__','__UsedBy__},
        Actions =>
            q{'<a href="__WebPath__/Admin/Conditions/Modify.html?&id=__id__">__id__</a>/TITLE:#'}
            .q{,'<a href="__WebPath__/Admin/Conditions/Modify.html?id=__id__">__Name__</a>/TITLE:Name'}
            .q{,'__Description__','__UsedBy__},
    );

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Jim Brandt <jbrandt@bestpractical.com>
sunnavy <sunnavy@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991