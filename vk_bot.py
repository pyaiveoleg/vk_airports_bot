import json
import random
import vk_api
import requests
from vk_api.longpoll import VkLongPoll, VkEventType
from vk_api import VkUpload
from phrases import phrases
from database import Database


def print_help():
    return """
    Добро пожаловать в авиакомпанию "Гордость МатМеха"! Здесь вы можете:
    Ознакомиться с актуальным расписанием, "/рейсы"
    Записаться на рейс: "/запись [Номер паспорта] [Фамилия] [Имя] [Отчество] [Номер рейса] [Дата]"
    Отменить запись на рейс: "/отменить_запись [Номер паспорта] [Фамилия] [Имя] [Отчество] [Номер рейса] [Дата]"
    Посмотреть прямые рейсы из одного интересующего города в другой: "/прямые_рейсы [Город N] [Город M]"
    Посмотреть прямые рейсы с пересадками из одного интересующего города в другой: "/рейсы_с_пересадками [Город N] [Город M]"
    Получить помощь, "/справка"
    """


class VkBot:
    def __init__(self):
        with open('config.json') as config_file:
            vk_bot_config = json.loads(config_file.read())['vk_bot']
        self.session = requests.Session()
        vk_session = vk_api.VkApi(token=vk_bot_config['token'])
        self.longpoll = VkLongPoll(vk_session)
        self.vk = vk_session.get_api()
        self.upload = VkUpload(vk_session)
        self.db = Database()

    def send_message(self, user_id, message="", template=None, keyboard=None):
        if template is None:
            template = {}
        self.vk.messages.send(
            user_id=user_id,
            message=message,
            random_id=random.randint(0, 4294967290),
            template=template,
            keyboard=keyboard
        )

    def run(self):
        for event in self.longpoll.listen():
            if event.type == VkEventType.MESSAGE_NEW and event.to_me and event.text:
                # user_id = event.user_id
                self.handle_event(event)

    def handle_event(self, event):
        try:
            if event.text == phrases["get_schedule"]:
                message = self.db.get_schedule()
            elif phrases["add_passenger"] in event.text:
                self.db.add_passenger(*event.text.split()[1:])
                message = phrases["success"]
            elif phrases["remove_passenger"] in event.text:
                self.db.remove_passenger(*event.text.split()[1:])
                message = phrases["success"]
            elif phrases["direct_flights"] in event.text:
                message = self.db.find_direct_flights(*event.text.split()[1:])
            elif phrases["all_flights"] in event.text:
                message = self.db.find_all_flights(*event.text.split()[1:])
            elif phrases["help"] in event.text:
                message = print_help()
            elif event.text == "/зенит":
                message = "Чемпион!"
            else:
                message = phrases["failure"]
        except Exception:
            message = phrases["exec_fail"]

        self.send_message(event.user_id, message)
