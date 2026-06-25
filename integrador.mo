model Simulacion
  constant Integer maxHamburguesasModelo = 12
    "Limite interno para permitir editar hamburguesasMax";

  //                              PARAMETROS
  // Generadores aleatorios
  parameter Integer globalSeed = 2026 "Semilla global";
  parameter Integer localSeed = 32309
    "Semilla para llegadas y composicion";
  parameter Integer localSeedServicio = 124642
    "Semilla para tiempos de servicio";
  parameter Integer replica = 0
    "Indice de replica para variar las semillas";

  // Tiempo y demanda
  parameter Real duracionPico = 120 "Horario pico en minutos";
  parameter Real duracionSimulacion = 210
    "Horizonte total del turno noche modelado";
  parameter Real pedidosPorHora(min = 0.01) = 12
    "Demanda supuesta para horario pico";
  parameter Integer maxPedidos(min = 1) = 100
    "Dimension suficiente para escenarios de demanda extraordinaria";

  // Composicion de pedidos
  parameter Integer hamburguesasMin(min = 1) = 1;
  parameter Integer hamburguesasMax(
    min = hamburguesasMin, max = maxHamburguesasModelo) = 4;
  parameter Real porcentajeEspeciales(min = 0, max = 1) = 0.35;
  parameter Real porcentajeConPapas(min = 0, max = 1) = 0.75
    "Probabilidad de que cada hamburguesa incluya una porcion de papas";

  // Personal observado
  parameter Integer cocinerosPlancha(min = 1, max = 3) = 1
    "Uno actual, dos alternativa principal, tres escenario exploratorio";
  parameter Integer personasArmado(min = 1, max = 3) = 2
    "Horario pico actual: dos personas arman y reponen";
  parameter Real factorCongestion(min = 1) = 1
    "Factor calibrable por interferencias y coordinacion";
  parameter Real tiempoReferenciaObservado(min = 0) = 0
    "Tiempo informado por el local; cero desactiva la comparacion";

  // Capacidad simultanea de una tanda
  parameter Integer cantidadPlanchas(min = 1) = 2
    "Cantidad de planchas disponibles";
  parameter Integer capacidadHamburguesasPorPlancha(min = 1) = 20;
  parameter Integer capacidadPapasPorPlancha(min = 1) = 20;
  parameter Integer capacidadHamburguesasTanda(min = 1) =
    cantidadPlanchas * capacidadHamburguesasPorPlancha;
  parameter Integer capacidadPapasTanda(min = 1) =
    cantidadPlanchas * capacidadPapasPorPlancha;

  // Tiempos de coccion
  parameter Real tMedallonMin = 7;
  parameter Real tMedallonMax = 9;
  parameter Real tPapasMin = 7;
  parameter Real tPapasMax = 10;
  parameter Real tExtraMin = 3;
  parameter Real tExtraMax = 6;
  parameter Real tAtencionCoccionMin = 0.20
    "Atencion manual minima por hamburguesa";
  parameter Real tAtencionCoccionMax = 0.50
    "Atencion manual maxima por hamburguesa";
  parameter Real tAtencionExtraMin = 0.25;
  parameter Real tAtencionExtraMax = 0.75;

  // Tiempos de armado y reposicion
  parameter Real tQueso = 0.5;
  parameter Real tArmadoSimpleMin = 1;
  parameter Real tArmadoSimpleMax = 2;
  parameter Real tArmadoEspecialMin = 2;
  parameter Real tArmadoEspecialMax = 4;
  parameter Real tEmpaqueMin = 0.5;
  parameter Real tEmpaqueMax = 1;
  parameter Real tReposicionMin = 0.25;
  parameter Real tReposicionMax = 0.75;

  // Pedido individual observado
  parameter Integer pedidoObjetivo(min = 1) = 5;

  //                              VARIABLES
  // Generadores
  discrete Real aleatorioDemanda(start = 0.5, fixed = false);
  discrete Real aleatorioServicio(start = 0.5, fixed = false);
  discrete Real proximaLlegada(start = 0, fixed = false);

  // Totales de demanda
  discrete Integer cantidadPedidos(start = 0, fixed = true);
  discrete Integer hamburguesasTotales(start = 0, fixed = true);
  discrete Integer hamburguesasSimples(start = 0, fixed = true);
  discrete Integer hamburguesasEspeciales(start = 0, fixed = true);
  discrete Integer porcionesPapasTotales(start = 0, fixed = true);

  // Cola de coccion
  discrete Integer longitudColaCoccion(start = 0, fixed = true);
  discrete Integer colaCoccionMaxima(start = 0, fixed = true);
  discrete Integer colaCoccionId[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer colaCoccionHamburguesas[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer colaCoccionEspeciales[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer colaCoccionPapas[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real colaCoccionLlegada[maxPedidos](
    each start = 0, each fixed = true);

  // Pedidos cocinandose simultaneamente
  discrete Boolean coccionActiva[maxPedidos](
    each start = false, each fixed = true);
  discrete Real finCoccion[maxPedidos](
    each start = 1e60, each fixed = true);
  discrete Integer coccionId[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer coccionHamburguesas[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer coccionEspeciales[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer coccionPapas[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real coccionLlegada[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real coccionInicio[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real coccionDuracion[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real coccionArmadoCalculado[maxPedidos](
    each start = 0, each fixed = true);

  // Cola de armado
  discrete Integer longitudColaArmado(start = 0, fixed = true);
  discrete Integer colaArmadoMaxima(start = 0, fixed = true);
  discrete Integer colaArmadoId[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer colaArmadoHamburguesas[maxPedidos](
    each start = 0, each fixed = true);
  discrete Integer colaArmadoEspeciales[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real colaArmadoLlegada[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real colaArmadoInicioCoccion[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real colaArmadoDuracionCoccion[maxPedidos](
    each start = 0, each fixed = true);
  discrete Real colaArmadoDuracion[maxPedidos](
    each start = 0, each fixed = true);

  // Puestos de armado independientes
  discrete Boolean armadoActivo[3](
    each start = false, each fixed = true);
  discrete Real finArmado[3](
    each start = 1e60, each fixed = true);
  discrete Integer armadoId[3](
    each start = 0, each fixed = true);
  discrete Real armadoLlegada[3](
    each start = 0, each fixed = true);
  discrete Real armadoInicioCoccion[3](
    each start = 0, each fixed = true);
  discrete Real armadoDuracionCoccion[3](
    each start = 0, each fixed = true);
  discrete Real armadoInicio[3](
    each start = 0, each fixed = true);
  discrete Real armadoDuracion[3](
    each start = 0, each fixed = true);

  // Ocupacion de equipos
  discrete Integer hamburguesasEnCoccion(start = 0, fixed = true);
  discrete Integer papasEnCoccion(start = 0, fixed = true);
  discrete Integer pedidosEnCoccion(start = 0, fixed = true);
  discrete Integer personasArmando(start = 0, fixed = true);

  // Resultados
  discrete Integer pedidosTerminados(start = 0, fixed = true);
  discrete Integer pedidosMas20Min(start = 0, fixed = true);
  discrete Integer pedidosMas35Min(start = 0, fixed = true);
  discrete Integer pedidosMas120Min(start = 0, fixed = true);
  discrete Real sumaTiemposPedido(start = 0, fixed = true);
  discrete Real tiempoMaximoPedido(start = 0, fixed = true);
  discrete Real ultimoTiempoPedido(start = 0, fixed = true);
  discrete Real tiempoFinalUltimoPedido(start = 0, fixed = true);

  // Tiempos por tipo del ultimo pedido iniciado
  discrete Real tiempoUnitarioSimple(start = 0, fixed = true);
  discrete Real tiempoUnitarioEspecial(start = 0, fixed = true);
  discrete Real tiempoCoccionUltimoPedido(start = 0, fixed = true);
  discrete Real tiempoArmadoUltimoPedido(start = 0, fixed = true);

  // Seguimiento del pedido elegido
  discrete Boolean pedidoObjetivoIniciado(start = false, fixed = true);
  discrete Boolean pedidoObjetivoTerminado(start = false, fixed = true);
  discrete Real llegadaPedidoObjetivo(start = 0, fixed = true);
  discrete Real inicioCoccionPedidoObjetivo(start = 0, fixed = true);
  discrete Real finCoccionPedidoObjetivo(start = 0, fixed = true);
  discrete Real inicioArmadoPedidoObjetivo(start = 0, fixed = true);
  discrete Real finPedidoObjetivo(start = 0, fixed = true);
  discrete Real esperaCoccionPedidoObjetivo(start = 0, fixed = true);
  discrete Real coccionPedidoObjetivo(start = 0, fixed = true);
  discrete Real esperaArmadoPedidoObjetivo(start = 0, fixed = true);
  discrete Real armadoPedidoObjetivo(start = 0, fixed = true);
  discrete Real tiempoTotalPedidoObjetivo(start = 0, fixed = true);

  // Utilizacion acumulada
  Real cargaPlanchaAcumulada(start = 0, fixed = true);
  Real cargaFreidoraAcumulada(start = 0, fixed = true);
  Real cargaArmadoAcumulada(start = 0, fixed = true);

  // Indicadores
  Real tiempoPromedioPedido;
  Real porcentajeMas20Min;
  Real porcentajeMas35Min;
  Real porcentajeMas120Min;
  Real utilizacionPlancha;
  Real utilizacionFreidora;
  Real utilizacionArmado;
  Real factorAtencionCoccion;
  Real proporcionEspecialObservada;
  Real proporcionConPapasObservada;
  Real errorCalibracionTiempo
    "Diferencia respecto del dato usado para calibrar";
  Real errorCalibracionPorcentual;
  Integer pedidosEnProceso;
  Integer balancePedidos;
  Integer balanceHamburguesas;

protected
  discrete Integer estadoDemanda[33](
    each start = 0, each fixed = false);
  discrete Integer estadoServicio[33](
    each start = 0, each fixed = false);
  Integer estadoDemandaT[33];
  Integer estadoServicioT[33];

  Integer qCoccionN;
  Integer qArmadoN;
  Integer hamburguesasOcupadas;
  Integer papasOcupadas;
  Integer cocinandoN;
  Integer armandoN;
  Integer terminadosT;
  Integer mas20T;
  Integer mas35T;
  Integer mas120T;
  Real sumaTiemposT;
  Real maxTiempoT;
  Real ultimoTiempoT;
  Real finUltimoT;

  Integer qCid[maxPedidos];
  Integer qCh[maxPedidos];
  Integer qCe[maxPedidos];
  Integer qCp[maxPedidos];
  Real qCl[maxPedidos];
  Boolean cActiva[maxPedidos];
  Real cFin[maxPedidos];
  Integer cId[maxPedidos];
  Integer cH[maxPedidos];
  Integer cE[maxPedidos];
  Integer cP[maxPedidos];
  Real cLlegada[maxPedidos];
  Real cInicio[maxPedidos];
  Real cDuracion[maxPedidos];
  Real cArmado[maxPedidos];

  Integer qAid[maxPedidos];
  Integer qAh[maxPedidos];
  Integer qAe[maxPedidos];
  Real qALlegada[maxPedidos];
  Real qAInicioC[maxPedidos];
  Real qADuracionC[maxPedidos];
  Real qADuracion[maxPedidos];
  Boolean aActiva[3];
  Real aFin[3];
  Integer aId[3];
  Real aLlegada[3];
  Real aInicioC[3];
  Real aDuracionC[3];
  Real aInicio[3];
  Real aDuracion[3];

  Integer cantidadT;
  Integer especialesT;
  Integer papasT;
  Integer simplesT;
  Integer slotLibre;
  Real aleatorioT;
  Real intervaloT;
  Real tMedallonT;
  Real tPapasT;
  Real tExtraT;
  Real tAtencionBaseT;
  Real tAtencionT;
  Real tArmadoSimpleT;
  Real tArmadoEspecialT;
  Real tEmpaqueT;
  Real tReposicionT;
  Real tCoccionT;
  Real tArmadoT;
  Real tiempoTotalT;

  //                              ALGORITMO
initial algorithm
  assert(duracionSimulacion >= duracionPico,
    "El horizonte total debe incluir el horario pico");
  assert(tAtencionCoccionMin <= tAtencionCoccionMax,
    "Los limites de atencion de coccion son invalidos");
  assert(hamburguesasMax <= capacidadHamburguesasTanda,
    "Un pedido individual supera la capacidad de hamburguesas");
  assert(hamburguesasMax <= maxHamburguesasModelo,
    "hamburguesasMax supera el limite interno del modelo");
  assert(hamburguesasMax <= capacidadPapasTanda,
    "Un pedido individual supera la capacidad de papas");

  estadoDemanda :=
    Modelica.Math.Random.Generators.Xorshift1024star.initialState(
      localSeed + 1009 * replica, globalSeed);
  estadoServicio :=
    Modelica.Math.Random.Generators.Xorshift1024star.initialState(
      localSeedServicio + 2003 * replica, globalSeed);
  (aleatorioDemanda, estadoDemanda) :=
    Modelica.Math.Random.Generators.Xorshift1024star.random(
      estadoDemanda);
  (aleatorioServicio, estadoServicio) :=
    Modelica.Math.Random.Generators.Xorshift1024star.random(
      estadoServicio);
  proximaLlegada :=
    -log(max(aleatorioDemanda, 1e-12)) * 60 / pedidosPorHora;

algorithm
  when (time >= pre(proximaLlegada) and
        pre(proximaLlegada) <= duracionPico) or
       min(pre(finCoccion)) <= time or
       min(pre(finArmado)) <= time then

    // Copia del estado previo
    qCoccionN := pre(longitudColaCoccion);
    qArmadoN := pre(longitudColaArmado);
    hamburguesasOcupadas := pre(hamburguesasEnCoccion);
    papasOcupadas := pre(papasEnCoccion);
    cocinandoN := pre(pedidosEnCoccion);
    armandoN := pre(personasArmando);
    terminadosT := pre(pedidosTerminados);
    mas20T := pre(pedidosMas20Min);
    mas35T := pre(pedidosMas35Min);
    mas120T := pre(pedidosMas120Min);
    sumaTiemposT := pre(sumaTiemposPedido);
    maxTiempoT := pre(tiempoMaximoPedido);
    ultimoTiempoT := pre(ultimoTiempoPedido);
    finUltimoT := pre(tiempoFinalUltimoPedido);
    estadoDemandaT := pre(estadoDemanda);
    estadoServicioT := pre(estadoServicio);

    qCid := pre(colaCoccionId);
    qCh := pre(colaCoccionHamburguesas);
    qCe := pre(colaCoccionEspeciales);
    qCp := pre(colaCoccionPapas);
    qCl := pre(colaCoccionLlegada);
    cActiva := pre(coccionActiva);
    cFin := pre(finCoccion);
    cId := pre(coccionId);
    cH := pre(coccionHamburguesas);
    cE := pre(coccionEspeciales);
    cP := pre(coccionPapas);
    cLlegada := pre(coccionLlegada);
    cInicio := pre(coccionInicio);
    cDuracion := pre(coccionDuracion);
    cArmado := pre(coccionArmadoCalculado);

    qAid := pre(colaArmadoId);
    qAh := pre(colaArmadoHamburguesas);
    qAe := pre(colaArmadoEspeciales);
    qALlegada := pre(colaArmadoLlegada);
    qAInicioC := pre(colaArmadoInicioCoccion);
    qADuracionC := pre(colaArmadoDuracionCoccion);
    qADuracion := pre(colaArmadoDuracion);
    aActiva := pre(armadoActivo);
    aFin := pre(finArmado);
    aId := pre(armadoId);
    aLlegada := pre(armadoLlegada);
    aInicioC := pre(armadoInicioCoccion);
    aDuracionC := pre(armadoDuracionCoccion);
    aInicio := pre(armadoInicio);
    aDuracion := pre(armadoDuracion);

    // Finalizacion de armado
    for a in 1:3 loop
      if a <= personasArmado and
         pre(armadoActivo[a]) and
         time >= pre(finArmado[a]) then
        tiempoTotalT := time - pre(armadoLlegada[a]);
        terminadosT := terminadosT + 1;
        sumaTiemposT := sumaTiemposT + tiempoTotalT;
        ultimoTiempoT := tiempoTotalT;
        maxTiempoT := max(maxTiempoT, tiempoTotalT);
        finUltimoT := time;
        mas20T := mas20T + (if tiempoTotalT > 20 then 1 else 0);
        mas35T := mas35T + (if tiempoTotalT > 35 then 1 else 0);
        mas120T := mas120T + (if tiempoTotalT > 120 then 1 else 0);
        armandoN := armandoN - 1;
        aActiva[a] := false;
        aFin[a] := 1e60;

        if pre(armadoId[a]) == pedidoObjetivo then
          pedidoObjetivoTerminado := true;
          finPedidoObjetivo := time;
          armadoPedidoObjetivo := pre(armadoDuracion[a]);
          tiempoTotalPedidoObjetivo := tiempoTotalT;
        end if;
      end if;
    end for;

    // Finalizacion de coccion y transferencia a armado
    for s in 1:maxPedidos loop
      if pre(coccionActiva[s]) and
         time >= pre(finCoccion[s]) then
        assert(qArmadoN < maxPedidos,
          "La cola de armado supero maxPedidos");
        qArmadoN := qArmadoN + 1;
        qAid[qArmadoN] := pre(coccionId[s]);
        qAh[qArmadoN] := pre(coccionHamburguesas[s]);
        qAe[qArmadoN] := pre(coccionEspeciales[s]);
        qALlegada[qArmadoN] := pre(coccionLlegada[s]);
        qAInicioC[qArmadoN] := pre(coccionInicio[s]);
        qADuracionC[qArmadoN] := pre(coccionDuracion[s]);
        qADuracion[qArmadoN] := pre(coccionArmadoCalculado[s]);

        hamburguesasOcupadas :=
          hamburguesasOcupadas - pre(coccionHamburguesas[s]);
        papasOcupadas := papasOcupadas - pre(coccionPapas[s]);
        cocinandoN := cocinandoN - 1;
        cActiva[s] := false;
        cFin[s] := 1e60;

        if pre(coccionId[s]) == pedidoObjetivo then
          finCoccionPedidoObjetivo := time;
          coccionPedidoObjetivo := pre(coccionDuracion[s]);
        end if;
      end if;
    end for;

    // Nueva llegada
    if time >= pre(proximaLlegada) and
       pre(proximaLlegada) <= duracionPico then
      assert(qCoccionN < maxPedidos,
        "La cola de coccion supero maxPedidos");

      (aleatorioT, estadoDemandaT) :=
        Modelica.Math.Random.Generators.Xorshift1024star.random(
          estadoDemandaT);
      cantidadT := hamburguesasMin + integer(floor(
        aleatorioT * (hamburguesasMax - hamburguesasMin + 1)));
      especialesT := 0;
      papasT := 0;
      for i in 1:maxHamburguesasModelo loop
        if i <= cantidadT then
          (aleatorioT, estadoDemandaT) :=
            Modelica.Math.Random.Generators.Xorshift1024star.random(
              estadoDemandaT);
          if aleatorioT < porcentajeEspeciales then
            especialesT := especialesT + 1;
          end if;
          (aleatorioT, estadoDemandaT) :=
            Modelica.Math.Random.Generators.Xorshift1024star.random(
              estadoDemandaT);
          if aleatorioT < porcentajeConPapas then
            papasT := papasT + 1;
          end if;
        end if;
      end for;

      qCoccionN := qCoccionN + 1;
      qCid[qCoccionN] := pre(cantidadPedidos) + 1;
      qCh[qCoccionN] := cantidadT;
      qCe[qCoccionN] := especialesT;
      qCp[qCoccionN] := papasT;
      qCl[qCoccionN] := time;

      cantidadPedidos := pre(cantidadPedidos) + 1;
      hamburguesasTotales :=
        pre(hamburguesasTotales) + cantidadT;
      hamburguesasEspeciales :=
        pre(hamburguesasEspeciales) + especialesT;
      hamburguesasSimples :=
        pre(hamburguesasSimples) + cantidadT - especialesT;
      porcionesPapasTotales :=
        pre(porcionesPapasTotales) + papasT;

      if pre(cantidadPedidos) + 1 == pedidoObjetivo then
        llegadaPedidoObjetivo := time;
      end if;

      (aleatorioT, estadoDemandaT) :=
        Modelica.Math.Random.Generators.Xorshift1024star.random(
          estadoDemandaT);
      intervaloT :=
        -log(max(aleatorioT, 1e-12)) * 60 / pedidosPorHora;
      proximaLlegada := time + intervaloT;
    end if;

    // Asignacion de cola de armado a personas disponibles
    for a in 1:3 loop
      if a <= personasArmado and not aActiva[a] and qArmadoN > 0 then
        aActiva[a] := true;
        aId[a] := qAid[1];
        aLlegada[a] := qALlegada[1];
        aInicioC[a] := qAInicioC[1];
        aDuracionC[a] := qADuracionC[1];
        aInicio[a] := time;
        aDuracion[a] := qADuracion[1];
        aFin[a] := time + qADuracion[1];
        armandoN := armandoN + 1;

        if qAid[1] == pedidoObjetivo then
          inicioArmadoPedidoObjetivo := time;
          esperaArmadoPedidoObjetivo :=
            time - (qAInicioC[1] + qADuracionC[1]);
        end if;

        for i in 1:maxPedidos - 1 loop
          if i < qArmadoN then
            qAid[i] := qAid[i + 1];
            qAh[i] := qAh[i + 1];
            qAe[i] := qAe[i + 1];
            qALlegada[i] := qALlegada[i + 1];
            qAInicioC[i] := qAInicioC[i + 1];
            qADuracionC[i] := qADuracionC[i + 1];
            qADuracion[i] := qADuracion[i + 1];
          end if;
        end for;
        qArmadoN := qArmadoN - 1;
      end if;
    end for;

    // Incorporacion de pedidos a la tanda mientras exista capacidad
    for intento in 1:maxPedidos loop
      if qCoccionN > 0 and
         hamburguesasOcupadas + qCh[1] <=
           capacidadHamburguesasTanda and
         papasOcupadas + qCp[1] <= capacidadPapasTanda then

        slotLibre := 0;
        for s in 1:maxPedidos loop
          if slotLibre == 0 and not cActiva[s] then
            slotLibre := s;
          end if;
        end for;
        assert(slotLibre > 0, "No hay espacio interno para coccion");

        cantidadT := qCh[1];
        especialesT := qCe[1];
        papasT := qCp[1];
        simplesT := cantidadT - especialesT;

        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tMedallonT := tMedallonMin +
          aleatorioT * (tMedallonMax - tMedallonMin);
        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tPapasT := tPapasMin +
          aleatorioT * (tPapasMax - tPapasMin);

        if especialesT > 0 then
          (aleatorioT, estadoServicioT) :=
            Modelica.Math.Random.Generators.Xorshift1024star.random(
              estadoServicioT);
          tExtraT := tExtraMin +
            aleatorioT * (tExtraMax - tExtraMin);
          (aleatorioT, estadoServicioT) :=
            Modelica.Math.Random.Generators.Xorshift1024star.random(
              estadoServicioT);
          tAtencionT := especialesT *
            (tAtencionExtraMin + aleatorioT *
              (tAtencionExtraMax - tAtencionExtraMin)) /
            cocinerosPlancha;
        else
          tExtraT := 0;
          tAtencionT := 0;
        end if;
        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tAtencionBaseT := cantidadT *
          (tAtencionCoccionMin + aleatorioT *
            (tAtencionCoccionMax - tAtencionCoccionMin)) /
          cocinerosPlancha;

        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tArmadoSimpleT := tArmadoSimpleMin +
          aleatorioT * (tArmadoSimpleMax - tArmadoSimpleMin);
        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tArmadoEspecialT := tArmadoEspecialMin +
          aleatorioT * (tArmadoEspecialMax - tArmadoEspecialMin);
        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tEmpaqueT := tEmpaqueMin +
          aleatorioT * (tEmpaqueMax - tEmpaqueMin);
        (aleatorioT, estadoServicioT) :=
          Modelica.Math.Random.Generators.Xorshift1024star.random(
            estadoServicioT);
        tReposicionT := tReposicionMin +
          aleatorioT * (tReposicionMax - tReposicionMin);

        tCoccionT := factorCongestion *
          (max(max(tMedallonT, tPapasT), tExtraT) +
           tAtencionBaseT + tAtencionT);
        tArmadoT := factorCongestion * (tQueso +
          simplesT * tArmadoSimpleT +
          especialesT * tArmadoEspecialT +
          tEmpaqueT + tReposicionT);

        tiempoUnitarioSimple := factorCongestion *
          (max(tMedallonT, tPapasT) +
          tAtencionBaseT / cantidadT +
          tQueso / cantidadT + tArmadoSimpleT +
          (tEmpaqueT + tReposicionT) / cantidadT);
        tiempoUnitarioEspecial := factorCongestion * (
          max(max(tMedallonT, tPapasT), tExtraT) +
          tAtencionBaseT / cantidadT +
          (if especialesT > 0 then tAtencionT / especialesT else 0) +
          tQueso / cantidadT + tArmadoEspecialT +
          (tEmpaqueT + tReposicionT) / cantidadT);
        tiempoCoccionUltimoPedido := tCoccionT;
        tiempoArmadoUltimoPedido := tArmadoT;

        cActiva[slotLibre] := true;
        cFin[slotLibre] := time + tCoccionT;
        cId[slotLibre] := qCid[1];
        cH[slotLibre] := cantidadT;
        cE[slotLibre] := especialesT;
        cP[slotLibre] := papasT;
        cLlegada[slotLibre] := qCl[1];
        cInicio[slotLibre] := time;
        cDuracion[slotLibre] := tCoccionT;
        cArmado[slotLibre] := tArmadoT;
        hamburguesasOcupadas := hamburguesasOcupadas + cantidadT;
        papasOcupadas := papasOcupadas + papasT;
        cocinandoN := cocinandoN + 1;

        if qCid[1] == pedidoObjetivo then
          pedidoObjetivoIniciado := true;
          inicioCoccionPedidoObjetivo := time;
          esperaCoccionPedidoObjetivo := time - qCl[1];
        end if;

        for i in 1:maxPedidos - 1 loop
          if i < qCoccionN then
            qCid[i] := qCid[i + 1];
            qCh[i] := qCh[i + 1];
            qCe[i] := qCe[i + 1];
            qCp[i] := qCp[i + 1];
            qCl[i] := qCl[i + 1];
          end if;
        end for;
        qCoccionN := qCoccionN - 1;
      end if;
    end for;

    // Actualizacion del estado
    estadoDemanda := estadoDemandaT;
    estadoServicio := estadoServicioT;
    aleatorioDemanda := aleatorioT;
    aleatorioServicio := aleatorioT;
    longitudColaCoccion := qCoccionN;
    longitudColaArmado := qArmadoN;
    colaCoccionMaxima := max(pre(colaCoccionMaxima), qCoccionN);
    colaArmadoMaxima := max(pre(colaArmadoMaxima), qArmadoN);
    hamburguesasEnCoccion := hamburguesasOcupadas;
    papasEnCoccion := papasOcupadas;
    pedidosEnCoccion := cocinandoN;
    personasArmando := armandoN;
    pedidosTerminados := terminadosT;
    pedidosMas20Min := mas20T;
    pedidosMas35Min := mas35T;
    pedidosMas120Min := mas120T;
    sumaTiemposPedido := sumaTiemposT;
    tiempoMaximoPedido := maxTiempoT;
    ultimoTiempoPedido := ultimoTiempoT;
    tiempoFinalUltimoPedido := finUltimoT;

    colaCoccionId := qCid;
    colaCoccionHamburguesas := qCh;
    colaCoccionEspeciales := qCe;
    colaCoccionPapas := qCp;
    colaCoccionLlegada := qCl;
    coccionActiva := cActiva;
    finCoccion := cFin;
    coccionId := cId;
    coccionHamburguesas := cH;
    coccionEspeciales := cE;
    coccionPapas := cP;
    coccionLlegada := cLlegada;
    coccionInicio := cInicio;
    coccionDuracion := cDuracion;
    coccionArmadoCalculado := cArmado;

    colaArmadoId := qAid;
    colaArmadoHamburguesas := qAh;
    colaArmadoEspeciales := qAe;
    colaArmadoLlegada := qALlegada;
    colaArmadoInicioCoccion := qAInicioC;
    colaArmadoDuracionCoccion := qADuracionC;
    colaArmadoDuracion := qADuracion;
    armadoActivo := aActiva;
    finArmado := aFin;
    armadoId := aId;
    armadoLlegada := aLlegada;
    armadoInicioCoccion := aInicioC;
    armadoDuracionCoccion := aDuracionC;
    armadoInicio := aInicio;
    armadoDuracion := aDuracion;
  end when;

  //                              ECUACIONES
equation
  factorAtencionCoccion = 1.0 / cocinerosPlancha;
  pedidosEnProceso =
    longitudColaCoccion + pedidosEnCoccion +
    longitudColaArmado + personasArmando;
  balancePedidos =
    cantidadPedidos - pedidosTerminados - pedidosEnProceso;
  balanceHamburguesas =
    hamburguesasTotales -
    hamburguesasSimples - hamburguesasEspeciales;

  assert(balancePedidos == 0,
    "Fallo de conservacion de pedidos");
  assert(balanceHamburguesas == 0,
    "Fallo de clasificacion de hamburguesas");
  assert(hamburguesasEnCoccion >= 0 and
    hamburguesasEnCoccion <= capacidadHamburguesasTanda,
    "Capacidad de hamburguesas excedida");
  assert(papasEnCoccion >= 0 and
    papasEnCoccion <= capacidadPapasTanda,
    "Capacidad de papas excedida");
  assert(personasArmando >= 0 and
    personasArmando <= personasArmado,
    "Cantidad de personas armando invalida");

  tiempoPromedioPedido =
    if pedidosTerminados > 0 then
      sumaTiemposPedido / pedidosTerminados
    else 0;
  porcentajeMas20Min =
    if pedidosTerminados > 0 then
      100 * pedidosMas20Min / pedidosTerminados
    else 0;
  porcentajeMas35Min =
    if pedidosTerminados > 0 then
      100 * pedidosMas35Min / pedidosTerminados
    else 0;
  porcentajeMas120Min =
    if pedidosTerminados > 0 then
      100 * pedidosMas120Min / pedidosTerminados
    else 0;
  proporcionEspecialObservada =
    if hamburguesasTotales > 0 then
      hamburguesasEspeciales / hamburguesasTotales
    else 0;
  proporcionConPapasObservada =
    if hamburguesasTotales > 0 then
      porcionesPapasTotales / hamburguesasTotales
    else 0;
  errorCalibracionTiempo =
    if tiempoReferenciaObservado > 0 then
      tiempoPromedioPedido - tiempoReferenciaObservado
    else 0;
  errorCalibracionPorcentual =
    if tiempoReferenciaObservado > 0 then
      100 * errorCalibracionTiempo / tiempoReferenciaObservado
    else 0;

  der(cargaPlanchaAcumulada) =
    hamburguesasEnCoccion / capacidadHamburguesasTanda;
  der(cargaFreidoraAcumulada) =
    papasEnCoccion / capacidadPapasTanda;
  der(cargaArmadoAcumulada) =
    personasArmando / personasArmado;

  utilizacionPlancha =
    if tiempoFinalUltimoPedido > 0 then
      100 * cargaPlanchaAcumulada / tiempoFinalUltimoPedido
    else 0;
  utilizacionFreidora =
    if tiempoFinalUltimoPedido > 0 then
      100 * cargaFreidoraAcumulada / tiempoFinalUltimoPedido
    else 0;
  utilizacionArmado =
    if tiempoFinalUltimoPedido > 0 then
      100 * cargaArmadoAcumulada / tiempoFinalUltimoPedido
    else 0;

  annotation(
    experiment(
      StartTime = 0,
      StopTime = 210,
      Tolerance = 1e-06,
      Interval = 0.1));
end Simulacion;




