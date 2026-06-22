"""Ejecuta replicas pareadas y compara escenarios de cocineros."""

from __future__ import annotations

import argparse
import csv
import random
import shutil
import statistics
import subprocess
import tempfile
from pathlib import Path


METRICAS = (
    "cantidadPedidos",
    "pedidosTerminados",
    "tiempoPromedioPedido",
    "tiempoMaximoPedido",
    "colaCoccionMaxima",
    "colaArmadoMaxima",
    "porcentajeMas20Min",
    "porcentajeMas35Min",
    "porcentajeMas120Min",
    "utilizacionPlancha",
    "utilizacionFreidora",
    "utilizacionArmado",
    "balancePedidos",
    "balanceHamburguesas",
)

OMC_PREDETERMINADO = Path(
    r"C:\Program Files\OpenModelica1.26.3-64bit\bin\omc.exe"
)


def argumentos() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compara 1, 2 y 3 cocineros mediante replicas pareadas."
    )
    parser.add_argument("--replicas", type=int, default=30)
    parser.add_argument("--cocineros", type=int, nargs="+", default=[1, 2, 3])
    parser.add_argument("--pedidos-por-hora", type=float, default=12.0)
    parser.add_argument("--duracion-pico", type=float, default=120.0)
    parser.add_argument("--horizonte", type=float, default=480.0)
    parser.add_argument("--personas-armado", type=int, default=2)
    parser.add_argument("--hamburguesas-min", type=int, default=1)
    parser.add_argument("--hamburguesas-max", type=int, default=4)
    parser.add_argument("--porcentaje-especiales", type=float, default=0.35)
    parser.add_argument("--porcentaje-papas", type=float, default=0.75)
    parser.add_argument("--factor-congestion", type=float, default=1.0)
    parser.add_argument("--bootstrap", type=int, default=10000)
    parser.add_argument(
        "--salida", type=Path, default=Path("resultados_estadisticos.csv")
    )
    parser.add_argument("--omc", type=Path, default=OMC_PREDETERMINADO)
    args = parser.parse_args()

    if args.replicas < 2:
        parser.error("--replicas debe ser al menos 2")
    if args.bootstrap < 1000:
        parser.error("--bootstrap debe ser al menos 1000")
    if not args.cocineros or any(c < 1 or c > 3 for c in args.cocineros):
        parser.error("--cocineros solo admite 1, 2 y 3")
    if len(set(args.cocineros)) != len(args.cocineros):
        parser.error("--cocineros no debe contener valores repetidos")
    if 1 not in args.cocineros:
        parser.error("Debe incluirse el escenario base de 1 cocinero")
    if args.horizonte < args.duracion_pico:
        parser.error("--horizonte debe ser mayor o igual a --duracion-pico")
    if args.hamburguesas_min > args.hamburguesas_max:
        parser.error("El minimo de hamburguesas supera al maximo")
    return args


def ejecutar(comando: list[str], carpeta: Path) -> subprocess.CompletedProcess[str]:
    resultado = subprocess.run(
        comando,
        cwd=carpeta,
        text=True,
        capture_output=True,
        check=False,
    )
    if resultado.returncode != 0:
        detalle = resultado.stdout + "\n" + resultado.stderr
        raise RuntimeError(f"Fallo el comando: {' '.join(comando)}\n{detalle}")
    return resultado


def compilar_modelo(omc: Path, modelo: Path, temporal: Path, horizonte: float) -> Path:
    prefijo = temporal / "SimulacionEstadistica"
    filtro = "|".join(METRICAS)
    intervalos = max(1, round(horizonte))
    script = temporal / "compilar.mos"
    script.write_text(
        "\n".join(
            (
                "loadModel(Modelica);",
                f'loadFile("{modelo.resolve().as_posix()}");',
                "buildModel(Simulacion, "
                f"startTime=0, stopTime={horizonte * 60:g}, "
                f"numberOfIntervals={intervalos}, outputFormat=\"csv\", "
                'fileNamePrefix="SimulacionEstadistica", '
                f'variableFilter="{filtro}");',
                "getErrorString();",
            )
        ),
        encoding="utf-8",
    )
    resultado = ejecutar([str(omc), str(script)], temporal)
    if "Error:" in resultado.stdout or "Error:" in resultado.stderr:
        raise RuntimeError(resultado.stdout + "\n" + resultado.stderr)

    ejecutable = prefijo.with_suffix(".exe")
    if not ejecutable.exists():
        raise RuntimeError("OpenModelica no genero el ejecutable esperado")
    return ejecutable


def leer_ultimo_registro(ruta: Path) -> dict[str, float]:
    with ruta.open(newline="", encoding="utf-8") as archivo:
        ultimo = None
        for fila in csv.DictReader(archivo):
            ultimo = fila
    if ultimo is None:
        raise RuntimeError(f"El resultado {ruta} esta vacio")
    return {metrica: float(ultimo[metrica]) for metrica in METRICAS}


