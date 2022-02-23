#if !CONFIG_INCLUDED
#define CONFIG_INCLUDED

///RU \file
///RU @brief Конфигурация контракта (ключи компиляции)
///RU @attention Файл должен быть подключен в проект ДО всего остального
///EN \file
///EN @brief Configuration of contract (compilation options)
///EN @attention File must be included to project BEFORE all other files

///RU У контракта есть владелец
///RU
///RU Владелец обладает всеми правами админа + может сменить владельца
///EN Contract has owner
///EN
///EN Owner can do all as admin and change admin
#define ENABLE_OWNER

///RU У контракта есть админ
///RU Полный доступ ко всем операциям, кроме смены владельца
///EN Contract has admin
///EN Full access to all contract method, exclude change of owner
#define ENABLE_ADMIN

///RU У контракта есть набор админов
///RU
///RU Полный доступ ко всем операциям (включая добавление/удаление других админов]), кроме смены владельца
///EN Contract has set of admins
///EN
///EN Full access to all contract method (include add/remove admins), exclude change of owner
//#define ENABLE_ADMINS

#if (ENABLE_ADMIN) && (ENABLE_ADMINS)
    ///RU Необходимы либо ENABLE_ADMIN, либо ENABLE_ADMINS, но не оба сразу
    ///EN Must be ENABLE_ADMIN or ENABLE_ADMINS, not together
    const cteAdminOrAdmins: compileTimeError = "Compile time error: Must be ENABLE_ADMIN or ENABLE_ADMINS, not together";
#endif

#if (!ENABLE_OWNER) && (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
    ///RU Необходимы либо ENABLE_OWNER, либо ENABLE_ADMIN, либо ENABLE_ADMINS
    ///EN Must be ENABLE_OWNER or ENABLE_ADMIN or ENABLE_ADMINS
    const cteOwnerOrAdmins: compileTimeError = "Compile time error: Must be ENABLE_OWNER or ENABLE_ADMIN or ENABLE_ADMINS";
#endif

///RU Статистика работы пула для продвижения: объем выплат, кол-во розыгрышей и т.д.
///EN Statistic of pool for promotion: volume of rewards, count of games and so on
//#define ENABLE_POOL_STAT

///RU Сгенерировать view для просмотра основной информации пула по его ID из других контрактов
///EN Make view method for show main options of pool by ID for call from another contracts
//#define ENABLE_POOL_VIEW

///RU У пулов есть менеджеры (админ одного пула)
///RU
///RU Менеджер может управлять своим пулом и менять менеджера. Необходимо для ENABLE_POOL_AS_SERVICE
#define ENABLE_POOL_MANAGER

///RU Пулы для розыгрышей как сервис
///RU
///RU Создать пул может любой, он и будет его единственным админом, владелец и админы контракта не будут иметь доступа к пулу
#define ENABLE_POOL_AS_SERVICE

#if (ENABLE_POOL_AS_SERVICE) && (!ENABLE_POOL_MANAGER)
    ///RU Необходим ENABLE_POOL_MANAGER, если включен ENABLE_POOL_AS_SERVICE
    ///EN Must be defined ENABLE_POOL_MANAGER, when ENABLE_POOL_AS_SERVICE
    const cteManagerForService: compileTimeError = "Compile time error: Must be ENABLE_POOL_MANAGER, when ENABLE_POOL_AS_SERVICE";
#endif

///RU По возможности максимально защищенный перевод токенов
///RU
///RU Если включено, при переводе токенов сначала делается approve AMOUNT|add_operator, после перевода approve 0|remove_operator.
///RU Если выключено, однократно включается approve MAXAMOUNT|add_operator и более не отзывается
//#define ENABLE_TRANSFER_SECURITY

///RU Сгенерировать view для баланса пользователя в пуле
///EN Make view method for return balance of user in pool
#define ENABLE_BALANCE_VIEW

[@inline] const cMIN_GAME_SECONDS: nat = 10n * 60n;///RU< Минимальное кол-во секунд для партии ///EN< Minimal seconds for game
[@inline] const cMAX_GAME_SECONDS: nat = 10n * 86400n;///RU< Максимальное кол-во секунд для партии ///EN< Maximum seconds for game

#endif // !CONFIG_INCLUDED
