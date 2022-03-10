#include "../include/workspace.ligo"
#include "../../contracts/CPoolGames.ligo"

function initialStorage(const _: unit): t_storage is block {
    const s = (record [
#if ENABLE_OWNER
        owner = aOWNER;
#endif // ENABLE_OWNER
#if ENABLE_ADMIN
        admin = aOWNER;//RU Владельца используем как админа //EN We use the owner as an admin
#endif // ENABLE_ADMIN
#if ENABLE_ADMINS
#if !ENABLE_OWNER
        admins = (set [aOWNER]: MAdmins.t_admins);
#else // !ENABLE_OWNER
        admins = (set []: MAdmins.t_admins);
#endif // else !ENABLE_OWNER
#endif // ENABLE_ADMINS
        inext = 1n;//RU ID первого пула //EN ID of the first pool
        pools = (big_map []: t_pools);
        users = (big_map []: t_ipooladdr2user);
        waitBalanceBeforeHarvest = -1;//RU Не ожидаем колбек //EN Don't expect a callback
        waitBalanceAfterHarvest = -1;//RU Не ожидаем колбек //EN Don't expect a callback
        waitBalanceBeforeTez2Burn = -1;//RU Не ожидаем колбек //EN Don't expect a callback
        waitBalanceAfterTez2Burn = -1;//RU Не ожидаем колбек //EN Don't expect a callback
        usedFarms = (big_map []: t_farms);
#if !ENABLE_TRANSFER_SECURITY
        approved = (big_map []: t_approved);
#endif // !ENABLE_TRANSFER_SECURITY
    ]: t_storage);
} with s;

function originate(const _: unit): typed_address(t_entrypoint, t_storage) * contract(t_entrypoint) is block {
    const sini = initialStorage(unit);
    const (addr, _, _) = Test.originate(main, sini, 0tez);
    const contract = Test.to_contract(addr);
} with (addr, contract);

const opts: t_opts = record [
    algo = AlgoTime;
    gameSeconds = 86400n;
    minSeconds = 0n;
    minDeposit = 0n;
    maxDeposit = 0n;
    winPercent = 60n;
    burnPercent = 35n;
    feePercent = 5n;
];

type t_crunchyfarm_entrypoint is
| [@annot:deposit] CrunchyFarmDeposit of MFarmCrunchy.t_deposit_params
| [@annot:withdraw] CrunchyFarmWithdraw of MFarmCrunchy.t_withdraw_params
| [@annot:harvest] CrunchyFarmHarvest of MFarmCrunchy.t_harvest_params
;

function farmCrunchyContract(const _e: t_crunchyfarm_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateFarmCrunchy(const _: unit): address is block {
    const (addr, _, _) = Test.originate(farmCrunchyContract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_crunchyfarm_entrypoint));
} with Tezos.address(contract);

type t_quipufarm_entrypoint is
| [@annot:deposit] QUIPUFarmDeposit of MFarmQUIPU.t_deposit_params
| [@annot:withdraw] QUIPUFarmWithdraw of MFarmQUIPU.t_withdraw_params
| [@annot:harvest] QUIPUFarmHarvest of MFarmQUIPU.t_harvest_params
;

function farmQUIPUContract(const _e: t_quipufarm_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateFarmQUIPU(const _: unit): address is block {
    const (addr, _, _) = Test.originate(farmQUIPUContract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_quipufarm_entrypoint));
} with Tezos.address(contract);

type t_random_entrypoint is
| [@annot:createFuture] RandomCreate of MRandom.t_ts_iobj
| [@annot:deleteFuture] RandomDelete of MRandom.t_ts_iobj
| [@annot:getFuture] RandomGet of MRandom.t_ts_iobj_callback
;

function randomContract(const _e: t_random_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateRandom(const _: unit): address is block {
    const (addr, _, _) = Test.originate(randomContract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_random_entrypoint));
} with Tezos.address(contract);

type t_fa2_entrypoint is
| [@annot:transfer] TokenFA2Transfer of MFA2.t_transfer_params
| [@annot:balance_of] TokenFA2Balance of MFA2.t_balance_params
| [@annot:update_operators] TokenFA2Operators of MFA2.t_operators_params
;

function tokenFA2Contract(const _e: t_fa2_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateTokenFA2(const _: unit): address is block {
    const (addr, _, _) = Test.originate(tokenFA2Contract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_fa2_entrypoint));
} with Tezos.address(contract);

type t_fa12_entrypoint is
| [@annot:transfer] TokenFA1_2Transfer of MFA1_2.t_transfer_params
| [@annot:getBalance] TokenFA1_2Balance of MFA1_2.t_balance_params
| [@annot:approve] TokenFA1_2Approve of MFA1_2.t_approve_params
;

function tokenFA1_2Contract(const _e: t_fa12_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateTokenFA1_2(const _: unit): address is block {
    const (addr, _, _) = Test.originate(tokenFA1_2Contract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_fa12_entrypoint));
} with Tezos.address(contract);

type t_quipuswap_entrypoint is
| [@annot:tezToTokenPayment] QUIPUSwapTez2Token of MQuipuswap.t_tez2token_params
| [@annot:tokenToTezPayment] QUIPUSwapToken2Tez of MQuipuswap.t_token2tez_params
;

