///RU \file
///RU \brief Начальное состояние хранилища для деплоя
///EN \file
///EN \brief Initial state of storage for deploy

(record [
#if ENABLE_OWNER
    owner = ("OWNER_ADDRESS": address);
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin = ("OWNER_ADDRESS": address);//RU Владельца используем как админа //EN We use the owner as an admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
#if !ENABLE_OWNER
    admins = (set [("OWNER_ADDRESS": address)]: MAdmins.t_admins);
#else // !ENABLE_OWNER
    admins = (set []: MAdmins.t_admins);
#endif // else !ENABLE_OWNER
#endif // ENABLE_ADMINS
    futures = (big_map []: t_futures);
]: t_storage)
