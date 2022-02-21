#if !MFARMQUIPU_INCLUDED
#define MFARMQUIPU_INCLUDED

#include "MToken.ligo"

//RU Модуль взаимодействия с фермой QUIPU
module MFarmQUIPU is {

    const cERR_NOT_FOUND_DEPOSIT: string = "MFarmQUIPU/NotFoundDeposit";//RU< Ошибка: Не найдена точка входа deposit для фермы в формате QUIPU
    const cERR_NOT_FOUND_WITHDRAW: string = "MFarmQUIPU/NotFoundWithdraw";//RU< Ошибка: Не найдена точка входа withdraw для фермы в формате QUIPU
    const cERR_NOT_FOUND_HARVEST: string = "MFarmQUIPU/NotFoundHarvest";//RU< Ошибка: Не найдена точка входа harvest для фермы в формате QUIPU

    type t_farm_id is nat;//RU< ID фермы QUIPU
    type t_amount is nat;//RU< Кол-во токенов

    //RU Параметры для депозита в ферму QUIPU
    type t_deposit_params is [@layout:comb] record [
        fid: t_farm_id;//RU< ID фермы QUIPU
        amt: t_amount;//RU< Кол-во токенов
        referrer: option(address);
        rewards_receiver: address;
        candidate: key_hash;
    ];
    type t_deposit_method is QUIPUDeposit of t_deposit_params;//RU Прототип метода deposit фермы QUIPU
    type t_deposit_contract is contract(t_deposit_method);//RU Контракт с точкой входа deposit в формате фермы QUIPU

    //RU Параметры для извлечения депозита в ферму QUIPU
    type t_withdraw_params is [@layout:comb] record [
        fid: t_farm_id;//RU< ID фермы QUIPU
        amt: t_amount;//RU< Кол-во токенов
        receiver: address;
        rewards_receiver: address;
    ];
    type t_withdraw_method is QUIPUWithdraw of t_withdraw_params;//RU Прототип метода withdraw фермы QUIPU
    type t_withdraw_contract is contract(t_withdraw_method);//RU Контракт с точкой входа withdraw в формате фермы QUIPU

    //RU Параметры получения вознаграждения из фермы QUIPU
    type t_harvest_params is [@layout:comb] record [
        fid: t_farm_id;//RU< ID фермы QUIPU
        rewards_receiver: address;
    ];
    type t_harvest_method is QUIPUHarvest of t_harvest_params;//RU Прототип метода harvest фермы QUIPU
    type t_harvest_contract is contract(t_harvest_method);//RU Контракт с точкой входа harvest в формате фермы QUIPU

    //RU Получить точку входа deposit фермы с интерфейсом QUIPU
    function depositEntrypoint(const addr: address): t_deposit_contract is
        case (Tezos.get_entrypoint_opt("%deposit", addr): option(t_deposit_contract)) of [
        | Some(deposit_contract) -> deposit_contract
        | None -> (failwith(cERR_NOT_FOUND_DEPOSIT): t_deposit_contract)
        ];

    //RU Параметры для метода deposit QUIPU
    function depositParams(const farm_id: t_farm_id; const damount: t_amount): t_deposit_method is
        QUIPUDeposit(record [
            fid = farm_id;
            amt = damount;
            referrer = (None: option(address));
            rewards_receiver = Tezos.self_address;
            candidate = cZERO_KEY_HASH;
        ]);

    //RU Депозит в ферму QUIPU
    function deposit(const addr: address; const farm_id: t_farm_id; const damount: t_amount): operation is 
        Tezos.transaction(
            depositParams(farm_id, damount),
            0mutez,
            depositEntrypoint(addr)
        );

    //RU Получить точку входа withdraw фермы с интерфейсом QUIPU
    function withdrawEntrypoint(const addr: address): t_withdraw_contract is
        case (Tezos.get_entrypoint_opt("%withdraw", addr): option(t_withdraw_contract)) of [
        | Some(withdraw_contract) -> withdraw_contract
        | None -> (failwith(cERR_NOT_FOUND_WITHDRAW): t_withdraw_contract)
        ];

    //RU Параметры для метода deposit QUIPU
    function withdrawParams(const farm_id: t_farm_id; const wamount: t_amount): t_withdraw_method is
        QUIPUWithdraw(record [
            fid = farm_id;
            amt = wamount;
            receiver = Tezos.self_address;
            rewards_receiver = Tezos.self_address;
        ]);

    //RU Извлечение депозита из фермы QUIPU
    function withdraw(const addr: address; const farm_id: t_farm_id; const wamount: t_amount): operation is 
        Tezos.transaction(
            withdrawParams(farm_id, wamount),
            0mutez,
            withdrawEntrypoint(addr)
        );

    //RU Получить точку входа harvest фермы с интерфейсом QUIPU
    function harvestEntrypoint(const addr: address): t_harvest_contract is
        case (Tezos.get_entrypoint_opt("%harvest", addr): option(t_harvest_contract)) of [
        | Some(harvest_contract) -> harvest_contract
        | None -> (failwith(cERR_NOT_FOUND_HARVEST): t_harvest_contract)
        ];

    //RU Параметры для метода harvest QUIPU
    function harvestParams(const farm_id: t_farm_id): t_harvest_method is
        QUIPUHarvest(record [
            fid = farm_id;
            rewards_receiver = Tezos.self_address;
        ]);

    //RU Получение вознаграждения из фермы QUIPU
    function harvest(const addr: address; const farm_id: t_farm_id): operation is 
        Tezos.transaction(
            harvestParams(farm_id),
            0mutez,
            harvestEntrypoint(addr)
        );

    //RU Проверка параметров фермы на валидность
    function check(const addr: address): unit is block {
        //RU Проверяем наличие метода deposit для фермы в формате QUIPU
        const _d: t_deposit_contract = depositEntrypoint(addr);
        //RU Проверяем наличие метода withdraw для фермы в формате QUIPU
        const _w: t_withdraw_contract = withdrawEntrypoint(addr);
        //RU Проверяем наличие метода harvest для фермы в формате QUIPU
        const _h: t_harvest_contract = harvestEntrypoint(addr);
    } with unit;

}
#endif // !MFARMQUIPU_INCLUDED
