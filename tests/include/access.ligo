#if ENABLE_OWNER

const testChangeOwnerOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, ChangeOwner(aADMIN), 0mutez);
    Test.log(("ChangeOwnerOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.owner := aADMIN;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

const testChangeOwnerFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, ChangeOwner(aADMIN), 0mutez);
    Test.log(("ChangeOwnerFailDenied", r));

    const musts = initialStorage(unit);
} with (mustERR(r, MOwner.cERR_DENIED)) and (musts = Test.get_storage(caddr));

#endif // ENABLE_OWNER

#if (ENABLE_OWNER) && (ENABLE_ADMIN)

const testChangeAdminByOwnerOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, ChangeAdmin(aADMIN), 0mutez);
    Test.log(("ChangeAdminByOwnerOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admin := aADMIN;
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testChangeAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, ChangeAdmin(aADMIN), 0mutez);
    Test.log(("ChangeAdminFailDenied", r));

    const musts = initialStorage(unit);
} with (mustERR(r, MAdmin.cERR_DENIED)) and (musts = Test.get_storage(caddr));

const testChangeAdminByAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, ChangeAdmin(aADMIN), 0mutez);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, ChangeAdmin(aMANAGER), 0mutez);
    Test.log(("ChangeAdminByAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admin := aMANAGER;
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

#endif // (ENABLE_OWNER) && (ENABLE_ADMIN)

#if (!ENABLE_OWNER) && (ENABLE_ADMIN)

const testChangeAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, ChangeAdmin(aADMIN), 0mutez);
    Test.log(("ChangeAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admin := aADMIN;
} with (mustOK(r)) and (musts = Test.get_storage(caddr));

const testChangeAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, ChangeAdmin(aADMIN), 0mutez);
    Test.log(("ChangeAdminFailDenied", r));

    const musts = initialStorage(unit);
} with (mustERR(r, MAdmin.cERR_DENIED)) and (musts = Test.get_storage(caddr));

#endif // (!ENABLE_OWNER) && (ENABLE_ADMIN)

#if (ENABLE_OWNER) && (ENABLE_ADMINS)

const testAddAdminByOwnerOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.log(("AddAdminByOwnerOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aADMIN]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testAddAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.log(("AddAdminFailDenied", r));

    const musts = initialStorage(unit);
} with (mustERR(r, MAdmins.cERR_DENIED)) and (musts = Test.get_storage(caddr));

const testAddAdminByAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, AddAdmin(aMANAGER), 0mutez);
    Test.log(("AddAdminByAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aADMIN; aMANAGER]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testRemAdminByOwnerOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, RemAdmin(aADMIN), 0mutez);
    Test.log(("RemAdminByOwnerOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set []: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testRemAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aMANAGER);
    const r = Test.transfer_to_contract(c, RemAdmin(aADMIN), 0mutez);
    Test.log(("RemAdminFailDenied", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aADMIN]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustERR(r, MAdmins.cERR_DENIED));

const testRemAdminFailNotFound = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, RemAdmin(aMANAGER), 0mutez);
    Test.log(("RemAdminFailNotFound", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aADMIN]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustERR(r, MAdmins.cERR_NOT_FOUND));

const testRemAdminByAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, RemAdmin(aADMIN), 0mutez);
    Test.log(("RemAdminByAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set []: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

#endif // (ENABLE_OWNER) && (ENABLE_ADMIN)

#if (!ENABLE_OWNER) && (ENABLE_ADMINS)

const testAddAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.log(("AddAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aOWNER; aADMIN]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testAddAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.log(("AddAdminFailDenied", r));

    const musts = initialStorage(unit);
} with (mustERR(r, MAdmins.cERR_DENIED)) and (musts = Test.get_storage(caddr));

const testRemAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, RemAdmin(aADMIN), 0mutez);
    Test.log(("RemAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aOWNER]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

const testRemAdminFailDenied = {
    const (caddr, c) = originate(unit);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, RemAdmin(aOWNER), 0mutez);
    Test.log(("RemAdminFailDenied", r));

    var musts: t_storage := initialStorage(unit);
} with (Test.get_storage(caddr) = musts) and (mustERR(r, MAdmins.cERR_DENIED));

const testRemAdminFailNotFound = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, RemAdmin(aADMIN), 0mutez);
    Test.log(("RemAdminFailNotFound", r));

    var musts: t_storage := initialStorage(unit);
} with (Test.get_storage(caddr) = musts) and (mustERR(r, MAdmins.cERR_NOT_FOUND));

const testRemAdminFailLastAdmin = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r = Test.transfer_to_contract(c, RemAdmin(aOWNER), 0mutez);
    Test.log(("RemAdminFailLastAdmin", r));

    var musts: t_storage := initialStorage(unit);
} with (Test.get_storage(caddr) = musts) and (mustERR(r, MAdmins.cERR_REM_LAST_ADMIN));

const testRemAdminOK = {
    const (caddr, c) = originate(unit);
    Test.set_source(aOWNER);
    const r0 = Test.transfer_to_contract(c, AddAdmin(aADMIN), 0mutez);
    Test.set_source(aADMIN);
    const r = Test.transfer_to_contract(c, RemAdmin(aOWNER), 0mutez);
    Test.log(("RemAdminOK", r));

    var musts: t_storage := initialStorage(unit);
    musts.admins := (set [aADMIN]: MAdmins.t_admins);
} with (Test.get_storage(caddr) = musts) and (mustOK(r));

#endif // (!ENABLE_OWNER) && (ENABLE_ADMIN)
