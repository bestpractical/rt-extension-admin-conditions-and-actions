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

=head1 DESCRIPTION

A web UI for managing RT conditions and actions.

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

=head1 USAGE

The core building blocks of scrips in RT are the conditions and actions
you select when configuring the scrip. A condition defines the criteria
for an action to run in the context of the current transaction. The
result is true or false: if true, the condition is satisfied and the
action runs, if false, the action is skipped. Actions define something
to be done when a condition is true and they can be anything you
can capture in code, either changing things in RT or calling out to
other systems, DBs, or APIs.

You can view all of the scrips that come standard with RT
by going to Tools > Global > Scrips (RT 4.0) or Admin >
Global > Scrips (RT 4.2). In the scrips list you'll see each has a
condition and an action and these are provided with the initial RT
installation. You might also see additional conditions and actions added
by extensions or through a local customization.

This extension provides a web UI to allow you to easily register your
own conditions and actions in RT, making it easier than ever to customize
RT for your specific needs.

=head2 User Defined Conditions and Actions

The simplest way to add a custom condition or action is to create a new
scrip and select "User Defined" as the Condition or Action. You can then
put your custom code right in the "User Defined" boxes on the bottom of
the scrip modification page.

However, you might prefer writing your condition or action in a module
with the code in a file. This allows you to track it in version control
and call it from other places like C<rt-crontool>. The following sections
describe how to create these modules.

=head2 Custom Conditions

Let's assume you have a custom lifecycle with a status
called 'review' and you want an 'On Review Needed' condition so you can
trigger actions when a ticket is put in review status. You notice RT
already has 'On Resolve' and other similar conditions, so you look at
the configuration at Admin > Global > Conditions and click on 'On Resolve'
(in RT 4.0, select Tools > Global > Conditions.)

The condition has a Name, which is displayed in the Condition dropdown when
you create a scrip, and a Description to identify it. The Condition Module is
the RT module that executes the condition, in this case C<StatusChange>. You
can find the code in C</opt/rt4/lib/RT/Condition/StatusChange.pm> and view
the documentation on the Best Practical L<"documentation site"|
http://bestpractical.com/docs/rt/latest/RT/Condition/StatusChange.html>.
(Confirm your RT version when checking the documentation.)

Parameters to Pass shows the actual parameter that is passed to the module
when this condition is executed. When you look at the module documentation
it makes sense when you see that C<StatusChange> accepts a valid status and
returns true if the transaction is setting the status to the provided value.
Finally, Applicable Transaction Types lists the transactions for which this
condition will run, and in this case it's Status transactions.

This is really close to what we might need for our 'On Review Needed' so
you can click the Copy Condition button to copy the current condition. On
the new condition page, you can update the Name and Description and set
the Parameters to Pass to 'review'. Then click save and you have your new
condition. You can now create a new scrip and select it from the Condition
dropdown.

=head2 Custom Condition Module

Now assume we have an additional requirement to check if a custom field value
'Special' is selected when we check the review status. For this one
we'll need to write some code. To start, create a new file for your new
SpecialReviewNeeded module here:

    /opt/rt4/local/lib/RT/Condition/SpecialReviewNeeded.pm

Creating it in the C<local> directory will keep it safe when you apply
RT upgrades in the future.

The basics of a condition module are as follows:

    package RT::Condition::SpecialReviewNeeded;

    use strict;
    use warnings;
    use base 'RT::Condition';

    sub IsApplicable {
        my $self = shift;

        # Your code here

        return 1; # True if condition is true, false if not
    }

    1; # Don't forget module needs this

C<IsApplicable> is the method you will override from the C<RT::Condition>
base class. The return value of this method, true or false, determines
whether the condition passes or not.

C<$self> gives you access to the ticket object and transaction object via:

    $self->TransactionObj
    $self->TicketObj

These are your main hooks into the current ticket and transaction.

To check review status and the custom field value, we might add something
like this:

    # Setting status to review?
    return 0 unless $self->TransactionObj->Type eq 'Status'
        and $self->TransactionObj->NewValue eq 'review';

    # Is 'Special' set to Yes?
    return 0 unless $self->TicketObj->FirstCustomFieldValue('Special') eq 'Yes';

    return 1;

We've hardcoded C<review> and C<Special> here, but as with C<StatusChange>,
you could pass a value from the Parameters to Pass field. You can access this
value by calling the C<Argument> method.

    my $arg = $self->Argument;

