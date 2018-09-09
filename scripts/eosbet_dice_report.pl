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

my $c_tblheader = $workbook->set_custom_color(40, '#003366');

my $f_tblheader = $workbook->add_format
    ( bold => 1,
      bottom => 1,
      align => 'center',
      bg_color => $c_tblheader,
      color => 'white' ); 

my $f_datetime = $workbook->add_format(num_format => 'yyyy-mm-dd hh:mm:ss');
my $f_money = $workbook->add_format(num_format => '0.0000');


{
    my $col = 0;
    my $row = 0;

    my $worksheet = $workbook->add_worksheet('Intro');

    my $r = $dbh->selectall_arrayref
        ('SELECT COUNT(*), MIN(block_time), MAX(block_time), SUM(bet_amt), SUM(payout) ' .
         'FROM EOSBET_DICE_RECEIPTS ' . $where_condition);

    $r = $r->[0];
    
    $worksheet->set_column($col, $col, 40);
    $col++;
    $worksheet->set_column($col, $col, 20);
    $col++;

    $col = 0;
    $worksheet->write($row, $col, 'EOSBET Dice statistics report');
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'First transaction:');
    $col++;
    my $ts = $r->[1];
    $ts =~ s/\s/T/;
    $worksheet->write_date_time($row, $col, $ts, $f_datetime);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Last transaction:');
    $col++;
    $ts = $r->[2];
    $ts =~ s/\s/T/;
    $worksheet->write_date_time($row, $col, $ts, $f_datetime);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'Total transactions:');
    $col++;
    $worksheet->write_number($row, $col, $r->[0]);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'EOS received:');
    $col++;
    $worksheet->write_number($row, $col, $r->[3], $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'EOS sent:');
    $col++;
    $worksheet->write_number($row, $col, $r->[4], $f_money);
    $row++;

    $col = 0;
    $worksheet->write($row, $col, 'House edge, EOS:');
    $col++;
    $worksheet->write_number($row, $col, ($r->[3] - $r->[4]), $f_money);
    $row++;
}


sub add_series
{
    my $wsname = shift;
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
    $worksheet->write($row, $col, 'Random roll');
    $col++;
    $worksheet->write($row, $col, 'Count');
    $col++;
    $worksheet->write($row, $col, 'Average');
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

    $worksheet->write(2, 5, 'chi-squared test:');
    $worksheet->write_formula(2, 6, 'CHITEST(B$2:B$101,C$2:C$101)');
    
    $worksheet->write(3, 5, 'chi-squared confidence:');
    $worksheet->write_formula(3, 6, '=CHIDIST($G$3,100)');

    my $chart = $workbook->add_chart( type => 'scatter', subtype => 'markers_only', embedded => 1 );
    $chart->set_y_axis( min => 0 );
    $chart->set_size( width => 720, height => 576 );
    
    $chart->add_series(
        name => 'Count per roll',
        categories => '=' . $wsname . '!$A$2:$A$101',
        values     => '=' . $wsname . '!$B$2:$B$101',
        );
    
    $worksheet->insert_chart( 'F6', $chart );
}





add_series('All_rolls');

$dbh->disconnect();
$workbook->close();
print "Wrote $xlsx_out\n";



    
        
