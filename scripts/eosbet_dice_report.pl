use strict;
use warnings;
use JSON;
use Getopt::Long;
use DBI;
use Excel::Writer::XLSX; 
use Excel::Writer::XLSX::Utility;


my $dsn = 'DBI:mysql:database=eosgames;host=localhost';
my $db_user = 'eosgames';
my $db_password = 'Einie4xa';

my $xlsx_out;
my $enddate;

my $ok = GetOptions
    ('out=s'     => \$xlsx_out,
     'end=s'     => \$enddate,
     'dsn=s'     => \$dsn,
     'dbuser=s'  => \$db_user,
     'dbpw=s'    => \$db_password);


if( not $ok or scalar(@ARGV) > 0 or
    not defined($xlsx_out) or not defined($enddate) )
{
    print STDERR "Usage: $0 --out=FILE.xlsx --end=YYYY-MM-DD [options...]\n",
    "The utility generates EOSBET Dice report from SQL database\n",
    "Options:\n",
    "  --out=FILE.xlsx      output file\n",
    "  --end=YYYY-MM-DD     end date\n",
    "  --dsn=DSN            \[$dsn\]\n",
    "  --dbuser=USER        \[$db_user\]\n",
    "  --dbpw=PASSWORD      \[$db_password\]\n" ;
    exit 1;
}


my $dbh = DBI->connect($dsn, $db_user, $db_password,
                       {'RaiseError' => 1, AutoCommit => 0,
                        mysql_server_prepare => 1});
die($DBI::errstr) unless $dbh;

my $where_condition = ' WHERE block_time < DATE(\'' . $enddate . '\')';


my $workbook = Excel::Writer::XLSX->new($xlsx_out) or die($!);

my $f_descr = $workbook->add_format(size => 20, border => 0);

my $c_tblheader = $workbook->set_custom_color(40, '#003366');

my $f_tblheader = $workbook->add_format
    ( bold => 1,
      bottom => 1,
      align => 'center',
      bg_color => $c_tblheader,
      color => 'white' ); 

my $f_datetime = $workbook->add_format(num_format => 'yyyy-mm-dd hh:mm:ss');
my $f_money = $workbook->add_format(num_format => '0.0000');

my $f_boxtext = $workbook->add_format(
    size => 12,
    );

