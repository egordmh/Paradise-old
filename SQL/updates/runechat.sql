#Updating the SQL for runechat
#Adding new columns to contain the runechat values.
<<<<<<< HEAD
ALTER TABLE `player` ADD `max_chat_length` tinyint(1) DEFAULT '110' AFTER `byond_date`;
=======
ALTER TABLE `player` ADD `max_chat_length` tinyint(1) DEFAULT '110' AFTER `parallax`;
>>>>>>> 2373ca292a... Перенос чата над персонажем с ТГ
ALTER TABLE `player` ADD `chat_on_map` tinyint(1) DEFAULT '1' AFTER `max_chat_length`;
ALTER TABLE `player` ADD `see_chat_non_mob` tinyint(1) DEFAULT '1' AFTER `chat_on_map`;
