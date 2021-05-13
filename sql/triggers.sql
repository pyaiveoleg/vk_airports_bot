-- 1. Проверять, что дата вылета в available_tickets действительно нужного дня недели
CREATE OR REPLACE FUNCTION check_weekday() RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
	IF extract(isodow from NEW.departure_date) NOT IN (SELECT weekday_number FROM schedule WHERE flight_number = NEW.flight_number) THEN
		RAISE EXCEPTION 'weekday of date is not equal to weekdate in schedule';
    END IF;
	RETURN NEW;
END;
$$;
CREATE TRIGGER check_weekday_trigger
    AFTER INSERT OR UPDATE
    ON passengers
    FOR EACH ROW
EXECUTE PROCEDURE check_weekday();


-- 2. Изменять количество свободных мест с помощью триггера
CREATE OR REPLACE FUNCTION sell_ticket() RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
	IF (tg_op = 'INSERT') THEN
		UPDATE available_tickets
		SET tickets_available = tickets_available - 1 WHERE flight_number = NEW.flight_number;
		RETURN NEW;
    ELSIF (tg_op = 'DELETE') THEN
        UPDATE available_tickets
		SET tickets_available = tickets_available + 1 WHERE flight_number = OLD.flight_number;
		RETURN OLD;
    END IF;
END;
$$;
CREATE TRIGGER sell_ticket_trigger
    AFTER INSERT OR DELETE
    ON passengers
    FOR EACH ROW
EXECUTE PROCEDURE sell_ticket();