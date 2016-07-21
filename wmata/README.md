Ingest for WMATA (Washington D.C. Metro)

https://developer.wmata.com/


# SQL

The SQL for the wmata database is in wmata.sql.  It is quick and dirty but works to get the data in.

# getMovements.pl

Ingest data into Redis first.  I like to separate ingest from processing so that a glitch in processing does not affect ingest.

# processMovement.pl

Pull data from Redis and move it to a Postgres Database