function quipuswapContract(const _e: t_quipuswap_entrypoint; const _s: unit): list(operation) * unit is (cNO_OPERATIONS, unit);

function originateQUIPUSwap(const _: unit): address is block {
    const (addr, _, _) = Test.originate(quipuswapContract, unit, 0tez);
    const contract = (Test.to_contract(addr): contract(t_quipuswap_entrypoint));
} with Tezos.address(contract);

function poolVars(const burn: bool; const fee: bool): t_opts * option(MToken.t_token) *
        option(MQuipuswap.t_swap) * option(MQuipuswap.t_swap) * option(address) is block {
    var winPercent: nat := 100n;
    var burnPercent: nat := 0n;
    var feePercent: nat := 0n;
    var burnToken: option(MToken.t_token) := None;
    var burnSwap: option(MQuipuswap.t_swap) := None;
    var rewardSwap: option(MQuipuswap.t_swap) := None;
    var feeAddr: option(address) := None;
    if burn then block {
        burnPercent := 35n;
        winPercent := abs(winPercent - burnPercent);
        burnToken := Some(record [
            addr = originateTokenFA2(unit);
            token_id = 1n;
            fa = FA2;
        ]);
        burnSwap := Some(originateQUIPUSwap(unit));
        rewardSwap := Some(originateQUIPUSwap(unit));
    } else skip;
    if fee then block {
        feePercent := 5n;
        winPercent := abs(winPercent - feePercent);
        feeAddr := Some(aUSER0);
    } else skip;
    const opts: t_opts = record [
        algo = AlgoTime;
        gameSeconds = 86400n;
        minSeconds = 0n;
        minDeposit = 0n;
        maxDeposit = 0n;
        winPercent = winPercent;
        burnPercent = burnPercent;
        feePercent = feePercent;
    ];
} with (opts, burnToken, burnSwap, rewardSwap, feeAddr);


function poolCreate(const burn: bool; const fee: bool): t_pool_create is block {
    const (opts, burnToken, burnSwap, rewardSwap, feeAddr) = poolVars(burn, fee);
    const p: t_pool_create = record [
        opts = opts;
        farm = record [
            addr = originateFarmCrunchy(unit);
            id = 1n;
            farmToken = record [
                addr = originateTokenFA1_2(unit);
                token_id = 0n;
                fa = FA1_2;
            ];
            rewardToken = record [
                addr = originateTokenFA2(unit);
                token_id = 1n;
                fa = FA2;
            ];
            interface = InterfaceCrunchy;
        ];
        randomSource = originateRandom(unit);
        burnToken = burnToken;
        burnSwap = burnSwap;
        rewardSwap = rewardSwap;
        feeAddr = feeAddr;
        state = PoolStateActive;
    ];
} with p;

function poolCreated(const pool_create: t_pool_create; const creator: address): t_pool is block {
    const p: t_pool = record [
        opts = pool_create.opts;
        farm = pool_create.farm;
        randomSource = pool_create.randomSource;
        rewardSwap = pool_create.rewardSwap;
        burnSwap = pool_create.burnSwap;
        burnToken = pool_create.burnToken;
        feeAddr = pool_create.feeAddr;
        state = pool_create.state;
        balance = 0n;
        count = 0n;
        game = MPoolGame.create(GameStateActive, pool_create.opts.gameSeconds);
        randomFuture = False;
        beforeHarvestBalance = 0n;
        beforeReward2TezBalance = 0mutez;
        beforeBurnBalance = 0n;
#if ENABLE_POOL_MANAGER
        manager = creator;
#endif // ENABLE_POOL_MANAGER
#if ENABLE_POOL_STAT
        stat = MPoolStat.create(unit);
#endif // ENABLE_POOL_STAT
    ];
} with p;

function poolEdit(const burn: bool; const fee: bool): t_pool_edit is block {
    const (opts, burnToken, burnSwap, rewardSwap, feeAddr) = poolVars(burn, fee);
    const p: t_pool_edit = record [
        opts = Some(opts);
        randomSource = (None: option(address));
        burnToken = burnToken;
        burnSwap = burnSwap;
        rewardSwap = rewardSwap;
        feeAddr = feeAddr;
        state = Some(PoolStateActive);
    ];
} with p;

function poolEdited(const pool_create: t_pool_create; const creator: address; const pool_edit: t_pool_edit): t_pool is block {
    var p: t_pool := poolCreated(pool_create, creator);
    case pool_edit.opts of [
    | Some(opts) -> p.opts := opts
    | None -> skip
    ];
    case pool_edit.randomSource of [
    | Some(source) -> p.randomSource := source
    | None -> skip
    ];
    case pool_edit.burnToken of [
    | Some(burnToken) -> p.burnToken := Some(burnToken)
    | None -> skip
    ];
    case pool_edit.burnSwap of [
    | Some(burnSwap) -> p.burnSwap := Some(burnSwap)
    | None -> skip
    ];
    case pool_edit.rewardSwap of [
    | Some(rewardSwap) -> p.rewardSwap := Some(rewardSwap)
    | None -> skip
    ];
    case pool_edit.feeAddr of [
    | Some(feeAddr) -> p.feeAddr := Some(feeAddr)
    | None -> skip
    ];
    case pool_edit.state of [
    | Some(state) -> p.state := state
    | None -> skip
    ];
} with p;