Using passed arguments can make your conditions and actions more general
and potentially reusable.

Once the file is created, return to the RT web UI and create a new condition,
possibly by editing On Review Needed and clicking Copy Condition.
You can name it Special Review Needed and set the Condition Module to
SpecialReviewNeeded.

=head2 Custom Actions

Once you have the correct condition you can now think about the action. You
want to send email to a group of people, so to start you look at some of the
existing actions on the action display page at Admin > Global > Actions (in RT 4.0,
Tools > Global > Actions). You find Notify AdminCcs, which might be close. Taking
a quick look you see it has a Name and Description, like conditions, and
the module it calls is C<Notify>, which can be found at
C</opt/rt4/lib/RT/Action/Notify.pm>.

The Parameter to Pass is AdminCc, and if you look at other notification
actions you'll see many use Notify and just pass a different ticket role.

Your reviewers aren't always AdminCcs on tickets, so you'd rather
send a notification to a group. You can create this new action using the
existing action module C<NotifyGroup>. On the action list page, click Create
and add something like the following:

    Name               Notify Review Group
    Description        Send notification to the review group
    Action Module      NotifyGroup
    Parameters to Pass Review Group

The 'Review Group' can be whatever your group name is. Then you can build a
template with some custom ticket information for reviewers and set up a new
scrip to send email to the review group whenever a ticket status is set to
review.

=head2 Custom Action Modules

As part of the request to add a condition to check for the 'Special' custom
field, we now want to route these special requests to the person who handles
them. This extra bit of functionality will require a module, maybe called
C<SetOwner>. Create the new file in:

    /local/lib/RT/Action/SetOwner.pm

The base action code looks like this:

    package RT::Action::SetOwner;

    use strict;
    use warnings;
    use base 'RT::Action';

    sub Prepare {
        my $self = shift;

        # Your code here

        return 1; # True if Commit should run, false if not
    }

    sub Commit {
        my $self = shift;

        # Your code here

        return 1; # True if action was successful
    }

    1; # Don't forget module needs this

Actions have two methods you can override. The C<Prepare> method provides
you with a chance to make sure the action should actually run.
If C<Prepare> returns false, C<Commit> will not run. You'll typically
handle this in your condition, in which case you can just omit C<Prepare>
from your action. However, when you have a condition that covers a common
general case, but you want to check one extra criteria for a particular
action, the C<Prepare> method can be helpful. In our example, you might
choose to keep just the On Review Needed condition and add the check
for the 'Special' custom field to the C<Prepare> method.

C<Commit> is where you do the actual work of the action. It should
return true on success. On failure, you can use C<RT::Logger> to
write errors or debugging information to RTs logs so you can track
down the problem.

In actions, C<$self> gives you access to the transaction and ticket
objects, just like conditions, via:

    $self->TransactionObj
    $self->TicketObj

For our C<SetOwner> action, we don't need C<Prepare> and can add the
following to C<Commit>:

    my $user = RT::User->new(RT->SystemUser);
    my ($ret, $msg) = $user->Load($self->Argument);
    RT::Logger->error('Unable to load user: '
                       . $self->Argument . " $msg") unless $ret;

    $self->TicketObj->SetOwner($user->Id);
    return 1;

The C<Argument> method returns the value set for Parameters to
Pass in the action configuration. This example expects the
argument to be the username of an RT user.

Now you can create the new action in RT. Go to the action page, click
Create, and enter the following:

    Name               Set Owner
    Description        Set owner
    Action Module      SetOwner
    Parameters to Pass reviewer_username

Click save and the new action will be available when creating scrips.

Note that actions you perform in scrips can themselves create new
transactions, as is the case with C<SetOwner>. When this action runs,
the set owner transaction will fire the default On Owner Change Notify
Owner scrip, if it is enabled.

=head1 ADDITIONAL INFORMATION

When writing actions and conditions, it's helpful to look at the actions
and conditions provided with RT. You can find more information about
the methods available from ticket and transaction objects in your RT
distribution and on the
L<"Best Practical website"|http://docs.bestpractical.com>.

=head1 AUTHOR

sunnavy <sunnavy@bestpractical.com>

Jim Brandt <jbrandt@bestpractical.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Best Practical Solutions, LLC.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991
