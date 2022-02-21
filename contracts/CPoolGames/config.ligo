#if !CONFIG_INCLUDED
#define CONFIG_INCLUDED

//RU Конфигурация (должна быть подключена ДО всего остального)
//EN Configuration (must be include BEFORE all other)

//RU У контракта есть владелец
//RU
//RU Владелец обладает всеми правами админа + может сменить владельца
//EN Contract has owner
#define ENABLE_OWNER

//RU У контракта есть админ
//RU
//RU Полный доступ ко всем операциям, кроме смены владельца
//EN Contract has admin
#define ENABLE_ADMIN

//RU У контракта есть набор админов
//RU
//RU Полный доступ ко всем операциям (включая добавление/удаление других админов]), кроме смены владельца
//EN Contract has set of admins
//#define ENABLE_ADMINS

//RU Необходимы либо ENABLE_ADMIN, либо ENABLE_ADMINS, но не оба сразу
#if (ENABLE_ADMIN) && (ENABLE_ADMINS)
    "Compile error: Must be ENABLE_ADMIN or ENABLE_ADMINS, not together";
#endif

//RU Необходимы либо ENABLE_OWNER, либо ENABLE_ADMIN, либо ENABLE_ADMINS
#if (!ENABLE_OWNER) && (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
    "Compile error: Must be ENABLE_OWNER or ENABLE_ADMIN or ENABLE_ADMINS";
#endif

//RU Статистика работы пула (для продвижения: объем выплат, кол-во розыгрышей)
//#define ENABLE_POOL_STAT

//RU Сгенерировать view для просмотра основной информации пула по его ID из других контрактов
//#define ENABLE_POOL_VIEW

//RU У пулов есть менеджеры (админ одного пула)
//RU
//RU Менеджер может управлять своим пулом и менять менеджера. Необходимо для ENABLE_POOL_AS_SERVICE
#define ENABLE_POOL_MANAGER

//RU Пулы для розыгрышей как сервис
//RU
//RU Создать пул может любой, он и будет его единственным админом, владелец и админы контракта не будут иметь доступа к пулу
#define ENABLE_POOL_AS_SERVICE

//RU Необходим ENABLE_POOL_MANAGER, если включен ENABLE_POOL_AS_SERVICE
#if (ENABLE_POOL_AS_SERVICE) && (!ENABLE_POOL_MANAGER)
    "Compile error: Must be ENABLE_POOL_MANAGER, when ENABLE_POOL_AS_SERVICE";
#endif

//RU По возможности максимально защищенный перевод токенов
//RU
//RU Если включено, при переводе токенов сначала делается approve AMOUNT|add_operator, после перевода approve 0|remove_operator.
//RU Если выключено, однократно включается approve MAXAMOUNT|add_operator и более не отзывается
//#define ENABLE_TRANSFER_SECURITY

//RU Сгенерировать view для баланса пользователя в пуле
#define ENABLE_BALANCE_VIEW

[@inline] const cMIN_GAME_SECONDS: nat = 10n * 60n;//RU< Минимальное кол-во секунд для партии
[@inline] const cMAX_GAME_SECONDS: nat = 10n * 86400n;//RU< Максимальное кол-во секунд для партии

#endif // !CONFIG_INCLUDED