{
    my $col = 0;
    my $row = 0;

    my $worksheet = $workbook->add_worksheet('Intro');

    my $r = $dbh->selectall_arrayref
        ('SELECT COUNT(*), MIN(block_time), MAX(block_time), SUM(bet_amt), SUM(payout), ' .
         'COUNT(DISTINCT bettor), AVG(bet_amt), MAX(bet_amt), AVG(payout), MAX(payout) ' .
         'FROM EOSBET_DICE_RECEIPTS ' . $where_condition);

    my ($totalreceipts, $min_block_time, $max_block_time, $sum_bets, $sum_payouts,
        $n_bettor_accounts, $avg_bet, $max_bet, $avg_payout, $max_payout) = @{$r->[0]};
           
    $r = $dbh->selectall_arrayref
        ('SELECT COUNT(*) FROM EOSBET_DICE_RESOLVED_BETS ' . $where_condition);
    my $totalresolved = $r->[0][0];
    
    $worksheet->set_column($col, $col, 40);
    $col++;
    $worksheet->set_column($col, $col, 20);
    $col++;

    $col = 0;
    $worksheet->write($row, $col, 'EOSBET Dice fairness report');
    $row+=2;

    $col = 0;
    $worksheet->write($row, $col, 'First transaction:');
    $col++;
    my $ts = $min_block_time;
    $ts =~ s/\s/T/;
    $worksheet->write_date_time($row, $col, $ts, $f_datetime);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Last transaction:');
    $col++;
    $ts = $max_block_time;
    $ts =~ s/\s/T/;
    $worksheet->write_date_time($row, $col, $ts, $f_datetime);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Total resolvebet transactions:');
    $col++;
    $worksheet->write_number($row, $col, $totalresolved);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Total betreceipt transactions:');
    $col++;
    $worksheet->write_number($row, $col, $totalreceipts);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Number of lost betreceipt transactions:');
    $col++;
    $worksheet->write_number($row, $col, $totalresolved - $totalreceipts);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Percentage of lost betreceipt transactions:');
    $col++;
    $worksheet->write_number($row, $col, 100.0*($totalresolved-$totalreceipts)/$totalresolved );
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Total wagers, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $sum_bets, $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Total payouts, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $sum_payouts, $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Difference, EOS:');
    $col++;
    $worksheet->write_number($row, $col, ($sum_bets - $sum_payouts), $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Difference, percent:');
    $col++;
    $worksheet->write_number($row, $col, 100.0*($sum_bets - $sum_payouts)/$sum_bets);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Number of players:');
    $col++;
    $worksheet->write_number($row, $col, $n_bettor_accounts);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Average wager, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $avg_bet, $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Maximum wager, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $max_bet, $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Average payout, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $avg_payout, $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Maximum payout, EOS:');
    $col++;
    $worksheet->write_number($row, $col, $max_payout, $f_money);
    $row++;

    my $text =
        "This report is based on data exported by nodeos ZMQ plugin. " .
        "The script 'eosbet_dice_getdata.pl' is extracting all actions named " .
        "'betreceipt' and 'resolvebet' issued by smart contract 'eosbetdice11', " .
        "and stores them in a " .
        "separate database. After that, the script 'eosbet_dice_report.pl' generates " .
        "this Excel report.\n\n" .
        
        "The dice players are transferring EOS tokens to the 'eosbetdice11' " .
        "smart contract with roll_under number specified in memo. An external " .
        "oracle is calling 'betresolve' action and specifying a digital signarure " .
        "of the bet data by using the casino's private key. " .
        "The 'betresolve' action calculates the dice rolling result between 1 and 100 " .
        "from the signature bits, and if the result is above the roll_under number, " .
        "the player receives the payout in EOS.\n\n" .
        
        "At the end of processing, 'betresolve' generates a deferred action named " .
        "'betreceipt'. A small number of receipts is lost in EOS network because of " .
        "congestion.\n\n" .

        "The following two worksheets represent chi-squared test of dice rolls. This is a " .
        "standard statistical method that tests a game fairness and uniform statistical " .
        "distribution. The chi-squared confidence of 1 indicates that the random " .
        "distribution is completely uniform and not forged.\n\n" .

        "The report is generated from publicly available data on the blockchain, and with " .
        "open-source tools available on GitHub at https://github.com/cc32d9/eos_game_reports\n\n" .

        "Total processing of blockchain data as of end of September takes about 4 days on a modern " .
        "mid-range server.";
    
    $col = 0;
    $row++;
    my $shape = $workbook->add_shape
        ( type => 'rect', 'text' => $text,
          scale_x => 15, scale_y => 10,
          line => '000000', fill => 'FFFFFF',
          align => 'l', format => $f_boxtext,
        );
    $worksheet->insert_shape( $row, $col, $shape );
}


sub add_series
{
    my $wsname = shift;
    my $descr = shift;
    my $cond = shift;


    my $query =
        'SELECT random_roll, COUNT(*) ' .
        ' FROM EOSBET_DICE_RECEIPTS ' . $where_condition;
    if( defined($cond) )
    {
        $query .= ' AND ' . $cond . ' ';
    }
    $query .= ' GROUP BY random_roll ORDER BY random_roll ';


    my $series = {};
    map { $series->{$_} = 0 } (1..100);
    
    my $r = $dbh->selectall_arrayref($query);
    foreach my $dr (@{$r})
    {
        $series->{$dr->[0]} = $dr->[1];
    }
    
    my $col = 0;
    my $row = 0;

    my $worksheet = $workbook->add_worksheet($wsname);
    
    $worksheet->set_column($col, $col, 15);
    $col++;
    $worksheet->set_column($col, $col, 15);
    $col++;
    $worksheet->set_column(5, 5, 30);

    $col = 0;
    $worksheet->write($row, $col, 'Random roll', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Count', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Average', $f_tblheader);
    $row++;

    foreach my $roll (sort {$a<=>$b} keys %{$series})
    {
        $col = 0;
        $worksheet->write_number($row, $col, $roll);
        $col++;
        $worksheet->write_number($row, $col, $series->{$roll});
        $col++;
        $worksheet->write_formula($row, $col, '=AVERAGE(B$2:B$101)');
        $row++;
    }
    
    $worksheet->write('F4', 'chi-squared test:');
    $worksheet->write_formula('G4', 'CHITEST(B$2:B$101,C$2:C$101)');
    
    $worksheet->write('F5', 'chi-squared confidence:');
    $worksheet->write_formula('G5', '=CHIDIST($G$4,100)');

    my $chart = $workbook->add_chart( type => 'scatter', subtype => 'markers_only', embedded => 1 );
    $chart->set_y_axis( min => 0 );
    $chart->set_size( width => 720, height => 576 );
    
    $chart->add_series(
        name => 'Rolls per result',
        categories => '=' . $wsname . '!$A$2:$A$101',
        values     => '=' . $wsname . '!$B$2:$B$101',
        );
    
    $worksheet->insert_chart( 'F6', $chart );

    my $shape = $workbook->add_shape
        ( type => 'rect', text => $descr,
          scale_x => 15, scale_y => 0.8,
          line => 'FFFFFF',
          'format' => $f_descr );
    $worksheet->insert_shape( 'F1', $shape );
}


add_series('All_rolls', 'Count of all rolls per result');
add_series('500plus_rolls',
  'Count of rolls per result where wager is 500 EOS or higher',
  'bet_amt >= 500');

{
    my $col = 0;
    my $row = 0;

    my $worksheet = $workbook->add_worksheet('Winners_Losers');
    
    $worksheet->set_column($col, $col, 20);
    $col++;
    $worksheet->set_column($col, $col, 15);
    $col++;
    $worksheet->set_column($col, $col, 15);
    $col++;
    $worksheet->set_column($col, $col, 15);
    $col++;
    $worksheet->set_column($col, $col, 15);

    $col = 0;
    my $shape = $workbook->add_shape
        ( type => 'rect', text => 'Winners and losers',
          scale_x => 15, scale_y => 0.8,
          line => 'FFFFFF',
          'format' => $f_descr );
    $worksheet->insert_shape( $row, $col, $shape );
    $row += 3;
    
    $col = 0;
    $worksheet->write($row, $col, 'Name', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Rolls', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Wagers, EOS', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Payouts, EOS', $f_tblheader);
    $col++;
    $worksheet->write($row, $col, 'Profit, EOS', $f_tblheader);
    $row++;


    my $r = $dbh->selectall_arrayref
        ('SELECT bettor, COUNT(*), SUM(bet_amt), SUM(payout), SUM(payout)-SUM(bet_amt) ' .
         'FROM EOSBET_DICE_RECEIPTS ' . $where_condition .
         'GROUP BY bettor ORDER BY SUM(payout)-SUM(bet_amt) DESC');
    foreach my $dr (@{$r})
    {
        $col = 0;
        $worksheet->write($row, $col, $dr->[0]);
        $col++;
        $worksheet->write_number($row, $col, $dr->[1]);
        $col++;
        $worksheet->write_number($row, $col, $dr->[2], $f_money);
        $col++;
        $worksheet->write_number($row, $col, $dr->[3], $f_money);        
        $col++;
        $worksheet->write_number($row, $col, $dr->[4], $f_money);
        $row++;
    }
}


$dbh->disconnect();
$workbook->close();
print "Wrote $xlsx_out\n";



    
        
