# Estándar de Versionado de Software

**Organización:** Rfacil
**Documento:** ENG-STD-001 — Estándar de Versionado, Releases y Revisiones
**Versión del documento:** 1.3.0
**Vigencia:** a partir de su aprobación
**Alcance:** todo repositorio de código productivo o preproductivo de la organización

---

## Tabla de contenido

0. **[Cómo usar este documento](#0-cómo-usar-este-documento)** ← empieza aquí
1. [Propósito y alcance](#1-propósito-y-alcance)
2. [Convenciones normativas del documento](#2-convenciones-normativas-del-documento)
3. [Formato de versión: SemVer 2.0.0](#3-formato-de-versión-semver-200)
4. [La superficie pública: el concepto que decide todo](#4-la-superficie-pública-el-concepto-que-decide-todo)
5. [Cómo y cuándo se decide MAYOR, MENOR o PARCHE](#5-cómo-y-cuándo-se-decide-mayor-menor-o-parche)
6. [Casos ambiguos y reglas de desempate](#6-casos-ambiguos-y-reglas-de-desempate)
7. [Conventional Commits: de commit a número de versión](#7-conventional-commits-de-commit-a-número-de-versión)
8. [Pre-releases: alpha, beta, rc y metadata de build](#8-pre-releases-alpha-beta-rc-y-metadata-de-build)
9. [Tipos de release](#9-tipos-de-release)
10. [Escenario A — Sistema monolítico](#10-escenario-a--sistema-monolítico)
11. [Escenario B — Back y Front conectados por API](#11-escenario-b--back-y-front-conectados-por-api)
12. [GitFlow: ramas, tags, ambientes y dónde nace el número de versión](#12-gitflow-ramas-tags-ambientes-y-dónde-nace-el-número-de-versión)
13. [Revisiones (parte 1): code review y pull requests](#13-revisiones-parte-1-code-review-y-pull-requests)
14. [Revisiones (parte 2): revisión de release y post-release](#14-revisiones-parte-2-revisión-de-release-y-post-release)
15. [Política de soporte y deprecación](#15-política-de-soporte-y-deprecación)
16. [Automatización y controles en CI/CD](#16-automatización-y-controles-en-cicd)
17. [Gobierno, roles y excepciones](#17-gobierno-roles-y-excepciones)
18. [Anexos](#18-anexos)

---

## 0. Cómo usar este documento

> **Lee esta sección antes que cualquier otra.** Define qué parte del estándar tienes que saber de memoria, qué parte se consulta solo cuando aparece el caso, y qué parte todavía no aplica en Rfacil.

### 0.1 Qué es y qué no es

| Este documento **sí** es | Este documento **no** es |
|---|---|
| Una **referencia** que se abre cuando aparece una duda concreta | Un checklist que se ejecuta a diario |
| El lugar donde se zanjan las discusiones de clasificación ya resueltas | Una lista de 126 reglas que alguien deba memorizar |
| Un contrato de equipo sobre cómo se libera software | Una evaluación del trabajo pasado |
| Un documento vivo, que se corrige cuando una regla estorba | Un reglamento inmutable |

Tres consecuencias prácticas:

1. **No se audita hacia atrás.** El estándar aplica desde su fecha de vigencia. **PROHIBIDO** reconstruir historial, renumerar versiones antiguas o revisar releases pasados con estas reglas (§17.4).
2. **Solo se memorizan 12 reglas** (§0.2). Todo lo demás se busca en el índice cuando toca.
3. **Una regla que necesita excepción recurrente está mal diseñada.** Se corrige el estándar, no se acumulan excepciones (§17.3).

### 0.2 Las 12 reglas que sí se saben de memoria

Son las que aplican a diario, a todas las personas, en todos los repositorios activos. Si el equipo cumple solo estas 12, ya obtuvo la mayor parte del beneficio del estándar.

| # | Regla | Detalle | Ref. |
|---|---|---|---|
| 1 | **Nada entra a `main` ni a `develop` sin pull request** | ni siquiera un cambio de una línea, ni siquiera el más senior | §12.1 |
| 2 | **Un PR, un propósito, ≤ 400 líneas** | prohibido mezclar refactor con cambio funcional | §13.2 |
| 3 | **Todo commit y todo título de PR es convencional** | `feat:`, `fix:`, `perf:`, `docs:`… y `!` o `BREAKING CHANGE:` cuando rompe | §7.1 |
| 4 | **Todo PR lleva su etiqueta `semver:major\|minor\|patch\|none`** | declararla obliga a pensar en el impacto antes de mergear | §5.1 |
| 5 | **Antes de clasificar, aplica la prueba del consumidor honesto** | *"quien ya lo usaba y le funcionaba, ¿tiene que cambiar algo?"* Sí → mayor | §4.3 |
| 6 | **Agregar es menor; quitar, renombrar o exigir es mayor** | incluye variables de entorno, defaults, unidades, formatos y métricas | §5.3–§5.5 |
| 7 | **Ante la duda entre dos niveles, se elige el más alto** | el costo de un mayor de más es una nota; el de un mayor disfrazado es una caída | §6.9 |
| 8 | **La versión nunca se escribe a mano** | la calcula y publica la herramienta; editar `package.json` está prohibido | §16.1 |
| 9 | **Una versión publicada es inmutable** | nunca se re-taggea ni se sobrescribe; si salió mal, sale la siguiente | §3.1 |
| 10 | **El CHANGELOG se escribe en el PR, no la noche del release** | y se redacta para quien consume, no para quien programa | Anexo C |
| 11 | **Rama de más de 5 días: se parte o se integra tras bandera apagada** | una rama larga no es una rama, es un fork | §12.1, §12.7.2 |
| 12 | **Los ambientes ejecutan versiones, no ramas** | se compila una vez y se promueve el mismo artefacto; QA, DEMO y producción en versiones distintas es normal | §12.6 |

Regla 13, implícita: **si tu caso no está en estas 12, búscalo en §0.3 antes de improvisar.**

### 0.3 El resto se consulta: índice por situación

No se lee el documento completo. Se abre por el caso que se tiene enfrente:

| Si te toca… | Lee |
|---|---|
| Decidir si un cambio es mayor, menor o parche | §5 (árbol y tablas), y §6 si es un caso raro |
| Definir qué es público en tu repo | §4 y la plantilla del Anexo B |
| Un cambio que rompe y no sabes cómo evitarlo | §11.6 (expand/contract) y §6.4 |
| Escribir el mensaje de commit | §7 |
| Publicar un `-rc`, `-beta` o build de prueba | §8 |
| Preparar un release y no sabes qué tipo es | §9 |
| Versionar un monolito | §10 |
| Coordinar versiones entre back y front | §11 |
| Saber qué rama usar o dónde nace el número | §12.1–§12.5 |
| Entender por qué QA y DEMO no llevan rama | §12.6 |
| Retomar una rama que quedó muy atrás | §12.7 |
| Revisar el PR de alguien más | §13.4 (checklist) |
| Autorizar la salida de un release | §14.1 |
| Retirar un endpoint o un campo | §15 |
| Montar la automatización | §16 |
| Pedir una excepción | §17.3 |
| Ver el caso resuelto en lugar de la regla | **Anexo F** (20 ejercicios) y **Anexo A** (tarjeta de decisión) |
| Traducir una palabra rara | Anexo G |

**Atajo:** para el 95 % de los casos diarios basta con la **tarjeta de decisión rápida del Anexo A**. Está pensada para imprimirse y pegarse a la vista.

### 0.4 Qué aplica a cada repositorio

**No todo el estándar aplica a todos los repos.** Cada repositorio tiene asignado un **nivel de cumplimiento** según su criticidad, declarado como propiedad del repositorio y visible en su README.

| | **Nivel 1 — Congelado** | **Nivel 2 — Núcleo** | **Nivel 3 — Completo** |
|---|---|---|---|
| **A quién aplica** | repos sin cambios en 6+ meses o en desuso | en producción, consumido solo internamente | en producción **y** con consumidores externos al repo |
| Tag del estado actual y rótulo de estado | ✅ | ✅ | ✅ |
| Reglas 1 a 12 de §0.2 | — | ✅ | ✅ |
| `CHANGELOG.md` y `GET /version` | — | ✅ | ✅ |
| `CONTRACT.md` | — | ligero | ✅ completo |
| Diff de contrato en CI | — | — | ✅ |
| Matriz de compatibilidad (§11.5) | — | — | ✅ |
| Niveles de revisión R1–R3 | — | R1 / R2 | ✅ R1–R3 |
| Go/No-Go formal y política de deprecación | — | — | ✅ |

**Regla:** un repo de nivel 1 que se reactive **DEBE** subir al nivel que le corresponda **antes** de aceptar su primer pull request. Nada se reactiva en nivel 1.

### 0.5 Reglas con condición de activación

Varias secciones de este documento describen prácticas que **hoy no aplican en Rfacil** porque protegen contra riesgos que la organización todavía no tiene. Están escritas para que existan el día que el riesgo aparezca, no para cumplirse ahora.

**Una regla marcada aquí no se incumple: está inactiva.** No cuenta para la auditoría hasta que se cumple su condición.

| Sección | Práctica | Se activa cuando… | Mientras tanto |
|---|---|---|---|
| §11.8 | **Contract testing tipo Pact** (broker, expectativas por consumidor) | haya **3 o más consumidores** del mismo contrato, o un consumidor fuera del equipo | el diff de contrato con `oasdiff` cubre la mayor parte del beneficio, y **sí** es obligatorio |
| §11.8 | **Cliente/SDK generado y publicado** | haya 2 o más consumidores del mismo contrato | el front genera sus tipos localmente desde el OpenAPI |
| §9.1, §15.1 | **Ramas `support/X.Y` y líneas LTS** | un cliente exija por contrato una línea antigua, o exista app móvil con adopción < 95 % | solo se soporta la línea vigente |
| §11.6 fase 3, §15.3 punto 4 | **Telemetría de uso por consumidor** de elementos deprecados | exista un consumidor externo o una app móvil que no se pueda forzar a migrar | se verifica el uso con logs y búsqueda en los repos consumidores conocidos |
| §15.2 filas de socios y móvil | **Ventanas de deprecación de 90 días y 6 meses** | existan consumidores externos, socios o app en tiendas | aplican las ventanas internas: 2 releases menores y 60 días |
| §9.6 | **Embargo de seguridad y publicación de CVE** | exista API pública o clientes con contrato de notificación | corrección inmediata + aviso interno |
| §17.1, §17.2 | **Los seis roles y el RACI completo** | exista **más de un equipo** de desarrollo | los roles se colapsan en tres: Version Owner, Tech Lead y Release Manager (este último puede rotar) |
| §14.1 | **Go/No-Go con junta formal y 5+ participantes** | el release sea **mayor** | los menores y parches se autorizan de forma asincrónica en el ticket, con los mismos criterios |
| §12.6.3 | **Ambientes efímeros por rama** | la cola por el ambiente de QA se vuelva un cuello de botella medible | se coordina el uso de QA y se rotula quién lo tiene |
| §11.9 | **Herramientas de monorepo** (`changesets`, tags con prefijo) | se adopte un monorepo | repos separados con `semantic-release` |

Estas condiciones se revisan en la **auditoría trimestral** (§14.3): si alguna se cumplió, la práctica pasa a activa y se planifica su implementación. **PROHIBIDO** activar una regla de esta tabla sin registrarlo, y **PROHIBIDO** reportar como incumplimiento una regla inactiva.

### 0.6 Rutas de lectura la primera vez

| Rol | Qué leer | Tiempo |
|---|---|---|
| **Cualquier persona del equipo** | §0.2 (las 12 reglas), Anexo A (tarjeta), Anexo F (los 20 ejercicios) | 30 min |
| **Quien revisa PRs** | lo anterior + §4, §5, §13 | 1 h |
| **Quien libera** | lo anterior + §8, §9, §12, §14, Anexo E | 2 h |
| **Version Owner / Tech Lead** | el documento completo | 3 h |
| **Alguien que se integra al equipo** | §0 completo + Anexo F, y el `CONTRACT.md` de sus repos | 45 min |

Para una explicación en lenguaje llano, sin el vocabulario normativo de este documento, existe la guía de lectura complementaria *"Versionado de software, explicado en simple"*. **No sustituye a este estándar**, pero es la mejor puerta de entrada.

---
## 1. Propósito y alcance

### 1.1 Problema que resuelve

Sin un estándar, el número de versión se vuelve decorativo: nadie sabe si actualizar de `2.3.1` a `2.4.0` es seguro, los equipos dependientes prueban "por si acaso", los rollbacks son adivinanza y el CHANGELOG se escribe después del incidente. Un número de versión bien gobernado es un **contrato de riesgo**: comunica, antes de instalar, cuánto trabajo implica adoptar el cambio.

### 1.2 Objetivo

Que cualquier persona de la organización pueda mirar dos versiones y responder sin consultar a nadie:

| Pregunta | Respuesta que da la versión |
|---|---|
| ¿Puedo actualizar sin cambiar mi código? | Sí, si solo cambió MENOR o PARCHE |
| ¿Necesito plan de migración? | Sí, si cambió MAYOR |
| ¿Esto es estable? | Sí, si no tiene sufijo de pre-release |
| ¿Qué exactamente cambió? | El CHANGELOG de esa versión |
| ¿Qué está corriendo en producción? | El tag inmutable + el endpoint `/version` |

### 1.3 Alcance

**Aplica a:** servicios backend, aplicaciones frontend, apps móviles, librerías internas, SDKs, contratos de API (OpenAPI/AsyncAPI), esquemas de eventos, imágenes de contenedor, charts de despliegue e infraestructura como código.

**No aplica a:** ramas de exploración personal que nunca se mergean, prototipos desechables marcados como tales y documentos no ejecutables (que usan su propio versionado editorial).

### 1.4 Principios

1. **La versión describe el impacto en quien consume, no el esfuerzo de quien desarrolla.** Un refactor de tres semanas que no cambia nada observable es un PARCHE o ni siquiera genera release. Renombrar un campo en 30 segundos es MAYOR.
2. **Una versión publicada es inmutable.** Nunca se re-taggea, nunca se sobrescribe un artefacto. Si salió mal, sale otra versión.
3. **Si hay duda entre dos niveles, se elige el más alto.** El costo de un MAYOR innecesario es una nota de release; el costo de un MAYOR disfrazado de MENOR es una caída en producción de un consumidor.
4. **Toda versión productiva es trazable** a un commit firmado, un pipeline y una aprobación.
5. **Automatizar antes que confiar en disciplina.** Lo que puede validar el CI, lo valida el CI.

---

## 2. Convenciones normativas del documento

| Palabra | Significado |
|---|---|
| **DEBE / OBLIGATORIO** | Requisito. Su incumplimiento bloquea el merge o el release. |
| **DEBERÍA / RECOMENDADO** | Requisito fuerte. Se puede omitir solo con justificación escrita en el PR. |
| **PUEDE / OPCIONAL** | A criterio del equipo. |
| **NO DEBE / PROHIBIDO** | Prohibición. Requiere excepción formal (§17.3). |

---

## 3. Formato de versión: SemVer 2.0.0

Todo artefacto versionable **DEBE** usar Semantic Versioning 2.0.0.

```
MAYOR . MENOR . PARCHE [ - pre-release ] [ + build ]
  │       │       │          │              │
  │       │       │          │              └─ metadata, NO afecta precedencia
  │       │       │          └──────────────── inestable, precede a la versión final
  │       │       └─────────────────────────── correcciones compatibles
  │       └─────────────────────────────────── funcionalidad nueva compatible
  └─────────────────────────────────────────── cambios incompatibles (breaking)
```

Ejemplos válidos:

```
1.0.0              estable
2.4.1              estable
3.0.0-alpha.1      pre-release interna
3.0.0-beta.2       pre-release para clientes selectos
3.0.0-rc.1         candidato a release
2.4.1+build.842    estable con metadata de build
0.7.3              fase inicial (§3.4)
```

### 3.1 Reglas duras del formato

1. Los tres números **DEBEN** ser enteros no negativos, sin ceros a la izquierda (`1.2.3`, nunca `1.02.3`).
2. Los números **NO DEBEN** decrecer nunca.
3. Al incrementar MAYOR, MENOR y PARCHE se reinician a `0` → `2.7.4` → `3.0.0`.
4. Al incrementar MENOR, PARCHE se reinicia a `0` → `2.7.4` → `2.8.0`.
5. **PROHIBIDO** usar el número de versión para comunicar marketing, fechas, sprints o número de ticket. Para eso existen los alias (§3.5).
6. Una versión, una vez publicada (tag creado y artefacto subido al registro), **NO DEBE** modificarse ni eliminarse. Si se detecta un error, se publica la siguiente.

### 3.2 Qué significa cada segmento, en una línea

| Segmento | Se incrementa cuando… | El consumidor debe… |
|---|---|---|
| **MAYOR** | se rompe la compatibilidad del contrato público | leer la guía de migración y cambiar su código o configuración |
| **MENOR** | se agrega capacidad compatible, o se deprecia algo (sin quitarlo) | nada; puede adoptar lo nuevo cuando quiera |
| **PARCHE** | se corrige un defecto sin cambiar el contrato | nada; solo actualizar |

### 3.3 Precedencia (orden de versiones)

Se compara MAYOR, luego MENOR, luego PARCHE numéricamente. Una versión **con** pre-release es **menor** que la misma versión sin él. La metadata de build se ignora.

```
1.0.0-alpha  <  1.0.0-alpha.1  <  1.0.0-alpha.beta  <  1.0.0-beta
             <  1.0.0-beta.2   <  1.0.0-beta.11     <  1.0.0-rc.1
             <  1.0.0          <  1.0.1             <  1.1.0  <  2.0.0
```

Nota práctica: `1.0.0-beta.11 > 1.0.0-beta.2` porque los identificadores numéricos se comparan como números, no como texto. Por eso **PROHIBIDO** usar `-beta.02`.

### 3.4 La fase `0.y.z` y cuándo salir de ella

Mientras la versión MAYOR sea `0`, el contrato se considera inestable y **cualquier** cambio puede ser incompatible. Convención de la organización durante `0.y.z`:

- Un breaking change incrementa **MENOR** (`0.7.4` → `0.8.0`).
- Un cambio compatible o un fix incrementa **PARCHE** (`0.7.4` → `0.7.5`).

Un proyecto **DEBE** pasar a `1.0.0` cuando ocurra cualquiera de estas condiciones:

- se usa en producción con tráfico real, o
- existe al menos un consumidor externo al equipo que lo escribió, o
- se documentó públicamente su API.

**PROHIBIDO** mantener un servicio en `0.x` con más de 3 meses en producción. Es la forma más común de evadir la disciplina de versionado.

### 3.5 Alias: cómo comunicar sin ensuciar la versión

Cuando negocio necesita un nombre comercial o un identificador de ciclo, se usa un **alias** que apunta a una versión SemVer, nunca en lugar de ella.

| Uso | Formato | Ejemplo |
|---|---|---|
| Nombre comercial del release | texto libre, en las notas | "Release Otoño 2026" → `4.0.0` |
| Ciclo de entrega interno | metadata de build o notas | `4.0.0+sprint.71` |
| Trazabilidad de build | metadata de build | `4.0.0+20260818.a1b2c3d` |
| Canal de distribución | tag de contenedor adicional | `app:4.0.0`, `app:4`, `app:stable` |

---

## 4. La superficie pública: el concepto que decide todo

**No se puede decidir si un cambio es mayor o menor sin haber definido antes qué es público.** Este es el paso que casi todos los equipos omiten, y es la causa raíz del 90 % de las discusiones de versionado.

Cada repositorio **DEBE** tener un archivo `CONTRACT.md` (o una sección en su README) que declare explícitamente su superficie pública.

### 4.1 Qué es superficie pública

Es todo aquello de lo que un tercero puede depender legítimamente porque está documentado o expuesto de forma estable.

| Tipo de proyecto | Superficie pública típica |
|---|---|
| **API HTTP / servicio** | rutas, métodos, parámetros, esquemas de request/response, códigos de estado, formato de error, headers relevantes, semántica de idempotencia, paginación, ordenamientos por defecto, límites de tasa documentados, esquemas de autenticación, webhooks y eventos publicados |
| **Librería / SDK** | símbolos exportados, firmas de funciones, tipos públicos, comportamiento documentado, versión mínima de runtime, dependencias que se filtran (peer deps) |
| **Aplicación frontend** | rutas navegables y deep links, contrato con la API que consume, parámetros de URL, formato de datos persistidos en el cliente, variables de configuración en tiempo de build/run, atributos usados por automatizaciones o analítica (`data-testid` documentado) |
| **CLI** | comandos, flags, formato de salida cuando es parseable, códigos de salida, variables de entorno, formato del archivo de configuración |
| **Base de datos compartida** | esquemas, vistas, funciones y eventos que consumen otros sistemas |
| **Cualquiera** | contrato operativo: variables de entorno requeridas, puertos, formato de logs consumido por alertas, métricas expuestas, requisitos de infraestructura |

### 4.2 Qué NO es superficie pública

- Módulos y funciones marcadas como internas (`_privado`, `internal/`, no exportadas).
- Estructura de carpetas, nombres de clases internas, esquema de tablas propias no compartidas.
- Endpoints marcados como `/internal/*` o `experimental` y documentados como inestables.
- Rendimiento absoluto, salvo que exista un SLA escrito.
- Textos de log no contractuales, mensajes de error en prosa (sí lo es el **código** de error).
- Detalles de implementación que se filtran por accidente y están documentados como "no depender de esto".

> **Regla de oro:** si algo no está en `CONTRACT.md`, no es público, y cambiarlo **no** obliga a MAYOR. Pero si un consumidor real ya depende de eso, primero se documenta y se define, y luego se cambia con la clasificación que corresponda. No se usa el vacío documental como atajo.

### 4.3 La prueba del consumidor honesto

Es el test mental obligatorio antes de clasificar cualquier cambio:

> *Un consumidor que usa **únicamente** lo declarado en `CONTRACT.md`, sin tocar internals ni depender de comportamiento no documentado, y que ya estaba funcionando en la versión anterior:*
> **¿sigue funcionando, sin tocar una sola línea de su código ni de su configuración?**

- **No** → es **MAYOR**.
- **Sí, y además hay algo nuevo disponible** → es **MENOR**.
- **Sí, y solo se corrigió algo que estaba mal** → es **PARCHE**.

"Funcionar" incluye: compilar, arrancar, autenticar, obtener los mismos resultados semánticos y no requerir configuración nueva.

---

## 5. Cómo y cuándo se decide MAYOR, MENOR o PARCHE

### 5.1 Cuándo se decide

La clasificación se decide **tres veces**, y las tres deben coincidir:

| Momento | Quién | Qué produce |
|---|---|---|
| **1. Diseño** (antes de escribir código) | autor del cambio + tech lead | impacto estimado; si es MAYOR, se evalúa si existe una alternativa compatible |
| **2. Pull request** | autor propone, revisor valida | etiqueta obligatoria `semver:major` \| `semver:minor` \| `semver:patch` \| `semver:none` en el PR |
| **3. Release** | CI, de forma automática | número final, derivado de los commits del rango (§7) |

Si la etiqueta del PR y el cálculo automático del CI difieren, **el pipeline falla** y se resuelve manualmente antes de continuar. Esa discrepancia es una señal valiosa, no una molestia.

> **Regla anti-sorpresa:** un cambio MAYOR **NO DEBE** descubrirse en el momento del release. Si el análisis de contrato del CI (§16.2) detecta un breaking change en un PR etiquetado como `semver:minor`, el PR se bloquea y se decide explícitamente: o se rediseña para ser compatible, o se reetiqueta y se planea como release mayor.

### 5.2 Árbol de decisión

```
┌─ ¿El cambio afecta algo declarado en CONTRACT.md?
│
├─ NO ──► ¿Cambia el comportamiento observable en runtime?
│          ├─ NO  ──► semver:none  (refactor, tests, docs, CI, formato)
│          └─ SÍ  ──► PARCHE       (mejora interna con efecto observable menor)
│
└─ SÍ ──► ¿Un consumidor conforme al contrato anterior deja de funcionar,
          o debe cambiar código / configuración / datos para seguir funcionando?
           │
           ├─ SÍ ──────────────────────────────────────────► MAYOR
           │
           └─ NO ──► ¿Se agrega capacidad, o se deprecia algo sin quitarlo,
                     o cambia un valor por defecto de forma compatible?
                      ├─ SÍ ─────────────────────────────────► MENOR
                      └─ NO ──► ¿Se corrige una desviación respecto
                                al comportamiento documentado?
                                 ├─ SÍ ────────────────────► PARCHE
                                 └─ NO ────────────────────► revisar §6
```

### 5.3 Tabla de decisión — cambios en API HTTP

| Cambio | Nivel | Por qué |
|---|---|---|
| Eliminar un endpoint | **MAYOR** | el consumidor recibe 404 |
| Renombrar un endpoint o cambiar su método | **MAYOR** | la ruta anterior deja de existir |
| Renombrar un campo de respuesta | **MAYOR** | el cliente lee `null`/undefined |
| Eliminar un campo de respuesta | **MAYOR** | ídem |
| Cambiar el tipo de un campo (`"123"` → `123`, número → objeto) | **MAYOR** | rompe deserialización y validación |
| Cambiar la unidad o escala de un campo (centavos → pesos, ms → s) | **MAYOR** | forma idéntica, semántica distinta: el peor tipo de breaking |
| Cambiar el formato de fecha, zona horaria o el redondeo de importes | **MAYOR** | cálculos y conciliaciones del consumidor quedan mal |
| Hacer obligatorio un parámetro de request antes opcional | **MAYOR** | requests válidos empiezan a fallar |
| Agregar un parámetro obligatorio | **MAYOR** | ídem |
| Endurecer una validación (largo máximo, regex, rango) | **MAYOR** | datos aceptados antes se rechazan; ver §6.2 |
| Cambiar un código de estado HTTP de éxito o error documentado | **MAYOR** | el manejo de errores del cliente deja de aplicar |
| Cambiar el esquema del cuerpo de error o los códigos de error | **MAYOR** | rompe el manejo de errores |
| Eliminar un valor posible de un enum de **respuesta** | **MAYOR** | el cliente pierde un caso que manejaba, si dependía de él |
| Agregar un valor a un enum de **request** | **MENOR** | amplía lo aceptado |
| Agregar un valor a un enum de **respuesta** | **MENOR con aviso** | ver §6.3, requiere contrato de "lector tolerante" |
| Eliminar un valor aceptado de un enum de **request** | **MAYOR** | requests válidos empiezan a fallar |
| Cambiar el tamaño de página por defecto o el orden por defecto | **MAYOR** | altera resultados silenciosamente en clientes que asumen el default |
| Reducir un límite de tasa documentado | **MAYOR** | integraciones conformes empiezan a recibir 429 |
| Aumentar un límite de tasa | **MENOR** | amplía |
| Cambiar el esquema de autenticación o la forma del token | **MAYOR** | requiere cambio en el cliente |
| Cambiar el contrato de idempotencia (dejar de ser idempotente) | **MAYOR** | riesgo de duplicados en el consumidor |
| Agregar un endpoint nuevo | **MENOR** | nada existente cambia |
| Agregar un campo **opcional** de request con default compatible | **MENOR** | los requests anteriores siguen siendo válidos |
| Agregar un campo a la respuesta | **MENOR** | requiere §6.3 |
| Agregar un header de respuesta informativo | **MENOR** | no rompe |
| Marcar un endpoint o campo como deprecado (sin quitarlo) | **MENOR** | inicia la ventana de deprecación (§15) |
| Corregir un endpoint que devolvía datos incorrectos según su doc | **PARCHE** | se alinea con el contrato |
| Corregir un 500 intermitente | **PARCHE** | |
| Mejorar tiempo de respuesta sin cambiar salida | **PARCHE** | |
| Corregir la ortografía de un mensaje de error en prosa | **PARCHE** | el texto no es contractual; el **código** sí |
| Cambiar el esquema de un webhook o evento publicado | igual que respuesta HTTP | los suscriptores son consumidores |

### 5.4 Tabla de decisión — librerías, SDKs y código

| Cambio | Nivel |
|---|---|
| Eliminar o renombrar una función/clase/tipo exportado | **MAYOR** |
| Quitar o reordenar parámetros posicionales | **MAYOR** |
| Agregar un parámetro obligatorio | **MAYOR** |
| Cambiar el tipo de retorno | **MAYOR** |
| Estrechar un tipo de parámetro de entrada (acepta menos) | **MAYOR** |
| Ampliar un tipo de retorno de forma que rompa el `switch` exhaustivo del consumidor | **MAYOR** |
| Convertir una excepción en valor de retorno, o viceversa | **MAYOR** |
| Subir la versión mínima del runtime (Node 18 → Node 20, PHP 8.1 → 8.3) | **MAYOR** |
| Subir la versión mayor de una dependencia que se expone en la API pública (peer dependency, tipos) | **MAYOR** |
| Cambiar el formato de módulo o los entry points (CJS → ESM) | **MAYOR** |
| Agregar una función, clase, sobrecarga o campo opcional exportado | **MENOR** |
| Agregar un parámetro opcional al final | **MENOR** |
| Ampliar un tipo de parámetro de entrada (acepta más) | **MENOR** |
| Marcar algo como `@deprecated` | **MENOR** |
| Subir una dependencia interna que no se filtra | **PARCHE** |
| Corregir un bug de comportamiento respecto a la doc | **PARCHE** |
| Corregir una vulnerabilidad sin cambiar la API | **PARCHE** |
| Refactor interno, mover archivos, renombrar variables privadas | **none** |
| Cambios en tests, CI, linters, formato, comentarios | **none** |

### 5.5 Tabla de decisión — configuración, datos y operación

Esta categoría es la que más incidentes causa porque no se percibe como "código".

| Cambio | Nivel | Nota |
|---|---|---|
| Requerir una variable de entorno nueva sin valor por defecto | **MAYOR** | el despliegue del consumidor/operador falla al arrancar |
| Agregar una variable de entorno **con** default seguro | **MENOR** | |
| Eliminar o renombrar una variable de configuración | **MAYOR** | |
| Cambiar el valor por defecto de una configuración de forma que altere comportamiento | **MAYOR** | ejemplo: timeout de 30 s a 5 s |
| Cambiar el formato del archivo de configuración | **MAYOR** | |
| Migración de base de datos **aditiva** (columna nullable, tabla nueva, índice) | **MENOR** o **PARCHE** | según si habilita funcionalidad |
| Migración **destructiva** (drop de columna/tabla, cambio de tipo, `NOT NULL` sobre datos existentes) | **MAYOR** | y obliga a expand/contract (§11.6) |
| Migración que requiere ventana de mantenimiento o backfill largo | **MAYOR** | el impacto operativo es parte del contrato |
| Cambiar el formato de logs que consume una alerta | **MAYOR** | rompe observabilidad de terceros |
| Renombrar o eliminar una métrica expuesta | **MAYOR** | rompe dashboards y alertas |
| Agregar métricas, trazas o logs nuevos | **MENOR** o **none** | |
| Cambiar recursos requeridos (CPU/RAM mínima, versión de motor de BD) | **MAYOR** | |
| Cambiar el puerto expuesto o el path de health check | **MAYOR** | |
| Actualizar la imagen base del contenedor sin cambio de contrato | **PARCHE** | |

### 5.6 Regla de acumulación

Un release puede contener muchos cambios. **El nivel del release es el más alto de todos los cambios que contiene.**

```
Release contiene: 3 fixes (PARCHE) + 2 features (MENOR) + 1 breaking (MAYOR)
Resultado: MAYOR       2.7.4 → 3.0.0
```

**PROHIBIDO** publicar dos incrementos en un solo release (no existe "de `2.7.4` a `3.1.0` de una vez"). Si se necesita entregar features nuevas junto con un breaking change, el número resultante es `3.0.0` y las features se documentan dentro de las notas de esa versión mayor.

---

## 6. Casos ambiguos y reglas de desempate

Los casos siguientes son los que generan discusión real. Cada uno tiene una regla fija para que no se decidan por opinión.

### 6.1 "Es un bug fix, pero hay gente que ya depende del bug"

Se resuelve consultando la documentación, en este orden:

| Situación | Nivel | Acción adicional |
|---|---|---|
| La documentación decía claramente X y el código hacía Y | **PARCHE** | anunciar en el CHANGELOG con la etiqueta `Fixed`, y avisar por el canal de consumidores |
| La documentación era ambigua o inexistente | **MENOR**, con el comportamiento nuevo detrás de una bandera opcional que por defecto conserva el viejo | documentar el contrato correcto; en el siguiente MAYOR se invierte el default |
| Se sabe que consumidores críticos dependen del comportamiento defectuoso | **MAYOR** | tratar como breaking, con guía de migración |
| El comportamiento defectuoso genera pérdida de datos, cobros incorrectos o brecha de seguridad | **PARCHE de emergencia** (§9.5) | corregir ya, sin importar quién dependa; documentar como excepción |

> La última fila es la única excepción legítima a la regla de compatibilidad: **la corrección de un defecto que causa daño se aplica de inmediato**, aunque rompa integraciones. La compatibilidad nunca justifica seguir cobrando mal.

### 6.2 Endurecer validaciones

Aceptar menos que antes es siempre incompatible, aunque lo que se rechaza sea "basura".

**Procedimiento obligatorio en dos fases:**

1. **MENOR** — se implementa la validación en modo *observación*: se registra la violación (log/métrica), se devuelve un header `Warning`, pero se acepta el request. Se mide cuántos consumidores están afectados.
2. **MAYOR** — cuando la métrica está en cero, o al final de la ventana de deprecación (§15), la validación se vuelve bloqueante.

Si la validación laxa es la causa de un problema de seguridad, se aplica §6.1 última fila.

### 6.3 Agregar campos a las respuestas

Formalmente es **MENOR**, pero rompe clientes con deserialización estricta (`additionalProperties: false`, `Strict` en algunos frameworks tipados, validadores de esquema).

**Regla de la organización:** el contrato de todo API **DEBE** incluir la cláusula de **lector tolerante**:

> "Los consumidores DEBEN ignorar campos que no reconozcan y DEBEN tolerar la aparición de nuevos valores en enums de respuesta, tratándolos con una rama por defecto. Un consumidor que falle por un campo nuevo se considera no conforme al contrato."

Con esa cláusula publicada, agregar campos es **MENOR** sin más trámite. Sin esa cláusula, agregar campos es **MAYOR**. No hay término medio: o se declara la tolerancia, o se paga el costo.

### 6.4 Cambio de semántica con la misma forma

El caso más peligroso: `status: "activo"` que antes significaba "contrato firmado" y ahora significa "contrato firmado y pagado". El JSON es idéntico; el significado cambió.

**Siempre MAYOR.** Y **DEBERÍA** preferirse una alternativa compatible: dejar el campo viejo con su semántica original y agregar uno nuevo (`fundingStatus`), deprecando el anterior. Eso convierte un MAYOR en un MENOR y da tiempo a los consumidores.

### 6.5 Cambios de rendimiento

| Situación | Nivel |
|---|---|
| Mejora de latencia o consumo, sin cambio de salida | **PARCHE** |
| Degradación conocida y aceptada que no viola un SLA escrito | **PARCHE**, documentada |
| Degradación que viola un SLA publicado | **MAYOR** |
| Cambio de complejidad que hace inviable un caso de uso documentado (una consulta que pasa de 200 ms a 40 s) | **MAYOR** |
| Un endpoint que era sincrónico pasa a ser asincrónico (202 + polling) | **MAYOR** |

### 6.6 Cambios visuales y de UX en el frontend

La UI no es superficie pública en sentido estricto, pero sí lo es para usuarios y para las automatizaciones.

| Situación | Nivel |
|---|---|
| Ajustes de estilo, copy, espaciado, iconografía | **PARCHE** |
| Vista nueva, componente nuevo, flujo nuevo opcional | **MENOR** |
| Rediseño de un flujo existente que obliga a reentrenar usuarios o invalida material de capacitación | **MAYOR** |
| Cambio o eliminación de una ruta navegable o deep link | **MAYOR** |
| Cambio del formato de datos persistidos en el cliente (localStorage, IndexedDB) sin migración | **MAYOR** |
| Elevar el requisito mínimo de navegador o de versión de sistema operativo | **MAYOR** |
| Quitar o renombrar `data-testid` documentados que usan pruebas E2E de otros equipos | **MAYOR** |
| Cambiar el nombre de eventos de analítica que alimentan reportes | **MAYOR** |

### 6.7 Reversiones (revert)

Revertir un cambio **no** devuelve el número de versión hacia atrás.

| Qué se revierte | Nivel del release que lo revierte |
|---|---|
| Un fix (PARCHE) que salió mal | **PARCHE** |
| Una feature (MENOR) ya publicada, que se retira | **MAYOR** — quitar capacidad publicada es breaking |
| Una feature MENOR publicada solo como pre-release | **el que corresponda**; los pre-releases no comprometen compatibilidad |
| Un breaking change ya publicado | **MAYOR** — volver atrás también rompe a quien ya migró |

Corolario: es más barato publicar una feature detrás de una bandera desactivada que publicarla y arrepentirse.

### 6.8 Actualización de dependencias

| Situación | Nivel |
|---|---|
| Dependencia interna, no se filtra en el contrato | **PARCHE** |
| Dependencia con CVE, sin cambio de contrato | **PARCHE** (release de seguridad, §9.6) |
| Dependencia cuya versión mayor se expone al consumidor (peer dependency, tipos públicos, framework del SDK) | **MAYOR** |
| Actualización que sube el requisito mínimo de runtime | **MAYOR** |
| Dependencia nueva que agrega una capacidad | **MENOR** |

### 6.9 Cuadro resumen de desempate

| Duda | Regla |
|---|---|
| MAYOR o MENOR | MAYOR |
| MENOR o PARCHE | MENOR |
| PARCHE o ninguno | PARCHE si se publica el artefacto |
| Nadie se pone de acuerdo | decide el *Version Owner* (§17.1) y se documenta el criterio en `CONTRACT.md` para que no se vuelva a discutir |

---

## 7. Conventional Commits: de commit a número de versión

Para que el número de versión sea **derivado y no negociado**, todo commit que llega a una rama compartida **DEBE** seguir Conventional Commits.

### 7.1 Formato

```
<tipo>(<ámbito opcional>)<!>: <descripción imperativa, ≤ 72 caracteres>

<cuerpo opcional: qué y por qué, no cómo>

<footers opcionales>
BREAKING CHANGE: <qué se rompe y cómo migrar>
Refs: PROJ-1234
```

### 7.2 Mapeo tipo → incremento

| Tipo | Significado | Incremento | Aparece en CHANGELOG |
|---|---|---|---|
| `feat` | funcionalidad nueva | **MENOR** | sí, en *Added* |
| `fix` | corrección de defecto | **PARCHE** | sí, en *Fixed* |
| `perf` | mejora de rendimiento | **PARCHE** | sí, en *Changed* |
| `security` | corrección de vulnerabilidad | **PARCHE** | sí, en *Security* |
| `deprecate` | marcar algo como deprecado | **MENOR** | sí, en *Deprecated* |
| `revert` | revierte un commit | según §6.7 | sí |
| `refactor` | reestructura sin cambio observable | ninguno | no |
| `docs` | documentación | ninguno | no |
| `test` | pruebas | ninguno | no |
| `build` | sistema de build o dependencias | ninguno* | no |
| `ci` | pipelines | ninguno | no |
| `chore` | tareas de mantenimiento | ninguno | no |
| `style` | formato, sin efecto funcional | ninguno | no |

\* `build` sube a **PARCHE** si cambia el artefacto publicado, y a **MAYOR** si aplica §6.8.

**El `!` después del tipo/ámbito, o el footer `BREAKING CHANGE:`, fuerza MAYOR, sin importar el tipo.**

```
feat(pagos)!: usar centavos en todos los montos

BREAKING CHANGE: los campos `amount` de /v1/payments pasan de decimal
a entero en centavos. Migración: multiplicar por 100 y truncar.
Guía: docs/migraciones/3.0.0.md
```

### 7.3 Ámbitos (`scope`)

Cada repositorio **DEBE** declarar su lista cerrada de ámbitos válidos y validarla en CI (`commitlint`). En un monorepo el ámbito **DEBE** identificar el paquete afectado, porque es lo que permite versionar cada paquete de forma independiente.

```
feat(back): ...
fix(front): ...
feat(api-contract)!: ...
```

### 7.4 Reglas de higiene

1. Un commit, un propósito. **PROHIBIDO** `fix: varios ajustes`.
2. **PROHIBIDO** el mensaje vacío de contenido: `wip`, `cambios`, `asdf`, `.`.
3. El footer `BREAKING CHANGE:` **DEBE** explicar *qué se rompe* y *cómo migrar*, no solo que se rompió.
4. La estrategia de merge **DEBE** ser squash con título conforme a Conventional Commits, o rebase con todos los commits conformes. Se elige una por repositorio y se aplica siempre.
5. El footer `Refs:` con el ticket es **OBLIGATORIO** para `feat`, `fix` y `security`.

---

## 8. Pre-releases: alpha, beta, rc y metadata de build

Un pre-release es una versión publicada que **declara explícitamente que no ofrece garantías de estabilidad**. Existe para que se pueda probar e integrar código antes de comprometerse con el contrato.

### 8.1 Los tres canales

| Sufijo | Estado del código | Audiencia | Se permiten breaking changes entre pre-releases | Requisitos para publicarlo |
|---|---|---|---|---|
| `-alpha.N` | incompleto, en construcción | solo el equipo autor | sí, libremente | build verde |
| `-beta.N` | funcionalmente completo, con defectos conocidos | equipos internos y clientes piloto seleccionados | sí, pero se anuncian | build verde + pruebas de integración + doc preliminar |
| `-rc.N` | candidato a ser la versión final | QA, staging, clientes piloto | **no**; solo correcciones de bloqueantes | suite completa verde + code freeze + CHANGELOG completo + guía de migración si es MAYOR |

### 8.2 Reglas de uso

1. El número de pre-release **DEBE** ser numérico e incremental: `-rc.1`, `-rc.2`. **PROHIBIDO** `-rc`, `-rc.01`, `-rc.final`, `-rc.2b`.
2. El pre-release **DEBE** llevar el número de la versión **a la que aspira**: si `2.7.4` está en producción y se prepara una versión con breaking changes, el pre-release es `3.0.0-rc.1`, no `2.7.5-rc.1`.
3. Un pre-release **NO DEBE** desplegarse en producción con tráfico de clientes reales, salvo programa piloto formal con consentimiento del cliente y plan de rollback.
4. La versión final se publica **sin** modificar código respecto al último `rc` aprobado: `3.0.0-rc.3` → `3.0.0` solo quita el sufijo. Si hubo que cambiar código, se publica `-rc.4` y se reinicia la validación.
5. **PROHIBIDO** que un consumidor productivo declare dependencia de un rango que incluya pre-releases (`^3.0.0-0`).
6. Cuando se abandona una línea de pre-release, se anuncia; **PROHIBIDO** dejar `-beta` colgados sin resolución más de 60 días.

### 8.3 Builds de desarrollo y nightly

Para builds automáticos que no son candidatos a nada, se usa un sufijo derivado del commit, nunca un número artesanal:

```
3.0.0-dev.20260818.a1b2c3d      build de rama de desarrollo
3.0.0-rc.1+build.1842           rc con metadata del pipeline
```

La metadata (`+`) **NO** afecta la precedencia: `3.0.0+build.1` y `3.0.0+build.2` son la **misma** versión para efectos de comparación. Por eso **PROHIBIDO** usar metadata de build para distinguir contenido funcional distinto: si el código cambió, cambia el número, no la metadata.

### 8.4 Diferencia clave: pre-release ≠ revisión

Es una confusión frecuente:

- **Pre-release** (`3.0.0-rc.1`): la versión `3.0.0` **todavía no existe**; esto es un ensayo previo.
- **PARCHE / revisión** (`3.0.1`): la versión `3.0.0` **ya existe** en producción y esto la corrige.

**PROHIBIDO** el cuarto dígito (`1.2.3.4`). No es SemVer y rompe la mayoría de gestores de paquetes. Si se requiere identificar rebuilds del mismo código fuente (por ejemplo, reconstruir una imagen para parchear la imagen base sin cambiar el código de la aplicación), se usa metadata de build o un tag adicional de contenedor, y **DEBERÍA** preferirse simplemente publicar un PARCHE.

---

## 9. Tipos de release

Un "tipo de release" no cambia el formato del número: cambia **el proceso, los controles y quién autoriza**. Elegir el tipo es una decisión distinta y posterior a elegir el incremento.

### 9.1 Cuadro comparativo

| Tipo | Número resultante | Origen | Autoriza | Ventana | Gates obligatorios | Entregables obligatorios |
|---|---|---|---|---|---|---|
| **Mayor** | `X+1.0.0` | `release/*` | Version Owner + Product + Ops | planificada, fuera de horario pico, con aviso ≥ 2 semanas | suite completa, contract testing, pruebas de migración y de rollback, revisión de seguridad, RC aprobado | guía de migración, CHANGELOG, notas al cliente, plan de rollback, comunicado |
| **Menor** | `X.Y+1.0` | `release/*` | Tech Lead + Product | cadencia programada (p. ej. semanal) | suite completa, contract testing | CHANGELOG, notas de release |
| **Parche** | `X.Y.Z+1` | `release/*` o `main` | Tech Lead | a demanda, en horario laboral | suite de regresión | CHANGELOG |
| **Hotfix** | `X.Y.Z+1` | `hotfix/*` desde el tag productivo | Tech Lead + On-call (aprobación posterior admisible) | inmediata | pruebas del área afectada + smoke en staging | CHANGELOG, incidente registrado, back-merge a `develop` |
| **Seguridad** | `X.Y.Z+1` (o mayor si rompe) | `hotfix/*` o rama de soporte | Seguridad + Tech Lead | según severidad y embargo | escaneo de dependencias, verificación del vector | aviso de seguridad, CVE si aplica |
| **Mantenimiento / LTS** | `X.Y.Z+1` sobre línea antigua | `support/X.Y` | Version Owner | según política de soporte (§15) | regresión de la línea soportada | CHANGELOG de la línea |
| **Pre-release** | `X.Y.Z-alpha\|beta\|rc.N` | `develop` o `release/*` | Tech Lead | libre | según §8.1 | notas preliminares |
| **Nightly / dev** | `X.Y.Z-dev.<fecha>.<sha>` | `develop` | automático | diaria | build verde | ninguno |

### 9.2 Release mayor — condiciones de admisión

Un release mayor **DEBE** cumplir, antes de siquiera abrir la rama `release/`:

- [ ] Existe un documento de decisión (ADR) que justifica por qué no fue posible resolverlo de forma compatible.
- [ ] Existe guía de migración escrita, con ejemplos de antes y después y estimación de esfuerzo para el consumidor.
- [ ] Los consumidores conocidos están identificados y notificados con al menos dos semanas de anticipación.
- [ ] Lo que se elimina llevaba deprecado el tiempo mínimo de la política (§15).
- [ ] Existe plan de rollback probado, incluyendo el caso de migraciones de base de datos.
- [ ] La versión anterior queda en soporte según §15.
- [ ] Pasó por al menos un `-rc` validado en staging con datos representativos.

**Regla:** los releases mayores se agrupan. Es preferible acumular breaking changes y liberarlos juntos, en una cadencia predecible (por ejemplo, máximo dos mayores por año por producto), que emitir mayores sueltos cada mes. Cada mayor le cuesta trabajo a todos los consumidores.

### 9.3 Release menor — cadencia

**DEBERÍA** existir una cadencia fija y publicada (por ejemplo, martes y jueves). Una cadencia predecible reduce releases de emergencia, porque nadie necesita colar cambios "aprovechando" un despliegue.

### 9.4 Release de parche

Se emite en cuanto hay una corrección validada. No requiere ventana ni aviso. **NO DEBE** incluir features: si un parche contiene un `feat`, deja de ser parche por definición (§5.6).

### 9.5 Hotfix

Definición: corrección urgente sobre lo que está en producción **ahora**, sin arrastrar todo lo que ya se acumuló en `develop`.

Procedimiento **OBLIGATORIO**:

1. Crear `hotfix/2.7.5` **a partir del tag `v2.7.4`** que está en producción, no de `develop`.
2. Cambio mínimo y quirúrgico. **PROHIBIDO** aprovechar el hotfix para colar refactors, mejoras o features.
3. PR con al menos un aprobador; en incidente severo se admite aprobación posterior (dentro de 24 h) documentada en el incidente.
4. Smoke test en staging. Si el incidente impide esperar, se registra la excepción (§17.3).
5. Merge a `main`, tag `v2.7.5`, despliegue.
6. **Back-merge obligatorio a `develop` y a toda rama `release/*` abierta.** Omitir este paso hace que el bug reaparezca en el siguiente release; es el error más común del proceso.
7. Registro del incidente y, si hubo impacto en clientes, post-mortem (§14.3).

### 9.6 Release de seguridad

> **⏸ Parcialmente inactiva (§0.5).** El **embargo** y la **publicación de CVE** se activan cuando exista API pública o clientes con contrato de notificación. Mientras tanto: corrección inmediata y aviso interno.


- Se desarrolla en repositorio o rama con acceso restringido si hay embargo.
- **DEBE** ser lo más pequeño posible y aplicarse a **todas** las líneas bajo soporte, no solo a la última.
- El CHANGELOG usa la sección `Security` y **NO DEBE** incluir detalles explotables antes de que el parche esté disponible.
- Si la corrección obliga a un breaking change, se emite igual: la seguridad tiene precedencia sobre la compatibilidad, y se documenta como excepción.

### 9.7 Despliegue ≠ release

Distinción **obligatoria** para no inflar el versionado:

| Concepto | Qué es | Genera versión nueva |
|---|---|---|
| **Release** | publicar una versión inmutable con un contrato declarado | sí |
| **Despliegue** | poner una versión ya publicada en un ambiente | no |
| **Canary / rollout por etapas** | dirigir 5 %, 50 %, 100 % del tráfico a la **misma** versión | no |
| **Activar una bandera de funcionalidad** | habilitar en runtime algo ya publicado | no; pero el release que **introdujo** la capacidad fue MENOR |
| **Rollback** | volver a desplegar una versión anterior ya publicada | no |
| **Re-build del mismo código** | reconstruir el artefacto | no; usar metadata de build (§8.3) |

Corolario práctico: con banderas de funcionalidad se puede publicar en MENOR el código de un cambio grande y activarlo después. Solo cuando la bandera vieja se elimina y el comportamiento nuevo se vuelve obligatorio se incurre en MAYOR.

---

## 10. Escenario A — Sistema monolítico

### 10.1 Definición operativa

Se considera monolítico un sistema que **se construye, versiona y despliega como una sola unidad atómica**: un único artefacto, un único pipeline, y no existe la posibilidad de que una parte esté en una versión y otra parte en otra en el mismo ambiente. Un monolito puede tener módulos internos, incluso "backend" y "frontend" en el mismo repositorio, siempre que se desplieguen juntos.

### 10.2 Regla central

> **Un monolito tiene una sola versión.** Un repositorio, un artefacto, un tag, un CHANGELOG.

**PROHIBIDO** versionar módulos internos del monolito por separado. Si dos partes necesitan versionarse por separado, dejaron de ser un monolito y aplica el §11.

### 10.3 Superficie pública de un monolito

Aunque el monolito no exponga librerías, su contrato incluye:

1. **API HTTP** que consumen terceros (móvil, integraciones, socios).
2. **Interfaz de usuario**: rutas navegables, flujos, deep links.
3. **Contrato operativo**: variables de entorno, migraciones, requisitos de infraestructura, puertos, health checks.
4. **Contratos de datos** con sistemas externos: archivos que importa o exporta, esquemas de eventos, colas, tablas o vistas que otros sistemas leen, reportes que alimentan a terceros.
5. **Jobs programados** y su contrato de ejecución (idempotencia, ventana, efectos).

El nivel del release es el máximo entre todas estas dimensiones (§5.6). Un cambio interno enorme con contrato intacto es PARCHE; un cambio de una variable de entorno requerida es MAYOR.

### 10.4 Ejemplo de decisión en monolito

Estado actual: `4.3.2`.

| Contenido del release | Resultado | Razón |
|---|---|---|
| 12 fixes de UI + 40 archivos refactorizados | `4.3.3` | contrato intacto |
| Módulo de reportes nuevo, nada existente cambia | `4.4.0` | capacidad nueva compatible |
| Nueva pantalla + columna nullable en BD + campo opcional en la API | `4.4.0` | todo aditivo |
| El layout del archivo CSV de conciliación que consume el banco cambia de columnas | `5.0.0` | contrato de datos con tercero, roto |
| Se requiere `REDIS_URL` sin default para arrancar | `5.0.0` | contrato operativo roto |
| Se elimina la pantalla `/reportes/legacy` que estaba deprecada desde `4.1.0` | `5.0.0` | se retira superficie pública |
| Se corrige el cálculo de IVA que redondeaba mal | `4.3.3` | corrige desviación respecto a lo documentado; además §6.1 última fila si hubo cobros incorrectos |

### 10.5 Migraciones de base de datos en monolito

Aunque se despliegue todo junto, el despliegue **no** es instantáneo: hay ventana entre migrar el esquema y tener todas las instancias con el código nuevo, y el rollback debe seguir siendo posible.

Reglas **OBLIGATORIAS**:

1. Toda migración **DEBE** ser reversible o tener un procedimiento de reversión documentado y probado.
2. En un release MENOR o PARCHE, la migración **DEBE** ser compatible hacia atrás: el código de la versión anterior debe seguir funcionando contra el esquema nuevo (permite rollback del código sin rollback de datos).
3. Las migraciones destructivas solo ocurren en releases **MAYORES**, y siguen el patrón expand/contract (§11.6), aunque sea dentro del mismo despliegue.
4. Las migraciones que tocan volúmenes grandes **DEBEN** ejecutarse fuera del arranque de la aplicación (job dedicado), para no bloquear el despliegue ni el rollback.
5. El número de versión de la migración **DEBE** ser trazable a la versión de la aplicación que la introdujo.

### 10.6 Artefactos y etiquetado

| Elemento | Convención |
|---|---|
| Tag de Git | `v4.4.0` (una sola serie, anotado y firmado) |
| Imagen de contenedor | `registry/app:4.4.0`, más alias móviles `:4.4`, `:4`, `:stable` |
| Versión en el código | un único archivo fuente de verdad (`package.json`, `pom.xml`, `VERSION`), generado por el CI, nunca editado a mano |
| Versión visible en runtime | `GET /version` → `{ "service": "app", "version": "4.4.0", "commit": "a1b2c3d", "buildDate": "2026-08-18T10:14:00Z" }`, y visible en el pie de la UI |
| CHANGELOG | uno, en la raíz |

### 10.7 Cuándo un monolito debe dejar de versionarse como uno

Señales de que el modelo del §11 ya aplica, aunque el código viva en un solo repositorio:

- El frontend se despliega en un CDN de forma independiente al backend.
- Existe una app móvil que consume la API y no se puede actualizar al mismo tiempo.
- Hay integraciones de terceros contra la API.
- Distintas partes tienen cadencias de release distintas.

En cuanto se cumpla una de estas, la API **DEBE** tener contrato y versionado propios (§11.3), aunque el resto siga siendo un artefacto único.

---

## 11. Escenario B — Back y Front conectados por API

### 11.1 El error que hay que evitar primero

El reflejo inicial de casi todos los equipos es mantener el back y el front **en la misma versión** ("los dos van en 2.4.0"). Esto se llama versionado en *lockstep* y está **PROHIBIDO**, porque:

- Obliga a publicar versiones falsas: si solo cambió el front, el back publica un release sin ningún cambio, y su número deja de significar algo.
- Hace imposible responder "¿qué versión del back es compatible con este front?": la respuesta se vuelve "la misma", lo cual es falso en cuanto hay despliegues escalonados, caché de CDN, o una app móvil que el usuario no actualizó.
- Impide el despliegue independiente, que es la única razón por la que se separaron los proyectos.

### 11.2 Las tres versiones que hay que distinguir

Este es el modelo mental central de este escenario. Existen **tres** versiones, y confundirlas es la causa del desorden:

| # | Qué versiona | Formato | Ejemplo | Cambia cuando |
|---|---|---|---|---|
| 1 | **Versión del contrato de API** (el acuerdo entre los dos proyectos) | `MAYOR` en la ruta + SemVer del documento OpenAPI | ruta `/api/v2`, contrato `2.7.0` | según §5.3, aplicado al contrato |
| 2 | **Versión del servicio backend** (la implementación) | SemVer propio | `back 3.1.4` | según sus propios cambios, incluido su contrato operativo |
| 3 | **Versión de la aplicación frontend** | SemVer propio | `front 5.2.0` | según su propia superficie pública (§6.6) |

Consecuencias que se derivan:

- El back puede pasar de `3.1.4` a `4.0.0` **sin** cambiar la API, si lo que rompió fue su contrato operativo (por ejemplo, exige una variable de entorno nueva). El front no se ve afectado.
- El back puede pasar de `3.1.4` a `3.2.0` **agregando** `/api/v2` mientras mantiene `/api/v1`. Ambas versiones de API conviven, y el front migra cuando pueda.
- La API mayor solo se incrementa cuando el contrato se rompe **y** se decide no mantener la anterior; mientras convivan `v1` y `v2`, para el consumidor no hubo breaking change.
- El front declara qué API consume; nunca "adivina".

### 11.3 Versionado del contrato de API

Reglas **OBLIGATORIAS**:

1. El contrato **DEBE** existir como archivo versionado en el repositorio (OpenAPI para HTTP, AsyncAPI para eventos), y ser la fuente de verdad. Documentación escrita a mano en Confluence **NO** es contrato.
2. La versión MAYOR del contrato **DEBE** ser explícita en la ruta: `/api/v1/...`, `/api/v2/...`. Es la forma más legible y la que mejor soporta convivencia. (Versionado por header `Accept` es **OPCIONAL** y solo si ya está en uso; **PROHIBIDO** mezclar ambos esquemas en el mismo servicio.)
3. MENOR y PARCHE del contrato **NO** aparecen en la ruta: se registran en el campo `info.version` del OpenAPI y en el CHANGELOG del contrato. Un consumidor de `/api/v2` recibe automáticamente las mejoras compatibles.
4. Todo cambio al contrato **DEBE** pasar por un diff automático en CI (§16.2) que clasifica el cambio y falla si el incremento declarado no coincide.
5. El servicio **DEBE** exponer qué versiones de API soporta:

```json
GET /version
{
  "service": "rfacil-core-api",
  "version": "3.2.0",
  "apiVersions": { "supported": ["v1", "v2"], "default": "v2", "deprecated": ["v1"] },
  "contractVersion": "2.7.0",
  "commit": "a1b2c3d",
  "buildDate": "2026-08-18T10:14:00Z"
}
```

6. **PROHIBIDO** tener más de dos versiones mayores de API activas simultáneamente. Cada una es código, pruebas y soporte duplicados.

### 11.4 Cómo el front declara su compatibilidad

Cada consumidor **DEBE** declarar, de forma legible por máquina, el rango de API que requiere. Ejemplo en el repositorio del front:

```json
{
  "name": "rfacil-web",
  "version": "5.2.0",
  "apiCompatibility": {
    "service": "rfacil-core-api",
    "apiVersion": "v2",
    "minContractVersion": "2.5.0",
    "maxContractVersion": "<3.0.0",
    "requiredFeatures": ["payments.batch", "auth.refresh-rotation"]
  }
}
```

Esto habilita tres controles automáticos **OBLIGATORIOS** en el pipeline del front:

1. **Gate de despliegue:** antes de publicar el front en un ambiente, el pipeline consulta `GET /version` del backend de ese ambiente y **falla** si no satisface `apiCompatibility`. Esto elimina la clase de incidente "el front salió antes que el back".
2. **Gate de contrato:** las pruebas del front corren contra el OpenAPI de la versión declarada, no contra un mock escrito a mano.
3. **Alerta de deprecación:** si el backend reporta que la versión consumida está deprecada, el pipeline emite una advertencia y crea el ticket de migración.

### 11.5 Matriz de compatibilidad

Cada producto **DEBE** publicar y mantener una matriz de compatibilidad. Es el artefacto que responde la pregunta más frecuente en soporte.

| Front | API requerida | Back compatible | Estado | Fin de soporte |
|---|---|---|---|---|
| `5.2.x` | `v2` ≥ `2.5.0` | `back` ≥ `3.1.0`, `< 5.0.0` | actual | — |
| `5.1.x` | `v2` ≥ `2.2.0` | `back` ≥ `3.0.0`, `< 5.0.0` | soportada | 2026-12-31 |
| `4.8.x` | `v1` | `back` ≥ `2.4.0`, `< 4.0.0` | deprecada | 2026-10-31 |
| `< 4.8` | `v1` | — | sin soporte | — |

Reglas de la matriz:

1. Se actualiza en el **mismo PR** que introduce el cambio de compatibilidad, no después.
2. Toda combinación marcada como soportada **DEBE** tener cobertura en pruebas de integración o de contrato.
3. Si existe app móvil, se agrega una fila por versión de app en tiendas, incluyendo las versiones antiguas que los usuarios no han actualizado. La app móvil es el consumidor que **no** se puede forzar a migrar: obliga a mantener la API mayor anterior más tiempo.

### 11.6 Expand / Contract: cómo hacer un cambio incompatible sin romper nada

Es el procedimiento **OBLIGATORIO** para todo cambio breaking entre back y front. Convierte un breaking change en una secuencia de pasos compatibles.

Ejemplo: dividir `nombreCompleto` en `nombre` y `apellidos`.

```
Fase 1 — EXPAND (back)                                    back 3.2.0  (MENOR)
  · Se agregan `nombre` y `apellidos` a la respuesta.
  · Se sigue devolviendo `nombreCompleto`, marcado como deprecado.
  · El request acepta ambas formas; si llegan las dos, la nueva gana.
  · Header de respuesta: Deprecation, Sunset, Link a la guía.
  · Ningún consumidor cambia. Se despliega sin coordinación.

Fase 2 — MIGRATE (cada consumidor, a su ritmo)            front 5.3.0 (MENOR)
  · El front lee `nombre`/`apellidos` y deja de usar `nombreCompleto`.
  · Se declara minContractVersion 2.8.0 en apiCompatibility.
  · La métrica de uso del campo deprecado en el back cae.
  · Se repite para app móvil, integraciones y socios.

Fase 3 — VERIFY (back)                                    sin release
  · Se confirma con métricas que el uso de `nombreCompleto` es cero
    durante al menos un ciclo completo de facturación / cierre de mes,
    y que se cumplió la ventana mínima de deprecación (§15).

Fase 4 — CONTRACT (back)                                  back 4.0.0  (MAYOR)
  · Se elimina `nombreCompleto`.
  · Se publica guía de migración y se actualiza la matriz.
```

Reglas:

1. **PROHIBIDO** ejecutar Expand y Contract en el mismo release.
2. ⏸ *(§0.5: la telemetría por consumidor se activa cuando exista un consumidor externo o app móvil; mientras tanto se verifica con logs y búsqueda en los repos consumidores conocidos.)* La Fase 3 **DEBE** basarse en telemetría real de uso del elemento deprecado, no en la creencia de que ya nadie lo usa. Todo elemento deprecado **DEBE** tener una métrica de uso etiquetada por consumidor.
3. Si la telemetría muestra uso residual al vencer la ventana, se escala al Version Owner: se extiende la ventana o se acepta el corte con notificación directa a los consumidores identificados.
4. El mismo patrón aplica a esquemas de base de datos, eventos y contratos de archivos.
5. La Fase 4 se puede ejecutar de dos formas, y hay que distinguir cuál se usa porque el número del **back** cambia:
   - **Eliminación directa** en la versión de API vigente → el back rompe a quien no migró: **MAYOR del back** (es el caso del diagrama anterior).
   - **Publicar una versión mayor de API nueva** (`/api/v3` sin el campo) y dejar `/api/v2` en deprecación → nada existente se rompe: **MENOR del back**, aunque el contrato sí suba a MAYOR. El MAYOR del back llega después, cuando se retira `/api/v2`. Es la opción **RECOMENDADA** cuando hay consumidores externos o app móvil. Ver la línea de tiempo del §11.10.

### 11.7 Orden de despliegue

| Naturaleza del cambio | Orden **OBLIGATORIO** | Razón |
|---|---|---|
| Aditivo en el back que el front va a usar | **back primero**, front después | el front nuevo requiere capacidad que debe existir ya |
| Cambio solo en el front, sobre API existente | front, cuando quiera | el back no se enteró |
| Eliminación en el back (fase Contract) | **front primero** (todos los consumidores migrados), back al final | mientras un consumidor use lo viejo, no se puede quitar |
| Cambio coordinado inevitable | evitarlo; si es inevitable: ventana de mantenimiento, despliegue conjunto y bandera de funcionalidad para conmutar | es la única situación que justifica coordinación estricta |

Regla derivada, de una línea: **lo que se agrega, se agrega primero en el back; lo que se quita, se quita al final en el back.**

### 11.8 Contract testing

> **⏸ Parcialmente inactiva (§0.5).** El **diff de contrato** es obligatorio desde ya. El **contract testing tipo Pact** y el **cliente/SDK publicado como paquete** se activan cuando existan 3 o más consumidores del mismo contrato, o un consumidor fuera del equipo.


**OBLIGATORIO** en ambos pipelines:

| Control | Dónde corre | Qué hace | Falla cuando |
|---|---|---|---|
| Diff de contrato (p. ej. `oasdiff`) | PR del back | compara el OpenAPI del PR contra el de `main` y clasifica cada cambio | detecta un breaking sin `semver:major` |
| Pruebas de contrato del consumidor (p. ej. Pact) | PR del front, verificación en el back | el front publica lo que espera; el back verifica que lo cumple | el back rompe una expectativa publicada de cualquier consumidor registrado |
| Validación de respuestas contra esquema | pruebas de integración del back | valida cada respuesta contra el OpenAPI | la implementación se desvía del contrato |
| Cliente generado | pipeline del front | el SDK/tipos se generan desde el OpenAPI publicado, no se escriben a mano | el contrato cambió y el front no compila (fallo temprano y deseable) |

El cliente generado **DEBERÍA** publicarse como paquete versionado (`@rfacil/api-client`), con su versión SemVer **espejo del contrato**: contrato `2.7.0` → cliente `2.7.0`. Así el front expresa su compatibilidad simplemente con `"@rfacil/api-client": "^2.7.0"` y el gestor de paquetes hace el trabajo.

### 11.9 Repositorios: monorepo o separados

Ambas opciones son válidas; lo que **NO** es válido es que la elección del repositorio determine el versionado. **En ambos casos las versiones son independientes.**

| Aspecto | Repos separados | Monorepo |
|---|---|---|
| Tag de Git | `v3.2.0` en repo del back; `v5.3.0` en repo del front | prefijo **obligatorio**: `back/v3.2.0`, `front/v5.3.0`, `api-contract/v2.7.0` |
| Cómo se decide el incremento | commits del repo | commits filtrados por el `scope` del paquete afectado (§7.3) |
| CHANGELOG | uno por repo | uno por paquete, en su carpeta |
| Contrato de API | repo dedicado o publicado como paquete desde el back | carpeta `contracts/`, versionada como paquete propio |
| Riesgo principal | el contrato se desincroniza entre repos | tentación de versionar todo junto en lockstep — **PROHIBIDO** |
| Herramienta recomendada | `semantic-release` por repo | `changesets` o `semantic-release` con configuración multipaquete |

En monorepo, **PROHIBIDO** el tag simple `v1.2.3` sin prefijo de paquete: hace ambiguo a qué se refiere y rompe la automatización.

### 11.10 Ejemplo completo de una línea de tiempo

Estado inicial: `back 3.1.4`, contrato `v2` `2.4.1`, `front 5.1.2`.

| # | Cambio | Back | Contrato | Front | Comentario |
|---|---|---|---|---|---|
| 1 | El front corrige un error de maquetación | `3.1.4` | `2.4.1` | `5.1.3` | el back no publica nada |
| 2 | Se agrega `GET /api/v2/facturas/{id}/pdf` | `3.2.0` | `2.5.0` | `5.1.3` | aditivo; se despliega el back solo |
| 3 | El front consume el endpoint nuevo | `3.2.0` | `2.5.0` | `5.2.0` | declara `minContractVersion 2.5.0` |
| 4 | Se corrige el cálculo de un total en el back | `3.2.1` | `2.5.0` | `5.2.0` | el contrato no cambió |
| 5 | El back exige `REDIS_URL` sin default | `4.0.0` | `2.5.0` | `5.2.0` | MAYOR por contrato **operativo**; la API no cambió y el front no se toca |
| 6 | Expand: se agrega `nombre`/`apellidos`, se deprecia `nombreCompleto` | `4.1.0` | `2.6.0` | `5.2.0` | headers de deprecación activos |
| 7 | El front migra a los campos nuevos | `4.1.0` | `2.6.0` | `5.3.0` | `minContractVersion 2.6.0` |
| 8 | La app móvil migra | `4.1.0` | `2.6.0` | `5.3.0` | app `3.4.0`; se actualiza la matriz |
| 9 | Contract: se publica `/api/v3` sin `nombreCompleto`, y `/api/v2` se deprecia con `Sunset` | `4.2.0` | `3.0.0` en `/api/v3` | `5.3.0` | el **contrato** sube a MAYOR, pero para el **back** es aditivo (conviven `v2` y `v3`): MENOR. Ningún consumidor se rompe todavía |
| 10 | El front migra a `/api/v3` | `4.2.0` | `3.0.0` | `6.0.0` | MAYOR del front: elevó su requisito mínimo de backend |
| 11 | Se retira `/api/v2` al vencer la ventana | `5.0.0` | `3.0.0` | `6.0.0` | ahora sí el back retira superficie pública: MAYOR |

Lo que este ejemplo demuestra: los tres números avanzan a ritmos distintos, y en ningún renglón coinciden por casualidad. Eso es señal de que el versionado está funcionando.

---

## 12. GitFlow: ramas, tags, ambientes y dónde nace el número de versión

### 12.1 Ramas

| Rama | Vida | Origen | Destino | Protegida | Qué representa |
|---|---|---|---|---|---|
| `main` | permanente | — | — | sí, máxima | exactamente lo que está en producción. Todo commit en `main` está taggeado |
| `develop` | permanente | `main` | — | sí | integración de lo que irá en el próximo release |
| `feature/<ticket>-<slug>` | días | `develop` | `develop` | no | una unidad de trabajo |
| `release/<X.Y.0>` | días | `develop` | `main` + `develop` | sí | estabilización de un release; aquí nacen los `-rc` |
| `hotfix/<X.Y.Z>` | horas | tag de `main` | `main` + `develop` + `release/*` abiertas | sí | corrección urgente de producción |
| `support/<X.Y>` | meses | tag de `main` | ella misma | sí | mantenimiento de una línea antigua bajo soporte (§15) |

Reglas **OBLIGATORIAS**:

1. `main` y `develop` **NO DEBEN** recibir push directo. Todo entra por PR.
2. Toda rama `feature/*` **DEBE** vivir menos de 5 días laborales. Si necesita más, se parte, o se integra progresivamente detrás de una bandera de funcionalidad. Esta regla no es cosmética: es la que impide que una rama se convierta en un fork (§12.7).
3. Las ramas se **eliminan** al mergear.
4. `main` **DEBE** estar siempre desplegable, y **todo** release estable **DEBE** existir en `main` como commit taggeado. El tag más alto de `main` es el **aprobado** para producción. Esto **no** significa que producción se despliegue "desde la rama `main`": los ambientes ejecutan artefactos versionados, no ramas (§12.6). Si producción corre una versión que no corresponde a ningún tag de `main`, es un incidente de proceso.
5. **Estas dos son las únicas ramas permanentes.** **PROHIBIDO** crear ramas permanentes por ambiente (`qa`, `demo`, `staging`, `uat`). La relación entre ramas y ambientes se resuelve por promoción de artefactos (§12.6).

### 12.2 Dónde nace el número de versión

Este es el punto de mayor confusión en GitFlow. La secuencia es:

```
1. develop acumula commits convencionales.        (aún no hay número)
2. Se decide abrir el release.
   El CI calcula el incremento a partir de los commits desde el último
   tag: si hay algún BREAKING → MAYOR; si hay algún feat → MENOR;
   si solo hay fix/perf → PARCHE.                 (el número se propone)
3. Se crea release/3.2.0 con ese número.
   Se escribe la versión en el archivo fuente de verdad y en el
   CHANGELOG; se publica 3.2.0-rc.1.              (el número se fija)
4. Correcciones de bloqueantes → -rc.2, -rc.3.
   PROHIBIDO agregar features en esta rama.
5. Aprobación de release (§14.1).
6. Merge a main (no fast-forward), tag anotado v3.2.0, despliegue.
                                                  (el número se publica)
7. Back-merge de release/3.2.0 a develop.
8. Se elimina la rama release/.
```

**Nadie escribe el número a mano** salvo en el paso 3, y ahí lo hace la herramienta de release, no una persona editando un JSON.

### 12.3 Cómo cambia el número si aparece un breaking en plena estabilización

Si durante `release/3.2.0` se detecta que un cambio ya integrado es en realidad breaking, hay dos salidas y ninguna es "publicarlo igual":

1. **Preferida:** revertir o rediseñar ese cambio para que sea compatible, y sacar `3.2.0` como estaba planeado.
2. **Alternativa:** renombrar la rama y el número a `4.0.0`, lo cual dispara todos los requisitos del §9.2 (guía de migración, aviso a consumidores, ventana). Esto suele retrasar el release semanas, y es exactamente la razón por la que la clasificación se hace en el PR (§5.1) y no al final.

### 12.4 Tags

| Regla | Detalle |
|---|---|
| Formato | `v<versión SemVer>` en repos simples; `<paquete>/v<versión>` en monorepo |
| Tipo | anotado (`git tag -a`) y **DEBERÍA** estar firmado (`-s`) |
| Contenido del mensaje | resumen del release y enlace al CHANGELOG |
| Inmutabilidad | **PROHIBIDO** mover, borrar o reutilizar un tag publicado |
| Quién los crea | el pipeline de release, no una persona |
| Correspondencia | todo tag **DEBE** tener un release publicado y un artefacto en el registro; todo artefacto en el registro **DEBE** provenir de un tag |

### 12.5 Nota sobre trunk-based

GitFlow es el estándar de la organización porque encaja con ventanas de QA y releases versionados. Si un equipo opera con despliegue continuo varias veces al día, **PUEDE** solicitar excepción (§17.3) para trunk-based, con estas condiciones: `main` siempre desplegable, ramas menores a 24 h, banderas de funcionalidad obligatorias para trabajo incompleto, versionado y tags generados automáticamente en cada merge a `main`, y todo lo demás de este estándar (clasificación, contrato, revisiones, CHANGELOG) sin cambios. **Lo que cambia es la topología de ramas, nunca las reglas de versionado.**

### 12.6 Ambientes, promoción y su relación con las ramas

#### 12.6.1 El principio que resuelve la confusión

> **Las ramas no son ambientes. Los ambientes no ejecutan ramas: ejecutan versiones.**

Las ramas existen para **integrar código**. Los ambientes existen para **ejecutar artefactos ya construidos**, identificados por su número de versión. Son dos planos distintos, y mezclarlos es el origen de la mayoría de los problemas de "¿qué hay desplegado dónde?".

De ahí se deriva la regla operativa central de esta sección:

> Un ambiente **NO DEBE** tener una rama asignada. Un ambiente tiene una **versión desplegada**, y esa versión llegó ahí por **promoción de un artefacto**.

Corolario: que QA, DEMO y producción estén en versiones distintas entre sí **no es un desvío del estándar**. Es el funcionamiento normal y esperado. Lo que sí sería un desvío es que alguno de ellos ejecute algo sin número de versión trazable.

#### 12.6.2 Build once, promote the artifact

```
feature/* ──build──► X.Y.Z-dev.<fecha>.<sha> ──► DEV / efímero
                                                  (nunca se promueve a PROD)

develop ────build──► X.Y.Z-dev.<fecha>.<sha> ──► QA (integración continua)

release/* ──build──► X.Y.Z-rc.N ──┬──► QA      ─┐
                                  ├──► DEMO     │ el MISMO artefacto,
                                  └──► PROD*    │ bit a bit
                                                 ┘
                     * al aprobar el Go/No-Go se publica X.Y.Z (se retira
                       el sufijo -rc.N sin recompilar el código)
```

Reglas **OBLIGATORIAS**:

1. El artefacto se construye **una sola vez** por versión. **PROHIBIDO** recompilar por ambiente: si se recompila, lo que se probó no es lo que se liberó y el número de versión pierde su significado.
2. Lo único que cambia entre ambientes es la **configuración externa** (variables de entorno, secretos, endpoints). **PROHIBIDO** que el artefacto contenga lógica condicionada al nombre del ambiente para alterar su comportamiento funcional.
3. Solo los **pre-releases `-rc.N`** y las **versiones estables** son promovibles a producción. Un build `-dev.*` **NO DEBE** llegar nunca a producción, aunque haya pasado todas las pruebas: se mergea a `develop` y se reconstruye como `-rc.N` desde `release/*`.
4. La promoción **DEBE** ejecutarla el pipeline, con registro de quién la autorizó. **PROHIBIDO** el despliegue manual desde la máquina de una persona.

#### 12.6.3 Qué ejecuta cada ambiente

| Ambiente | Qué ejecuta | Origen del artefacto | Quién decide qué se pone | ¿Rama propia? | ¿Promovible a PROD? |
|---|---|---|---|---|---|
| **DEV / efímero por rama** | `X.Y.Z-dev.<fecha>.<sha>` | cualquier `feature/*` | el autor del cambio | **no** | no |
| **QA** | `X.Y.Z-rc.N`, o `X.Y.Z-dev.*` para validar una feature aislada | `release/*`, `develop` o `feature/*` | QA + tech lead | **no** | solo si es `-rc.N` |
| **DEMO** | normalmente un tag **estable** (`X.Y.Z`), congelado; ocasionalmente un `-rc.N` para mostrar lo que viene | `main` o `release/*` | Producto / Comercial | **no** | n/a |
| **PROD** | el tag estable vigente | `main` | Version Owner (Go/No-Go, §14.1) | **no** | — |

#### 12.6.4 Los tres casos que generan la duda, resueltos

**Caso 1 — "QA tiene algo que no está en `develop`."**
Es legítimo: se está validando una `feature/*` en aislamiento antes de integrarla. Se despliega como `X.Y.Z-dev.<fecha>.<sha>`, con dueño explícito y carácter desechable. Al aprobarse, la feature se mergea a `develop` y el candidato real se construye después desde `release/*`. Ese build de QA **nunca** se promueve a producción (§12.6.2, regla 3).
Si esta situación es frecuente y genera cola por el ambiente, la solución **RECOMENDADA** son **ambientes efímeros por rama** (uno por PR, creado y destruido por el pipeline), no una rama `qa` permanente.

**Caso 2 — "DEMO está en una versión más vieja que producción."**
Es el caso normal y no requiere corrección. Una demo comercial se congela deliberadamente en, por ejemplo, `4.1.0` con su conjunto de datos, mientras producción avanza a `4.3.2`. DEMO no "está atrasada": **está en una versión declarada, con dueño y motivo registrados**. Lo único obligatorio es que esté anotado en el registro de despliegues (§12.6.5) y que exista una fecha de revisión para decidir si se actualiza.

**Caso 3 — "DEMO está adelantada a producción."**
También legítimo: corre `5.0.0-rc.2` para mostrar funcionalidad próxima. Sigue siendo un artefacto identificable y registrado. La condición **OBLIGATORIA** es que DEMO esté claramente rotulada como preproductiva para quien la usa, y que no se tomen compromisos comerciales sobre funcionalidad que aún no pasó el Go/No-Go.

#### 12.6.5 Lo que sí es obligatorio, en lugar de ramas por ambiente

1. **Todo lo desplegado en cualquier ambiente tiene número de versión y commit trazable.** Nada corre "desde una rama". Esta es la regla que sustituye a la idea de rama por ambiente.
2. **`GET /version` disponible en todos los ambientes** (§11.3). "¿Qué hay en QA?" se responde con una consulta, no preguntando en el chat del equipo.
3. **Registro de despliegues** actualizado automáticamente por el pipeline, visible para todo el equipo:

| Ambiente | Versión | Desde | Desplegó | Autorizó | Nota |
|---|---|---|---|---|---|
| PROD | `4.3.2` | 2026-08-20 | pipeline #1842 | Version Owner | — |
| DEMO | `4.1.0` | 2026-06-02 | pipeline #1610 | Producto | congelada para demo del socio X; revisar 2026-09-30 |
| QA | `4.4.0-rc.2` | 2026-08-24 | pipeline #1851 | QA | validando release 4.4.0 |
| QA-2 (efímero) | `4.5.0-dev.20260824.a1b2c3d` | 2026-08-24 | pipeline #1853 | autor del PR #612 | validación aislada; no promovible |

4. **Toda versión congelada en un ambiente no productivo DEBE tener fecha de revisión.** Un DEMO olvidado dos años en `2.x` deja de ser una decisión y pasa a ser deuda: se revisa al menos cada trimestre en la auditoría del §14.3.
5. **Gates de promoción** definidos por ambiente: qué debe estar verde para que un artefacto avance al siguiente. El gate hacia producción es el Go/No-Go del §14.1.

#### 12.6.6 Antipatrones prohibidos

| Antipatrón | Por qué falla |
|---|---|
| Ramas permanentes `qa`, `demo`, `staging`, `uat` | multiplican los back-merges, se desincronizan silenciosamente y terminan conteniendo cambios que no existen en `develop` ni en `main` |
| Cherry-pick directo a una rama de ambiente | genera código que nunca pasó por `develop`: el mismo defecto reaparece en el siguiente release |
| Recompilar el artefacto por ambiente | lo probado deja de ser idéntico a lo liberado |
| Aplicar un hotfix sobre el ambiente de QA o DEMO | el fix no llega a `main` ni a `develop`; se pierde |
| Desplegar desde la máquina de una persona | sin trazabilidad ni autorización registrada |
| Un ambiente sin `/version` o sin registro | ningún resultado de prueba obtenido ahí es concluyente |
| "En QA está el build de ayer, creo" | síntoma de los dos anteriores |
| Promover a producción un build `-dev.*` | no pasó por `release/*` ni por estabilización |

#### 12.6.7 Resumen en cuatro líneas

- `main` y `develop` son las **únicas** ramas permanentes, y son para integrar código.
- QA y DEMO **no necesitan ninguna rama**; reciben artefactos versionados por promoción.
- Que los cuatro ambientes estén en versiones distintas es **normal**, no un desvío.
- La regla que aplica a todos por igual: **lo que corre ahí tiene versión, es trazable a un commit y está registrado.**

### 12.7 Ramas divergentes de larga vida: prevención y rescate

#### 12.7.1 El modo de falla que esta sección evita

Una rama de funcionalidad que se desarrolla en aislamiento durante meses deja de ser una rama y se convierte en un **fork no declarado**. El patrón se repite siempre igual:

```
Semana 1    se crea la rama a partir de la línea principal
Semana 4    el trabajo entra en pruebas; nadie la ha integrado
Semana 6    llega otro requerimiento que toca el mismo flujo y también
            se desarrolla en paralelo, sobre la línea principal
Mes 4       el segundo requerimiento se libera; la primera rama se pausa
            "hasta que el cliente confirme"
Mes 12      la línea principal lleva 200 commits de ventaja.
            Se pide liberar la rama pausada.
```

Lo que hace caro este final no son los conflictos de texto, sino tres cosas que se acumularon en silencio:

| Deuda acumulada | Por qué duele al final |
|---|---|
| **Conflictos diferidos** | resolver un año de divergencia de golpe, sin el contexto de por qué cambió cada cosa |
| **Conflicto semántico** | el código mergea limpio, compila y hace algo incorrecto, porque el flujo que modificaba fue redefinido por otro cambio |
| **Validación caducada** | las pruebas de hace un año se hicieron contra un sistema que ya no existe; el sello de QA no vale |

> **Principio:** el costo de integrar crece de forma no lineal con el tiempo de aislamiento. Integrar todos los días cuesta minutos; integrar una vez al año cuesta un proyecto.

#### 12.7.2 Reglas de prevención (OBLIGATORIAS)

Estas cinco reglas eliminan el escenario anterior. Son la parte importante de esta sección; el rescate (§12.7.5 en adelante) es solo el plan de contingencia para cuando ya falló.

1. **Integración continua detrás de bandera, no aislamiento.**
   Todo desarrollo que no pueda completarse en 5 días laborales **DEBE** integrarse a `develop` de forma incremental **detrás de una bandera de funcionalidad apagada**, en lugar de acumularse en una rama. El código viaja con la línea principal desde el primer día, los conflictos se pagan el día que aparecen, y "liberar la funcionalidad" se convierte en un cambio de configuración, no en un merge.
   Esta regla, por sí sola, previene el 100 % del modo de falla descrito arriba.

2. **Límite duro de vida de rama.**
   `feature/*` ≤ 5 días laborales (§12.1, regla 2). Al día 10 sin merge, la rama entra en el semáforo del §12.7.4 y requiere decisión explícita del tech lead: partirla, integrarla tras bandera, o archivarla. **PROHIBIDO** dejar que una rama simplemente siga abierta.

3. **Dos cambios que tocan el mismo flujo se secuencian, no se paralelizan.**
   Cuando llega un requerimiento que interactúa con uno en curso, **DEBE** decidirse explícitamente, en diseño y por escrito, una de tres: (a) el nuevo se construye sobre el primero, (b) ambos se construyen sobre una abstracción común acordada, o (c) el primero se integra tras bandera y el nuevo parte de ahí. **PROHIBIDO** desarrollarlos en paralelo ciego sobre la misma línea: garantiza conflicto semántico, que es el que ningún merge detecta.

4. **Trabajo suspendido ≠ rama viva.**
   Si un desarrollo se pausa por decisión de negocio o del cliente, la rama **DEBE** archivarse (§12.7.3) y cerrarse. Retomarlo más adelante es **re-planear**, no re-mergear. Una rama que "está ahí por si acaso" es deuda invisible con dueño difuso.

5. **Toda rama abierta tiene dueño, ticket y fecha de decisión.**
   El inventario de ramas se revisa semanalmente y se escala al Version Owner. Que una rama quede "olvidada" es una falla de gobierno, no de la herramienta: un control automático la detecta en la semana 2, no en el mes 12.

#### 12.7.3 Política de trabajo suspendido: archivar en lugar de dejar abierto

Archivar **DEBE** hacerse así, y toma cinco minutos:

```bash
# 1. Congelar el estado con un tag permanente
git tag -a archive/<rama>-<AAAA-MM-DD> <rama> \
  -m "Trabajo suspendido. Bifurcada de <base> el <fecha>. Motivo: <motivo>. Ticket: PROJ-####"
git push origin archive/<rama>-<AAAA-MM-DD>

# 2. Conservar el diff y la bitácora como documentos legibles
BASE=$(git merge-base develop <rama>)
git diff $BASE <rama>            > docs/archivo/<rama>-cambios.patch
git log --reverse --format='%h %s%n%b' $BASE..<rama> > docs/archivo/<rama>-bitacora.txt

# 3. Eliminar la rama: el tag la preserva íntegra
git push origin --delete <rama>
git branch -D <rama>
```

Y **DEBE** registrarse en el inventario del §12.7.10. Con el tag creado, la rama deja de ser irremplazable y nadie tiene miedo de borrarla: ese miedo es la razón por la que las ramas muertas sobreviven años.

Lo que **DEBE** preservarse explícitamente al archivar, porque es lo que conserva valor con el tiempo:

| Activo | Vida útil | Nota |
|---|---|---|
| **Especificación funcional** | alta | es lo que realmente se rescata después |
| **Pruebas automatizadas** | alta | describen el comportamiento esperado y casi no envejecen |
| **Decisiones de diseño / ADR** | alta | evitan volver a discutir lo ya resuelto |
| **Código de implementación** | **baja** | es el activo que más rápido caduca |

#### 12.7.4 Semáforo de divergencia

Métrica **OBLIGATORIA** por rama abierta, calculada a diario por el CI: `commits de la línea base que la rama no tiene`.

| Estado | Umbral | Acción requerida |
|---|---|---|
| 🟢 Verde | < 5 días y < 20 commits detrás | ninguna |
| 🟡 Ámbar | 5–10 días, o 20–60 commits detrás | el autor **DEBE** sincronizar con la base esta semana; el tech lead evalúa partirla |
| 🔴 Rojo | > 10 días, o > 60 commits detrás | **bloquea el merge**. Decisión explícita del tech lead: partir, integrar tras bandera, o archivar. Se registra la decisión |
| ⚫ Fork | > 30 días, o > 150 commits detrás | ya no es una rama. Se archiva (§12.7.3) y se aplica el procedimiento de rescate si el trabajo sigue siendo requerido |

#### 12.7.5 Rescate — Paso 0: diagnóstico antes de tocar nada

Cuando una rama ya llegó a ⚫, la primera pregunta **NO** es "¿merge o rebase?", sino **"¿cuánto de esto sigue siendo aplicable?"**. Se mide antes de decidir:

```bash
BASE=$(git merge-base main invoice)

# 1. Magnitud de la divergencia
git log --oneline invoice..main | wc -l      # commits que la rama no tiene
git log --oneline main..invoice | wc -l      # commits propios de la rama
git log -1 --format=%ci $BASE                # fecha real de la bifurcación

# 2. Tamaño real de la funcionalidad
git diff --stat $BASE invoice

# 3. MÉTRICA QUE DECIDE: ¿la línea principal tocó los MISMOS archivos?
git diff --name-only $BASE invoice | sort > /tmp/inv.txt
git diff --name-only $BASE main    | sort > /tmp/mainf.txt
comm -12 /tmp/inv.txt /tmp/mainf.txt > /tmp/traslape.txt
wc -l /tmp/inv.txt /tmp/traslape.txt         # traslape / total tocado por la rama

# 4. Ensayo de merge en seco: el dato más informativo
git switch -c probe/rescate invoice
git merge --no-commit --no-ff main
git diff --name-only --diff-filter=U | tee /tmp/conflictos.txt | wc -l
git merge --abort && git switch - && git branch -D probe/rescate
```

Y dos preguntas que **no** responde ninguna herramienta, y que pesan más que las anteriores:

- ¿La especificación original sigue siendo lo que el cliente quiere hoy? **DEBE** revalidarse antes de escribir una línea de código.
- ¿Algún cambio liberado en el intervalo redefinió el flujo que esta rama modifica? Si la respuesta es sí, hay **conflicto semántico**: el merge saldrá limpio y el comportamiento será incorrecto.

#### 12.7.6 Rescate — matriz de decisión de ruta

| Traslape de archivos | Conflictos en el ensayo | Semántica del flujo | Ruta |
|---|---|---|---|
| < 15 % | pocos y localizados | intacta | **B — Rebase / replay** |
| 15–50 % | moderados | intacta o con cambios menores | **C — Merge en rebanadas** |
| > 50 %, o el módulo fue reescrito | muchos y dispersos | redefinida por otro cambio | **A — Archivar y reimplementar** |

> Con más de seis meses de aislamiento, la ruta **A** es la más probable y **NO** debe leerse como fracaso: reconoce que el activo valioso es la especificación, no el código.

**Antes de cualquier ruta es OBLIGATORIO archivar el estado original** (§12.7.3). Con el tag creado se puede trabajar sin miedo a perder nada.

**Regla común a las tres rutas:** durante el rescate se mergea siempre **línea principal → rama de trabajo**, nunca al revés. La rama solo va hacia `develop` cuando está completa, probada y verde.

#### 12.7.7 Rescate — las tres rutas

**Ruta A — Archivar y reimplementar**

No es empezar de cero: es reimplementar con un diseño ya resuelto.

1. Revalidar la especificación con el cliente. Es una conversación de una hora que ahorra semanas.
2. Portar primero las **pruebas** de la rama archivada, en rojo. Son el activo mejor conservado.
3. Abrir rama nueva desde `develop` con la nomenclatura estándar: `feature/PROJ-1234-<slug>`.
4. Reimplementar en incrementos pequeños y mergeables (PR ≤ 400 líneas), usando el patch archivado como plano de referencia, **no** como fuente a copiar.
5. Todo detrás de bandera apagada, para integrar sin depender de la autorización de liberación.

El costo típico es **30–50 %** del desarrollo original, porque el diseño y los casos borde ya están resueltos.

**Ruta B — Rebase / replay** (traslape bajo)

```bash
git config rerere.enabled true      # reutiliza resoluciones de conflicto
git switch -c feature/<slug>-rebase invoice
git rebase --onto develop $BASE feature/<slug>-rebase
```

Si los commits originales son muchos o sucios, es **RECOMENDADO** el replay como conjunto limpio: aplicar el diff completo sobre `develop` y partirlo en commits convencionales nuevos.

```bash
git switch -c feature/<slug>-replay develop
git apply --3way docs/archivo/<rama>-cambios.patch
# resolver y luego partir en commits pequeños con git add -p
```

El replay produce historia limpia y revisable; la atribución original queda preservada en el tag de archivo.

**Ruta C — Merge en rebanadas** (traslape medio, se requiere conservar historia)

La técnica clave es **no cerrar la distancia en un solo salto**: se trae la línea principal por etapas, usando los tags de release como escalones.

```bash
git config rerere.enabled true
git switch -c feature/<slug>-catchup invoice

for T in v4.0.0 v4.1.0 v4.2.0 v4.3.0 v4.3.2; do
  git merge $T        # resolver los conflictos de ESTE salto y correr pruebas
done                  # se confirma cada merge solo con la suite en verde
git merge develop
```

Cada rebanada presenta los conflictos de un solo release, con contexto entendible, y `rerere` reutiliza las resoluciones repetidas.

#### 12.7.8 Rescate — re-verificación OBLIGATORIA

Todo rescate entra como **código nuevo**, en revisión **R3** (§13.1). La validación anterior está caducada y **NO DEBE** invocarse como evidencia. Cuatro trampas específicas:

| Trampa | Por qué revienta | Qué hacer |
|---|---|---|
| **Migraciones de base de datos** | fueron escritas contra un esquema que ya no existe y su orden respecto a las migraciones posteriores está indefinido | se **reescriben** sobre el esquema actual; **PROHIBIDO** reciclarlas |
| **Dependencias y lockfile** | la rama compila contra un árbol de dependencias antiguo, con vulnerabilidades incluidas | se regenera desde el estado actual y se corre el escaneo |
| **Contrato de API** | el diff debe correrse contra el OpenAPI **de hoy**, no contra el de la bifurcación | puede haber pasado de MENOR a MAYOR (§11.8) |
| **Interacción con lo liberado en el intervalo** | es el riesgo real, y un merge limpio no protege de él | pruebas de integración explícitas de los flujos en conjunto |

#### 12.7.9 Rescate — versionado y liberación

1. Se libera **sobre la línea actual, con el número que corresponde hoy**. Si la línea va en `4.3.2`, el rescate sale como `4.4.0`. **PROHIBIDO** retomar el número que le tocaba en su momento o abrir una línea paralela para él.
2. Clasificación normal según §5: es `feat` → **MENOR** si no rompe el contrato; sube a **MAYOR** si la interacción con lo liberado en el intervalo cambia el comportamiento de un flujo ya publicado (§6.4).
3. **RECOMENDADO:** liberar con la bandera apagada y encenderla después. Separa "el código está en producción" de "la funcionalidad está activa", que son dos decisiones con dueños distintos.
4. El CHANGELOG **DEBE** describir la funcionalidad como nueva para el consumidor, sin referencias al historial interno del rescate.

#### 12.7.10 Inventario de ramas y de archivos

**OBLIGATORIO**, actualizado por el CI y revisado semanalmente por el tech lead, y en la auditoría trimestral (§14.3) por el Version Owner:

| Rama / tag de archivo | Ticket | Dueño | Estado | Commits detrás | Fecha de decisión | Resolución |
|---|---|---|---|---|---|---|
| `feature/PROJ-1201-pagos` | PROJ-1201 | J. Pérez | 🟡 ámbar | 34 | 2026-08-28 | sincronizar esta semana |
| `feature/PROJ-1180-reportes` | PROJ-1180 | M. Ruiz | 🔴 rojo | 78 | 2026-08-26 | partir en tres PR |
| `archive/invoice-2026-08-25` | PROJ-0942 | sin dueño | ⚫ archivada | 200 | 2026-08-25 | rescate ruta A aprobado |

Indicadores que **DEBERÍAN** medirse junto con los del §14.3:

| Indicador | Meta orientativa |
|---|---|
| Ramas en estado 🔴 o ⚫ | 0 |
| Vida promedio de una rama `feature/*` | < 3 días |
| Desarrollos > 5 días que corren detrás de bandera | 100 % |
| Ramas archivadas sin tag de preservación | 0 |

---

## 13. Revisiones (parte 1): code review y pull requests

Las revisiones son el mecanismo que hace que el versionado sea real: es en el PR donde se detecta un breaking change antes de que sea un incidente.

### 13.1 Niveles de revisión

El nivel se determina por el **riesgo**, no por el tamaño del diff.

| Nivel | Aplica a | Aprobadores mínimos | Requisitos adicionales | Tiempo objetivo de primera respuesta |
|---|---|---|---|---|
| **R1 — Ligera** | `docs`, `style`, `test`, `chore`, `ci`, cambios de copy, dependencias de desarrollo | 1 cualquiera del equipo | ninguno | 8 h laborales |
| **R2 — Estándar** | `feat` y `fix` sin impacto en contrato; `semver:minor` y `semver:patch` | 1 revisor con contexto del módulo | checklist §13.4 completo | 8 h laborales |
| **R3 — Crítica** | cualquier `semver:major`; cambios en contrato de API o esquema de eventos; migraciones de BD; autenticación/autorización; manejo de dinero, cobros o conciliación; datos personales; infraestructura; jobs con efectos irreversibles | **2 aprobadores**, uno de ellos el *Version Owner* o el tech lead del módulo | ADR, guía de migración si aplica, plan de rollback, revisión de seguridad, revisión de DBA si toca esquema, actualización de la matriz de compatibilidad (§11.5) | 24 h laborales |
| **R0 — Emergencia** | hotfix de incidente activo (§9.5) | 1 aprobador, admite aprobación posterior ≤ 24 h | registro del incidente y revisión formal posterior obligatoria | inmediata |

Un PR **DEBE** llevar la etiqueta de su nivel. El CI **DEBE** escalar automáticamente a R3 cuando detecte cambios en rutas sensibles (`contracts/`, `migrations/`, `auth/`, `payments/`, IaC) o cuando el diff de contrato encuentre un breaking, sin importar la etiqueta que puso el autor.

### 13.2 Requisitos del pull request

Un PR **NO DEBE** entrar a revisión si no cumple:

- [ ] Título conforme a Conventional Commits (§7.1).
- [ ] Etiqueta `semver:*` presente y coherente con lo que hace.
- [ ] Etiqueta de nivel de revisión (R1/R2/R3).
- [ ] Un solo propósito. **PROHIBIDO** mezclar refactor con cambio funcional en el mismo PR: hace imposible revisar el cambio de comportamiento.
- [ ] Tamaño **DEBERÍA** ser ≤ 400 líneas de cambio efectivo (excluyendo generados, lockfiles y snapshots). Por encima de 400 líneas la efectividad de la revisión cae drásticamente; por encima de 1000, se **DEBE** justificar o partir.
- [ ] Descripción con: qué cambia, por qué, cómo se probó, impacto en el contrato, y cómo revertirlo.
- [ ] Todos los checks automáticos en verde (§13.5).
- [ ] Ticket enlazado.
- [ ] Si es `semver:major`: enlace al ADR y a la guía de migración.

### 13.3 Reglas de conducta de la revisión

1. **PROHIBIDO** aprobar el propio PR o mergear sin aprobación, incluso siendo el autor más senior.
2. Las observaciones se clasifican explícitamente para que el autor sepa qué es bloqueante:
   - `bloqueante:` debe resolverse antes del merge.
   - `sugerencia:` mejora opcional, a criterio del autor.
   - `duda:` pregunta, no exige cambio.
   - `elogio:` reconocer buen trabajo también es parte de la revisión.
3. El revisor **DEBE** revisar el comportamiento y el contrato, no solo el estilo. El estilo lo revisa el linter; si el humano está discutiendo comillas, falta configuración automática.
4. Si el revisor no entiende el cambio, eso **es** un hallazgo: se pide claridad, no se aprueba por confianza.
5. Un PR con más de 3 rondas de ida y vuelta **DEBERÍA** pasar a conversación sincrónica.
6. Aprobar implica corresponsabilidad sobre lo que salga a producción.
7. **PROHIBIDO** el "sello" (`LGTM` sin haber abierto los archivos). Es la causa más común de breaking changes no detectados.

### 13.4 Checklist del revisor

**Contrato y versionado** — la parte que este estándar agrega y que suele faltar:

- [ ] ¿El cambio toca algo declarado en `CONTRACT.md`?
- [ ] ¿La etiqueta `semver:*` corresponde a lo que realmente pasa? (aplicar §4.3)
- [ ] Si se agregó algo, ¿es realmente opcional y con default compatible?
- [ ] Si se quitó o renombró algo, ¿cumplió su ventana de deprecación?
- [ ] ¿Se actualizó el OpenAPI/AsyncAPI y su `info.version`?
- [ ] ¿Se actualizó la matriz de compatibilidad (§11.5) si cambió el requisito mínimo?
- [ ] ¿Se agregó o requirió alguna variable de entorno o configuración? (§5.5)
- [ ] ¿Cambió algún valor por defecto, unidad, redondeo, formato de fecha o zona horaria?
- [ ] ¿Cambió el CHANGELOG?

**Correctitud y datos**

- [ ] La lógica hace lo que dice el título del PR, y nada más.
- [ ] Casos borde: nulos, vacíos, cero, negativos, concurrencia, reintentos, duplicados.
- [ ] Manejo de errores explícito; nada se silencia.
- [ ] Idempotencia donde hay reintentos o cobros.
- [ ] Migraciones: reversibles, compatibles hacia atrás, probadas con volumen realista.
- [ ] Sin pérdida de datos posible; sin escrituras destructivas sin respaldo.

**Seguridad**

- [ ] Autorización verificada en el servidor, no solo escondida en la UI.
- [ ] Entradas validadas; salidas escapadas; consultas parametrizadas.
- [ ] Sin secretos en el código, en logs o en el repositorio.
- [ ] Datos personales o financieros no se registran en logs ni en trazas.

**Pruebas y observabilidad**

- [ ] Hay prueba que falla sin el cambio y pasa con él.
- [ ] Para un `fix`, hay una prueba de regresión del defecto exacto.
- [ ] Para un breaking change, hay prueba de que la ruta anterior sigue funcionando durante la fase Expand.
- [ ] Métricas o logs suficientes para detectar si esto falla en producción.
- [ ] Si se deprecó algo, existe métrica de uso del elemento deprecado (§11.6).

**Reversibilidad**

- [ ] Se puede revertir el despliegue sin intervención manual.
- [ ] Si hay migración de datos, el rollback está documentado y probado.

### 13.5 Controles automáticos que bloquean el merge

**OBLIGATORIOS** en toda rama protegida:

| Control | Bloquea si |
|---|---|
| Lint y formato | hay violaciones |
| Compilación / type check | falla |
| Pruebas unitarias | fallan o la cobertura de las líneas nuevas baja del umbral acordado |
| Pruebas de integración | fallan |
| `commitlint` | algún commit o el título del PR no es convencional |
| Validación de etiqueta `semver:*` | falta, o contradice el análisis automático |
| Diff de contrato (§11.8) | detecta breaking sin `semver:major` |
| Pruebas de contrato del consumidor | rompe una expectativa registrada |
| Escaneo de dependencias y secretos | vulnerabilidad crítica o secreto detectado |
| Verificación de CHANGELOG | el PR es `feat`/`fix`/`security` y no hay entrada de CHANGELOG |
| Rama actualizada respecto a la base | está desactualizada |

---

## 14. Revisiones (parte 2): revisión de release y post-release

### 14.1 Revisión de release (Go / No-Go)

> **⏸ Parcialmente inactiva (§0.5).** La **junta formal con cinco o más participantes** aplica solo a releases **mayores**. Los menores y parches se autorizan de forma asincrónica en el ticket, con los mismos criterios de Go.


Antes de taggear una versión **MENOR** o **MAYOR** se realiza una revisión formal, corta y con decisión registrada.

| Elemento | Contenido |
|---|---|
| **Duración** | 15–30 minutos; asincrónica en un ticket si todos los criterios están verdes |
| **Participantes** | Version Owner (decide), tech lead, QA, Product, Ops/On-call. En releases mayores también Seguridad y Soporte |
| **Insumo** | el `-rc` desplegado en staging, el CHANGELOG, la matriz de compatibilidad y el plan de rollback |
| **Salida** | decisión **Go** o **No-Go** registrada, con nombre de quien decide y fecha |

Criterios de **Go** — todos **OBLIGATORIOS**:

- [ ] Todos los controles del §13.5 verdes en la rama `release/*`.
- [ ] Cero defectos abiertos de severidad crítica o alta en el alcance del release.
- [ ] El `-rc` estuvo en staging el tiempo mínimo acordado (**DEBERÍA** ser ≥ 24 h para MENOR, ≥ 72 h para MAYOR) con datos representativos.
- [ ] CHANGELOG completo y legible por un no-desarrollador.
- [ ] Número de versión verificado contra §5 (la clasificación se revalida aquí, con el diff completo del release, no solo por PR).
- [ ] Matriz de compatibilidad actualizada y publicada.
- [ ] Plan de rollback probado, incluyendo migraciones.
- [ ] Consumidores notificados si hay breaking changes o deprecaciones nuevas.
- [ ] Ventana de despliegue acordada y personal de guardia identificado.
- [ ] Ambientes de los consumidores verificados si hay dependencia de orden de despliegue (§11.7).

Un **No-Go** no es un fracaso: es el control funcionando. Se registra el motivo y se define qué falta.

### 14.2 Verificación posterior al despliegue

Inmediatamente después del despliegue, y de forma **OBLIGATORIA**:

- [ ] `GET /version` devuelve la versión esperada en todos los nodos y ambientes.
- [ ] Smoke test de los flujos críticos ejecutado y verde.
- [ ] Tablero de errores, latencia y tasa de éxito observado durante la ventana definida (**DEBERÍA** ser ≥ 30 min para MENOR, ≥ 2 h para MAYOR).
- [ ] Métricas de uso de elementos deprecados revisadas.
- [ ] Tag creado, artefactos publicados, CHANGELOG y matriz publicados.
- [ ] Back-merge realizado (`release/*` o `hotfix/*` → `develop`).
- [ ] Comunicado enviado a los canales de consumidores.

Si algo falla en esta lista, se ejecuta el rollback **antes** de investigar. Primero se restaura el servicio, después se entiende el problema.

### 14.3 Revisión retrospectiva del release

| Cuándo | Qué se revisa |
|---|---|
| Después de **todo** rollback o hotfix de severidad alta | post-mortem sin culpables: por qué el control no lo detectó, qué control falta, qué se automatiza |
| Mensual | releases del mes: proporción de hotfixes sobre el total, tiempo medio de revisión de PR, cuántos breaking changes se detectaron en PR contra cuántos aparecieron en el release |
| Trimestral | cumplimiento del estándar: repos sin `CONTRACT.md`, repos en `0.x` con más de 3 meses en producción, tags fuera de convención, versiones mayores de API activas de más, deprecaciones vencidas sin retirar, excepciones otorgadas, inventario de ramas y archivos (§12.7.10), versiones congeladas en ambientes no productivos (§12.6.5) |

Indicadores **DEBERÍAN** medirse y publicarse:

| Indicador | Meta orientativa |
|---|---|
| Hotfixes / total de releases | < 10 % |
| Breaking changes detectados en PR vs. en release | > 90 % en PR |
| Tiempo desde PR abierto a primera revisión | < 8 h laborales |
| Releases con rollback | < 5 % |
| Deprecaciones retiradas dentro de su ventana | > 90 % |
| Repos con `CONTRACT.md` vigente | 100 % |

---

## 15. Política de soporte y deprecación

### 15.1 Soporte de versiones

> **⏸ Inactiva (§0.5).** Las **ramas `support/X.Y` y las líneas LTS** se activan cuando un cliente las exija por contrato, o cuando exista app móvil con adopción de la versión migrada por debajo del 95 %. Hoy solo se soporta la línea vigente.


| Línea | Qué recibe |
|---|---|
| Última mayor (`N`) | features, fixes y seguridad |
| Mayor anterior (`N-1`) | solo fixes críticos y seguridad, durante **6 meses** desde la publicación de `N`, en rama `support/X.Y` |
| `N-2` y anteriores | nada |

**PROHIBIDO** mantener más de dos líneas mayores con soporte simultáneo, salvo excepción formal (por ejemplo, un contrato con un cliente que lo exija, con costo asignado).

### 15.2 Ventanas mínimas de deprecación

> **⏸ Parcialmente inactiva (§0.5).** Las filas de **consumidores externos, socios y app móvil** se activan cuando esos consumidores existan. Hoy aplican las ventanas internas: 2 releases menores y 60 días.


Se cuenta desde que la deprecación se **publica** en un release estable, no desde que se decide.

| Qué se deprecia | Ventana mínima antes de poder retirarlo |
|---|---|
| Endpoint o campo de API con consumidores internos | 2 releases menores **y** 60 días |
| Endpoint o campo de API con consumidores externos o socios | 90 días, y no menos de una mayor de por medio |
| Versión mayor completa de API (`/v1`) | 6 meses desde que `/v2` está estable y disponible |
| Elemento consumido por app móvil | 6 meses, o hasta que la adopción de la versión que ya migró supere el 95 % |
| Símbolo de librería interna | 1 release menor y 30 días |
| Variable de configuración | 1 release menor, con default compatible durante la ventana |

### 15.3 Cómo se comunica una deprecación

**OBLIGATORIO**, todo junto:

1. Entrada en la sección `Deprecated` del CHANGELOG del release que la introduce, indicando el reemplazo y la fecha de retiro.
2. Marca en el contrato: `deprecated: true` en OpenAPI, `@deprecated` en el código, con nota del reemplazo.
3. Headers HTTP en cada respuesta del elemento deprecado:

```http
Deprecation: true
Sunset: Sat, 31 Oct 2026 00:00:00 GMT
Link: <https://docs.rfacil.com/migraciones/v2>; rel="deprecation"; type="text/html"
Warning: 299 - "El campo nombreCompleto se retira el 2026-10-31; usar nombre y apellidos"
```

4. Métrica de uso etiquetada por consumidor, para poder aplicar la Fase 3 del §11.6.
5. Aviso directo a los consumidores identificados por el canal acordado.
6. Ticket de retiro creado y agendado en la fecha de `Sunset`, no "cuando haya tiempo".

**Regla:** una deprecación sin fecha de retiro no es una deprecación; es un comentario. Toda deprecación **DEBE** nacer con fecha.

---

## 16. Automatización y controles en CI/CD

### 16.1 Principio

> El número de versión **DEBE** ser calculado por la herramienta, escrito por la herramienta y publicado por la herramienta. La persona decide el **tipo de cambio** en el mensaje de commit y en la etiqueta del PR; la aritmética no es trabajo humano.

Editar la versión a mano en `package.json` está **PROHIBIDO** en ramas protegidas.

### 16.2 Piezas mínimas del pipeline

| Etapa | Herramienta (referencia) | Función |
|---|---|---|
| Validación de commits | `commitlint` + `husky` | rechaza mensajes no convencionales antes del push |
| Cálculo de versión | `semantic-release` (repo simple) o `changesets` (monorepo) | deriva el incremento de los commits del rango |
| Diff de contrato | `oasdiff`, `openapi-diff` | clasifica cambios de OpenAPI en breaking / no breaking |
| Contract testing | `Pact` u equivalente | verifica expectativas de cada consumidor registrado |
| Cliente generado | `openapi-generator` | genera tipos y SDK desde el contrato |
| CHANGELOG | generador desde commits + edición humana de las notas al usuario | mantiene el registro |
| Publicación | pipeline de release | crea tag firmado, sube artefactos, publica notas |
| Verificación de despliegue | script de smoke + consulta a `/version` | confirma qué versión quedó arriba |
| Gate de compatibilidad | script que compara `apiCompatibility` con `/version` del ambiente | impide desplegar un consumidor sin su dependencia |

### 16.3 Controles que impiden que el estándar se degrade

| Control | Frecuencia | Acción al fallar |
|---|---|---|
| Todo repo tiene `CONTRACT.md` y `CHANGELOG.md` | en cada PR | bloquea |
| Todo tag cumple el formato | al crear el tag | bloquea |
| Ningún artefacto publicado sin tag correspondiente | diaria | alerta al Version Owner |
| Ningún repo en `0.x` con > 3 meses en producción | mensual | ticket obligatorio |
| Ninguna deprecación con `Sunset` vencido | semanal | ticket obligatorio |
| No más de 2 versiones mayores de API activas | mensual | plan de retiro |
| Ninguna rama `feature/*` con más de 5 días | diaria | aviso al autor |
| Semáforo de divergencia por rama abierta (§12.7.4) | diaria | ámbar: aviso · rojo: **bloquea el merge** y exige decisión del tech lead |
| Ninguna rama en estado 🔴 o ⚫ sin decisión registrada | semanal | escala al Version Owner |
| Todo desarrollo de más de 5 días corre detrás de bandera de funcionalidad | semanal | ticket obligatorio |
| Toda rama archivada tiene su tag `archive/*` y su registro | al archivar | bloquea el borrado de la rama |
| Ninguna rama permanente por ambiente (`qa`, `demo`, `staging`, `uat`) | semanal | bloquea; se elimina la rama |
| Todo ambiente reporta versión en `/version` y coincide con el registro de despliegues (§12.6.5) | diaria | alerta al Release Manager |
| Toda versión congelada en un ambiente no productivo tiene fecha de revisión vigente | mensual | ticket obligatorio |
| Ningún artefacto `-dev.*` desplegado en producción | en cada despliegue | bloquea |

---

## 17. Gobierno, roles y excepciones

### 17.1 Roles

> **⏸ Parcialmente inactiva (§0.5).** Con **un solo equipo de desarrollo**, los seis roles se colapsan en tres: **Version Owner**, **Tech Lead** y **Release Manager** (puede rotar). Las responsabilidades de QA, Seguridad y Soporte las absorbe el Version Owner hasta que exista más de un equipo.


| Rol | Responsabilidad |
|---|---|
| **Version Owner** (uno por producto) | dueño del `CONTRACT.md`; resuelve discusiones de clasificación; decide Go/No-Go; autoriza mayores y deprecaciones |
| **Tech Lead del módulo** | asegura que la etiqueta `semver:*` sea correcta en cada PR; aprueba R2 y participa en R3 |
| **Release Manager** (puede rotar) | ejecuta el procedimiento de release y las verificaciones del §14.2 |
| **Autor del cambio** | propone la clasificación, escribe el CHANGELOG, la guía de migración y el plan de rollback |
| **Revisor** | aplica el checklist del §13.4; corresponsable del resultado |
| **QA** | valida el `-rc`, incluida la compatibilidad hacia atrás |
| **Seguridad** | obligatorio en R3 y en releases de seguridad |
| **Soporte / Cuentas** | comunica deprecaciones y mayores a los consumidores externos |

### 17.2 RACI abreviado

> **⏸ Inactiva (§0.5).** El RACI completo se activa con **más de un equipo** de desarrollo. Con un solo equipo aplica la asignación reducida de §17.1.


| Actividad | Autor | Revisor | Tech Lead | Version Owner |
|---|---|---|---|---|
| Clasificar el cambio | R | C | A | C |
| Aprobar PR R2 | R | R | A | I |
| Aprobar PR R3 | R | R | R | A |
| Autorizar release mayor | C | I | C | A |
| Autorizar deprecación | R | C | C | A |
| Decidir Go/No-Go | I | I | C | A |
| Otorgar excepción | — | — | C | A |

R = responsable de ejecutar · A = aprueba · C = consultado · I = informado

### 17.3 Excepciones

Toda desviación de este estándar **DEBE** registrarse antes o dentro de las 24 h posteriores, con:

1. Regla que se incumple.
2. Motivo y por qué no había alternativa.
3. Riesgo aceptado y quién lo acepta (mínimo Version Owner).
4. Plan y fecha para volver al estándar.

Las excepciones se revisan en la retrospectiva trimestral (§14.3). Una regla que necesita excepción recurrente es una regla mal diseñada: se corrige el estándar, no se acumulan excepciones.

### 17.4 Adopción en proyectos existentes

Secuencia recomendada para un repositorio que hoy no cumple nada de esto:

| Paso | Acción | Esfuerzo |
|---|---|---|
| 1 | Escribir `CONTRACT.md`, aunque sea imperfecto | 1 día |
| 2 | Fijar la versión actual como punto de partida (si no hay ninguna, `1.0.0` si ya está en producción) y crear el tag | 1 hora |
| 3 | Activar `commitlint` y la etiqueta `semver:*` en los PR | 1 día |
| 4 | Iniciar `CHANGELOG.md` desde la versión actual hacia adelante; no se reconstruye el pasado | 1 hora |
| 5 | Automatizar el cálculo de versión y el tag | 2 días |
| 6 | Publicar el OpenAPI y activar el diff de contrato en CI | 2–5 días |
| 7 | Publicar la matriz de compatibilidad y el gate de despliegue | 2 días |
| 8 | Activar contract testing por consumidor | iterativo |

**PROHIBIDO** intentar reconstruir el historial de versiones pasado. El estándar aplica hacia adelante.

---

## 18. Anexos

### Anexo A — Tarjeta de decisión rápida (para pegar en la pared)

```
¿Alguien que ya usaba la versión anterior tiene que cambiar algo?
   ├─ Sí, código, configuración o datos ..................... MAYOR   X+1.0.0
   ├─ No, y hay algo nuevo disponible ...................... MENOR   X.Y+1.0
   ├─ No, y solo se corrigió un defecto ................... PARCHE   X.Y.Z+1
   └─ No, y nada observable cambió ........................... sin release

Trampas frecuentes que SÍ son MAYOR:
   · variable de entorno nueva sin default
   · cambio de unidad, redondeo, formato de fecha o zona horaria
   · endurecer una validación
   · cambiar un valor por defecto (orden, tamaño de página, timeout)
   · renombrar o eliminar una métrica, un log contractual o un data-testid
   · migración destructiva de base de datos
   · retirar una feature ya publicada
   · misma forma, distinto significado

Trampas frecuentes que NO son MAYOR:
   · refactor grande sin cambio observable ............. sin release
   · renombrar cosas internas o privadas .............. sin release
   · agregar endpoint, campo opcional o valor de enum de request .. MENOR
   · marcar algo como deprecado (sin quitarlo) ................... MENOR
   · mejorar rendimiento ....................................... PARCHE

Si hay duda entre dos niveles, se elige el más alto.
```

### Anexo B — Plantilla de `CONTRACT.md`

```markdown
# Contrato público — <nombre del proyecto>

Versión actual: <X.Y.Z>
Version Owner: <nombre>
Última actualización: <fecha>

## 1. Es público (cambiarlo puede obligar a MAYOR)
- API HTTP: rutas bajo /api/v2, definidas en `contracts/openapi.yaml`
- Códigos de error: catálogo en `docs/errores.md`
- Eventos publicados: `contracts/asyncapi.yaml`
- Variables de entorno requeridas: ver `.env.example` (sección REQUERIDAS)
- Métricas expuestas: `docs/observabilidad.md`
- Health check: GET /health · Versión: GET /version
- Archivos de intercambio: layout de conciliación en `docs/archivos/`

## 2. No es público (se puede cambiar libremente)
- Todo bajo `internal/`
- Esquema de tablas propias no consumidas por otros sistemas
- Rutas bajo /internal/* y /experimental/*
- Textos de error en prosa (los códigos SÍ son públicos)
- Rendimiento absoluto (no hay SLA escrito, salvo lo indicado abajo)

## 3. Cláusula de lector tolerante
Los consumidores DEBEN ignorar campos desconocidos y tolerar valores
nuevos en enums de respuesta. Un consumidor que falle por un campo
nuevo se considera no conforme.

## 4. SLA comprometido
- p95 de /api/v2/pagos < 800 ms
- Disponibilidad mensual 99.9 %

## 5. Consumidores conocidos
| Consumidor | Contacto | Versión de API | Notas |
|---|---|---|---|
| rfacil-web | equipo web | v2 | despliegue continuo |
| rfacil-app (iOS/Android) | equipo móvil | v2 | no forzable a migrar |
| Socio X | cuentas | v1 | deprecada, sunset 2026-10-31 |

## 6. Deprecaciones vigentes
| Elemento | Deprecado en | Reemplazo | Sunset |
|---|---|---|---|
| campo nombreCompleto | 4.1.0 | nombre + apellidos | 2026-10-31 |

## 7. Decisiones de clasificación ya resueltas
- Agregar campos a respuestas: MENOR (aplica cláusula de lector tolerante)
- Cambiar textos de error: PARCHE
- <se agregan aquí las discusiones ya zanjadas, para no repetirlas>
```

### Anexo C — Plantilla de `CHANGELOG.md` (Keep a Changelog)

```markdown
# Changelog

Todos los cambios relevantes de este proyecto se documentan aquí.
Formato: Keep a Changelog. Versionado: SemVer 2.0.0.

## [No publicado]

## [4.0.0] - 2026-09-15
### ⚠ Cambios incompatibles
- **API:** los montos de `/api/v2/pagos` pasan de decimal a entero en
  centavos. Migración: `docs/migraciones/4.0.0.md`
- **Config:** `REDIS_URL` ahora es obligatoria y sin valor por defecto.
- **Eliminado:** campo `nombreCompleto` (deprecado desde 3.5.0, sunset
  2026-08-31).

### Added
- Endpoint `GET /api/v2/facturas/{id}/pdf`.
- Exportación de conciliación en formato XLSX.

### Changed
- El tamaño de página por defecto de listados pasa de 20 a 50.

### Deprecated
- `GET /api/v3/reportes/legacy` — reemplazo: `/api/v3/reportes`.
  Sunset: 2027-03-31.

### Removed
- Campo `nombreCompleto` (ver arriba).

### Fixed
- Corregido el redondeo de IVA en notas de crédito (#1842).

### Security
- Actualizado `libxyz` a 3.2.1 (CVE-2026-12345).

### Migración
Guía completa: `docs/migraciones/4.0.0.md`
Compatibilidad: ver matriz en `docs/compatibilidad.md`
Rollback: `docs/runbooks/rollback-4.0.0.md`

## [3.2.1] - 2026-08-20
### Fixed
- Corregido cálculo de total en facturas con descuento (#1830).

[4.0.0]: https://git.rfacil.com/core/compare/v3.2.1...v4.0.0
[3.2.1]: https://git.rfacil.com/core/compare/v3.2.0...v3.2.1
```

Reglas del CHANGELOG:

1. **DEBE** escribirse para quien **consume**, no para quien programa. "Refactor del servicio de pagos" no le sirve a nadie externo.
2. Los cambios incompatibles **DEBEN** ir primero y visualmente destacados.
3. Toda entrada de breaking change **DEBE** decir cómo migrar, no solo qué se rompió.
4. Se escribe **en el PR**, no la noche del release.
5. **PROHIBIDO** la entrada `- varios fixes y mejoras`.

### Anexo D — Plantilla de pull request

```markdown
## Qué cambia
<descripción en una o dos frases, orientada al comportamiento>

## Por qué
<problema o necesidad; enlace al ticket>
Refs: PROJ-1234

## Clasificación de versión
- [ ] semver:major   - [ ] semver:minor   - [ ] semver:patch   - [ ] semver:none

Justificación: <por qué ese nivel, aplicando la prueba del consumidor
honesto del §4.3>

## Nivel de revisión
- [ ] R1 ligera   - [ ] R2 estándar   - [ ] R3 crítica   - [ ] R0 emergencia

## Impacto en el contrato
- [ ] No toca la superficie pública
- [ ] Toca la API HTTP → OpenAPI actualizado
- [ ] Toca configuración / variables de entorno
- [ ] Toca esquema de base de datos (adjuntar plan expand/contract)
- [ ] Toca eventos, archivos o métricas
- [ ] Introduce una deprecación (con fecha de sunset y métrica de uso)

## Cómo se probó
<pruebas automáticas agregadas, pruebas manuales, ambiente>

## Cómo se revierte
<pasos de rollback; si hay migración, cómo se revierte el dato>

## Checklist del autor
- [ ] CHANGELOG actualizado
- [ ] Matriz de compatibilidad actualizada si aplica
- [ ] Guía de migración y ADR si es semver:major
- [ ] Sin secretos ni datos personales en código ni logs
- [ ] Un solo propósito en este PR
```

### Anexo E — Checklist de release (imprimible)

```
PREPARACIÓN
[ ] Alcance congelado; rama release/X.Y.0 creada desde develop
[ ] Versión calculada por el CI y verificada contra §5
[ ] CHANGELOG completo y legible por no-desarrolladores
[ ] Guía de migración (si MAYOR) y ADR enlazado
[ ] Matriz de compatibilidad actualizada
[ ] Plan de rollback escrito y probado (incluye datos)
[ ] Consumidores notificados (si MAYOR o hay deprecaciones nuevas)

VALIDACIÓN
[ ] X.Y.0-rc.N publicado y desplegado en staging
[ ] Tiempo mínimo en staging cumplido (24 h MENOR / 72 h MAYOR)
[ ] Suite completa verde; contract testing verde
[ ] Pruebas de compatibilidad hacia atrás ejecutadas
[ ] Migraciones probadas con volumen realista, ida y vuelta
[ ] Cero defectos críticos o altos abiertos

AUTORIZACIÓN
[ ] Revisión Go/No-Go realizada; decisión y responsable registrados
[ ] Ventana acordada; guardia identificada

PUBLICACIÓN
[ ] Merge a main (no fast-forward)
[ ] Tag anotado y firmado creado por el pipeline
[ ] Artefactos publicados; alias de contenedor actualizados
[ ] Se promovió el MISMO artefacto validado; no se recompiló (§12.6.2)
[ ] Orden de despliegue respetado (§11.7)
[ ] Registro de despliegues actualizado (§12.6.5)

VERIFICACIÓN
[ ] /version correcto en todos los nodos y ambientes
[ ] Smoke test verde
[ ] Tableros observados (30 min MENOR / 2 h MAYOR)
[ ] Notas de release publicadas y comunicado enviado

CIERRE
[ ] Back-merge a develop y a release/* abiertas
[ ] Rama release/hotfix eliminada
[ ] Tickets de retiro de deprecaciones agendados
[ ] Si hubo rollback o hotfix: post-mortem agendado
```

### Anexo F — Ejercicios resueltos

Sirven para calibrar criterio en el equipo. Estado inicial: `back 3.4.2`, contrato `v2` `2.6.0`, `front 5.1.0`.

| # | Situación | Respuesta | Razonamiento |
|---|---|---|---|
| 1 | Se reescribe el módulo de facturación completo; misma entrada, misma salida, 40 % más rápido | `back 3.4.3` | contrato intacto; el esfuerzo no cuenta |
| 2 | Se agrega el campo opcional `referencia` al request de pago | `back 3.5.0`, contrato `2.7.0` | aditivo, requests previos siguen válidos |
| 3 | `referencia` se vuelve obligatorio dos meses después | `back 4.0.0`, contrato `3.0.0` | requests conformes empiezan a fallar |
| 4 | Se corrige que `fechaPago` devolvía la fecha en UTC cuando la doc decía hora local | `back 3.4.3` | se alinea con el contrato documentado; se avisa en el CHANGELOG por prudencia |
| 5 | La doc no decía nada de zona horaria y se cambia UTC → hora local | `back 3.5.0` con bandera, luego `4.0.0` | §6.1 fila 2: doc ambigua, se implementa con bandera y default viejo |
| 6 | Se descubre que se cobraba doble comisión en un caso borde | `back 3.4.3` inmediato | §6.1 última fila: daño económico, se corrige ya |
| 7 | Se limita `descripcion` a 200 caracteres; hoy se aceptaba cualquier largo | `3.5.0` (observación) → `4.0.0` (bloqueante) | §6.2, dos fases obligatorias |
| 8 | Se agrega el valor `EN_REVISION` al enum `estado` de la respuesta | `back 3.5.0`, contrato `2.7.0` | MENOR gracias a la cláusula de lector tolerante (§6.3) |
| 9 | El front rediseña por completo el flujo de alta de clientes | `front 6.0.0` | §6.6: obliga a reentrenar usuarios e invalida capacitación |
| 10 | El front cambia el color de los botones primarios | `front 5.1.1` | cosmético |
| 11 | El front deja de soportar Safari 14 | `front 6.0.0` | elevar requisito mínimo del entorno |
| 12 | El back agrega `POST /api/v2/pagos/lote` y el front lo usa en el mismo sprint | `back 3.5.0` luego `front 5.2.0` | back primero (§11.7); el front declara `minContractVersion 2.7.0` |
| 13 | Se renombra la métrica `pagos_ok_total` a `pagos_exitosos_total`; hay alertas sobre ella | `back 4.0.0` | rompe observabilidad de terceros (§5.5) |
| 14 | Se sube la imagen base del contenedor por un CVE, sin cambio de código | `back 3.4.3` | release de seguridad, PARCHE |
| 15 | Se elimina `/api/v1`, deprecada desde hace 8 meses, con uso en cero (los consumidores ya están en `v2`) | `back 4.0.0`; el contrato de `v2` no cambia | retirar superficie pública es MAYOR del **servicio** aunque nadie la use; el contrato vigente no se toca |
| 16 | Se agrega un job nocturno nuevo que no altera nada existente | `back 3.5.0` | capacidad nueva |
| 17 | Ese job nocturno pasa de correr a las 2:00 a las 6:00, y un tercero depende de que termine antes de las 5:00 | `back 4.0.0` | contrato operativo con un consumidor real |
| 18 | Se corrige un error de dedo en un texto de la UI | `front 5.1.1` | |
| 19 | Se agrega `data-testid` nuevos para pruebas E2E | `front 5.1.1` o `5.2.0` | aditivo; MENOR si se documentan como contrato |
| 20 | Se despliega la misma versión al 10 % del tráfico y luego al 100 % | sin cambio de versión | es despliegue, no release (§9.7) |

### Anexo G — Glosario

| Término | Definición |
|---|---|
| **Artefacto** | resultado construido y publicable: paquete, imagen, bundle |
| **Back-merge** | traer a `develop` lo que se mergeó en `main` desde `release/*` o `hotfix/*` |
| **Breaking change** | cambio que obliga al consumidor a modificar código, configuración o datos |
| **Contract testing** | verificación automática de que la implementación cumple lo que los consumidores esperan |
| **Contrato** | conjunto declarado de compromisos observables; ver `CONTRACT.md` |
| **Deprecar** | anunciar que algo se retirará, sin retirarlo aún, con fecha de sunset |
| **Expand/Contract** | patrón de dos fases para hacer un cambio incompatible sin romper consumidores |
| **Lockstep** | versionar dos proyectos con el mismo número; **prohibido** |
| **Lector tolerante** | consumidor que ignora lo que no reconoce en lugar de fallar |
| **Pre-release** | versión publicada sin garantía de estabilidad (`-alpha`, `-beta`, `-rc`) |
| **Promoción** | mover el **mismo** artefacto ya construido de un ambiente al siguiente, sin recompilar |
| **Ambiente efímero** | ambiente creado y destruido por el pipeline para validar una rama concreta |
| **Registro de despliegues** | tabla que dice qué versión hay en cada ambiente, desde cuándo y quién la autorizó |
| **Fork no declarado** | rama de funcionalidad que por su tiempo de aislamiento dejó de ser integrable con costo razonable (§12.7) |
| **Semáforo de divergencia** | métrica diaria de qué tan atrás quedó cada rama respecto a su base, con umbrales de acción |
| **Conflicto semántico** | el merge sale limpio y compila, pero el comportamiento resultante es incorrecto porque el flujo fue redefinido |
| **Archivar una rama** | congelarla en un tag `archive/*` con su diff y bitácora, y eliminarla |
| **Rescate** | procedimiento para retomar trabajo contenido en una rama archivada o en estado de fork |
| **Release** | acto de publicar una versión inmutable con su contrato |
| **Sunset** | fecha en la que un elemento deprecado deja de existir |
| **Superficie pública** | todo lo que un tercero puede legítimamente consumir |
| **Version Owner** | responsable último del contrato y de la clasificación en un producto |

### Anexo H — Preguntas frecuentes

**¿Y si el equipo de negocio quiere que la versión sea "3.0" porque es un lanzamiento importante?**
Se usa un alias comercial (§3.5). El número SemVer describe compatibilidad técnica; el nombre comercial describe mercado. Son dos cosas distintas y pueden convivir sin contradicción.

**¿Un cambio grande siempre es MAYOR?**
No. El tamaño no importa; importa la compatibilidad. Un rewrite completo compatible es PARCHE. Renombrar un campo es MAYOR.

**¿Qué pasa si nos equivocamos y publicamos un breaking change como MENOR?**
No se re-taggea nunca. Se publica de inmediato un PARCHE que restaura la compatibilidad, si es posible; si no, se publica el MAYOR correcto, se marca la versión errónea como no recomendada en el registro y se notifica a los consumidores. Después, post-mortem: qué control faltó (§14.3).

**¿Cuándo pasa el front a MAYOR si la API no cambió?**
Cuando rompe **su** propia superficie pública (§6.6): rutas, datos persistidos, requisitos de navegador, rediseño disruptivo, o cuando eleva su requisito mínimo de backend.

**¿Es obligatorio que back y front tengan la misma versión mayor?**
No, y **PROHIBIDO** forzarlo. Que `back 5.x` funcione con `front 6.x` es normal y saludable.

**¿Cuántas versiones de API mantenemos vivas?**
Dos como máximo. Cada versión adicional es código, pruebas, soporte y superficie de bugs duplicados.

**¿Podemos saltar de `2.7.4` a `4.0.0` porque el `3.x` "no salió bien"?**
No. Los números no se saltan por estética. Si `3.0.0` se publicó, existe; si nunca se publicó, se usa `3.0.0`.

**¿Los pre-releases cuentan para la política de deprecación?**
No. Las ventanas se cuentan desde la publicación en un release **estable**.

**¿Un hotfix puede incluir un feature pequeño?**
No. Es la excepción que degrada el proceso. El feature espera al siguiente release menor.

**Tenemos ambientes de QA y DEMO que no siguen ni a `main` ni a `develop`. ¿Necesitamos una rama para cada uno?**
No. Los ambientes ejecutan **versiones**, no ramas: reciben artefactos versionados por promoción. Que QA, DEMO y producción estén en versiones distintas es normal y no viola nada. Lo obligatorio es que cada ambiente reporte su versión en `/version` y aparezca en el registro de despliegues. Ver §12.6, y en particular §12.6.4 para los tres casos típicos.

**¿DEMO puede quedarse congelada en una versión vieja?**
Sí, si es una decisión con dueño, motivo y **fecha de revisión** registrados. Sin fecha de revisión deja de ser decisión y se vuelve deuda (§12.6.5, regla 4).

**Tenemos una rama de hace un año, con cientos de commits de atraso, y ahora piden liberarla. ¿Rebase o merge?**
Ninguna de las dos, todavía. Primero se mide (§12.7.5): traslape de archivos, ensayo de merge en seco y, sobre todo, si la especificación sigue vigente y si algún cambio liberado en el intervalo redefinió el mismo flujo. Con esos datos la matriz del §12.7.6 elige la ruta. Con más de seis meses de aislamiento, lo más frecuente y lo más barato es **archivar y reimplementar** conservando especificación y pruebas.

**¿Reimplementar no es tirar el trabajo?**
No. Se conserva lo que mantiene valor —especificación, pruebas y decisiones de diseño— y se descarta lo que caduca rápido, que es el código de implementación. El costo típico es 30–50 % del desarrollo original, contra un merge a ciegas de duración impredecible.

**¿Cómo se versiona una funcionalidad rescatada?**
Con el número que corresponde hoy en la línea actual, no con el que le tocaba cuando se desarrolló, y sin abrir una línea paralela (§12.7.9).

**Un desarrollo va a tomar tres meses. ¿Qué hacemos con la rama?**
No se usa una rama de tres meses. Se integra a `develop` de forma incremental detrás de una bandera de funcionalidad apagada (§12.7.2, regla 1). El código convive con la línea principal desde el primer día y liberar se vuelve un cambio de configuración.

**El cliente pausó un desarrollo indefinidamente. ¿Dejamos la rama abierta?**
No. Se archiva con tag `archive/*`, diff y bitácora, y se elimina la rama (§12.7.3). Retomarlo después es re-planear, no re-mergear.

**Si una feature se validó en QA, ¿ese mismo build puede ir a producción?**
Solo si es un `-rc.N` construido desde `release/*`. Un build `-dev.*` de una rama de feature nunca se promueve: se mergea a `develop` y el candidato se reconstruye (§12.6.2, regla 3).

### Anexo I — Referencias

- Semantic Versioning 2.0.0 — https://semver.org/lang/es/
- Conventional Commits 1.0.0 — https://www.conventionalcommits.org/es/
- Keep a Changelog 1.1.0 — https://keepachangelog.com/es-ES/
- RFC 8594 — The Sunset HTTP Header Field
- RFC 9745 — The Deprecation HTTP Header Field
- OpenAPI Specification — https://spec.openapis.org/
- Patrón Expand/Contract (Parallel Change) — Danilo Sato

---

## Control de cambios de este documento

| Versión | Fecha | Autor | Cambio |
|---|---|---|---|
| 1.0.0 | 2026-08-18 | Cesar Villegas | Versión inicial del estándar |
| 1.1.0 | 2026-08-24 | Cesar Villegas | Se agrega §12.6 (ambientes, promoción de artefactos y su relación con las ramas). Se precisa la regla 4 del §12.1 y se agrega la regla 5. Nuevos controles en §16.3, entradas de glosario y FAQ. |
| 1.2.0 | 2026-08-28 | Cesar Villegas | Se agrega §12.7 (ramas divergentes de larga vida: prevención, semáforo de divergencia, política de archivado y procedimiento de rescate). Nuevos controles en §16.3, revisión de inventario en §14.3, entradas de glosario y FAQ. |
| 1.3.0 | 2026-08-28 | Cesar Villegas | Se agrega §0 (cómo usar el documento): las 12 reglas de práctica diaria, índice por situación, niveles de cumplimiento por repositorio y tabla de reglas con condición de activación. Se marcan como inactivas o parcialmente inactivas §9.6, §11.6, §11.8, §14.1, §15.1, §15.2, §17.1 y §17.2. |

**Próxima revisión programada:** trimestral, junto con la auditoría de cumplimiento del §14.3.
