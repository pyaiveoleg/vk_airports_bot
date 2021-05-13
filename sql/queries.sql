1.
SELECT COUNT(*) AS tickets_quantity 
FROM passengers NATURAL JOIN schedule 
WHERE departure_date >= NOW() - INTERVAL '1' Month AND schedule.departure = 'LED' AND schedule.destination = 'MUC';

2.
WITH quantity_of_flights AS 
	(SELECT name, surname, patronymic, COUNT(*) AS flights_quantity FROM passengers GROUP BY passport, name, surname, patronymic)
SELECT * FROM quantity_of_flights ORDER BY flights_quantity DESC LIMIT(10);

3. 
WITH destination_frequency AS 
	(SELECT destination, COUNT(*) AS frequency FROM passengers NATURAL JOIN schedule WHERE schedule.departure = 'LED' GROUP BY schedule.destination ORDER BY frequency)
SELECT destination FROM destination_frequency WHERE frequency IN (SELECT MAX(frequency) FROM destination_frequency);

4. 
WITH flight_info AS 
	(SELECT DISTINCT * FROM passengers NATURAL JOIN schedule),
	temp AS 
	(SELECT DISTINCT A.departure AS start_point, A.destination AS transfer_point, B.destination AS end_point FROM flight_info A join flight_info B ON (B.departure = A.destination) AND (A.passport = B.passport)),
frequencies_table AS
	(SELECT transfer_point, COUNT(*) AS frequency FROM temp
	GROUP BY transfer_point
	ORDER BY frequency DESC)
SELECT transfer_point FROM frequencies_table WHERE frequency IN (SELECT MAX(frequency) FROM frequencies_table);

5. 
WITH flight_info AS 
	(SELECT DISTINCT * FROM passengers NATURAL JOIN schedule),
	temp AS 
	(SELECT A.flight_number as first_flight, B.flight_number AS second_flight FROM flight_info A join flight_info B ON (B.departure = A.destination) AND (A.passport = B.passport) AND (A.departure_date > NOW() - INTERVAL '3' month))
	SELECT AVG(transfer_time) FROM temp NATURAL JOIN transfer_time_view;