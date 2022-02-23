///RU \file
///RU @brief Начальное состояние хранилища для деплоя
///EN \file
///EN @brief Initial state of storage for deploy

(record [
#if ENABLE_OWNER
    owner = ("OWNER_ADDRESS": address);
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
    admin = ("OWNER_ADDRESS": address);
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
    admins = (set [ ]: t_admins);
#endif // ENABLE_ADMINS
    futures = (big_map []: t_futures);
]: t_storage)