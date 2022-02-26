#if !CONFIG_INCLUDED
#define CONFIG_INCLUDED

///RU \file
///RU \brief Конфигурация контракта (ключи компиляции)
///RU \attention Файл должен быть подключен в проект ДО всего остального
///EN \file
///EN \brief Configuration of contract (compilation options)
///EN \attention File must be included to project BEFORE all other files

///RU У контракта есть владелец
///RU
///RU Владелец обладает всеми правами админа + может сменить владельца
///EN Contract has owner
///EN
///EN Owner can do all as admin and change admin
/// \see MOwner::isOwner, MOwner::mustOwner
#define ENABLE_OWNER

///RU У контракта есть админ
///RU
///RU Полный доступ ко всем операциям, кроме смены владельца
///EN Contract has admin
///EN
///EN Full access to all contract method, except change of owner
/// \see isAdmin, mustAdmin
#define ENABLE_ADMIN

///RU У контракта есть набор админов
///RU
///RU Полный доступ ко всем операциям (включая добавление/удаление других админов]), кроме смены владельца
///EN Contract has set of admins
///EN
///EN Full access to all contract method (include add/remove admins), except change of owner
/// \see isAdmin, mustAdmin
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
/// \see MPoolStat, t_stat
//#define ENABLE_POOL_STAT

///RU Сгенерировать view для просмотра основной информации пула по его ID из других контрактов
///EN Make view method for show main options of pool by ID for call from another contracts
/// \see viewPoolInfo, MPools::viewPoolInfo, t_pool_info
//#define ENABLE_POOL_VIEW

///RU У пулов есть менеджеры (админ одного пула)
///RU
///RU Менеджер может управлять своим пулом и менять менеджера. Необходимо для ENABLE_POOL_AS_SERVICE
///EN Managers for pools (admin of one pool)
///EN
///EN Manager can control his pool and change manager. Required for ENABLE_POOL_AS_SERVICE
/// \see ENABLE_POOL_AS_SERVICE, ChangePoolManager, MPools::changePoolManager
#define ENABLE_POOL_MANAGER

///RU Пулы для розыгрыша вознаграждений как сервис
///RU
///RU Создать пул может любой, он и будет его единственным админом, владелец и админы контракта не будут иметь доступа к пулу
///EN Reward draw pools as a service
///EN
///EN Anybody can create pool, and he will be it alone admin, owner of contract and admins of contract has no access to pool
/// \see CreatePool
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
///EN As far as possible, the most secure transfer of tokens
///EN
///EN If enabled, when transferring tokens, approve AMOUNT|add_operator is done first, after transfer, approve 0|remove_operator.
///EN If disabled, approve MAXAMOUNT|add_operator is enabled once and is no longer revoked
/// \see MPools::deposit, MFarm::deposit, t_storage.approved
//#define ENABLE_TRANSFER_SECURITY

///RU Сгенерировать view для баланса пользователя в пуле
///EN Make view method for return balance of user in pool
/// \see viewBalance
#define ENABLE_BALANCE_VIEW

[@inline] const cMIN_GAME_SECONDS: nat = 10n * 60n;///RU< Минимальное кол-во секунд для партии ///EN< Minimal seconds for game
[@inline] const cMAX_GAME_SECONDS: nat = 10n * 86400n;///RU< Максимальное кол-во секунд для партии ///EN< Maximum seconds for game

#endif // !CONFIG_INCLUDED
