-- 1. Скидка для часто летающих пассажиров
CREATE OR REPLACE VIEW discounts AS
WITH flights_quantity_table AS 
	(SELECT name, surname, patronymic, passport, COUNT(*) AS flights_quantity 
	FROM passengers 
	GROUP BY name, surname, patronymic, passport)
SELECT name, surname, patronymic, passport, CASE
WHEN flights_quantity >= 50 THEN 20
ELSE (flights_quantity / 10) * 5
END AS discount
FROM flights_quantity_table;

-- 2. Самое выгодное предложение по цене
CREATE OR REPLACE FUNCTION find_cheap_flight(
	departure_point schedule.departure%TYPE, 
	destination_point schedule.destination%TYPE,
	flight_date DATE
) RETURNS TABLE(
	first_flight schedule.flight_number%TYPE,
	second_flight schedule.flight_number%TYPE,
	flight_cost schedule.flight_cost%TYPE
)
LANGUAGE plpgsql AS
$$
BEGIN
	RETURN QUERY
		(SELECT A.flight_number AS first_flight, B.flight_number AS second_flight, (A.flight_cost + B.flight_cost) AS flight_cost
		FROM schedule A JOIN schedule B 
		ON (A.destination = B.departure) and (A.departure = departure_point) and (B.destination = destination_point)
		ORDER BY flight_cost ASC)
		UNION
		(SELECT flight_number as first_flight, null as second_flight, schedule.flight_cost FROM schedule WHERE departure = departure_point and destination = destination_point);
END;
$$;

SELECT * FROM find_cheap_flight('SLK', 'KUF', '12.05.2021');

-- 3. Средняя заполняемость самолёта из пункта А в пункт Б по месяцам
WITH occupancy_table AS 
	(SELECT CAST(archive.tickets_sold AS float) / archive.tickets_overall AS occupancy, to_char(departure_date, 'MM') AS flight_month 
	FROM archive NATURAL JOIN schedule 
	WHERE (schedule.departure = 'LED') and (schedule.destination = 'MUC'))
SELECT AVG(occupancy), flight_month FROM occupancy_table GROUP BY flight_month;