def crear_override(args: argparse.Namespace, replica: int, cocineros: int) -> str:
    valores = {
        "replica": replica,
        "cocinerosPlancha": cocineros,
        "personasArmado": args.personas_armado,
        "pedidosPorHora": args.pedidos_por_hora,
        "duracionPico": args.duracion_pico,
        "duracionSimulacion": args.horizonte,
        "hamburguesasMin": args.hamburguesas_min,
        "hamburguesasMax": args.hamburguesas_max,
        "porcentajeEspeciales": args.porcentaje_especiales,
        "porcentajeConPapas": args.porcentaje_papas,
        "factorCongestion": args.factor_congestion,
    }
    return ",".join(f"{nombre}={valor}" for nombre, valor in valores.items())


def correr_replicas(
    ejecutable: Path, temporal: Path, args: argparse.Namespace
) -> list[dict[str, float | int | str]]:
    filas: list[dict[str, float | int | str]] = []
    for cocineros in args.cocineros:
        for replica in range(args.replicas):
            resultado_csv = temporal / f"c{cocineros}_r{replica}.csv"
            ejecutar(
                [
                    str(ejecutable),
                    f"-override={crear_override(args, replica, cocineros)}",
                    f"-r={resultado_csv}",
                ],
                temporal,
            )
            metricas = leer_ultimo_registro(resultado_csv)
            resultado_csv.unlink()

            if round(metricas["balancePedidos"]) != 0:
                raise RuntimeError(
                    f"Fallo el balance: {cocineros} cocineros, replica {replica}"
                )
            if round(metricas["balanceHamburguesas"]) != 0:
                raise RuntimeError(
                    f"Fallo la clasificacion de hamburguesas, replica {replica}"
                )
            if round(metricas["cantidadPedidos"]) != round(
                metricas["pedidosTerminados"]
            ):
                raise RuntimeError(
                    "El horizonte no alcanzo para terminar todos los pedidos: "
                    f"{cocineros} cocineros, replica {replica}"
                )

            filas.append(
                {
                    "tipo": "corrida",
                    "cocineros": cocineros,
                    "replica": replica,
                    **metricas,
                }
            )
    return filas


def percentil_ordenado(valores: list[float], proporcion: float) -> float:
    posicion = (len(valores) - 1) * proporcion
    inferior = int(posicion)
    superior = min(inferior + 1, len(valores) - 1)
    fraccion = posicion - inferior
    return valores[inferior] * (1 - fraccion) + valores[superior] * fraccion


def intervalo_bootstrap(
    valores: list[float], repeticiones: int, semilla: int
) -> tuple[float, float]:
    generador = random.Random(semilla)
    n = len(valores)
    medias = sorted(
        statistics.fmean(generador.choice(valores) for _ in range(n))
        for _ in range(repeticiones)
    )
    return percentil_ordenado(medias, 0.025), percentil_ordenado(medias, 0.975)


def resumir(
    corridas: list[dict[str, float | int | str]], args: argparse.Namespace
) -> list[dict[str, float | int | str]]:
    por_cocinero = {
        cocineros: sorted(
            (fila for fila in corridas if fila["cocineros"] == cocineros),
            key=lambda fila: int(fila["replica"]),
        )
        for cocineros in args.cocineros
    }
    base = por_cocinero[1]
    media_base = statistics.fmean(
        float(fila["tiempoPromedioPedido"]) for fila in base
    )
    resumen: list[dict[str, float | int | str]] = []

    for cocineros in args.cocineros:
        filas = por_cocinero[cocineros]
        tiempos = [float(fila["tiempoPromedioPedido"]) for fila in filas]
        inferior, superior = intervalo_bootstrap(
            tiempos, args.bootstrap, 1000 + cocineros
        )
        fila_resumen: dict[str, float | int | str] = {
            "tipo": "resumen",
            "cocineros": cocineros,
            "replica": "",
            "mediaTiempoPromedio": statistics.fmean(tiempos),
            "desvioTiempoPromedio": statistics.stdev(tiempos),
            "ic95InferiorTiempoPromedio": inferior,
            "ic95SuperiorTiempoPromedio": superior,
            "mediaTiempoMaximo": statistics.fmean(
                float(fila["tiempoMaximoPedido"]) for fila in filas
            ),
            "mediaColaArmadoMaxima": statistics.fmean(
                float(fila["colaArmadoMaxima"]) for fila in filas
            ),
        }

        if cocineros == 1:
            fila_resumen.update(
                {
                    "mejoraMediaVsUno": 0.0,
                    "mejoraPorcentualVsUno": 0.0,
                    "ic95InferiorMejora": 0.0,
                    "ic95SuperiorMejora": 0.0,
                    "significativa": "base",
                }
            )
        else:
            diferencias = [
                float(fila_base["tiempoPromedioPedido"])
                - float(fila_alternativa["tiempoPromedioPedido"])
                for fila_base, fila_alternativa in zip(base, filas)
            ]
            mejora = statistics.fmean(diferencias)
            inf_mejora, sup_mejora = intervalo_bootstrap(
                diferencias, args.bootstrap, 2000 + cocineros
            )
            if inf_mejora > 0:
                significativa = "si_mejora"
            elif sup_mejora < 0:
                significativa = "si_empeora"
            else:
                significativa = "no"
            fila_resumen.update(
                {
                    "mejoraMediaVsUno": mejora,
                    "mejoraPorcentualVsUno": 100 * mejora / media_base,
                    "ic95InferiorMejora": inf_mejora,
                    "ic95SuperiorMejora": sup_mejora,
                    "significativa": significativa,
                }
            )
        resumen.append(fila_resumen)
    return resumen


