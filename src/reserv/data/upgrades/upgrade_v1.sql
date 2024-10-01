ALTER TABLE user
ADD status TEXT NOT NULL
DEFAULT "active" CHECK(
	status = "active" OR
	status = "inactive" OR
	status = "terminated"
);

ALTER TABLE user RENAME COLUMN userid to user_id;

ALTER TABLE user RENAME COLUMN displayname to display_name;

ALTER TABLE schedule RENAME COLUMN userid to user_id;

CREATE TABLE IF NOT EXISTS role (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT,
    "desc"  TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS permission (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT NOT NULL,
    "desc"  TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);

CREATE TABLE IF NOT EXISTS role_permission (
	"role_id"	INTEGER NOT NULL,
	"permission_id"	INTEGER NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_role (
	"user_id"	INTEGER NOT NULL,
	"role_id"	INTEGER NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

INSERT OR IGNORE INTO role (id, name, desc) VALUES 
(1, "admin", "Can view the schedule and manage all bookings"),
(2, "user", "Can view the schedule and manage their own bookings"),
(3, "guest", "Can only view the schedule");

INSERT OR IGNORE INTO permission (id, name, desc) VALUES 
(1, "manage", "Can make/cancel all bookings to the schedule"),
(2, "book", "Can make/cancel their own bookings to the schedule"),
(3, "view", "Can view the schedule");

INSERT OR IGNORE INTO role_permission (role_id, permission_id) VALUES 
(1, 1), (1, 3),
(2, 2), (2, 3),
(3, 3);

DROP TABLE IF EXISTS archive;

CREATE TABLE user_new (
	"user_id" TEXT NOT NULL UNIQUE,
    "created_on" TEXT NOT NULL CHECK(date("created_on")) DEFAULT (
        strftime('%Y-%m-%d %H:%M:%S', 'now')
    ),
    "updated_on" TEXT NOT NULL CHECK(date("updated_on")) DEFAULT (
        strftime('%Y-%m-%d %H:%M:%S', 'now')
    ),
	"display_name" TEXT UNIQUE,
	"password" TEXT,
	"status" TEXT NOT NULL DEFAULT "active" CHECK(
		status = "active" OR
		status = "inactive" OR
		status = "terminated"
	),
	PRIMARY KEY("user_id")
);

INSERT INTO user_new(user_id, display_name, password, status) SELECT * FROM user;

DROP TABLE user;
ALTER TABLE user_new RENAME TO user;

CREATE TRIGGER user_updated_on_update
    BEFORE UPDATE ON user
BEGIN
    UPDATE user
    SET updated_on = strftime('%Y-%m-%d %H:%M:%S', 'now') 
    WHERE user_id = old.user_id;
END;

CREATE TRIGGER user_created_on_immutable
    BEFORE UPDATE OF created_on ON user
BEGIN
    SELECT RAISE(FAIL, "Created on is read only");
END;

CREATE TABLE schedule_new (
    "date"	TEXT NOT NULL CHECK(date("date") IS NOT NULL) UNIQUE,
    "created_on" TEXT NOT NULL CHECK(date("created_on")) DEFAULT (
        strftime('%Y-%m-%d %H:%M:%S', 'now')
    ),
    "updated_on" TEXT NOT NULL CHECK(date("updated_on")) DEFAULT (
        strftime('%Y-%m-%d %H:%M:%S', 'now')
    ),
    "user_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT "booked" CHECK(
        status = "booked" OR
        status = "cancelled"
    ),
	PRIMARY KEY("date")
);

INSERT INTO schedule_new(date, user_id) SELECT * FROM schedule;

DROP TABLE schedule;
ALTER TABLE schedule_new RENAME TO schedule;

CREATE TRIGGER schedule_updated_on_update
    BEFORE UPDATE ON schedule
BEGIN
    UPDATE schedule
    SET updated_on = strftime('%Y-%m-%d %H:%M:%S', 'now') 
    WHERE date = old.date;
END;

CREATE TRIGGER schedule_created_on_immutable
    BEFORE UPDATE OF created_on ON schedule
BEGIN
    SELECT RAISE(FAIL, "Created on is read only");
END;