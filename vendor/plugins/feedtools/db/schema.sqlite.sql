-- Example Sqlite schema
  CREATE TABLE cached_feeds (
    id                INTEGER PRIMARY KEY NOT NULL,
    href              VARCHAR(255) DEFAULT NULL,
    title             VARCHAR(255) DEFAULT NULL,
    link              VARCHAR(255) DEFAULT NULL,
    feed_data         TEXT DEFAULT NULL,
    feed_data_type    VARCHAR(20) DEFAULT NULL,
    http_headers      TEXT DEFAULT NULL,
    last_retrieved    DATETIME DEFAULT NULL,
    time_to_live      INTEGER DEFAULT NULL,
    serialized        TEXT DEFAULT NULL
  );
