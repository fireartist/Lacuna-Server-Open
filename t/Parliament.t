use lib '../lib';
use Test::More tests => 12;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna::Constants qw(ORE_TYPES);

use TestHelper;
my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $emb = Lacuna->db->resultset('Lacuna::DB::Result::Building')->new({
        x               => 4,
        y               => 4,
        class           => 'Lacuna::DB::Result::Building::Embassy',
    });
$home->build_building($emb);
$emb->finish_upgrade;

my $result;
$result = $tester->post('embassy', 'create_alliance', [$session_id, $emb->id, 'test alliance']);
ok(exists $result->{result}, 'can create alliance');
$result = $tester->post('embassy', 'get_alliance_status', [$session_id, $emb->id]);
ok(scalar@{$result->{result}{alliance}{members}}, 'alliance has members');
$empire = $empire->get_from_storage;
ok $empire->alliance_id, 'empire has alliance';

my $station = Lacuna->db->resultset('Map::Body')->search({class => {like => 'Lacuna::DB::Result::Map::Body::Planet::P%'}, empire_id => undef},{rows=>1})->single;
$station->convert_to_station($empire);
$station = $station->get_from_storage; # just in case

ok $station->alliance_id, 'alliance assigned to station';

my $par = $station->parliament;
$par->level(4);
$par->update;
    
$result = $tester->post('parliament', 'view', [$session_id, $par->id]);
is($result->{result}{building}{name}, 'Parliament', 'built successfully');

$result = $tester->post('body', 'rename', [$session_id, $station->id, 'station'.rand(1000000)]);
is($result->{error}{code}, 1017, 'renaming the station causes a proposition response');

$result = $tester->post('parliament', 'view_propositions', [$session_id, $par->id]);
is($result->{result}{propositions}[0]{name}, 'Rename Station', 'got a list of propositions');

$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $result->{result}{propositions}[0]{id}, 1]);
is($result->{result}{proposition}{my_vote}, 1, 'got my vote');

$result = $tester->post('parliament', 'propose_writ', [$session_id, $par->id, 'Do the big thing.', 'Make it go.']);
is($result->{result}{proposition}{name}, 'Do the big thing.', 'writ proposed');
$result = $tester->post('parliament', 'cast_vote', [$session_id, $par->id, $result->{result}{proposition}{id}, 1]);
$result = $tester->post('parliament', 'view_laws', [$session_id, $station->id]);
is($result->{result}{laws}[0]{name}, 'Do the big thing.', 'writ enacted');

$result = $tester->post('parliament', 'propose_transfer_station_ownership', [$session_id, $par->id]);
is($result->{error}{data}, 6, 'transfering ownership of station requires level 6 parliament');

$result = $tester->post('parliament', 'propose_seize_star', [$session_id, $par->id]);
is($result->{error}{data}, 7, 'transfering ownership of station requires level 7 parliament');

$result = $tester->post('parliament', 'propose_fire_bfg', [$session_id, $par->id]);
is($result->{error}{data}, 30, 'firing bfg requires level 30 parliament');


END {
    $station->sanitize;
    $tester->cleanup;
}
