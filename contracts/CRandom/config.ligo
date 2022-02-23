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
///RU
///RU Полный доступ ко всем операциям, кроме смены владельца
///EN Contract has admin
///EN
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

#endif // !CONFIG_INCLUDED