def guardar(
    ruta: Path,
    corridas: list[dict[str, float | int | str]],
    resumen: list[dict[str, float | int | str]],
    args: argparse.Namespace,
) -> Path:
    configuracion = {
        "replicasConfiguradas": args.replicas,
        "pedidosPorHoraConfigurados": args.pedidos_por_hora,
        "duracionPicoMin": args.duracion_pico,
        "horizonteMin": args.horizonte,
        "personasArmadoConfiguradas": args.personas_armado,
        "hamburguesasMinConfiguradas": args.hamburguesas_min,
        "hamburguesasMaxConfiguradas": args.hamburguesas_max,
        "porcentajeEspecialesConfigurado": args.porcentaje_especiales,
        "porcentajePapasConfigurado": args.porcentaje_papas,
        "factorCongestionConfigurado": args.factor_congestion,
    }
    campos_corridas = list(configuracion) + [
        "tipo",
        "cocineros",
        "replica",
        *METRICAS,
    ]
    campos_resumen = list(configuracion) + [
        "tipo",
        "cocineros",
        "mediaTiempoPromedio",
        "desvioTiempoPromedio",
        "ic95InferiorTiempoPromedio",
        "ic95SuperiorTiempoPromedio",
        "mediaTiempoMaximo",
        "mediaColaArmadoMaxima",
        "mejoraMediaVsUno",
        "mejoraPorcentualVsUno",
        "ic95InferiorMejora",
        "ic95SuperiorMejora",
        "significativa",
    ]

    def valor_excel(valor: float | int | str | None) -> str:
        if valor is None or valor == "":
            return ""
        if isinstance(valor, str):
            return valor
        numero = float(valor)
        if numero.is_integer():
            return str(int(numero))
        return f"{numero:.4f}".rstrip("0").rstrip(".").replace(".", ",")

    def escribir(ruta_destino: Path, campos: list[str], filas: list[dict]) -> None:
        with ruta_destino.open("w", newline="", encoding="utf-8-sig") as archivo:
            escritor = csv.DictWriter(
                archivo,
                fieldnames=campos,
                delimiter=";",
                extrasaction="ignore",
                lineterminator="\n",
            )
            escritor.writeheader()
            for fila in filas:
                completa = {**configuracion, **fila}
                escritor.writerow(
                    {campo: valor_excel(completa.get(campo, "")) for campo in campos}
                )

    ruta.parent.mkdir(parents=True, exist_ok=True)
    ruta_corridas = ruta.with_name(f"{ruta.stem}_corridas{ruta.suffix}")
    escribir(ruta_corridas, campos_corridas, corridas)
    escribir(ruta, campos_resumen, resumen)
    return ruta_corridas


def imprimir_resumen(resumen: list[dict[str, float | int | str]]) -> None:
    print("\nCocineros | Media min | IC95 media | Mejora vs 1 | IC95 mejora | Resultado")
    for fila in resumen:
        print(
            f"{int(fila['cocineros']):9d} | "
            f"{float(fila['mediaTiempoPromedio']):9.2f} | "
            f"[{float(fila['ic95InferiorTiempoPromedio']):.2f}, "
            f"{float(fila['ic95SuperiorTiempoPromedio']):.2f}] | "
            f"{float(fila['mejoraMediaVsUno']):11.2f} | "
            f"[{float(fila['ic95InferiorMejora']):.2f}, "
            f"{float(fila['ic95SuperiorMejora']):.2f}] | "
            f"{fila['significativa']}"
        )


def main() -> None:
    args = argumentos()
    proyecto = Path(__file__).resolve().parent
    modelo = proyecto / "integrador.mo"
    omc = args.omc.resolve()
    if not modelo.exists():
        raise FileNotFoundError(modelo)
    if not omc.exists():
        alternativa = shutil.which("omc")
        if alternativa is None:
            raise FileNotFoundError(
                "No se encontro omc.exe; indique su ruta mediante --omc"
            )
        omc = Path(alternativa)

    with tempfile.TemporaryDirectory(prefix="tp_integrador_") as carpeta:
        temporal = Path(carpeta)
        ejecutable = compilar_modelo(omc, modelo, temporal, args.horizonte)
        corridas = correr_replicas(ejecutable, temporal, args)

    resumen = resumir(corridas, args)
    salida = args.salida
    if not salida.is_absolute():
        salida = proyecto / salida
    salida_corridas = guardar(salida, corridas, resumen, args)
    imprimir_resumen(resumen)
    print(f"\nResumen: {salida}")
    print(f"Corridas: {salida_corridas}")


if __name__ == "__main__":
    main()
