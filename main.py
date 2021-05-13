from vk_bot import VkBot
import threading

vk_bot = VkBot()


def vk_start():
    vk_bot.run()


thread_for_bot = threading.Thread(target=vk_start)
thread_for_bot.start()
