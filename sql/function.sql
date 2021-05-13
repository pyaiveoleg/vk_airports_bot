CREATE OR REPLACE VIEW transfer_time_view AS
	WITH temp AS (
		SELECT A.flight_number AS first_flight, 
		B.flight_number AS second_flight, 
		(B.weekday_number - A.weekday_number) * INTERVAL '24' hour + CAST(B.departure_time - A.departure_time - A.flight_time AS INTERVAL) AS transfer_time 
		FROM schedule A JOIN schedule B ON A.destination = B.departure)
	SELECT first_flight, second_flight, CASE
	WHEN transfer_time < interval '0' hour THEN transfer_time + interval '168' hour
	ELSE transfer_time
	END as transfer_time
	FROM temp;

----------------------------------------------------------------
CREATE OR REPLACE FUNCTION select_flights(
	departure_point schedule.departure%TYPE, 
	destination_point schedule.destination%TYPE, 
	flight_date DATE
) RETURNS TABLE(
	first_flight INT,
	second_flight INT,
	third_flight INT,
	flight_time INTERVAL
)
LANGUAGE plpgsql AS
$$
BEGIN
	RETURN QUERY
		WITH one_transfer AS 
			(SELECT A.flight_number AS first_flight, A.flight_time AS first_flight_time, B.flight_number AS second_flight, B.flight_time as second_flight_time FROM schedule A JOIN schedule B 
			ON (A.destination = B.departure) and (A.departure = departure_point) and (B.destination = destination_point) and (A.weekday_number = extract(isodow from flight_date))),
		two_transfers AS
			(SELECT A.flight_number AS first_flight, A.flight_time AS first_flight_time,
			B.flight_number AS second_flight, B.flight_time as second_flight_time,
			C.flight_number AS third_flight, C.flight_time as third_flight_time 
			FROM schedule A JOIN schedule B ON (A.destination = B.departure) JOIN schedule C
			ON (A.departure = departure_point) and (B.destination = C.departure) and (C.destination = destination_point) and (A.weekday_number = extract(isodow from flight_date))
			)
		(
		SELECT one_transfer.first_flight, one_transfer.second_flight, cast(null as integer) AS third_flight, 
			first_flight_time + transfer_time + second_flight_time AS flight_time
		FROM one_transfer NATURAL JOIN transfer_time_view
		)
		UNION
		(
		SELECT two_transfers.first_flight, two_transfers.second_flight, two_transfers.third_flight, 
			first_flight_time + A.transfer_time + second_flight_time + third_flight_time AS flight_time
		FROM two_transfers NATURAL JOIN transfer_time_view A JOIN transfer_time_view B ON two_transfers.second_flight = B.first_flight and two_transfers.third_flight = B.second_flight
		)
		ORDER BY flight_time ASC;
END;
$$;

SELECT * FROM select_flights('VKO', 'MUC', '10.05.2021');
