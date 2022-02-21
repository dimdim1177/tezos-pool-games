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
