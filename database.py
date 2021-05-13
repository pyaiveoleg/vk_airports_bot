import json
from sqlalchemy import create_engine
from sqlalchemy import Column, String, Integer, Date, Time, Interval
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session
from sqlalchemy import func
from datetime import datetime
from phrases import days_of_week


base = declarative_base()


def result_dict(r):
    return dict(zip(r.keys(), r))


def result_dicts(rs):
    return list(map(result_dict, rs))


class Schedule(base):
    __tablename__ = 'schedule'

    flight_number = Column(Integer, primary_key=True)
    aircraft_type = Column(String)
    departure = Column(String)
    destination = Column(String)
    weekday_number = Column(Integer)
    departure_time = Column(Time)
    flight_time = Column(Interval)
    flight_cost = Column(Integer)


class AvailableTickets(base):
    __tablename__ = 'available_tickets'

    flight_number = Column(Integer, primary_key=True)
    departure_date = Column(Date, primary_key=True)
    tickets_overall = Column(Integer)
    tickets_available = Column(Integer)


class Passengers(base):
    __tablename__ = 'passengers'

    passport = Column(String, primary_key=True)
    surname = Column(String)
    name = Column(String)
    patronymic = Column(String)
    flight_number = Column(Integer)
    departure_date = Column(Date)


class Archive(base):
    __tablename__ = 'archive'

    flight_number = Column(Integer, primary_key=True)
    departure_date = Column(Date, primary_key = True)
    tickets_overall = Column(Integer)
    tickets_sold = Column(Integer)


class DbSession(object):
    def __init__(self, Session, with_commit=False):
        self.Session = Session
        self.with_commit = with_commit

    def __enter__(self):
        self.session = self.Session()
        return self.session

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.with_commit:
            self.session.commit()
        self.session.close()


class Database:
    def __init__(self):
        with open('config.json') as config_file:
            config = json.loads(config_file.read())['db']
        self.engine = create_engine('postgresql://{}:{}@{}/{}'.format(config['user'], config['password'],
                                                                      config['host'], config['db_name']))
        session_factory = sessionmaker(self.engine)
        self.Session = scoped_session(session_factory)
        base.metadata.create_all(self.engine)

    def get_schedule(self):
        with DbSession(self.Session) as session:
            string = ""
            for ob in session.query(Schedule).all():
                string += f"Номер рейса: {ob.flight_number}, {ob.departure} {ob.destination} {days_of_week[ob.weekday_number]}, Вылет: {ob.departure_time}, Время полёта: {ob.flight_time}\n"
            return string

    def add_passenger(self, passport, name, surname, patronymic, flight_number, date):
        with DbSession(self.Session, with_commit=True) as session:
            new_record = Passengers(
                passport=passport,
                name=name,
                surname=surname,
                patronymic=patronymic,
                flight_number=flight_number,
                departure_date=date
            )
            session.add(new_record)

    def remove_passenger(self, passport, name, surname, patronymic, flight_number, date):
        with DbSession(self.Session, with_commit=True) as session:
            session.query(Passengers).filter(
                Passengers.passport == passport,
                Passengers.name == name,
                Passengers.surname == surname,
                Passengers.patronymic == patronymic,
                Passengers.flight_number == flight_number,
                Passengers.departure_date == date
            ).delete(synchronize_session='fetch')

    @staticmethod
    def print_flights(query_object):
        string = ""
        for flight in query_object:
            string += f"Номер рейса: {flight.flight_number}, День недели: {days_of_week[flight.weekday_number]}, Время вылета: {flight.departure_time}, Время в пути: {flight.flight_time}\n"
        return string or "Не найдено подходящих рейсов."

    def find_direct_flights(self, departure, destination):
        with DbSession(self.Session) as session:
            return self.print_flights(session.query(Schedule).filter(
                Schedule.departure == departure, Schedule.destination == destination
            ).all())

    @staticmethod
    def print_all_flights(query_object):
        string = ""
        for flight in query_object:
            tup = flight[0].replace(")", "").replace("(", "").split(",")
            string += f"{tup[0]} -> {tup[1]} {' -> ' + tup[2] if tup[2] else ''}, Время в пути: {tup[3]}\n"
        return string or "Не найдено подходящих рейсов."

    def find_all_flights(self, departure, destination, date=datetime.today().strftime('%d.%m.%Y')):
        with DbSession(self.Session) as session:
            query_object = session.query(func.public.select_flights(
                departure, destination, date)
            ).all()
            return self.print_all_flights(query_object)
