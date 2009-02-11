-- Example PostgreSQL schema
  CREATE TABLE cached_feeds (
    id                SERIAL PRIMARY KEY NOT NULL,
    href              varchar(255) default NULL,
    title             varchar(255) default NULL,
    link              varchar(255) default NULL,
    feed_data         text default NULL,
    feed_data_type    varchar(20) default NULL,
    http_headers      text default NULL,
    last_retrieved    timestamp default NULL,
    time_to_live      integer(10) default NULL,
    serialized        text default NULL
  );
