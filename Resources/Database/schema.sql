CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY,
    vendor_id INTEGER,
    product_id INTEGER,
    vendor_name TEXT,
    product_name TEXT,
    device_class TEXT,
    speed TEXT,
    serial_number TEXT
);

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT,
    event_type TEXT,
    timestamp DATETIME,
    location_id INTEGER,
    properties JSON,
    FOREIGN KEY(device_id) REFERENCES devices(id)
);

CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_device ON events(device_id);
