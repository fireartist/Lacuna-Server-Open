package Lacuna::DB::Result::Building::Permanent::HallsOfVrbansk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::HallsOfVrbansk';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    if ($body->get_plan(__PACKAGE__, 1)) {
        return $orig->($self, $body);  
    }
    confess [1013,"You can't build the Halls of Vrbansk."];
};

sub can_upgrade {
    confess [1013, "You can't upgrade the Halls of Vrbansk."];
}

use constant image => 'hallsofvrbansk';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('The ancient wisdom of the Great Race is still alive on %s.', $self->body->name));
};

sub get_halls {
    my $self = shift;
    return $self->body->get_buildings_of_class('Lacuna::DB::Result::DB::Building::Permanent::HallsOfVrbansk');
}

sub get_upgradable_buildings {
    my ($self) = @_;
    my @halls = $self->get_halls->get_column('id')->all;
    return $self->body->buildings->search({
        level   => { '<' => scalar @halls},
        class   => { like => 'Lacuna::DB::Result::Building::Permanent::%' },
        id      => { 'not in' => \@halls },
    });
}

use constant name => 'Halls of Vrbansk';
use constant time_to_build => 0;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
