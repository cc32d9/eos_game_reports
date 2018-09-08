use strict;
use warnings;
use JSON;
use Getopt::Long;
use DBI;


my $dsnr = 'DBI:mysql:database=eosio;host=localhost';
my $dbr_user = 'eosioro';
my $dbr_password = 'eosioro';

my $dsnw = 'DBI:mysql:database=eosgames;host=localhost';
my $dbw_user = 'eosgames';
my $dbw_password = 'Einie4xa';

my $diceacc = 'eosbetdice11';
my $rcpt_action = 'betreceipt';


my $json = JSON->new;

my $ok = GetOptions
    ('dsnr=s'     => \$dsnr,
     'dbruser=s'  => \$dbr_user,
     'dbrpw=s'    => \$dbr_password,
     'dsnw=s'     => \$dsnw,
     'dbwuser=s'  => \$dbw_user,
     'dbwpw=s'    => \$dbw_password);


if( not $ok or scalar(@ARGV) > 0 )
{
    print STDERR "Usage: $0 [options...]\n";
    exit 1;
}


my $dbhr = DBI->connect($dsnr, $dbr_user, $dbr_password,
                        {'RaiseError' => 1, AutoCommit => 0,
                         mysql_server_prepare => 1});
die($DBI::errstr) unless $dbhr;

my $dbhw = DBI->connect($dsnw, $dbw_user, $dbw_password,
                        {'RaiseError' => 1, AutoCommit => 0,
                         mysql_server_prepare => 1});
die($DBI::errstr) unless $dbhw;


my $block_num = 0;
my $max_seq = 0;
{
    my $r = $dbhw->selectall_arrayref
        ('SELECT MAX(block_num), MAX(global_action_seq) FROM EOSBET_DICE_RECEIPTS');
    if( defined($r->[0][0]) )
    {
        $block_num = $r->[0][0];
        $max_seq = $r->[0][1];
    }
}

my $sth_getreceipts = $dbhr->prepare
    ('SELECT ' .
     ' global_action_seq, block_num, ' .
     ' DATE(block_time) AS bd, block_time, trx_id, ' .
     ' jsdata ' .
     'FROM EOSIO_ACTIONS ' .
     'WHERE actor_account = ? AND action_name = ? AND block_num >= ? ' .
     ' AND global_action_seq > ? ' .
     'ORDER BY block_num LIMIT 1000');

my $sth_addreceipt = $dbhw->prepare
    ('INSERT INTO EOSBET_DICE_RECEIPTS ' . 
     '(global_action_seq, block_num, block_time, trx_id, bettor, ' .
     ' curr_issuer, currency, bet_amt, payout, roll_under, random_roll) ' .
     'VALUES(?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE block_num=?');

my @addreceipt_columns =
    qw(global_action_seq block_num block_time trx_id bettor
       curr_issuer currency bet_amt payout roll_under random_roll
       block_num);

my $processing_date = '';
my $rowcnt = 0;

while(1)
{
    $sth_getreceipts->execute($diceacc, $rcpt_action, $block_num, $max_seq);

    my $r = $sth_getreceipts->fetchall_arrayref({});
    my $nrows = scalar(@{$r});
    last if $nrows == 0;
    
    foreach my $row (@{$r})
    {
        my $seq = $row->{'global_action_seq'};
        if( $seq > $max_seq )
        {
            $max_seq = $seq;
        }
        
        my $action = eval { $json->decode($row->{'jsdata'}) };
        if($@)
        {
            printf("Error reading JSON: SEQ=%d ACTION=%s ACTOR=%s\n",
                   $seq,
                   $row->{'action_name'}, $row->{'actor_account'});
            next;
        }        
        
        if( $row->{'bd'} ne $processing_date )
        {
            $processing_date = $row->{'bd'};
            print("Processing $processing_date\n");
        }

        my $data = $action->{'action_trace'}{'act'}{'data'};

        if( ref($data) ne 'HASH' )
        {
            printf("Unreadable data in %s\n", $row->{'trx_id'});
            next;
        }                                                         
        
        $row->{'bettor'} = $data->{'bettor'};
        $row->{'curr_issuer'} = $data->{'amt_contract'};
        my $asset = $data->{'bet_amt'};
        my ($amount, $currency) = split(/\s/, $asset);
        $row->{'currency'} = $currency;
        $row->{'bet_amt'} = $amount;
        $asset = $data->{'payout'};
        ($amount, $currency) = split(/\s/, $asset);
        $row->{'payout'} = $amount;
        $row->{'roll_under'} = $data->{'roll_under'};
        $row->{'random_roll'} = $data->{'random_roll'};
        
        my @args;
        foreach my $col (@addreceipt_columns)
        {
            push(@args, $row->{$col});
        }
        
        $sth_addreceipt->execute(@args);
        $block_num = $row->{'block_num'};
        $rowcnt++;
    }
    
    $dbhw->commit();
    print("$rowcnt\n");
}


$dbhr->disconnect();
$dbhw->disconnect();


