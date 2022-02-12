#if !CONFIG_INCLUDED
#define CONFIG_INCLUDED

//RU Конфигурация (должна быть подключена ДО всего остального)
//EN Configuration (must be include BEFORE all other)

#define ENABLE_OWNER //RU< У контракта есть владелец //EN< Contract has owner
#define ENABLE_ADMIN //RU< У контракта есть админ //EN< Contract has admin
//#Define ENABLE_ADMINS //RU< У контракта есть набор админов //EN< Contract has set of admins

//RU Необходимы либо ENABLE_ADMIN, либо ENABLE_ADMINS
#if (ENABLE_ADMIN) && (ENABLE_ADMINS)
    "Must be ENABLE_ADMIN or ENABLE_ADMINS";//RU< Генерируем ошибку компиляции //EN Generate compile error
#endif

//RU Необходимы либо ENABLE_OWNER, либо ENABLE_ADMIN, либо ENABLE_ADMINS
#if (!ENABLE_OWNER) && (!ENABLE_ADMIN) && (!ENABLE_ADMINS)
    "Must be ENABLE_OWNER or ENABLE_ADMIN or ENABLE_ADMINS";//RU< Генерируем ошибку компиляции //EN Generate compile error
#endif

#define ENABLE_REINDEX_USERS //RU< Переупаковка разряженных индексов пользователей в пулах
#define ENABLE_POOL_EDIT //RU< Методы для редактирования созданного пула
#define ENABLE_POOL_FORCE //RU< Принудительные методы для пула
#define ENABLE_POOL_STAT //RU< Статистика работы пула
#define ENABLE_POOL_VIEW //RU< View для просмотра основной информации пула по его ID из других контрактов

const cMIN_GAME_SECONDS: nat = 10n * 60n;//RU< Минимальное кол-во секунд для партии
const cMAX_GAME_SECONDS: nat = 10n * 86400n;//RU< Максимальное кол-во секунд для партии

#endif // !CONFIG_INCLUDED
