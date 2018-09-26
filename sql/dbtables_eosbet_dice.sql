use eosgames;

CREATE TABLE EOSBET_DICE_RESOLVED_BETS
(
 global_action_seq BIGINT PRIMARY KEY,
 block_num BIGINT NOT NULL,
 block_time DATETIME NOT NULL,
 trx_id VARCHAR(64) NOT NULL
)  ENGINE=InnoDB;

CREATE INDEX EOSBET_DICE_RESOLVED_BETS_I01 ON EOSBET_DICE_RESOLVED_BETS (block_num);
CREATE INDEX EOSBET_DICE_RESOLVED_BETS_I02 ON EOSBET_DICE_RESOLVED_BETS (block_time);
CREATE INDEX EOSBET_DICE_RESOLVED_BETS_I03 ON EOSBET_DICE_RESOLVED_BETS (trx_id(8));


CREATE TABLE EOSBET_DICE_RECEIPTS
(
 global_action_seq BIGINT PRIMARY KEY,
 block_num BIGINT NOT NULL,
 block_time DATETIME NOT NULL,
 trx_id VARCHAR(64) NOT NULL,
 bettor VARCHAR(13) NOT NULL,
 curr_issuer VARCHAR(13) NOT NULL,
 currency VARCHAR(8) NOT NULL,
 bet_amt DOUBLE PRECISION NOT NULL,
 payout  DOUBLE PRECISION NOT NULL,
 roll_under INTEGER NOT NULL,
 random_roll INTEGER NOT NULL
)  ENGINE=InnoDB;

CREATE INDEX EOSBET_DICE_RECEIPTS_I01 ON EOSBET_DICE_RECEIPTS (block_num);
CREATE INDEX EOSBET_DICE_RECEIPTS_I02 ON EOSBET_DICE_RECEIPTS (block_time);
CREATE INDEX EOSBET_DICE_RECEIPTS_I03 ON EOSBET_DICE_RECEIPTS (trx_id(8));
CREATE INDEX EOSBET_DICE_RECEIPTS_I04 ON EOSBET_DICE_RECEIPTS (bettor, block_time);
CREATE INDEX EOSBET_DICE_RECEIPTS_I05 ON EOSBET_DICE_RECEIPTS (bet_amt, payout);
CREATE INDEX EOSBET_DICE_RECEIPTS_I06 ON EOSBET_DICE_RECEIPTS (payout);
CREATE INDEX EOSBET_DICE_RECEIPTS_I07 ON EOSBET_DICE_RECEIPTS (bettor, bet_amt);
CREATE INDEX EOSBET_DICE_RECEIPTS_I08 ON EOSBET_DICE_RECEIPTS (bettor, payout);
CREATE INDEX EOSBET_DICE_RECEIPTS_I09 ON EOSBET_DICE_RECEIPTS (bettor, roll_under);
CREATE INDEX EOSBET_DICE_RECEIPTS_I10 ON EOSBET_DICE_RECEIPTS (bettor, random_roll);
CREATE INDEX EOSBET_DICE_RECEIPTS_I11 ON EOSBET_DICE_RECEIPTS (roll_under,random_roll);
CREATE INDEX EOSBET_DICE_RECEIPTS_I12 ON EOSBET_DICE_RECEIPTS (random_roll,roll_under);

