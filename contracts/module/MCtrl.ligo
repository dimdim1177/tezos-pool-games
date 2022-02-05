#if !MCTRL_INCLUDED
#define MCTRL_INCLUDED

//RU Модуль управления пулом
module MCtrl is {

    //RU Вероятность выигрыша пропорционально суммарному времени в игре
    const c_ALGO_TIME:    nat = 1n;
    
    //RU Вероятность выигрыша пропорционально сумме произведений объема на время в игре
    const c_ALGO_TIMEVOL: nat = 2n;

    //RU Алгоритмы определения победителя
    const c_ALGOs: set(nat) = set [c_ALGO_TIME; c_ALGO_TIMEVOL];

    //RU Параметры управления пулом
    type t_ctrl is [@layout:comb] record [
        paused: bool;//RU< Приостановка пула
        algo: nat;//RU< Алгоритм, см. c_ALGO...
        seconds: nat;//RU< Длительность партии в секундах
    ];

}
#endif // MCTRL_INCLUDED
