CREATE TABLE schedule(
	flight_number INT PRIMARY KEY NOT NULL,
	aircraft_type VARCHAR NOT NULL,
	departure CHAR(3) NOT NULL,  -- Код аэропорта состоит из 3 латинских букв
	destination CHAR(3) NOT NULL,
	weekday_number INT CONSTRAINT day_of_week CHECK(weekday_number >= 1 AND weekday_number <= 7) NOT NULL,
	departure_time TIME NOT NULL,  -- in UTC time
	flight_time INTERVAL NOT NULL,
	flight_cost NUMERIC NOT NULL
);

CREATE TABLE available_tickets(
	flight_number INT NOT NULL REFERENCES schedule(flight_number),
	departure_date DATE NOT NULL,
	tickets_overall INT NOT NULL,
	tickets_available INT CONSTRAINT available_tickets CHECK(tickets_available <= tickets_overall) NOT NULL,
	PRIMARY KEY (flight_number, departure_date)
);

CREATE TABLE passengers(
	passport CHAR(10) NOT NULL,
	surname VARCHAR NOT NULL,
	name VARCHAR NOT NULL,
	patronymic VARCHAR NOT NULL,
	flight_number INT NOT NULL REFERENCES schedule(flight_number) NOT NULL,
	departure_date DATE NOT NULL
);

CREATE TABLE archive(
	flight_number INT REFERENCES schedule(flight_number) NOT NULL,
	departure_date DATE NOT NULL,
	tickets_overall INT NOT NULL,
	tickets_sold INT CONSTRAINT sold_tickets CHECK(tickets_sold <= tickets_overall) NOT NULL
);