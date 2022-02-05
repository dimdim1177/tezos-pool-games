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

//#Define ENABLE_MANAGER //RU< У контракта есть менеджеры для управления его частями //EN< Contract has managers for control parts
#define ENABLE_MANAGERS //RU< У контракта есть наборы менеджеров для управления его частями //EN< Contract has sets of managers for control parts

//RU Необходимы либо ENABLE_MANAGER, либо ENABLE_MANAGERS
#if (ENABLE_MANAGER) && (ENABLE_MANAGERS)
    "Must be ENABLE_MANAGER or ENABLE_MANAGERS";//RU< Генерируем ошибку компиляции //EN Generate compile error
#endif

#endif // CONFIG_INCLUDED
